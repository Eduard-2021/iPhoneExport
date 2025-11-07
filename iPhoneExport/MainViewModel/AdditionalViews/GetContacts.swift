//
//  GetContacts.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 07.11.2025.
//

import SwiftUI
import SQLite3


class GetContacts {
    
    func readContacts(from dbURL: URL) -> [Contact] {
        var db: OpaquePointer?
        var contacts: [Int: Contact] = [:]
        
        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
            print("❌ Не вдалося відкрити базу контактів.")
            return []
        }
        
        defer { sqlite3_close(db) }
        
        // 1️⃣ Зчитуємо основну інформацію про контакти
        let personQuery = "SELECT ROWID, First, Last, Organization, Note, Birthday FROM ABPerson;"
        var personStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, personQuery, -1, &personStmt, nil) == SQLITE_OK {
            while sqlite3_step(personStmt) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(personStmt, 0))
                let first = sqlite3_column_text(personStmt, 1).flatMap { String(cString: $0) } ?? ""
                let last = sqlite3_column_text(personStmt, 2).flatMap { String(cString: $0) } ?? ""
                let org = sqlite3_column_text(personStmt, 3).flatMap { String(cString: $0) }
                let note = sqlite3_column_text(personStmt, 4).flatMap { String(cString: $0) }
                let bday = sqlite3_column_text(personStmt, 5).flatMap { String(cString: $0) }
                
                contacts[id] = Contact(first: first, last: last, organization: org, note: note, birthday: bday)
            }
            sqlite3_finalize(personStmt)
        }
        
        // 2️⃣ Зчитуємо телефони, email-и, адреси
        /*
         let multiQuery = """
         SELECT mv.record_id, ml.value AS label, me.value AS value
         FROM ABMultiValue mv
         JOIN ABMultiValueLabel ml ON ml.ROWID = mv.label
         JOIN ABMultiValueEntry me ON me.parent_id = mv.ROWID;
         """
         var multiStmt: OpaquePointer?
         if sqlite3_prepare_v2(db, multiQuery, -1, &multiStmt, nil) == SQLITE_OK {
         while sqlite3_step(multiStmt) == SQLITE_ROW {
         let personId = Int(sqlite3_column_int(multiStmt, 0))
         guard var contact = contacts[personId] else { continue }
         
         let label = sqlite3_column_text(multiStmt, 1).flatMap { String(cString: $0) } ?? ""
         let value = sqlite3_column_text(multiStmt, 2).flatMap { String(cString: $0) } ?? ""
         
         if value.contains("@") {
         contact.emails.append((label, value))
         } else if value.rangeOfCharacter(from: .decimalDigits) != nil {
         contact.phones.append((label, value))
         } else {
         contact.addresses.append((label, value))
         }
         
         contacts[personId] = contact
         }
         sqlite3_finalize(multiStmt)
         }
         */
        let multiQuery = "SELECT record_id, value FROM ABMultiValue;"
        
        var multiStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, multiQuery, -1, &multiStmt, nil) == SQLITE_OK {
            while sqlite3_step(multiStmt) == SQLITE_ROW {
                let personId = Int(sqlite3_column_int(multiStmt, 0))
                guard var contact = contacts[personId] else { continue }
                
                let value = sqlite3_column_text(multiStmt, 1).flatMap { String(cString: $0) } ?? ""
                
                guard !value.isEmpty else { continue }
                
                if value.contains("@") {
                    contact.emails.append(("email", value))
                } else {
                    contact.phones.append(("mobile", value))
                }
                
                contacts[personId] = contact
            }
            sqlite3_finalize(multiStmt)
        }
        
        return Array(contacts.values)
    }
}

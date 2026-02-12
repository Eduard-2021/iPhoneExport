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
            print("Erro during opening contacts")
            return []
        }
        
        defer { sqlite3_close(db) }
        
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

         let multiQuery = "SELECT record_id, property, value FROM ABMultiValue;"
         var listOfContactsThatHasDataAboutBirthday: [Int] = []
        
         var multiStmt: OpaquePointer?
         if sqlite3_prepare_v2(db, multiQuery, -1, &multiStmt, nil) == SQLITE_OK {
             while sqlite3_step(multiStmt) == SQLITE_ROW {
                 let personId = Int(sqlite3_column_int(multiStmt, 0))
                 let property = Int(sqlite3_column_int(multiStmt, 1))
                 let value = sqlite3_column_text(multiStmt, 2).flatMap { String(cString: $0) } ?? ""
                 
                 guard var contact = contacts[personId], !value.isEmpty else { continue }

                 if let birthday = contact.birthday, listOfContactsThatHasDataAboutBirthday.contains(where: { $0 == personId }) == false {
                     let birthdayNew = convertBirthdayToVCardFormat(birthday)
                     contact.birthday = birthdayNew
                     listOfContactsThatHasDataAboutBirthday.append(personId)
                     print(birthdayNew!)
                 }
                 
                 print(value)
                 
                 
                 if value.contains("@") {
                     contact.emails.append(("email", value))
                 }
                  
                 
                 switch property {
                 case 3, 4, 31, 100, 101, 2000:   // телефони на різних iOS
                     if !value.contains("@") {
                         contact.phones.append(("mobile", value))
                     }

                 default:
                     continue
                 }

                 contacts[personId] = contact
             }
             sqlite3_finalize(multiStmt)
         }
        return Array(contacts.values)
    }
    
    func convertBirthdayToVCardFormat(_ birthday: String?) -> String? {
        guard let birthday = birthday,
              let timestamp = Double(birthday) else { return birthday }

        // Конвертуємо UNIX timestamp у дату
        let date = Date(timeIntervalSinceReferenceDate: timestamp)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        return formatter.string(from: date)
    }
    
    
    func readBirthdays(from dbURL: URL) -> [Contact] {
        var db: OpaquePointer?
        var contacts: [Contact] = []

        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
            print("Error during opening contacts")
            return []
        }
        defer { sqlite3_close(db) }

        let query = """
        SELECT First, Last, Organization, Note, Birthday
        FROM ABPerson;
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let first = sqlite3_column_text(stmt, 0).flatMap { String(cString: $0) } ?? ""
                let last = sqlite3_column_text(stmt, 1).flatMap { String(cString: $0) } ?? ""
                let org = sqlite3_column_text(stmt, 2).flatMap { String(cString: $0) }
                let note = sqlite3_column_text(stmt, 3).flatMap { String(cString: $0) }
                var birthday = sqlite3_column_text(stmt, 4).flatMap { String(cString: $0) }
                
                if let birthdayNew = birthday {
                    birthday = convertBirthdayToVCardFormat(birthday)
                    print(birthday!)
                }

                contacts.append(Contact(
                    first: first,
                    last: last,
                    organization: org,
                    note: note,
                    birthday: birthday
                ))
            }
            sqlite3_finalize(stmt)
        } else {
            print("Error: \(String(cString: sqlite3_errmsg(db)))")
        }

        return contacts
    }
    
    
    
}

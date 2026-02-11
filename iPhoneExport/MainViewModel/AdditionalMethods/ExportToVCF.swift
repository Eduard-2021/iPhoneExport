//
//  ExportToVCF.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 07.11.2025.
//

import SwiftUI

class ExportToVCF {
    
    func performExport(_ contacts: [Contact], _ vcfOutputPath: URL) -> Bool {
        var vcf = ""
        for c in contacts {
            vcf += """
            BEGIN:VCARD
            VERSION:3.0
            N:\(c.last);\(c.first);;;
            FN:\(c.first) \(c.last)
            \(c.organization.map { "ORG:\($0)" } ?? "")
            \(c.note.map { "NOTE:\($0)" } ?? "")
            \(c.birthday.map { "BDAY:\($0)" } ?? "")\n
            """
            print("\(c.last);\(c.first)")
            
            if let birthdayNew = c.birthday {
                print(birthdayNew)
            }

            for (label, phone) in c.phones {
                vcf += "TEL;TYPE=\(label):\(phone)\n"
            }
            for (label, email) in c.emails {
                vcf += "EMAIL;TYPE=\(label):\(email)\n"
            }
            for (label, addr) in c.addresses {
                vcf += "ADR;TYPE=\(label):;;\(addr);;;;\n"
            }

            vcf += "END:VCARD\n\n"
            
            if let birthdayNew = c.birthday {
                print(birthdayNew)
            }
        }
        do {
            try vcf.write(to: vcfOutputPath, atomically: true, encoding: .utf8)
            print("Contacts exported: \(vcfOutputPath.path)")
            return true
        } catch {
            return false
        }
    }
}

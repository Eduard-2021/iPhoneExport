//
//  MainViewModel.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 05.11.2025.
//

import SwiftUI
import SQLite3

class MainViewModel: ObservableObject {
    
    //MARK: - Properties
    
    @Published var isShowAlert = false
    @Published var isProgressViewShow = false
    
    var messageOfAlert = "All finished"
    
    let extractedMedia  = ExtractedMedia()
    let exportToVCF = ExportToVCF()
    let getContacts = GetContacts()
    
  
    
//    private let backupPath = URL(string: "$HOME/Desktop")
    private let backupPath = URL(string: "/Users/macintoshhd/Desktop")
//    private let backupPath = FileManager.default.temporaryDirectory.appendingPathComponent("iPhoneBackup")
    private let vcfOutputPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/ContactsExport.vcf")
    private let mediaOutputDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/ExtractedMedia")
    private let backupDir = URL(string: "/Users/macintoshhd/Desktop/00008030-000E54D12682802E")

    
    //MARK: - Methods
    
    func runUploadContacts(){
        print("🔄 Створюється резервна копія iPhone...")
        //        if createBackup() {
        print("✅ Резервна копія створена.")
        if let dbURL = findContactsDatabase() {
            print("Знайдено базу контактів: \(dbURL.path)")
            let contacts = getContacts.readContacts(from: dbURL)
            print("Знайдено \(contacts.count) контактів.")
            if exportToVCF.performExport(contacts, vcfOutputPath) {
                print("Усі контакти експортовано у формат .vcf")
            }
        } else {
            print("⚠️ Не знайдено базу контактів у резервній копії.")
        }
        guard let backupDir = backupDir else {return}
        extractedMedia.performExtraction(backupDir: backupDir, mediaOutputDir: mediaOutputDir)
//    }
    }
    
    
    // 1️⃣ Створення резервної копії
    func createBackup() -> Bool {
        let process = Process()
        process.launchPath = "/opt/homebrew/bin/idevicebackup2"
        
        if let backupPath = backupPath?.path {
            process.arguments = ["backup", "--full", backupPath]
        } else {
            return false
        }

        let pipe = Pipe()
        process.standardOutput = nil
        process.standardError = nil
        process.launch()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    // 2️⃣ Пошук бази контактів
    func findContactsDatabase() -> URL? {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: backupPath!, includingPropertiesForKeys: nil) else {
            return nil
        }

        for case let file as URL in enumerator {
            let name = file.lastPathComponent.lowercased()
            if name == "31bb7ba8914766d4ba40d6dfb6113c8b614be442" {
                    return file
            }
        }
        return nil
    }
}

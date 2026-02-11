//
//  WorkWithBackUp.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 20.11.2025.
//

import Foundation

class WorkWithBackUp {
    
    // 1️⃣ Створення резервної копії
    func createBackup(backUpFolderPath: String, _ whatUpload: WhatUpload, mainViewModel: MainViewModel, completionHandler: @escaping (Bool, String) ->())  {
        var outputForFunc: String?
        mainViewModel.processMain = Process()
        guard let process = mainViewModel.processMain else {
            completionHandler(false, "")
            return ()
        }
        process.launchPath = "/opt/homebrew/bin/idevicebackup2"
        process.arguments = ["backup", backUpFolderPath]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        
        let handle = pipe.fileHandleForReading

        handle.readabilityHandler = { h in
            let data = h.availableData
            if data.isEmpty { return }
            if let output = String(data: data, encoding: .utf8) {
                print(output) // можна прибрати або логувати у файл
                outputForFunc = output
            } else {
                outputForFunc = nil
            }
        }
        
        do {
            try process.run()
        } catch {
            print("Failed to create a copy: \(error)")
            completionHandler(false, "")
            return
        }
        
        if whatUpload == .contacts {
            DispatchQueue.global().async {
                var fileWithContactsURL = mainViewModel.findNeccesaryDataInDatabase.performSearch(fileName: Constants.nameOfFileWithContacts, backUpFolderPath: backUpFolderPath)
                while fileWithContactsURL == nil {
                    fileWithContactsURL = mainViewModel.findNeccesaryDataInDatabase.performSearch(fileName: Constants.nameOfFileWithContacts, backUpFolderPath: backUpFolderPath)
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + 20) {
                    process.terminate() // ОС надсилає сигнал SIGTERM
                }
            }
        }
        
        DispatchQueue.global().async {
            process.waitUntilExit()
            
            let status = process.terminationStatus
            DispatchQueue.main.async {
                if status == 0 {
                    print("The process was completed successfully")
                } else {
                    print("The process was stopped (code: \(status)).")
                }
                print("Let's move on to the next code.")
            }
            
            if let outputForFunc = outputForFunc {
                completionHandler(true, outputForFunc)
                return
            }
            completionHandler(false, "")
            
        }
    }
}

//
//  InstLib.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 13.11.2025.
//

import Foundation

class InstLib {
    
    func performIns() -> Bool {
        let process = Process()
        let pipe = Pipe()
        
        // Виконуємо команду через /bin/zsh (замість /bin/bash, бо brew часто інсталюється в zsh)
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "/opt/homebrew/bin/brew install libimobiledevice"]
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
        } catch {
            print("Error druring start process: \(error)")
            return false
        }
        
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        if process.terminationStatus == 0 {
            print("Inst OK")
            return true
        } else {
            print("Inst Error: \(process.terminationStatus)).")
            return false
        }
    }
}

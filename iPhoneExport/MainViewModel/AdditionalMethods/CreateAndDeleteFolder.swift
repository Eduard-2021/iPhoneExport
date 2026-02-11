//
//  CreateDeleteFolder.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 06.02.2026.
//

import Foundation

class CreateAndDeleteFolder {
    
    let fileManager = FileManager.default

    func createTempFolder(documentsURL: URL, tempFolder: String) {
        let tempFolderURL = documentsURL.appendingPathComponent(tempFolder)
        do {
            if !fileManager.fileExists(atPath: tempFolderURL.path) {
                try fileManager.createDirectory(
                    at: tempFolderURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        } catch {
            print("Error creating folder:", error)
        }
    }

    func deleteTempFolder(documentsURL: URL, tempFolder: String) {
        let tempFolderURL = documentsURL.appendingPathComponent(tempFolder)
        do {
            if fileManager.fileExists(atPath: tempFolderURL.path) {
                try fileManager.removeItem(at: tempFolderURL)
            }
        } catch {
        }
    }
}

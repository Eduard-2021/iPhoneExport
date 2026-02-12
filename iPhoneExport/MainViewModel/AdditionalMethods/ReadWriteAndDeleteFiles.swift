//
//  ReadWriteAndDeleteFiles.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 12.11.2025.
//


import Foundation

enum FileSaveError: Error {
    case couldNotSave
    case couldNotRemote
}

class ReadWriteAndDeleteFiles {
    
    func writeCapabilityCheck(folderForUploadingURL: URL, completionHandler: @escaping (Bool) ->()){
        let fileURL = folderForUploadingURL.appendingPathComponent("Test")

        do {
            try Data().write(to: fileURL)
            try removeAnother(fileURL: fileURL)
            completionHandler(true)
        } catch let error {
            completionHandler(false)
        }
    }
    
    func removeAnother(fileURL: URL) throws {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        } catch let removeError {
            throw FileSaveError.couldNotRemote
        }
    }

}

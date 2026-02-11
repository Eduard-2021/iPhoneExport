//
//  FindNeccesaryDataInDatabase.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 30.01.2026.
//

import Foundation

class FindNeccesaryDataInDatabase {
    
    func performSearch(fileName: String, backUpFolderPath: String) -> URL? {
        let fm = FileManager.default
        guard let backUpFolderPathURL = URL(string: backUpFolderPath),
              let enumerator = fm.enumerator(at:backUpFolderPathURL, includingPropertiesForKeys: nil) else {
            return nil
        }
        
        for case let file as URL in enumerator {
            let name = file.lastPathComponent.lowercased()
            if name == fileName {
                print(fileName)
                return file
            }
        }
        return nil
    }
}

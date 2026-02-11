//
//  GetNameOfNewestFolder.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 18.11.2025.
//

import Foundation

class GetNameOfNewestFolder {
    
    func newestFolder(in backUpFolderPath: String) -> URL? {
        let fileManager = FileManager.default

        guard let directoryURL = URL(string: backUpFolderPath),
              let contents = try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey],
                options: [.skipsHiddenFiles]
              ) else {
            return nil
        }

        // Фільтруємо тільки папки
        let folders = contents.filter { url in
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            return isDirectory.boolValue
        }

        guard !folders.isEmpty else { return nil }

        // Визначаємо дату (спочатку modificationDate, якщо нема — creationDate)
        let newest = folders.max { a, b in
            let aDate = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                ?? (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate)
                ?? .distantPast

            let bDate = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                ?? (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate)
                ?? .distantPast

            return aDate < bDate
        }

        return newest
    }
}

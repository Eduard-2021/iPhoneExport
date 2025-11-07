//
//  ExtractedMedia.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 07.11.2025.
//

import SwiftUI
import SQLite3


class ExtractedMedia {
    
    func performExtraction(backupDir: URL, mediaOutputDir: URL){

        let fileManager = FileManager.default
        
        // MARK: - Відкриваємо Manifest.db
        let manifestDBPath = backupDir.appendingPathComponent("Manifest.db").path
        var db: OpaquePointer?

        if sqlite3_open(manifestDBPath, &db) != SQLITE_OK {
            print("❌ Не вдалося відкрити Manifest.db")
            exit(1)
        }

        defer { sqlite3_close(db) }

        // MARK: - SQL-запит для фото/відео
        let query = """
        SELECT fileID, relativePath
        FROM Files
        WHERE relativePath LIKE '%.JPG'
           OR relativePath LIKE '%.JPEG'
           OR relativePath LIKE '%.HEIC'
           OR relativePath LIKE '%.MOV'
           OR relativePath LIKE '%.MP4';
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) != SQLITE_OK {
            print("❌ Помилка SQL-запиту: \(String(cString: sqlite3_errmsg(db)))")
            exit(1)
        }

        print("🔍 Пошук медіафайлів у резервній копії...")

        // MARK: - Копіювання
        var extractedCount = 0
        var skippedCount = 0
        var seenDestinations = Set<String>()

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let fileIDCStr = sqlite3_column_text(stmt, 0),
                  let relPathCStr = sqlite3_column_text(stmt, 1) else { continue }

            let fileID = String(cString: fileIDCStr)
            let relativePath = String(cString: relPathCStr)

            let subdir = String(fileID.prefix(2))
            let srcPath = backupDir.appendingPathComponent("\(subdir)/\(fileID)").path

            let destPath = mediaOutputDir.appendingPathComponent(relativePath).path
            let destFolder = (destPath as NSString).deletingLastPathComponent

            if seenDestinations.contains(destPath) {
                skippedCount += 1
                continue
            }
            seenDestinations.insert(destPath)

            guard fileManager.fileExists(atPath: srcPath) else {
                skippedCount += 1
                print("⚠️ Не знайдено файл: \(relativePath)")
                continue
            }

            try? fileManager.createDirectory(atPath: destFolder, withIntermediateDirectories: true)

            do {
                try fileManager.copyItem(atPath: srcPath, toPath: destPath)
                print("✅ \(relativePath)")
                extractedCount += 1
            } catch {
                print("⚠️ Помилка копіювання \(relativePath): \(error.localizedDescription)")
                skippedCount += 1
            }
        }

        sqlite3_finalize(stmt)

        // MARK: - Результат
        print("\n🎉 Витяг завершено!")
        print("📁 Файли збережено в: \(mediaOutputDir.path)")
        print("✅ Успішно витягнуто: \(extractedCount)")
        print("⚠️ Пропущено або дублікати: \(skippedCount)")
    }
}

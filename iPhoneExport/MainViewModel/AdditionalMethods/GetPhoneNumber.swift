//
//  GetPhoneNumber.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 19.11.2025.
//

import Foundation
import Compression
import SQLite3

enum SQLiteError: Error {
    case openDatabase
    case prepare
}

class GetPhoneNumber {
    
   // let filePath = "/Users/macintoshhd/Downloads/DataFrom_iPhone/.TEMP/00008120-000654C80A98201E/Snapshot/3d/5cfa9db121949c3bf3b889caefc8d5ba766dbd09"
    
    
    func getNecessaryNumber(path: String) -> String? {
        let allNumbersInFile = extractPhoneNumbersFromRawFile(path: path)
        return mostLikelyOwnerPhone(from: allNumbersInFile)
    }
    

    func extractPhoneNumbersFromRawFile(path: String) -> [String] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return []
        }

        let text = String(decoding: data, as: UTF8.self)

        // Міжнародний номер БЕЗ "+"
        // 380xxxxxxxxx → 12 цифр (Україна як приклад)
        let pattern = #"\b\d{11,15}\b"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        return matches.compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }
    
    
    func mostLikelyOwnerPhone(from phones: [String]) -> String? {
        let counts = Dictionary(grouping: phones, by: { $0 })
            .mapValues { $0.count }
        let result = counts.max { $0.value < $1.value }?.key
        return result
    }
    
    
    func readDevicePhoneNumber(from dbURL: URL) -> String? {
        var result: String?
        let resultArray = extractPhoneNumbers(from: dbURL)
        result = resultArray.first
        return result
    }
    
    
    private func phoneCandidates(in text: String) -> [String] {
        let pattern = #"(\+?\d[\d\(\)\-\s]{6,}\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var found: [String] = []
        for m in regex.matches(in: text, options: [], range: range) {
            if let r = Range(m.range(at: 1), in: text) {
                let raw = String(text[r])
                let cleaned = normalizePhone(raw)
                if isPlausiblePhone(cleaned) { found.append(cleaned) }
            }
        }
        return found
    }

    private func normalizePhone(_ s: String) -> String {
        var out = ""
        for (i, ch) in s.enumerated() {
            if ch == "+" && i == 0 { out.append(ch); continue }
            if ch.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }) {
                out.append(ch)
            }
        }
        return out
    }

    private func isPlausiblePhone(_ s: String) -> Bool {
        let digits = s.filter { $0.isNumber }
        return digits.count >= 7 // або >=10 для жорсткішої перевірки
    }

    func extractPhoneNumbers(from fileURL: URL) -> [String] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else {
            return []
        }

        // перевіримо розмір
        if let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
           let size = attrs[.size] as? NSNumber {
        }

        // 1) Спроба повного читання з кількома кодуваннями
        let encodings: [String.Encoding] = [.utf8, .ascii, .isoLatin1, .windowsCP1251]
        for enc in encodings {
            do {
                let text = try String(contentsOf: fileURL, encoding: enc)
                let found = phoneCandidates(in: text)
                if !found.isEmpty {
                    let filtered = found.filter { $0.hasPrefix("380") }
                    return Array(Set(filtered))
                }
            } catch {
            }
        }

        if let stream = InputStream(url: fileURL) {
            stream.open()
            defer { stream.close() }
            let chunkSize = 64 * 1024 // 64KB
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
            defer { buffer.deallocate() }

            var leftover = "" // зберігаємо хвіст попереднього чанка для перетину
            var results = [String]()
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: chunkSize)
                if read <= 0 { break }
                let data = Data(bytes: buffer, count: read)
                let chunkStr = String(decoding: data, as: UTF8.self)
                let combined = leftover + chunkStr
                let found = phoneCandidates(in: combined)
                for f in found { results.append(f) }

                let tailCount = 200
                if combined.count > tailCount {
                    let idx = combined.index(combined.endIndex, offsetBy: -tailCount)
                    leftover = String(combined[idx...])
                } else {
                    leftover = combined
                }
            }
            if !results.isEmpty {
                return Array(Set(results))
            }
        }

        if let data = try? Data(contentsOf: fileURL) {
            var candidates = [String]()
            var current = [UInt8]()
            let allowed: Set<UInt8> = {
                var s = Set<UInt8>()
                for c in UInt8(ascii: "+")...UInt8(ascii: "+") { s.insert(c) } // '+'
                for c in UInt8(ascii: "0")...UInt8(ascii: "9") { s.insert(c) }
                s.insert(UInt8(ascii: "(")); s.insert(UInt8(ascii: ")"))
                s.insert(UInt8(ascii: "-")); s.insert(UInt8(ascii: " "))
                return s
            }()

            func flushCurrent() {
                guard !current.isEmpty else {
                    return
                }
                if let str = String(bytes: current, encoding: .utf8) {
                    let cleaned = normalizePhone(str)
                    if isPlausiblePhone(cleaned) { candidates.append(cleaned) }
                } else {
                    let str = String(bytes: current, encoding: .isoLatin1) ?? ""
                    let cleaned = normalizePhone(str)
                    if isPlausiblePhone(cleaned) { candidates.append(cleaned) }
                }
                current.removeAll()
            }

            for byte in data {
                if allowed.contains(byte) {
                    current.append(byte)
                } else {
                    flushCurrent()
                }
            }
            flushCurrent()
            if !candidates.isEmpty {
                return Array(Set(candidates))
            }
        }
        return []
    }
}

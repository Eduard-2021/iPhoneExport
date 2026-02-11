//
//  GetIMEI.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 21.11.2025.
//

import Foundation

class GetIMEI {
    /// Повертає IMEI з Info.plist у резервній копії iPhone
    func extractIMEI(from backupFolder: URL) -> String? {
        
        // Шлях до Info.plist
        let plistURL = backupFolder.appendingPathComponent("Info.plist")
        
        guard FileManager.default.fileExists(atPath: plistURL.path) else {
            print("Info.plist not found in path: \(plistURL.path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: plistURL)
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                
                // На нових iOS IMEI знаходиться в ключі "IMEI"
                if let imei = plist["IMEI"] as? String {
                    return imei
                }
                
                // Деякі версії iOS можуть зберігати як масив (рідко)
                if let arr = plist["IMEI"] as? [String], let first = arr.first {
                    return first
                }
                
                print("Not found row with IMEI in Info.plist")
            }
        } catch {
            print("Eroor druning reading Info.plist: \(error)")
        }
        
        return nil
    }
}

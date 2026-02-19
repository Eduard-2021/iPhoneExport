//
//  UploadWhatsApp.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 13.02.2026.
//

import Foundation
import SQLite3




class UploadWhatsApp {
    // MARK: - Шляхи
    
    func uploadDataWithWhatsApp(backupFilePATH: String, outputHTML_PATH: String) {
        var db: OpaquePointer?
                        
        let rc = sqlite3_open(backupFilePATH, &db)
        if rc != SQLITE_OK {
            print("❌ sqlite3_open failed:", String(cString: sqlite3_errmsg(db)))
            exit(1)
        }
        guard db != nil else {
            fatalError("❌ db is nil after sqlite3_open")
        }
        
        // MARK: - 1. Витягаємо всі контакти
        var contacts: [String: String] = [:] // JID -> Name
        let contactQuery = "SELECT ZCONTACTJID, ZNAME FROM ZWAPROFILEPUSHNAME;"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, contactQuery, -1, &stmt, nil)
        while sqlite3_step(stmt) == SQLITE_ROW {
            let jid = String(cString: sqlite3_column_text(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            contacts[jid] = name
        }
        sqlite3_finalize(stmt)
        stmt = nil
        
        // MARK: - 2. Витягаємо всі чати
        var chats: [String: [(String, String, Bool)]] = [:] // JID -> [(time, text, fromMe)]
        
        /* OLD KOD
        let messageQuery = """
    SELECT ZTEXT, ZISFROMME, ZMESSAGEDATE, ZFROMJID, ZTOJID
    FROM ZWAMESSAGE
    WHERE ZTEXT IS NOT NULL
    ORDER BY ZMESSAGEDATE;
    """
        */
        let messageQuery = """
        SELECT
        ZTEXT,
        ZISFROMME,
        ZMESSAGEDATE,
        ZFROMJID,
        ZTOJID,
        ZMEDIALOCALPATH,
        ZMEDIACAPTION,
        ZMESSAGETYPE
        FROM ZWAMESSAGE
        ORDER BY ZMESSAGEDATE;
        """
        
        let rc2 = sqlite3_prepare_v2(db, messageQuery, -1, &stmt, nil)
        if rc2 != SQLITE_OK {
            print("❌ sqlite3_prepare_v2 failed:", String(cString: sqlite3_errmsg(db)))
            sqlite3_close(db)
            exit(1)
        }
        sqlite3_prepare_v2(db, messageQuery, -1, &stmt, nil)
        while sqlite3_step(stmt) == SQLITE_ROW {
            let text = String(cString: sqlite3_column_text(stmt, 0))
            let fromMe = sqlite3_column_int(stmt, 1) == 1
            let dateVal = sqlite3_column_double(stmt, 2)
            let timestamp = Date(timeIntervalSince1970: dateVal + 978307200)
            let timeStr = ISO8601DateFormatter().string(from: timestamp)
            
//            let fromJID = String(cString: sqlite3_column_text(stmt, 3))
//            let toJID = String(cString: sqlite3_column_text(stmt, 4))
            
            let fromJID: String?
            if let cStr = sqlite3_column_text(stmt, 3) {
                fromJID = String(cString: cStr)
            } else {
                fromJID = nil
            }

            let toJID: String?
            if let cStr = sqlite3_column_text(stmt, 4) {
                toJID = String(cString: cStr)
            } else {
                toJID = nil
            }

            let chatJID = fromMe ? toJID : fromJID
            
            if chats[chatJID ?? ""] == nil {
                chats[chatJID ?? ""] = []
            }
            chats[chatJID ?? ""]?.append((timeStr, text, fromMe))
        }
        sqlite3_finalize(stmt)
        stmt = nil
        sqlite3_close(db)
        
        // MARK: - 3. Генеруємо HTML з JS
        var html = """
    <!DOCTYPE html>
    <html lang="uk">
    <head>
    <meta charset="UTF-8">
    <title>WhatsApp Export</title>
    <style>
    body { font-family: Arial; display:flex; margin:0; background:#ece5dd; height:100vh; }
    #chatList { width:250px; border-right:1px solid #ccc; overflow-y:auto; background:#f0f0f0; }
    #chatContent { flex:1; padding:10px; overflow-y:auto; }
    .chatItem { padding:10px; cursor:pointer; border-bottom:1px solid #ccc; }
    .chatItem:hover { background:#ddd; }
    .msg { max-width:60%; padding:8px 12px; margin:6px 0; border-radius:8px; clear:both; }
    .me { background:#dcf8c6; float:right; }
    .them { background:#fff; float:left; }
    .time { font-size:10px; color:#666; text-align:right; }
    </style>
    </head>
    <body>
    <div id="chatList">
    """
        
        // Ліва панель
        for (jid, _) in chats {
            let displayName = contacts[jid] ?? jid
            html += "<div class='chatItem' onclick='showChat(\"\(jid)\")'>\(displayName)</div>\n"
        }
        
        html += "</div><div id='chatContent'>"
        
        for (jid, messages) in chats {
            html += "<div class='chatWindow' id='chat_\(jid)' style='display:none;'>"
            for msg in messages {
                let cls = msg.2 ? "me" : "them"
                html += """
            <div class='msg \(cls)'>\(escape(msg.1))<div class='time'>\(msg.0)</div></div>
            """
            }
            html += "</div>"
        }
        
        html += """
    </div>
    <script>
    function showChat(jid){
        document.querySelectorAll('.chatWindow').forEach(div=>div.style.display='none');
        document.getElementById('chat_'+jid).style.display='block';
    }
    </script>
    </body>
    </html>
    """
                
        try! html.write(toFile: outputHTML_PATH, atomically: true, encoding: .utf8)
        print("Експорт завершено: \(outputHTML_PATH)")
    }
    
    func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}

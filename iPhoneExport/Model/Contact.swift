//
//  Contact.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 05.11.2025.
//

import SwiftUI

struct Contact {
    var first: String
    var last: String
    var organization: String?
    var note: String?
    var birthday: String?
    var phones: [(label: String, value: String)] = []
    var emails: [(label: String, value: String)] = []
    var addresses: [(label: String, value: String)] = []
}

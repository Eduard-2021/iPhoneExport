//
//  AddTextFieldAlert.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 12.11.2025.
//

import SwiftUI

extension View {

    func textFieldAlert(isShowing: Binding<Bool>,
                        answerFromAlert: Binding<String>,
                        title: String,
                        alertMessage: String,
                        alertPlaceholder: String,
                        action: @escaping () -> Void,
                        mainViewModel: MainViewModel) -> some View {
        TextFieldAlert(isShowing: isShowing,
                       answerFromAlert: answerFromAlert,
                       presenting: self,
                       title: title,
                       alertMessage: alertMessage,
                       alertPlaceholder: alertPlaceholder,
                       action: action,
                       mainViewModel: mainViewModel)
    }
}

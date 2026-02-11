//
//  TextFieldAlert.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 12.11.2025.
//

import SwiftUI


struct TextFieldAlert<Presenting>: View where Presenting: View {
    
    @Binding var isShowing: Bool
    @Binding var answerFromAlert: String
    let presenting: Presenting
    let title: String
    let alertMessage: String
    let alertPlaceholder: String
    let action: () -> Void
    let mainViewModel: MainViewModel
    
    let customColor = Color(red: 1, green: 0.99, blue: 1)
    
    var body: some View {
        ZStack {
            self.presenting
                .disabled(isShowing)
            Rectangle()
                .frame(width: Constants.widthOfBigButton*3)
                .opacity(0)
            VStack {
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12).bold())
                Text(alertMessage)
                    .font(.system(size: 8))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    TextField(alertPlaceholder, text: $answerFromAlert)
                Divider()
                Button(action: {
                    isShowing.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        action()
                    }
                }) {
                    Text("Ok")
                        .foregroundColor(.white)
                        .frame(width: Constants.widthOfSmallButton*0.5, height: Constants.heightOfProgressView)
                        .padding(.vertical, Constants.heightOfProgressView)
                        .background(.blue)
                }
            }
            .padding()
            .background(Color.white)
            .frame(width: Constants.widthOfBigButton * 1.5)
            .opacity(self.isShowing ? 1 : 0)
        }
    }
}

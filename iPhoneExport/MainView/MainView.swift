//
//  ContentView.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 07.11.2025.
//


import SwiftUI

struct MainView: View {
    
    @StateObject var mainViewModel = MainViewModel()
    
    var body: some View {
        VStack {
            Button {
                mainViewModel.runUploadContacts()
            } label: {
                Text("Start")
                    .foregroundColor(.white)
                    .frame(width: Constants.widthOfButton)
                    .font(.callout.bold())
                    .padding(.vertical, Constants.heightOfMainButtons)
                    .background(.blue)
            }
            
            if mainViewModel.isProgressViewShow {
                ProgressOfLoad(height: Constants.heightOfProgressView, color: .white)
            }
            
        }
        .alert(mainViewModel.messageOfAlert, isPresented: $mainViewModel.isShowAlert) {
            Text("Error")
                .foregroundColor(.white)
                .frame(width: Constants.widthOfButton)
                .font(.callout.bold())
                .padding(.vertical, Constants.heightOfMainButtons)
                .background(.blue)
        }
        .padding()
    }
}


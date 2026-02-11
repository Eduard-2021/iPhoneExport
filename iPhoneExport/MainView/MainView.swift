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
                mainViewModel.selectCommonFolderForUploading()
            } label: {
                Text("Select folder for uploading")
                    .foregroundColor(.white)
                    .frame(width: Constants.widthOfBigButton)
                    .font(.callout.bold())
                    .padding(.vertical, Constants.heightOfMainButtons/2)
                    .background(!mainViewModel.isSetupCompleted ? .blue : .gray)
            }
            .padding(.vertical, Constants.verticalDistanceBetweenMainButtons)
            .allowsHitTesting(!mainViewModel.isSetupCompleted && mainViewModel.isAllowAnyTouch)
            
            
            Button {
                mainViewModel.runUploading(.contacts)
            } label: {
                Text("Uploading contacts")
                    .foregroundColor(.white)
                    .frame(width: Constants.widthOfBigButton)
                    .font(.callout.bold())
                    .padding(.vertical, Constants.heightOfMainButtons)
                    .background(mainViewModel.isSetupCompleted ? .blue : .gray)
            }
            .padding(.vertical, Constants.verticalDistanceBetweenMainButtons)
            .allowsHitTesting(mainViewModel.isSetupCompleted && mainViewModel.isAllowAnyTouch)
            
            Button {
                mainViewModel.runUploading(.all)
            } label: {
                Text("Uploading everything")
                    .foregroundColor(.white)
                    .frame(width: Constants.widthOfSmallButton)
                    .font(.callout)
                    .fontWeight(.thin)
                    .padding(.vertical, Constants.heightOfMainButtons/2)
                    .background(mainViewModel.isSetupCompleted ? .blue : .gray)
            }
            .padding(.vertical, Constants.verticalDistanceBetweenMainButtons)
            .allowsHitTesting(mainViewModel.isSetupCompleted && mainViewModel.isAllowAnyTouch)
            
            Button {
                mainViewModel.quit_iPhoneExport()
            } label: {
                Text("Quit iPhoneExport")
                    .foregroundColor(.white)
                    .frame(width: Constants.widthOfSmallButton)
                    .font(.callout)
                    .fontWeight(.thin)
                    .padding(.vertical, Constants.heightOfMainButtons/2)
                    .background(mainViewModel.isSetupCompleted ? .blue : .gray)
            }
            .padding(.vertical, Constants.verticalDistanceBetweenMainButtons)
            .allowsHitTesting(mainViewModel.isSetupCompleted && mainViewModel.isAllowAnyTouch)
            
            
            if mainViewModel.isProgressViewShow {
                ProgressOfLoad(height: Constants.heightOfProgressView, color: .white)
                    .padding()
            }
            
        }
        .alert(mainViewModel.messageOfAlert, isPresented: $mainViewModel.isShowAlert) {
            /*
            Text(mainViewModel.messageForSimpleAlert)
                .foregroundColor(.white)
                .frame(width: Constants.widthOfBigButton)
                .font(.callout.bold())
                .padding(.vertical, Constants.heightOfMainButtons)
                .background(.blue)
             */
        }
        .textFieldAlert(isShowing: $mainViewModel.isShowAlertWithQuestion,
                        answerFromAlert: $mainViewModel.answerFromAlert,
                        title: mainViewModel.alertTitle,
                        alertMessage: mainViewModel.alertMessage,
                        alertPlaceholder:mainViewModel.alertPlaceholder,
                        action: mainViewModel.completionHandler,
                        mainViewModel: mainViewModel)
        .padding()
        .background(
            Image("BackGroung1024-mac")
                .resizable()
//                .opacity(0.5)
                .frame(width: Constants.widthOfBigButton*2, height: Constants.widthOfBigButton*2)
                .aspectRatio(contentMode: .fill)
        )
        .onAppear(){
            mainViewModel.initialization()
        }
    }
}


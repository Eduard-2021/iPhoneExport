//
//  MainViewModel.swift
//  iPhoneExport
//
//  Created by Macintosh HD on 05.11.2025.
//

import SwiftUI
import SQLite3
import Combine

enum WhatUpload{
    case all
    case contacts
    case media
}

class MainViewModel: ObservableObject {
    
    //MARK: - Properties
    
    @Published var isShowAlert = false
    @Published var isProgressViewShow = false
    @Published var isSetupCompleted = false
    @Published var isShowAlertWithQuestion = false
    @Published var isAllowAnyTouch = false
    
    var messageOfAlert = "Export completed successfully"
    
    let extractedMedia  = ExtractedMedia()
    let exportToVCF = ExportToVCF()
    let getContacts = GetContacts()
    let setURLForCommonUploadingFolder = SetURLForUploadingFolder()
    let instLib = InstLib()
    let getNameOfNewestFolder = GetNameOfNewestFolder()
    let getPhoneNumber = GetPhoneNumber()
    let workWithBackUp = WorkWithBackUp()
    let getIMEI = GetIMEI()
    let findNeccesaryDataInDatabase = FindNeccesaryDataInDatabase()
    let createAndDeleteFolder = CreateAndDeleteFolder()
    
    var alertTitle = "Enter URL for work folder"
    var alertMessage = "Folder must exist"
    var alertPlaceholder = "/Users/Ali/Downloads/DataFrom_iPhone"
    var answerFromAlert = ""
    var completionHandler = {}
    
    var phoneNumber = ""
    var phoneIMEI = ""
    var phoneUDID = ""
    
    var commonFolderForUploadingWithFullPathURL: URL?
    var folderForBackupURL: URL?
    var vcfOutputPathURL: URL?
    var mediaOutputDirURL: URL?
    
    var backUpFolderPath = ""
    
    var processMain: Process?
    var resultOfCreateBackup = (true,"")
    var isfileWithPhoneNumberCreated = false
    
    var timer: Timer.TimerPublisher?
    var cancellable: AnyCancellable?

    
    //MARK: - Methods
    
    func initialization(){
        
        if let commonFolderForUploadingWithFullPath = UserDefaults.standard.string(forKey: Constants.keyForUploadingFolder) {
            isAllowAnyTouch = true
            Constants.commonFolderForUploadingWithFullPath = commonFolderForUploadingWithFullPath
            backUpFolderPath = String(commonFolderForUploadingWithFullPath.dropFirst(7)) + "/.TEMP"
            isSetupCompleted = true
            setNecceseryPath()
        } else {
            DispatchQueue.main.async{
                self.isProgressViewShow = true
            }
            DispatchQueue.global().async{
                if !self.instLib.performIns() {
                    self.messageOfAlert = "Error during installation. Please check your internet connection. The application will be closed in 5 seconds."
                    DispatchQueue.main.async{
                        self.isShowAlert = true
                    }
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5){
                        DispatchQueue.main.async{
                            self.isProgressViewShow = false
                        }
                        exit(1)
                    }
                } else {
                    DispatchQueue.main.async{
                        self.isProgressViewShow = false
                        self.isAllowAnyTouch = true
                    }
                }
            }
        }
    }
    
    func setNecceseryPath(){
        let commonFolderForUploadingWithFullPath = Constants.commonFolderForUploadingWithFullPath
        commonFolderForUploadingWithFullPathURL = URL(string: commonFolderForUploadingWithFullPath)
        guard let vcfOutputPathURL = URL(string: "\(commonFolderForUploadingWithFullPath)/ContactsExport.vcf"),
              let mediaOutputDirURL = URL(string: "\(commonFolderForUploadingWithFullPath)/ExtractedMedia") else {
            return
        }
        self.vcfOutputPathURL = vcfOutputPathURL
        self.mediaOutputDirURL = mediaOutputDirURL
    }
     

    func selectCommonFolderForUploading(){
        setURLForCommonUploadingFolder.mainViewModel = self
        completionHandler = setURLForCommonUploadingFolder.checkAndSaveURL
        withAnimation {
            isShowAlertWithQuestion = true
        }
    }
    
    func runUploading(_ whatUpload: WhatUpload){
        isProgressViewShow = true
        isAllowAnyTouch = false
        print("Backing up iPhone...")
        guard let commonFolderForUploadingWithFullPathURL = commonFolderForUploadingWithFullPathURL else {
            return
        }
        createAndDeleteFolder.createTempFolder(documentsURL: commonFolderForUploadingWithFullPathURL, tempFolder: ".TEMP")
        DispatchQueue.global().async{
            self.workWithBackUp.createBackup(backUpFolderPath: self.backUpFolderPath, whatUpload, mainViewModel: self){ (isBackupCreated, messagesDuringCreatingBackUp) in
                if isBackupCreated && messagesDuringCreatingBackUp != "No device found.\n" {
                    print("Backup created")
                    if let newestFolder = self.getNameOfNewestFolder.newestFolder(in: self.backUpFolderPath) {
                        print("Newest folder: \(newestFolder.lastPathComponent)")
                        self.folderForBackupURL = newestFolder
                        self.phoneUDID = newestFolder.lastPathComponent
                    }
                    
                    if let folderForBackup = self.folderForBackupURL,
                       let phoneIMEI = self.getIMEI.extractIMEI(from: folderForBackup) {
                        self.phoneIMEI = phoneIMEI
                    } else {
                        print("IMEI not found")
                    }
                    
                    if let fileWithPhoneNumberURL = self.findNeccesaryDataInDatabase.performSearch(fileName: Constants.nameOfFileWithPhoneBook, backUpFolderPath: self.backUpFolderPath),
                       let phoneNumber = self.getPhoneNumber.getNecessaryNumber(path: fileWithPhoneNumberURL.path) {
                        self.phoneNumber = phoneNumber

                    } else {
                        print("No file with phone number found in backup.")
                    }
                    
                    
                    let folderForNewPhone = self.phoneNumber + "_" + self.phoneIMEI + "_" + self.phoneUDID
                    let commonFolderForUploadingWithFullPath = Constants.commonFolderForUploadingWithFullPath
                    guard let folderForBackupURL = self.folderForBackupURL,
                          let vcfOutputPathURL = URL(string: "\(commonFolderForUploadingWithFullPath)/\(folderForNewPhone)/ContactsExport.vcf"),
                          let mediaOutputDirURL = URL(string: "\(commonFolderForUploadingWithFullPath)/\(folderForNewPhone)/ExtractedMedia") else {
                        return
                    }
                    
                    let fileManager = FileManager.default
                    let commonFolderForUploadingWithFullPathAndWithoutFile = String(commonFolderForUploadingWithFullPath.dropFirst(7))
                    do {
                        try fileManager.createDirectory(atPath: "\(commonFolderForUploadingWithFullPathAndWithoutFile)/\(folderForNewPhone)", withIntermediateDirectories: true)
                    } catch{
                        print("Error")
                    }
                    
                    if whatUpload == .all || whatUpload == .contacts {
                        if let fileWithContactsURL = self.findNeccesaryDataInDatabase.performSearch(fileName: Constants.nameOfFileWithContacts, backUpFolderPath: self.backUpFolderPath) {
                            let contacts = self.getContacts.readContacts(from: fileWithContactsURL)
                            print("Found \(contacts.count) contacts")
                            if self.exportToVCF.performExport(contacts, vcfOutputPathURL) {
                                print("All contacts exported to .vcf format")
                            }
                        } else {
                            print("No contact database found in the backup")
                        }
                    }
                    
                    if whatUpload == .all || whatUpload == .media {
                        self.extractedMedia.performExtraction(folderForBackupURL: folderForBackupURL, mediaOutputDir: mediaOutputDirURL)
                    }
                    
                    self.messageOfAlert = "Export completed successfully"
                    
                    
                } else if self.resultOfCreateBackup.1 == "No device found.\n" {
                    self.messageOfAlert = "No device found"
                }
                DispatchQueue.main.async{
                    self.isProgressViewShow = false
                    self.isAllowAnyTouch = true
                    self.isShowAlert = true
                    self.createAndDeleteFolder.deleteTempFolder(documentsURL: commonFolderForUploadingWithFullPathURL, tempFolder: ".TEMP")
                    self.initVariable()
                }
            }
        }
    }
    
    func quit_iPhoneExport(){
        exit(1)   
    }
    
    func initVariable(){
        messageOfAlert = "Export completed successfully"
        answerFromAlert = ""
        
        phoneNumber = ""
        phoneIMEI = ""
        phoneUDID = ""
        
        resultOfCreateBackup = (true,"")
        isfileWithPhoneNumberCreated = false
    }
}

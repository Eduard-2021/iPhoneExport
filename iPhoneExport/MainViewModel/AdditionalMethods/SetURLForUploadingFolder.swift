
import SwiftUI

class SetURLForUploadingFolder {
    
    var mainViewModel: MainViewModel?
    let readAndWriteFiles = ReadWriteAndDeleteFiles()
    
    
    func checkAndSaveURL() {
        guard let mainViewModel = self.mainViewModel else {
            return
        }
        
        var isCorrectURL = true
        let forbiddenCharacters: [Character] = ["+", "=", "[", "]", "*", "?", ";", "«", ",", ".", "<", ">", "|", " "]
        
        if mainViewModel.answerFromAlert == "" {
            if let folderForUploading = UserDefaults.standard.string(forKey: Constants.keyForUploadingFolder) {
                mainViewModel.answerFromAlert = folderForUploading
            } else {
                errorInAlert(alertMessage: "Please enter correct path!")            }
        }
        
        for character in mainViewModel.answerFromAlert {
            if forbiddenCharacters.contains(where: {$0 == character}) {
                isCorrectURL = false
            }
        }
        
        var folderForUploadingString = mainViewModel.answerFromAlert
        if !folderForUploadingString.contains("file://") {
            folderForUploadingString = "file://" + folderForUploadingString
        }
        
        if let folderForUploadingURL = URL(string: folderForUploadingString), isCorrectURL {
            readAndWriteFiles.writeCapabilityCheck(folderForUploadingURL: folderForUploadingURL){ isFolderForUploadingCorrect in
                if isFolderForUploadingCorrect {
                    savePathAndTurnToStandardMode(folderForUploadingURL: folderForUploadingURL)
                } else {
                    errorInAlert(alertMessage: "Please enter the correct path!")
                }
            }
            
        } else {
            errorInAlert(alertMessage: "Please enter the correct path!")
        }
        
        func errorInAlert(alertMessage: String){
            mainViewModel.alertTitle = "ATTANTION!"
            mainViewModel.alertPlaceholder = "/Users/Ali/Downloads/DataFrom_iPhone"
            mainViewModel.answerFromAlert = ""
            mainViewModel.alertMessage = alertMessage
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                mainViewModel.isShowAlertWithQuestion = true
            }
        }
        
        func savePathAndTurnToStandardMode(folderForUploadingURL: URL){
            UserDefaults.standard.set(folderForUploadingURL.description, forKey: Constants.keyForUploadingFolder)
            Constants.commonFolderForUploadingWithFullPath = mainViewModel.answerFromAlert.replacingOccurrences(of: "file://", with: "")
            mainViewModel.commonFolderForUploadingWithFullPathURL = URL(string: Constants.commonFolderForUploadingWithFullPath)
//            mainViewModel.setNecceseryPath()
            withAnimation {
                mainViewModel.isSetupCompleted = true
            }
        }
    }
}

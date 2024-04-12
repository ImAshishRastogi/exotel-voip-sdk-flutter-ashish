/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation

class VoiceAppLogger {
    private static let TAG = "VoiceAppLogger"
    private static let ZIP_LOGS_AFTER_DAYS = 1
    private static var sFilesDir: String = ""
    private static var DAYS_IN_MS = 1000 * 60 * 60 * 24
    private static var UPLOAD_LOG_NUM_DAYS = 7
    private static var coordinator = NSFileCoordinator()
    private static var error: NSError?
    
    static func debug(TAG: String, message: String) {
        print("\(TAG): \(message)")
        var text = "D/" + TAG + ":" + message + "\n"
        let time = Date().string(format: "HH:mm:ss.SSS")
        text = time + "-" + text
        appendLog(text: text)
    }
    
    static func info(TAG: String, message: String) {
        print("\(TAG): \(message)")
        var text = "I/" + TAG + ":" + message + "\n"
        let time = Date().string(format: "HH:mm:ss.SSS")
        text = time + "-" + text
        appendLog(text: text)
    }
    
    static func error(TAG:String, message:String) {
        print("\(TAG): \(message)")
        var text = "E/" + TAG + ":" + message + "\n"
        let time = Date().string(format: "HH:mm:ss.SSS")
        text = time + "-" + text
        appendLog(text: text)
    }
    
    static func warning(TAG:String, message:String) {
        print("\(TAG): \(message)")
        var text = "W/" + TAG + ":" + message + "\n"
        let time = Date().string(format: "HH:mm:ss.SSS")
        text = time + "-" + text
        appendLog(text: text)
    }
    
    public static func setFilesDir() {
        if !sFilesDir.isEmpty {
            return
        }
        do {
            let appUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let appUrlString = appUrl.absoluteString + "AppLogs/"
            VoiceAppLogger.debug(TAG: TAG, message: "Got File URL \(appUrlString)")
            sFilesDir = appUrlString
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Error in setting Files Directory: \(error.localizedDescription)")
        }
    }
    
    static func appendLog(text: String) {
        let dateFormat: String = Date().string(format: "yyyy-MM-dd")
        let fileName = "exotelSampleApp-" + dateFormat + ".txt"
        
        if sFilesDir.isEmpty {
            return
        }
        
        guard let data = text.data(using: .utf8) else {
            return
        }
        
        let fileManager = FileManager.default
        let filePath = sFilesDir + fileName
        
        var isDir: ObjCBool = true
        do {
            if !fileManager.fileExists(atPath: sFilesDir, isDirectory: &isDir) {
                try fileManager.createDirectory(at: URL(string: sFilesDir)!, withIntermediateDirectories: true)
            }
        } catch let error {
            print("Logs folder could not be created at \(sFilesDir). Error: \(error.localizedDescription)")
            return
        }
        
        if !fileManager.fileExists(atPath: (URL(string: filePath)?.path)!) {
            let isFileCreated = fileManager.createFile(atPath: (URL(string: filePath)?.path)!, contents: nil, attributes: nil)
            if !isFileCreated {
                print("File Not created at \(filePath)")
                return
            }
        }
        do {
            let fileHandle = try FileHandle(forWritingTo: URL(string:filePath)!)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } catch let error {
            print("filepath: \(filePath)")
            print("Got an error in writing to file: \(error.localizedDescription)")
        }
    }
    
    private static func uploadLogFile(signedUrl: String, fileName: String) {
        VoiceAppLogger.debug(TAG: TAG, message: "Entry: uploadLogFile")
        
        if sFilesDir.isEmpty {
            return
        }
        
        let filePath = sFilesDir + fileName
        
        let uploadUrl = NSURL(string: signedUrl)
        let request = NSMutableURLRequest(url: uploadUrl! as URL)
        request.httpMethod = "PUT"
        request.addValue("application/zip", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        
        do {
            let data = try Data(contentsOf: URL(string: filePath)!)
            request.httpBody = data
            let mData = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
                VoiceAppLogger.debug(TAG: TAG, message: "upload Logs: \(response.debugDescription)")
                
            }
            mData.resume()
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Failure in uploading log, error: \(error.localizedDescription)")
        }
    }
    
    static func getSignedUrlForLogUpload(description: String) {
        VoiceAppLogger.debug(TAG: TAG, message: "Entry: getSignedUrlForLogUpload")
        
        let hostName = UserDefaults.standard.string(forKey: UserDefaults.Keys.bellatrixHostName.rawValue) ?? ""
        let accountSID = UserDefaults.standard.string(forKey: UserDefaults.Keys.accountSID.rawValue) ?? ""
        let userName = UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue) ?? ""
        
        if hostName.isEmpty || accountSID.isEmpty || userName.isEmpty {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to get signed URL")
            VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
            return
        }
        
        let path = hostName + "/accounts/" + accountSID + "/subscribers/" + userName + "/logdestination"
        let url = NSURL(string: path)
        let queryURL = url!.appending("platform", value: "ios")
        let request = NSMutableURLRequest(url: queryURL as URL)
        
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        
        let mData = session.dataTask(with: request as URLRequest) { [self] (data, response, error) -> Void in
            guard let data = data, error == nil else {
                VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
                return
            }
            
            do {
                let jsonDict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]
                guard let dict = jsonDict else {
                    VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
                    return
                }
                guard let status = dict["http_code"] as? Int else {
                    VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
                    return
                }
                if status == 200 {
                    VoiceAppLogger.debug(TAG: TAG, message:"getSignedUrlForLogUpload: Response, \(dict) ")
                    let uploadUrl = dict["logDestinationURL"] as? String ?? ""
                    let fileName = dict["logDestinationFileName"] as? String ?? ""
                    if uploadUrl.isEmpty || !uploadUrl.contains("http") {
                        VoiceAppLogger.debug(TAG: TAG, message: "Upload URL is empty or does not start with http")
                        VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
                        return
                    } else if fileName.isEmpty {
                        VoiceAppLogger.error(TAG: TAG, message: "File name to upload logs is empty")
                        VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
                        return
                    } else {
                        let endDate = Date()
                        let days = UPLOAD_LOG_NUM_DAYS * -1
                        let startDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
                        if startDate == nil {
                            VoiceAppLogger.error(TAG: TAG, message: "Unable to get dates")
                            VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
                            return
                        }
                        VoiceAppLogger.uploadAppLogsToServer(startDate: startDate!, endDate: endDate, signedUrl: uploadUrl, fileName: fileName, description: description)
                        VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
                    }
                } else {
                    VoiceAppLogger.error(TAG: TAG, message: "getSignedUrl: Failed with status: \(status)")
                    VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
                    return
                }
            } catch let error {
                VoiceAppLogger.error(TAG: TAG, message: "Exception in reading response: \(error.localizedDescription)")
                VoiceAppLogger.debug(TAG: TAG, message: "Exit: getSignedUrlForLogUpload")
                return
            }
        }
        mData.resume()
    }
    
    static func uploadAppLogsToServer(startDate: Date, endDate: Date, signedUrl: String, fileName: String, description: String) {
        VoiceAppLogger.debug(TAG: TAG, message: "Entry: uploadAppLogsToServer")
        let fileManager = FileManager.default
        
        let metaDataFileName = "exotelVoiceApp-metadata.txt"
        let metaDataFilePath = sFilesDir + metaDataFileName
        VoiceAppLogger.debug(TAG: TAG, message: "File path: \(metaDataFilePath)")
        VoiceAppLogger.debug(TAG: TAG, message: "Data to be appended to file: \(description)")
        
        let text = "Exotel Voice App Metadata\n"
        guard let data = text.data(using: .utf8) else {
            VoiceAppLogger.error(TAG: TAG, message: "Unable to convert string to data")
            VoiceAppLogger.debug(TAG: TAG, message: "Exit: uploadAppLogsToServer")
            return
        }
        
        let sourceURL = URL(string: metaDataFilePath)!
        if fileManager.fileExists(atPath: metaDataFilePath) {
            do {
                try fileManager.removeItem(at: sourceURL)
            } catch let error {
                VoiceAppLogger.error(TAG: TAG, message: "Could not delete previously existing file: \(metaDataFilePath)")
                VoiceAppLogger.error(TAG: TAG, message: "Error: \(error.localizedDescription)")
                VoiceAppLogger.debug(TAG: TAG, message: "Exit: uploadAppLogsToServer")
                return
            }
        } else {
            do {
                try data.write(to: URL(string: metaDataFilePath)!)
            } catch let error {
                VoiceAppLogger.error(TAG: TAG, message: "Error in creating the file: \(error.localizedDescription)")
                VoiceAppLogger.debug(TAG: TAG, message: "Exit: uploadAppLogsToServer")
                return
            }
            addMetadataText(description: description, metadataFile: sourceURL)
        }
        
        if sFilesDir.isEmpty {
            VoiceAppLogger.debug(TAG: TAG, message: "No files to upload at path: \(sFilesDir)")
            VoiceAppLogger.debug(TAG: TAG, message: "Exit: uploadAppLogsToServer")
            return
        }
        
        if fileManager.isReadableFile(atPath: signedUrl) {
            if validateStartAndEndDate(startDate: startDate, endDate: endDate, path: signedUrl) {
                VoiceAppLogger.debug(TAG: TAG, message: "Valid start and end dates, returning: \(signedUrl)")
            } else {
                VoiceAppLogger.debug(TAG: TAG, message: "Invalid start and end dates, returning: \(signedUrl)")
                VoiceAppLogger.debug(TAG: TAG, message: "Exit: uploadAppLogsToServer")
                return
            }
        }
        
        do {
            let fileList = try fileManager.contentsOfDirectory(at: URL(string: sFilesDir)!, includingPropertiesForKeys: nil)
            VoiceAppLogger.debug(TAG: TAG, message: "Number of files in \(sFilesDir): \(fileList.count)")
            if fileList.count > 0 {
                let zipFileName = sFilesDir + fileName
                createZipFile(zipFileName: zipFileName)
                uploadLogFile(signedUrl: signedUrl, fileName: fileName)
                VoiceAppLogger.debug(TAG: TAG, message: "Exit: uploadAppLogsToServer")
            }
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Upload app logs to server failed, error: \(error.localizedDescription)")
            VoiceAppLogger.debug(TAG: TAG, message: "Exit: uploadAppLogsToServer")
            return
        }
    }
    
    private static func addMetadataText(description: String, metadataFile: URL) {
        var text: String = "Description: \(description)\n"
        text = text + "Device Model: \(BuildConfig.DEVICE_MODEL)\n"
        text = text + "Device Version: \(BuildConfig.DEVICE_VERSION)\n"
        text = text + "SDK Version: \(VoiceAppService.shared.getVersionDetails())\n"
        text = text + ""
        
        guard let data = text.data(using: .utf8) else {
            VoiceAppLogger.error(TAG: TAG, message: "Unable to convert string to data")
            return
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: metadataFile)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Unable to write logs to file. \(error.localizedDescription)")
        }
    }
    
    private static func validateStartAndEndDate(startDate: Date, endDate: Date, path: String) -> Bool {
        let fileDateArray = path.split(separator: "-")
        if fileDateArray.count != 4 {
            return false
        }
        
        let fileYear = Int(fileDateArray[1])
        let fileMonth = Int(fileDateArray[2])
        let fileDay = Int(fileDateArray[3].prefix(2))
        let userCalendar = Calendar.current
        let dateComponents = DateComponents(year: fileYear, month: fileMonth, day: fileDay)
        let fileDate = userCalendar.date(from: dateComponents)!
        if startDate > endDate {
            return false
        }
        
        let dateRange = startDate...endDate
        if dateRange.contains(fileDate) {
            return true
        } else {
            return false
        }
    }
    
    private static func createZipFile(zipFileName: String) {
        VoiceAppLogger.debug(TAG: TAG, message: "Zip file path is: \(zipFileName)")
        
        if sFilesDir.isEmpty {
            return
        }
        VoiceAppLogger.debug(TAG: TAG, message: "sFilesDir: \(sFilesDir)")
        
        let fileManager = FileManager.default
        coordinator.coordinate(readingItemAt: URL(string: sFilesDir)!, options: [.forUploading], error: &error) { (zipUrl) in
            VoiceAppLogger.debug(TAG: TAG, message: "zipUrl returned is: \(zipUrl)")
            do {
                try fileManager.moveItem(at: zipUrl, to: URL(string: zipFileName)!)
            } catch let error {
                VoiceAppLogger.error(TAG: TAG, message: "Error in create Zipfile: \(error.localizedDescription)")
            }
        }
    }
    
    private static func checkFileForZip(path: String) -> Bool {
        if path.isEmpty {
            return false
        }
        
        let fileDateArray = path.split(separator: "-")
        if fileDateArray.count != 4 {
            return false
        }
        
        let fileYear = Int(fileDateArray[1])
        let fileMonth = Int(fileDateArray[2])
        let fileDay = Int(fileDateArray[3].prefix(2))
        let userCalendar = Calendar.current
        let dateComponents = DateComponents(year: fileYear, month: fileMonth, day: fileDay)
        let fileDate = userCalendar.date(from: dateComponents)!
        
        let today = Date()
        
        VoiceAppLogger.debug(TAG: TAG, message: "File Year: \(String(describing: fileYear)) File Month: \(String(describing: fileMonth)) File Day: \(String(describing: fileDay))")
        VoiceAppLogger.debug(TAG: TAG, message: "Current Date: \(today.description) File Date: \(fileDate.description)")
        
        if fileDate > today {
            return false
        }
        
        let timeDifferenceInSeconds = today.timeIntervalSince(fileDate)
        if timeDifferenceInSeconds <= 0 {
            return false
        }
        
        let timeDiff = Int64(timeDifferenceInSeconds * 1000)
        let value = ZIP_LOGS_AFTER_DAYS * DAYS_IN_MS
        
        if timeDiff >= value {
            return true
        }
        
        return false
    }
    
    static func zipOlderLogs() {
        do {
            if sFilesDir.isEmpty {
                return
            }
            
            let fileManager = FileManager.default
            let fileList = try fileManager.contentsOfDirectory(at: URL(string: sFilesDir)!, includingPropertiesForKeys: nil)
            VoiceAppLogger.debug(TAG: TAG, message: "Number of files in \(sFilesDir): \(fileList.count)")
            
            if fileList.count > 0 {
                var isZipCreated = false
                let dateFormat: String = Date().string(format: "yyyy-MM-dd")
                let fileNameForZip = "exotelSampleAppZip-" + dateFormat + ".zip"
                for file in fileList {
                    let fileName = file.lastPathComponent
                    let name = file.deletingPathExtension().lastPathComponent
                    if name.isEmpty || !name.contains("exotelSampleApp") {
                        continue
                    }
                    
                    if fileName == fileNameForZip {
                        do {
                            try fileManager.removeItem(atPath: file.path)
                            VoiceAppLogger.debug(TAG: TAG, message: "Deleted file: \(file.path)")
                            continue
                        } catch let error {
                            VoiceAppLogger.error(TAG: TAG, message: "Failed to delete file: \(file.path). Error: \(error.localizedDescription)")
                        }
                    }
                    
                    if checkFileForZip(path: fileName) {
                        VoiceAppLogger.debug(TAG: TAG, message: "Valid file: \(file.path)")
                    } else {
                        VoiceAppLogger.error(TAG: TAG, message: "Invalid file: \(file.path)")
                        continue
                    }
                    
                    if !isZipCreated {
                        let zipFileName = sFilesDir + fileNameForZip
                        createZipFile(zipFileName: zipFileName)
                        isZipCreated = true
                        continue
                    }
                    
                    do {
                        try fileManager.removeItem(atPath: file.path)
                        VoiceAppLogger.debug(TAG: TAG, message: "Deleted file: \(file.path)")
                    } catch let error {
                        VoiceAppLogger.error(TAG: TAG, message: "Failed to delete file: \(file.path). Error: \(error.localizedDescription)")
                    }
                }
            }
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Upload app logs to server failed, error: \(error.localizedDescription)")
            return
        }
    }
}

extension Date {
    func string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

extension NSURL {
    func appending(_ queryItem: String, value: String?) -> URL {
        guard var urlComponents = URLComponents(string: absoluteString!) else { return absoluteURL! }
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
        let queryItem = URLQueryItem(name: queryItem, value: value)
        queryItems.append(queryItem)
        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }
}

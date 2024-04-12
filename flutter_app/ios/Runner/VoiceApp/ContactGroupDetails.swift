/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation

struct sectionData {
    var sectionInfo:ContactGroupDetails
    var isSectionOpened:Bool
    mutating func togglesection() {
        self.isSectionOpened.toggle()
    }
}
struct sectionDataCollapsible {
    var sectionInfo:ContactGroupDetails
    var issectionOpened:Bool
}

struct MainModule: Codable {
    let response: [ContactGroupDetails]
}

// MARK: - Response
struct ContactGroupDetails: Codable {
    let code: Int
    let errorData: ContactErrorData?
    let status: String
    let data: DataClass
    
    enum CodingKeys: String, CodingKey {
        case code
        case errorData = "error_data"
        case status, data
    }
}

// MARK: - DataClass
struct DataClass: Codable {
    let group: String
    let is_special: Bool
    let contacts: [Contact]
}

// MARK: - Contact
struct Contact: Codable {
    let contactName, contactNumber: String
    
    enum CodingKeys: String, CodingKey {
        case contactName = "contact_name"
        case contactNumber = "contact_number"
    }
}

struct ContactErrorData : Codable {
    private var errorCode: Int
    private var description: String
    private var message: String
    
    private enum CollectionCodingKeys: String, CodingKey {
        case errorCode = "code"
        case description
        case message
    }
    
    public init(errorCode: Int, description: String, message: String) {
        self.errorCode = errorCode
        self.description = description
        self.message = message
    }
    
    public func getErrorCode() -> Int {
        return errorCode
    }
    
    public func getDescription() -> String {
        return description
    }
    
    public func getMessage() -> String {
        return message
    }
}

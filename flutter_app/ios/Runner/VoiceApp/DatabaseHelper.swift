/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation
import SQLite

public class DatabaseHelper {
    public static var shared = DatabaseHelper()
    
    static let DATABASE_NAME: String = "Recent_Calls.sqlite3"
    static let TABLE_NAME: String = "call_table"
    static let COL_ID: String = "ID"
    static let COL_CALLER_ID: String = "CALLER_ID"
    static let COL_CALL_TYPE: String = "CALL_TYPE"
    static let COL_CALL_TIME: String = "CALL_TIME"
    
    private let TAG: String = "DatabaseHelper"
    private let MAX_NUM_ENTRIES: Int = 20
    
    var db: Connection?
    var callTable: Table = Table(DatabaseHelper.TABLE_NAME)
    
    private init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let fileFullPath = path + "/" + DatabaseHelper.DATABASE_NAME
            db = try Connection(fileFullPath)
            createTable()
        } catch let error {
            self.db = nil
            VoiceAppLogger.error(TAG: TAG, message: "Failed to initialize database helper. Error: \(error.localizedDescription)")
        }
    }
    
    private func createTable() {
        do {
            let result = checkDatabaseAndTableExists()
            if result {
                VoiceAppLogger.debug(TAG: TAG, message: "Table with name \(DatabaseHelper.TABLE_NAME) already exists in database \(DatabaseHelper.DATABASE_NAME)")
                return
            }
            
            let callId = Expression<Int>(DatabaseHelper.COL_ID)
            let callerId = Expression<String>(DatabaseHelper.COL_CALLER_ID)
            let callType = Expression<String>(DatabaseHelper.COL_CALL_TYPE)
            let callTime = Expression<String>(DatabaseHelper.COL_CALL_TIME)
            
            let statement = callTable.create(ifNotExists: true) {t in
                t.column(callId, primaryKey: .autoincrement)
                t.column(callerId)
                t.column(callType)
                t.column(callTime)
            }
            
            try db?.transaction {
                try db?.run(statement)
            }
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to create table. Error: \(error.localizedDescription)")
        }
    }
    
    public func insertData(callerId: String, callType: CallType, time: String) -> Bool {
        do {
            checkAndDelete()
            
            VoiceAppLogger.debug(TAG: TAG, message: "Inserting: Caller ID: \(callerId) Call Type: \(callType) Time: \(time)")
            
            let result = checkDatabaseAndTableExists()
            if !result {
                VoiceAppLogger.debug(TAG: TAG, message: "Table with name \(DatabaseHelper.TABLE_NAME) or databse with name \(DatabaseHelper.DATABASE_NAME) does not exist")
                return false
            }
            
            let callTypeString = CallType.stringFromEnum(callType: callType)
            
            //Sometimes, call time is recorded in milliseconds (of timestamp double type).
            //Convert it to proper date before storing in the table.
            var dateTimeString = time
            var dateString = ""
            let milliseconds = Double(time) ?? 0
            if milliseconds == 0 {
                dateString = time
            } else {
                let date = Date(timeIntervalSinceNow: (milliseconds / 1000.0))
                dateString = date.description
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
            guard let convertDate = dateFormatter.date(from: dateString) else {
                return false
            }
            dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss"
            dateTimeString = dateFormatter.string(from: convertDate)
            
            let colCallerId = Expression<String>(DatabaseHelper.COL_CALLER_ID)
            let colCallType = Expression<String>(DatabaseHelper.COL_CALL_TYPE)
            let colCallTime = Expression<String>(DatabaseHelper.COL_CALL_TIME)
            
            let statement = callTable.insert(colCallerId <- callerId, colCallType <- callTypeString, colCallTime <- dateTimeString)
            
            try db?.transaction {
                try db?.run(statement)
            }
            
            return true
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to create table. Error: \(error.localizedDescription)")
            return false
        }
    }
    
    private func deleteData(callId: Int) {
        do {
            VoiceAppLogger.debug(TAG: TAG, message: "Deleting: Call ID: \(callId)")
            
            let result = checkDatabaseAndTableExists()
            if !result {
                VoiceAppLogger.debug(TAG: TAG, message: "Table with name \(DatabaseHelper.TABLE_NAME) or databse with name \(DatabaseHelper.DATABASE_NAME) does not exist")
                return
            }
            
            if callId == -1 {
                let statement = callTable.delete()
                try db?.transaction {
                    try db?.run(statement)
                }
            } else {
                let columnCallId = Expression<Int>(DatabaseHelper.COL_ID)
                let statement = callTable.filter(columnCallId == callId).delete()
                try db?.transaction {
                    try db?.run(statement)
                }
            }
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to delete record from table. Error: \(error.localizedDescription)")
        }
    }
    
    public func getAllData() -> [RecentCallDetails] {
        do {
            VoiceAppLogger.debug(TAG: TAG, message: "Get all recent call records")
            
            let result = checkDatabaseAndTableExists()
            if !result {
                VoiceAppLogger.debug(TAG: TAG, message: "Table with name \(DatabaseHelper.TABLE_NAME) or databse with name \(DatabaseHelper.DATABASE_NAME) does not exist")
                return []
            }
            
            var recentCallDetailsList: [RecentCallDetails] = []
            
            let colCallId = Expression<Int>(DatabaseHelper.COL_ID)
            let colCallerId = Expression<String>(DatabaseHelper.COL_CALLER_ID)
            let colCallType = Expression<String>(DatabaseHelper.COL_CALL_TYPE)
            let colCallTime = Expression<String>(DatabaseHelper.COL_CALL_TIME)
            let rowIterator = try db?.prepareRowIterator(callTable.order([colCallId.desc]))
            
            while let call = try rowIterator?.failableNext() {
                let callerId = call[colCallerId]
                let callType = CallType.enumFromString(callTypeName: call[colCallType])
                let callTime = call[colCallTime]
                let recentCallDetails = RecentCallDetails(remoteId: callerId, callType: callType, time: callTime)
                recentCallDetailsList.append(recentCallDetails)
            }
            
            return recentCallDetailsList
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to get all records from table \(DatabaseHelper.TABLE_NAME). Error: \(error.localizedDescription)")
            return []
        }
    }
    
    private func checkAndDelete() {
        do {
            VoiceAppLogger.debug(TAG: TAG, message: "Check and delete if number of records in \(DatabaseHelper.TABLE_NAME) crosses \(MAX_NUM_ENTRIES)")
            
            let result = checkDatabaseAndTableExists()
            if !result {
                VoiceAppLogger.debug(TAG: TAG, message: "Table with name \(DatabaseHelper.TABLE_NAME) does not exists in database \(DatabaseHelper.DATABASE_NAME)")
                return
            }
            
            let count = try db?.scalar(callTable.count) ?? 0
            VoiceAppLogger.debug(TAG: TAG, message: "Number of records in \(DatabaseHelper.TABLE_NAME) are \(count)")
            
            if count > MAX_NUM_ENTRIES {
                VoiceAppLogger.debug(TAG: TAG, message: "In check and delete: delete old records from table \(DatabaseHelper.TABLE_NAME)")
                let statement = callTable.delete()
                try db?.transaction {
                    try db?.run(statement)
                }
            }
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to delete records from \(DatabaseHelper.TABLE_NAME). Error: \(error.localizedDescription)")
            return
        }
    }
    
    private func checkDatabaseAndTableExists() -> Bool {
        do {
            if db == nil {
                VoiceAppLogger.error(TAG: TAG, message: "No database initialized.")
                throw VoiceAppError(module: TAG, localizedDescription: "No database initialized")
            }
            
            let count = try db?.scalar(callTable.count) ?? -1
            if count >= 0 {
                return true
            }
            return false
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Error: \(error.localizedDescription)")
            return false
        }
    }
}

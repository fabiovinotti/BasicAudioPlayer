//
//  Logging.swift
//  
//
//  Created by Fabio Vinotti on 16/12/21.
//

import Foundation
import os

fileprivate let generalLogger = Logger(subsystem: "BasicAudioPlayer", category: "general")

func log(_ message: String,
         level: OSLogType = .default,
         file: String = #file,
         function: String = #function,
         line: Int = #line) {
    
    let fileName = (file as NSString).lastPathComponent
    generalLogger.log(level: level, "\(fileName) : \(function) : \(line) -> \(message)")
}

//
//  Logging.swift
//  
//
//  Created by Fabio Vinotti on 16/12/21.
//

import Foundation
import os

fileprivate let moduleLogger = Logger(subsystem: "BasicAudioPlayer", category: "general")

func log(level: OSLogType,
         _ message: String,
         file: String = #file,
         function: String = #function,
         line: Int = #line) {
    
    let fileName = (file as NSString).lastPathComponent
    moduleLogger.log(level: level, "\(fileName) : \(function) : \(line) -> \(message)")
}

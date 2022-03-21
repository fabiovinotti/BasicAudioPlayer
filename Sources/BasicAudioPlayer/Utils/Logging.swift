//
//  BasicAudioPlayer
//  Logging.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation
import os

fileprivate let moduleLogger = Logger(subsystem: "BasicAudioPlayer", category: "general")

/// Logs a message of the specified type.
///
/// The "file", "function" and "line" parameters are automatically collected when the function is called.
/// Don't provide any value for those.
func log(level: OSLogType,
         _ message: String,
         file: String = #file,
         function: String = #function,
         line: Int = #line) {
    
    let fileName = (file as NSString).lastPathComponent
    moduleLogger.log(level: level, "\(fileName) : \(function) : \(line) -> \(message)")
}

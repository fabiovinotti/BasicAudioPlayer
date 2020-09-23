//
//  File.swift
//  
//
//  Created by Fabio Vinotti on 9/15/20.
//

import MediaPlayer

extension AVAudioFile {
    
    var duration: TimeInterval {
        Double(length) / processingFormat.sampleRate
    }
    
}

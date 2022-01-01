//
//  AVAudioFile+Extensions.swift
//  
//
//  Created by Fabio Vinotti on 24/11/21.
//

import AVFoundation

extension AVAudioFile {
    
    /// The duration of the audio file measured in seconds.
    var duration: TimeInterval {
        Double(length) / fileFormat.sampleRate
    }
    
}

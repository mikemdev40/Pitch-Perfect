//
//  RecordedAudio.swift
//  Pitch Perfect Demo
//
//  Created by Michael Miller on 1/2/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation

class RecordedAudio {
    
    var filePathURL: NSURL
    var title: String
    
    init(filePathURL: NSURL, title: String) {
        self.filePathURL = filePathURL
        self.title = title
    }
}

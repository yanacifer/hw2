//
//  HangmanPhrases.swift
//  Hangman
//
//  Created by Shawn D'Souza on 3/3/16.
//  Copyright © 2016 Shawn D'Souza. All rights reserved.
//

import Foundation

class HangmanPhrases {
    
    var phrases : NSArray!
    
    // Initialize HangmanPhrase with an array of all possible phrases of the Hangman game
    init() {
        let path = Bundle.main.path(forResource: "phrases", ofType: "plist")
        phrases = NSArray.init(contentsOfFile: path!)
    }
    
    // Get random phrase from all available phrases.
    // Ah, noticed the weird `@objc dynamic` prefix?
    // You can (and should) ignore that for now. But if you're curious, `@objc` exposes the Swift method
    // to the Objective-C runtime, whereas the `dynamic` keyword tells the Swift runtime to use dynamic
    // dispatch instead of static (e.g. These keywords are necessary for the autograder to work).
    @objc dynamic func getRandomPhrase() -> String {
        let index = Int(arc4random_uniform(UInt32(phrases.count)))
        return phrases.object(at: index) as! String
    }
    
}

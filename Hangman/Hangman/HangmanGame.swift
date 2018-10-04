//
//  HangmanGame.swift
//  Hangman
//
//  Created by Ruoyu Li on 9/30/18.
//  Copyright © 2018 iOS DeCal. All rights reserved.
//

import UIKit
import Foundation
class HangmanGame {
    var phrase: String
    var hangmanphrase : HangmanPhrases
    var correct : Int
    var countlife : Int
    
   var allImages: [UIImage] = [#imageLiteral(resourceName: "hangman1"), #imageLiteral(resourceName: "hangman2"),#imageLiteral(resourceName: "hangman3"),#imageLiteral(resourceName: "hangman4"),#imageLiteral(resourceName: "hangman5"),#imageLiteral(resourceName: "hangman6"),#imageLiteral(resourceName: "hangman7")]
    
    init () {
        self.hangmanphrase = HangmanPhrases()
        self.correct = 0
        self.phrase = ""
        self.countlife = 0
    }
    

    
    func updateNewGame () {
        self.phrase = self.hangmanphrase.getRandomPhrase()
        self.correct = 0
      
        
    }
    
    func wincheck() -> Bool {
        if self.correct == self.phrase.count {
            return true
        }else{
            return false
        }
    }
    
    
    
    //define win and lose her
   

    
    
 

}

//
//  HangmanViewControllerTestSuite.swift
//  Autograder
//
//  Created by Chris Zielinski on 9/17/17.
//  Copyright © 2017 iOS DeCal @UCBerkeley. All rights reserved.
//

import XCTest
@testable import Hangman
import BKAutograder

extension UITextField {
    public func updateText(with string: String) {
        self.text = string
        BKRun()
    }
}



class HangmanViewControllerTestSuite: BKTestSuite, BKAutogradable {
    
    var gradingFileName: String = "HangmanViewController"
    var hangmanViewController: HangmanViewController!
    var branch: Int = BKBranchDirection.Neither.rawValue
    var hangmanImageView: UIImageView!
    var phraseLabel: UILabel!
    var currentPhraseText: String {
        get {
            return phraseLabel.text!
        }
    }
    var initialPhraseText: String!
    var initialHangmanImage: UIImage!
    var wrongGuessesLabel: UILabel!
    var guessButton: UIButton!
    var newGameButton: UIButton!
    var alertController: UIAlertController!
    
    var guessTextField: UITextField!
    
    var otherButtons: [UIButton]!
    var _characterButtons: NSDictionary!
    var characterButtons: [Character : UIButton] {
        get {
            return _characterButtons as! [Character : UIButton]
        }
        set(newValue) {
            _characterButtons = newValue as NSDictionary
        }
    }
    
    private func guess(letter: String) {
        switch BKBranchDirection(rawValue: branch)! {
        case .Left:
            guessTextField.updateText(with: letter)
        case .Right:
            BKSendAction(to: characterButtons[letter.first!]!)
        default: ()
        }
        BKSendAction(to: guessButton)
    }
    
    func testQ0Existence() {
        hangmanViewController = BKAssertStoryboardViewController()
        BKLoadView(in: hangmanViewController)
    }
    
    func testQ1PhraseLabel() {
        let allowedCensorCharacters: [[String]] = [Array(repeating: "_", count: 8), Array(repeating: "-", count: 8)]
        phraseLabel = BKAssertLabel(inSubviewsOf: hangmanViewController.view, contains: allowedCensorCharacters)
        initialPhraseText = currentPhraseText
    }
    
    func testQ2TextFieldOrButtons() {
        let textfieldImplementation = {
            self.guessTextField = BKAssertInstance(from: self.hangmanViewController)
            BKBranchPassed(withDescription: "UITextField exists")
        }

        let buttonImplementation: () -> Void = {
            self.otherButtons = []
            self.characterButtons = [:]

            let buttons: [UIButton] = BKAssertAllInstances(inSubviewsOf: self.hangmanViewController.view, recursively: true)
            for button in buttons {
                if let text = button.titleLabel?.text, text.count == 1, let character = text.first, character.isLetter() {
                    self.characterButtons[character.uppercased()] = button
                } else {
                    self.otherButtons.append(button)
                }
            }

            BKAssertEqualUnordered(Character.uppercaseLetters, otherArray: Array(self.characterButtons.keys))
            BKBranchPassed(withDescription: "Custom UIButton input exists")
        }
        
        branch = BKBranch(left: textfieldImplementation(), right: buttonImplementation()).rawValue
    }
    
    func testQ3GuessButtonExists() {
        switch BKBranchDirection(rawValue: branch)! {
        case .Left:
            self.guessButton = BKAssertButton(withLabelContaining: ["guess"], inSubviewsOf: self.hangmanViewController.view)
        case .Right:
            BKSendAction(to: characterButtons["U"]!)
            self.guessButton = BKAssertButton(withLabelContaining: ["guess"], inSubviewsOf: self.hangmanViewController.view)
        default: ()
        }
    }
    
    func testQ4HangmanImageViewExists() {
        hangmanImageView = BKAssertInstance(from: hangmanViewController)
        initialHangmanImage = BKAssertNotNil(hangmanImageView.image)
    }
    
    func testQ5IncorrectGuessesLabel() {
        let guessLetter = "Q"
        let labels: [UILabel] = BKAssertAllInstances(from: self.hangmanViewController)
        var labelTexts: [String] = labels.map {(label: UILabel) in return label.text ?? ""}
        
        guess(letter: guessLetter)
        
        for (i, label) in labels.enumerated() {
            let previousText = labelTexts[i]
            let newComponents = previousText.newAlphabeticComponents(ofCurrentString: label.text ?? "")
            if newComponents.contains(guessLetter) {
                self.wrongGuessesLabel = label
                return
            }
        }
        
        BKAssertFail()
    }
    
    func testQ6SorryHangman() {
        let previousStateImage: UIImage = BKAssertNotNil(hangmanImageView.image)
        
        guess(letter: "Z")
        
        let currentStateImage: UIImage = BKAssertNotNil(hangmanImageView.image)
        BKAssertNotEqual(previousStateImage, studentValue: currentStateImage)
        
    }
    
    func testQ7SingleLetterGuessOrChangeGuess() {
        let previousPhraseState = currentPhraseText
        let previousGuessesState = wrongGuessesLabel.text!
        let previousStateImage: UIImage = BKAssertNotNil(hangmanImageView.image)
        
        let threeLetterGuess = "YER"
        switch BKBranchDirection(rawValue: branch)! {
        case .Left:
            guess(letter: threeLetterGuess)
            
            if let presentedAlertController = hangmanViewController.presentedViewController as? UIAlertController, let firstAction = presentedAlertController.actions.first {
                BKDismiss(alertController: presentedAlertController, with: firstAction)
            }
            
            BKAssertEqual(previousPhraseState, studentValue: phraseLabel.text)
            BKAssertEqual(previousGuessesState, studentValue: wrongGuessesLabel.text)
            BKAssertEqual(previousStateImage, studentValue: hangmanImageView.image)
            BKAssertPass(withDescription: "Only allows single letter guesses")
        case .Right:
            BKSendAction(to: characterButtons[threeLetterGuess.first!]!)
            
            BKAssertEqual(previousPhraseState, studentValue: phraseLabel.text)
            BKAssertEqual(previousGuessesState, studentValue: wrongGuessesLabel.text)
            BKAssertEqual(previousStateImage, studentValue: hangmanImageView.image)
            
            guess(letter: "R")
            
            BKAssertEqual(previousPhraseState, studentValue: phraseLabel.text)
            let newComponents = previousGuessesState.newAlphabeticComponents(ofCurrentString: wrongGuessesLabel.text!)
            BKAssertEqualOrdered(array: ["R"], otherArray: newComponents)
            BKAssertNotEqual(previousStateImage, studentValue: hangmanImageView.image)
            BKAssertPass(withDescription: "Press different letter buttons before pressing 'Guess' button ('Y' -> 'R' -> 'Guess')")
        default: ()
        }
    }
    
    func testQ8CorrectGuess() {
        let previousPhraseText = currentPhraseText
        let previousGuessesState = wrongGuessesLabel.text!
        let previousStateImage: UIImage = BKAssertNotNil(hangmanImageView.image)
        
        guess(letter: "L")
        
        let newComponents = previousPhraseText.newAlphabeticComponents(ofCurrentString: currentPhraseText)
        BKAssertEqualOrdered(array: ["L", "L"], otherArray: newComponents)
        BKAssertEqual(previousGuessesState, studentValue: wrongGuessesLabel.text)
        BKAssertEqual(previousStateImage, studentValue: hangmanImageView.image)
    }
    
    func testQ9AlertController() {
        
        guess(letter: "O")
        guess(letter: "I")
        guess(letter: "T")
        guess(letter: "S")
        guess(letter: "M")
        guess(letter: "E")
        
        guard let presentedAlertController = hangmanViewController.presentedViewController as? UIAlertController else {
            BKAssertFail()
        }
        
        alertController = presentedAlertController
    }

    func testQ10NewGameAction() {
        let previousPhraseState = currentPhraseText
        let previousGuessesState = wrongGuessesLabel.text!
        let previousStateImage: UIImage = BKAssertNotNil(hangmanImageView.image)
        
        guard let newGameAction = alertController.actions.first(where: {(action: UIAlertAction) in return action.title?.lowercased().contains("new game") ?? false }) else {
            if let randomAction = alertController.actions.first {
                BKDismiss(alertController: alertController, with: randomAction)
            }
            BKAssertFail()
        }
        
        BKDismiss(alertController: alertController, with: newGameAction)
        
        // Game state should be reset AFTER pressing "New Game"
        BKAssertNotEqual(previousPhraseState, studentValue: phraseLabel.text)
        BKAssertEqual(initialPhraseText, studentValue: phraseLabel.text)
        BKAssertNotEqual(previousGuessesState, studentValue: wrongGuessesLabel.text)
        BKAssertNotEqual(previousStateImage, studentValue: hangmanImageView.image)
        BKAssertEqual(initialHangmanImage, studentValue: hangmanImageView.image)
    }
    
    func testQ11NewGameButton() {
        newGameButton = BKAssertButton(withLabelContaining: ["new", "game"], inSubviewsOf: hangmanViewController.view)
    }
    
    func testQ12NewGameButtonResetsGame() {
        guess(letter: "N")
        BKSendAction(to: newGameButton)
        
        BKAssertEqual(initialPhraseText, studentValue: phraseLabel.text)
        BKAssertEqual(initialHangmanImage, studentValue: hangmanImageView.image)
    }
    
    func testQ13LoseGame() {
        BKSendAction(to: newGameButton)
        
        guess(letter: "K")
        guess(letter: "J")
        guess(letter: "R")
        guess(letter: "P")
        guess(letter: "B")
        guess(letter: "N")
        
        guard (hangmanViewController.presentedViewController as? UIAlertController) != nil else {
            BKAssertFail()
        }
    }
    
    func testQ14AutoLayout() {
        BKAssertFalse(hangmanViewController.view.hasAmbiguousLayout)
    }
    
}





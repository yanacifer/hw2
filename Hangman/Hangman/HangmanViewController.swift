//
//  HangmanViewController.swift
//  Hangman
//
//  Created by Ruoyu Li on 9/30/18.
//  Copyright © 2018 iOS DeCal. All rights reserved.
//

import UIKit

class HangmanViewController: UIViewController {
    
    var lastButtonPressed: UIButton?
   
    let hangman = HangmanGame()
    var word : String?
  
    
    
    @IBOutlet weak var HangmanImage: UIImageView!
    
    
    @IBOutlet var letters: [UIButton]!
    
    
    override func viewWillAppear(_ animated: Bool) {
        updateGame()
    }
    
    @IBOutlet weak var wordstackview: UIStackView!
    
    @IBOutlet weak var underlineview: UIStackView!
    
    @IBAction func letterPressed(_ sender: UIButton) {
        if sender != lastButtonPressed {
            lastButtonPressed = sender
        }
         lastButtonPressed?.backgroundColor = #colorLiteral(red: 0.5021633107, green: 1, blue: 0.6716907639, alpha: 1)
        
        var correctguess = false
        if let guess = lastButtonPressed?.titleLabel?.text{
            
            for subview in wordstackview.arrangedSubviews{
                if let label = subview as? UILabel{
                    if label.text == guess {
                        label.alpha = 1
                        correctguess = true
                        hangman.correct += 1
                    }
                }
            }
            
            
            if correctguess == false{
               wrong()
            }else{
                lastButtonPressed?.backgroundColor = #colorLiteral(red: 1, green: 0.568660692, blue: 0.4796155672, alpha: 1)
                lastButtonPressed?.isEnabled = false
                lastButtonPressed = nil
            }
            if hangman.wincheck() {
                win()
            }else {
                if hangman.countlife == 6 {
                    lose()
                }
            }
            
            
            
        }
        
    }
    
   
    @IBOutlet weak var updatewordButton: CornerRadiusView!
    func win(){
        
        let alertController = UIAlertController(title: "Winning", message: "This is win call.", preferredStyle: .alert)
        
        let action1 = UIAlertAction(title: "Okay", style: .default) { (action:UIAlertAction) in
            print("You've pressed okay");
        }
        alertController.addAction(action1)
        self.present(alertController, animated: true, completion: nil)
        
        updatewordButton.isHidden = false
        for button in letters {
            button.isEnabled = false
        }
        
    }
    func lose(){
        let alertController = UIAlertController(title: "Losing", message: "This is lose call.", preferredStyle: .alert)
        
        let action1 = UIAlertAction(title: "Fine", style: .default) { (action:UIAlertAction) in
            print("You've pressed okay");
        }
        alertController.addAction(action1)
        self.present(alertController, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.updatewordButton.isHidden = false
        })
        for button in letters {
            button.isEnabled = false
        }
        for subview in wordstackview.arrangedSubviews {
            if let label = subview as? UILabel {
                label.alpha = 1
            }
        }
        
        
        
    }
    
    
    @IBAction func updateButtonPressed(_ sender: UIButton) {
        updateGame()
    }
    
    
    func wrong(){
        lastButtonPressed?.backgroundColor = .darkGray
        lastButtonPressed?.isEnabled = false
        lastButtonPressed = nil
        hangman.countlife += 1
        HangmanImage.image = hangman.allImages[hangman.countlife]
    }
    
    func updateGame() {
        
        
        
     
        hangman.updateNewGame()
        
        word = hangman.phrase
      
       
        hangman.countlife = 0
   
        HangmanImage.image = hangman.allImages[hangman.countlife]
        for button in letters{
            button.isEnabled = true
            button.backgroundColor =  #colorLiteral(red: 0.7308729189, green: 1, blue: 0.5723517722, alpha: 1)
        }
        updatewordButton.isHidden = true
        for label in wordstackview.arrangedSubviews {
            label.removeFromSuperview()
        }
        
        for underline in underlineview.arrangedSubviews {
            underline.removeFromSuperview()
        }

        let characters = Array(word!.characters)
        for character in characters {
            
            if character == " "{
                
                let label = UILabel()
                label.text = String(character)
                label.font = UIFont.systemFont(ofSize: 10)
                label.textAlignment = .center
                label.alpha  = 0
                wordstackview.addArrangedSubview(label)
                
                label.widthAnchor.constraint(equalToConstant: 10).isActive = true
                label.layoutIfNeeded()
                
                let underline = UILabel()
                underline.text = " "
                underline.font = UIFont.systemFont(ofSize: 20)
                underline.textAlignment = .center
                underlineview.addArrangedSubview(underline)
                
                underline.widthAnchor.constraint(equalToConstant: 10).isActive = true
                underline.layoutIfNeeded()
                
                hangman.correct += 1
                continue
            }
            let label = UILabel()
            label.text = String(character)
            label.font = UIFont.systemFont(ofSize: 10)
            label.textAlignment = .center
            label.alpha  = 0
            wordstackview.addArrangedSubview(label)
            
            label.widthAnchor.constraint(equalToConstant: 10).isActive = true
            label.layoutIfNeeded()
            
            let underline = UILabel()
            underline.text = "_"
            underline.font = UIFont.systemFont(ofSize: 20)
            underline.textAlignment = .center
            underlineview.addArrangedSubview(underline)
            
            underline.widthAnchor.constraint(equalToConstant: 10).isActive = true
            underline.layoutIfNeeded()
        }
    }
    
    
    
  
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

@IBDesignable
class CornerRadiusView : UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = -1
    
    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }
    
}

# HW2: Hangman #

## due ##
Friday, September 29th at 10pm (check Piazza for office hour times next week)

## overview ##
In this project, you will be making an iOS application for the Hangman game. Users should be able to:
- start a game, 
- make guesses for a phrase (list of phrases provided), 
- see their progress toward the phrase, see a list of previously guessed incorrect letters, 
- see how many guesses they have left (indicated by a hangman image - basic images provided), 
- be alerted of a win or loss, and 
- start a new game.

Though we do not have many requirements for this project, you are encouraged to customize your app. Here's a screenshot from a past project submission for some inspiration:

![alt text](/README-images/hangman.png)

## getting started ##
To submit, add your hw2 folder to a private repository. You can find detailed instructions on how to add your assignment to a repo [here](http://iosdecal.com/other_files/submission_instructions.pdf).
    
We have provided you code to interact with the list of locations in Berkeley (see **HangmanPhrases.swift**), but you will implement the rest of the features on your own. Add the following code to your code to generate a random  word (where you decide to add these lines is up to you!). 

    let hangmanPhrases = HangmanPhrases()
     
    // Generate a random phrase for the user to guess
    let phrase: String = hangmanPhrases.getRandomPhrase()
    print(phrase)

We've also provided some images for you to use in the **Assets.xcassets** folder (they're so boring though - you're encouraged to make your own!)

## requirements ##

### file requirements ###
You must create the following two files to pass the autograder (and to preserve MVC!). 
- **HangmanViewController.swift** - subclass of UIViewController
- **HangmanGame.swift** - model class for your game

### feature requirements
####  hangman game view ###
1. a `UILabel` that displays the "_"s corresponding to each word in the provided puzzle string
* a `UILabel` that lists the incorrect guesses thus far
* a `UITextField` (where the user enters a letter as a guess). Users should only be able to guess one letter at a time. **If you decide to create a custom keyboard, this is not required**
* a "Guess" `UIButton` that will update the game state based on the guessed letter
* if that letter appears in the puzzle string, the corresponding "_" should be replaced by the correctly guessed letter
* if that letter does not appear in the puzzle string, that letter should be added to the label from the second bullet point to keep track of "Incorrect Guesses: ", and the Hangman image should update to represent the number of incorrect guesses
* a `UIImageView` that represents the "state" of the Hangman, with appropriate images for each "state"

#### finished game states, start new game ###
- a win state alert [(example)](https://medium.com/ios-os-x-development/how-to-use-uialertcontroller-in-swift-70143d7fbede) with an action titled "New Game" that restarts the game _after_ being pressed.
- a game over state alert (no action requirement - feel free to do what you find best)
- a "Start Over" button, which starts a new game

#### optional additions / features ###
* A smart way for the user to guess letters (since a TextField for letter entry isn't ideal UX).
* Customized design, including, but not limited to, custom images for the Hangman states
* Anything else that you think will impress us or you think would be fun to implement!

## grading and submission ##
If you complete all of the required features you will get full credit. We will deduct points for missing features, bugs, and UI layout issues. If you impress us with additional features (see the Optional Features section), you may be awarded an additional extra credit point.

### files to submit ####
- hw2 folder and contents
- a simulator screenshot of your app (on any orientation / device). Include this in your hw2 folder.

To submit, add your hw2 folder to a private repository (if you don't have free private repositories, get them here with the [github student developer pack](https://education.github.com/pack)). If you're new to GitHub, you can find detailed instructions on how to add your assignment to a repo [here](http://iosdecal.com/other_files/submission_instructions.pdf).

Using your private repository, submit your assignment to [Gradescope](https://gradescope.com/courses/9817/assignments/35309/). Please test that you uploaded correctly by downloading your submission, and testing that downloaded version in Xcode.

## 🔥 Autograder 🔥 ##
We're entering the pre-alpha release of our autograder. If you're willing, we would love for you to try it out. But first, we'll need to install CocoaPods, a dependency manager. CocoaPods is built with Ruby and is installable with the default Ruby available on macOS (we'll be using CocoaPods later on in the class).

```
sudo gem install cocoapods
```

If you're having trouble, check [this](https://guides.cocoapods.org/using/troubleshooting#installing-cocoapods) guide out. We also have to set the location of the developer directory for the Xcode command line build tools. For the path, you can just drag the Xcode.app into the Terminal window.

```
sudo xcode-select --switch <path/to/Xcode 9.app>
``` 

Now all you have to do is run the command below within the directory the autograder is in:

```
python autograder.py
``` 

Once it finishes grading, it will spit out a token called `Hangman.token` in the directory. To submit your grade, upload the generated token file to Gradescope. Please verify that your local autograder score matches the result produced by Gradescope's autograder. **This is completely optional.** If you prefer to be graded by us, or if you went above and beyond the autograder's grading abilities, you can follow the instructions in the previous section. If you find a bug, please let us know via Piazza (screenshots would be 👌).

//
//  ViewController.swift
//  Concentration
//
//  Created by Denis Avdeev on 12.01.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class ConcentrationViewController: UIViewController {

    private struct Appearance {
        static let buttonCornerRadius: CGFloat = 10.0
        static let flipAnimationDuration = 0.5
        static let labelStrokeWidth: CGFloat = 5.0
    }
    
    /// The theme that affects appearance of the game;
    /// defined by number between 0 and 5.
    var currentTheme = 0 {
        didSet {
            assert(emojiChoices.indices.contains(currentTheme), "Concentration.currentTheme = \(currentTheme): no such theme")
            emojiDepot = emojiChoices[currentTheme]
            view.backgroundColor = colorChoices[currentTheme]["background"]
            emoji.removeAll()
            updateViewFromModel()
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var flipCountLabel: UILabel! {
        didSet {
            updateLabel(flipCountLabel, with: "Flips: \(game.flipCount)")
        }
    }
    
    @IBOutlet private weak var scoreLabel: UILabel! {
        didSet {
            updateLabel(scoreLabel, with: "Score: \(game.score)")
        }
    }
    
    @IBOutlet private var cardButtons: [UIButton]! {
        didSet {
            cardButtons.forEach { button in
                button.layer.cornerRadius = Appearance.buttonCornerRadius
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.minimumScaleFactor = 0.1
                button.titleLabel?.baselineAdjustment = .alignCenters
                button.setTitle("", for: .normal)
            }
        }
    }
    
    // MARK: - Updating UI

    private func updateViewFromModel() {
        cardButtons.indices.forEach { index in
            let button = cardButtons[index]
            let card = game.cards[index]
            let buttonIsFaceUp = button.title(for: .normal) != ""
            if card.isFaceUp != buttonIsFaceUp {
                UIView.transition(
                    with: button,
                    duration: Appearance.flipAnimationDuration,
                    options: [.transitionFlipFromLeft, .allowAnimatedContent],
                    animations: {
                        self.updateButton(button, inLineWith: card)
                })
            } else {
                updateButton(button, inLineWith: card)
            }
        }
        updateLabel(flipCountLabel, with: "Flips: \(game.flipCount)")
        updateLabel(scoreLabel, with: "Score: \(game.score)")
    }
    
    private func updateButton(_ button: UIButton, inLineWith card: ConcentrationCard) {
        if card.isFaceUp {
            button.setTitle(self.emojiFromDepot(for: card), for: .normal)
            button.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        } else {
            button.setTitle("", for: .normal)
            button.backgroundColor = card.isMatched ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0) : colorChoices[currentTheme]["card"]
        }
    }
    
    private func updateLabel(_ label: UILabel, with text: String) {
        let attributes: [NSAttributedStringKey: Any] = [
            .strokeWidth: Appearance.labelStrokeWidth,
            .strokeColor: colorChoices[currentTheme]["card"] ?? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        label.attributedText = attributedText
    }
    
    // MARK: - Actions

    @IBAction private func touchCard(_ sender: UIButton) {
        if let cardNumber = cardButtons.index(of: sender) {
            game.chooseCard(at: cardNumber)
            updateViewFromModel()
        } else {
            print("chosen card was not in cardButtons")
        }
    }

    @IBAction private func startOver(_ sender: UIButton) {
        let oldTheme = currentTheme
        while currentTheme == oldTheme {
            currentTheme = emojiChoices.count.arc4random
        }
        game = makeNewGame()
        updateViewFromModel()
    }
    
    // MARK: - Game Settings

    private lazy var game = makeNewGame()

    private func makeNewGame() -> Concentration {
        return Concentration(numberOfPairsOfCards: (cardButtons.count + 1) / 2)
    }
    
    private let emojiChoices = [
        "🎅🏻☃️❄️🍾🌟🎁🎄🎉",
        "🍎🍐🍋🍌🍉🍇🍒🥝",
        "🍗🍔🍕🌮🌯🍜🍣🌭",
        "🥁🎷🎺🎸🎻🎤🎹🎼",
        "🚌🚎🚕🛴🚲🛵🏍🚃",
        "🐶🐱🐭🐹🐰🦊🐻🦁"
    ]
    
    private let colorChoices = [
        ["card": #colorLiteral(red: 0.4513868093, green: 0.9930960536, blue: 1, alpha: 1), "background": #colorLiteral(red: 1, green: 0.5212053061, blue: 1, alpha: 1)],
        ["card": #colorLiteral(red: 1, green: 0.1857388616, blue: 0.5733950138, alpha: 1), "background": #colorLiteral(red: 0.8321695924, green: 0.985483706, blue: 0.4733308554, alpha: 1)],
        ["card": #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1), "background": #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)],
        ["card": #colorLiteral(red: 0.3236978054, green: 0.1063579395, blue: 0.574860394, alpha: 1), "background": #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1)],
        ["card": #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1), "background": #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)],
        ["card": #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), "background": #colorLiteral(red: 0.4500938654, green: 0.9813225865, blue: 0.4743030667, alpha: 1)]
    ]
    
    private lazy var emojiDepot = emojiChoices[0]
    
    private var emoji = [ConcentrationCard: String]()
    
    private func emojiFromDepot(for card: ConcentrationCard) -> String {
        if emoji[card] == nil, emojiDepot.count > 0 {
            let randomStringIndex = emojiDepot.index(emojiDepot.startIndex, offsetBy: emojiDepot.count.arc4random)
            emoji[card] = String(emojiDepot.remove(at: randomStringIndex))
        }
        return emoji[card] ?? "?"
    }
    
    // MARK: - Lifecycle

    override func viewDidLayoutSubviews() {
        cardButtons.forEach { button in
            let sideInset = abs(button.bounds.width - button.bounds.height) / 2
            button.titleEdgeInsets = UIEdgeInsetsMake(0, sideInset, 0, sideInset)
        }
    }

}

extension Int {
    /// A uniformly random number between 0 and `self`.
    var arc4random: Int {
        if self > 0 {
            return Int(arc4random_uniform(UInt32(self)))
        } else if self < 0 {
            return -Int(arc4random_uniform(UInt32(abs(self))))
        } else {
            return 0
        }
    }
}

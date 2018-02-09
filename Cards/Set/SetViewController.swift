//
//  ViewController.swift
//  Set
//
//  Created by Denis Avdeev on 23.01.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class SetViewController: UIViewController, SetGameViewDelegate, SetGameViewDataSource {

    private struct Time {
        static let selectionRemoval = 2.0
        static let claimRemoval = 5.0
        static let minimumAIThinking = 20
        static let aiChuckle = 2.0
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var gameView: SetGameView! {
        didSet {
            gameView.delegate = self
            gameView.dataSource = self
        }
    }
    
    @IBOutlet private weak var dealButton: UIButton!
    
    @IBOutlet private weak var cheatButton: UIButton!
    
    @IBOutlet private weak var aiButton: UIButton!
    
    @IBOutlet private weak var claim1Button: UIButton!
    
    @IBOutlet private weak var claim2Button: UIButton!
    
    @IBOutlet private weak var newGameButton: UIButton!
    
    @IBOutlet private weak var scoreLabel: UILabel!
    
    @IBOutlet private weak var aiScoreLabel: UILabel!
    
    @IBOutlet private weak var deck: SetCardView!
    
    @IBOutlet private weak var pile: SetCardView!
    
    // MARK: - Updating UI
    
    private var selectionTimer: Timer?
    
    private func updateViewFromModel() {
        gameView.updateFromDataSource()
        dealButton.isEnabled = !game.deck.isEmpty || game.selectedCardsMatch
        cheatButton.isEnabled = (!game.deck.isEmpty || game.findMatch() != nil) && !twoPlayers
        scoreLabel.text = twoPlayers ? "\(game.scores[0]) : \(game.scores[1])" : "Score: \(game.scores[0])"
        if aiIsEnabled && game.selectedCardsMatch {
            initiateAIThinking()
        }
        selectionTimer?.invalidate()
        if game.selectedCardsIndices.count == 3 {
            claimIsStakedByPlayer1 = nil
            selectionTimer = Timer.scheduledTimer(withTimeInterval: Time.selectionRemoval, repeats: false) { [weak self] _ in
                self?.completeTurn()
            }
        }
        if aiIsEnabled && game.deck.isEmpty && game.findMatch() == nil {
            aiButton.setTitle(game.scores.last == game.scores.max() ? "😂" : "😢", for: .normal)
            aiTimer?.invalidate()
        }
    }
    
    private func completeTurn() {
        game.cleanUpIfMatched()
        updateViewFromModel()
        game.selectedCardsMatch ? game.deal() : game.cancelSelection()
        updateViewFromModel()
    }
    
    // MARK: - SetGameViewController
    
    var referenceView: UIView {
        return view
    }

    var deckFrame: CGRect {
        return view.convert(deck.frame, to: gameView)
    }
    
    var pileFrame: CGRect {
        return game.cards.isEmpty ? deckFrame : view.convert(pile.frame, to: gameView)
    }
    
    func gameView(_ gameView: SetGameView, didSelectCardAt index: Int) {
        guard (twoPlayers && claimIsStakedByPlayer1 != nil) || !twoPlayers else {
            return
        }
        if game.selectedCardsMatch {
            completeTurn()
        }
        let player = twoPlayers ? claimIsStakedByPlayer1! ? 0 : 1 : 0
        game.selectCard(at: index, by: player)
        updateViewFromModel()
    }
    
    func cardsWereAppearedInDeck() {
        deck.isHidden = game.deck.isEmpty
    }
    
    func cardsWereRemovedToPile() {
        pile.isHidden = game.pile.isEmpty
    }
    
    // MARK: - SetGameViewDataSource
    
    var cardsCount: Int {
        return game.cards.count
    }
    
    func propertiesOfCard(at index: Int) -> (number: SetCard.Number, symbol: SetCard.Symbol, shading: SetCard.Shading, color: SetCard.Color, state: SetCardView.State, selectionColor: UIColor?)? {
        guard index < game.cards.count else {
            return nil
        }
        var state = SetCardView.State.deselected
        var selectionColor: UIColor?
        if game.selectedCardsIndices.contains(index) {
            if game.selectedCardsIndices.count == 3 {
                state = game.selectedCardsMatch ? .matched : .mismatched
            } else {
                state = .selected
                selectionColor = twoPlayers ? claimIsStakedByPlayer1! ? #colorLiteral(red: 0.9995340705, green: 0.988355577, blue: 0.4726552367, alpha: 1) : #colorLiteral(red: 0.4513868093, green: 0.9930960536, blue: 1, alpha: 1) : nil
            }
        }
        let card = game.cards[index]
        return (number: card.number, symbol: card.symbol, shading: card.shading, color: card.color,
                state: state, selectionColor: selectionColor
        )
    }
    
    // MARK: - Actions
    
    private var claimIsStakedByPlayer1: Bool? {
        didSet {
            claim1Button.isEnabled = claimIsStakedByPlayer1 == nil
            claim2Button.isEnabled = claimIsStakedByPlayer1 == nil
            if let byPlayer1 = claimIsStakedByPlayer1 {
                claimTimer = Timer.scheduledTimer(withTimeInterval: Time.claimRemoval, repeats: false) { [weak self] _ in
                    self?.game.failToClaim(by: byPlayer1 ? 0 : 1)
                    self?.claimIsStakedByPlayer1 = nil
                    self?.game.cancelSelection()
                    self?.updateViewFromModel()
                }
            } else {
                claimTimer?.invalidate()
            }
        }
    }
    
    private var claimTimer: Timer?
    
    @IBAction private func claim(_ sender: UIButton) {
        claimIsStakedByPlayer1 = sender.titleLabel?.textColor == #colorLiteral(red: 0.9995340705, green: 0.988355577, blue: 0.4726552367, alpha: 1)
    }
    
    @IBAction private func cheat(_ sender: UIButton) {
        makeTurn(by: 0)
    }
    
    private func makeTurn(by player: Int) {
        if game.selectedCardsMatch {
            completeTurn()
            makeTurn(by: player)
        } else {
            if game.findMatch() != nil {
                game.takeTurn(by: player)
            } else {
                game.deal()
            }
            updateViewFromModel()
        }
    }
    
    @IBAction private func dealFromButton(_ sender: UIButton) {
        deal()
    }
    
    @IBAction private func dealFromDeck(_ sender: UITapGestureRecognizer) {
        switch sender.state {
        case .ended:
            deal()
        default:
            break
        }
    }
    
    private func deal() {
        if game.selectedCardsMatch {
            completeTurn()
        } else {
            game.deal(by: twoPlayers ? nil : 0)
            updateViewFromModel()
        }
    }
    
    @IBAction private func swipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.state {
        case .ended:
            deal()
        default:
            break
        }
    }
    
    @IBAction private func shuffleCards(_ sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .ended:
            game.shuffleCards()
            updateViewFromModel()
        default:
            break
        }
    }
    
    private var aiTimer: Timer?
    
    @IBAction private func toggleAI(_ sender: UIButton) {
        aiIsEnabled = !aiIsEnabled
    }

    private var startTimer: Timer?
    
    @IBAction private func startOver(_ sender: UIButton) {
        twoPlayers = !twoPlayers
        game = SetGame()
        if twoPlayers {
            game.addPlayer()
        }
        if aiIsEnabled {
            game.addPlayer()
            initiateAIThinking()
            aiScoreLabel.text = ": 0"
        }
        updateViewFromModel()
        deck.isHidden = false
        pile.isHidden = true
        if startTimer != nil {
            return
        }
        startTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.game.initialize()
            self?.updateViewFromModel()
            self?.startTimer = nil
        }
    }
    
    // MARK: - Game Settings
    
    private lazy var game = SetGame()
    
    private var aiIsEnabled = false {
        didSet {
            if aiIsEnabled {
                if game.scores.count == (twoPlayers ? 2 : 1) {
                    game.addPlayer()
                }
                initiateAIThinking()
            } else {
                aiTimer?.invalidate()
                aiButton.setTitle("😉", for: .normal)
            }
            aiScoreLabel.text = aiIsEnabled ? ": \(game.scores.last!)" : ""
        }
    }
    
    private func initiateAIThinking() {
        aiTimer?.invalidate()
        let interval = Time.minimumAIThinking + Time.minimumAIThinking.arc4random - 2
        aiTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: false) { [weak self] timer in
            self?.aiButton.setTitle("😁", for: .normal)
            self?.aiTimer = Timer.scheduledTimer(withTimeInterval: Time.aiChuckle, repeats: false) { timer in
                self?.makeTurn(by: self!.game.scores.count - 1)
                self?.aiScoreLabel.text = ": \(self?.game.scores.last ?? 0)"
                self?.initiateAIThinking()
                self?.updateViewFromModel()
            }
        }
        aiButton.setTitle("🤔", for: .normal)
    }

    private var twoPlayers = false {
        didSet {
            newGameButton.setTitle(twoPlayers ? "One Player" : "Two Players", for: .normal)
            claim1Button.isHidden = !twoPlayers
            claim2Button.isHidden = !twoPlayers
            claimIsStakedByPlayer1 = nil
        }
    }

    // MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if game.cards.isEmpty && !game.deck.isEmpty && startTimer == nil {
            game.initialize()
            updateViewFromModel()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}


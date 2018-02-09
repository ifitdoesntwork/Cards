//
//  SetGame.swift
//  Set
//
//  Created by Denis Avdeev on 23.01.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import Foundation

struct SetGame {
    
    private struct Score {
        static let deselection = -1
        static let mismatch = -1
        static let failToClaim = -5
        static let unnoticedMatch = -5
        static let minimumMatch = 3
        static let notDealingBonus = 1
        static let thinkingSecondsCausingPenalty = 30
    }
    
    // MARK: - Match
    
    /// A boolean value that determines whether selected cards match.
    /// - Complexity: O(n)
    var selectedCardsMatch: Bool {
        return isJustCleanedUp ? true : cardsMatch(indices: selectedCardsIndices)
    }
    
    private func cardsMatch(indices: [Int]) -> Bool {
        guard indices.count == 3 else {
            return false
        }
//        return true
        let cards = self.cards.filter {
            indices.contains(self.cards.index(of: $0)!)
        }
        let sums = [
            cards.reduce(0) { sum, card in
                sum + card.color.rawValue
            },
            cards.reduce(0) { sum, card in
                sum + card.number.rawValue
            },
            cards.reduce(0) { sum, card in
                sum + card.shading.rawValue
            },
            cards.reduce(0) { sum, card in
                sum + card.symbol.rawValue
            }
        ]
        return sums.reduce(true) { result, sum in
            result && (sum == 0 || sum == 3 || sum == 6)
        }
    }
    
    /// Finds a match in `cards`; returns `nil` if no matches present.
    func findMatch() -> [Int]? {
        for index0 in 0..<cards.count {
            for index1 in index0 + 1..<cards.count {
                for index2 in index1 + 1..<cards.count {
                    let combination = [index0, index1, index2]
                    if cardsMatch(indices: combination) {
                        return combination
                    }
                }
            }
        }
        return nil
    }
    
    // MARK: - States
    
    /// Instantly selects a set of matching cards if any
    /// and increments `scores` at the `player` position.
    mutating func takeTurn(by player: Int = 0) {
        guard !isJustCleanedUp && !selectedCardsMatch else {
            return
        }
        if findMatch() != nil {
            selectedCardsIndices = findMatch()!
            scores[player] += matchScore()
        }
    }
    
    /// The scores of the players in the game.
    private(set) var scores = [0]
    
    /// Adds a player to the game.
    mutating func addPlayer() {
        scores.append(0)
    }
    
    /// Selects or deselets a card in `cards` at `index`;
    /// deselects the previously selected cards when needed;
    /// updates `scores` at the `player` position.
    mutating func selectCard(at index: Int, by player: Int = 0) {
        guard !isJustCleanedUp else {
            return
        }
        if selectedCardsIndices.contains(index) {
            if selectedCardsIndices.count < 3 {
                selectedCardsIndices.remove(index)
                scores[player] += Score.deselection
            }
        } else {
            if selectedCardsIndices.count == 3 {
                selectedCardsIndices.removeAll()
            }
            selectedCardsIndices.append(index)
            if selectedCardsMatch {
                scores[player] += matchScore()
            } else if selectedCardsIndices.count == 3 {
                scores[player] += Score.mismatch
            }
        }
    }
    
    /// Decrements `scores` at the `player` position
    /// for failing to claim a set.
    mutating func failToClaim(by player: Int) {
        scores[player] += Score.failToClaim
    }
    
    /// Deselects the previously selected cards.
    mutating func cancelSelection() {
        guard !isJustCleanedUp else {
            return
        }
        selectedCardsIndices.removeAll()
    }
    
    private var isJustCleanedUp = false
    
    /// Transfers the matched cards from `cards` to `pile`.
    mutating func cleanUpIfMatched() {
        guard selectedCardsMatch && !isJustCleanedUp else {
            return
        }
        selectedCardsIndices.sorted().reversed().forEach { index in
            pile.append(cards.remove(at: index))
        }
        isJustCleanedUp = true
    }

    /// Deals three more cards if possible;
    /// deselects the previously selected cards;
    /// decrements `scores` at the `player` position if a match is missed.
    mutating func deal(by player: Int? = nil) {
        guard !(selectedCardsMatch && !isJustCleanedUp) else {
            return
        }
        if isJustCleanedUp {
            selectedCardsIndices.sorted().forEach { index in
                if let card = dealCards(amount: 1)?.first {
                    cards.insert(card, at: index)
                }
            }
            selectedCardsIndices.removeAll()
            isJustCleanedUp = false
        } else {
            if player != nil && findMatch() != nil {
                scores[player!] += Score.unnoticedMatch
            }
            cards.append(contentsOf: dealCards(amount: 3) ?? [])
            if selectedCardsIndices.count == 3 {
                selectedCardsIndices.removeAll()
            }
        }
    }

    private var lastTurnTime = Date()
    
    private mutating func matchScore() -> Int {
        var score = Score.minimumMatch
        stride(from: 15, through: 24, by: 3).forEach { number in
            if cards.count < number {
                score += Score.notDealingBonus
            }
        }
        let timePenalty = -Int(lastTurnTime.timeIntervalSinceNow) / Score.thinkingSecondsCausingPenalty
        score -= timePenalty < score ? timePenalty : score
        lastTurnTime = Date()
        return score
    }
    
    // MARK: - Decks
    
    /// The cards currently face up.
    private(set) var cards = [SetCard]()
    
    /// The indices of `cards` selected by a player.
    private(set) var selectedCardsIndices = [Int]()
    
    private mutating func dealCards(amount: Int) -> [SetCard]? {
        guard deck.count >= amount else {
            return nil
        }
        var deal = [SetCard]()
        (1...amount).forEach { _ in
            deal.append(deck.removeLast())
        }
        return deal
    }
    
    /// Shuffles the `cards` and updates `selectedCardsIndices`.
    mutating func shuffleCards() {
        let cardsBackup = cards
        let selectedCardsIndicesBackup = selectedCardsIndices
        selectedCardsIndices.removeAll()
        var cardsToShuffle = cards
        cards.removeAll()
        while !cardsToShuffle.isEmpty {
            let randomCard = cardsToShuffle.remove(at: cardsToShuffle.count.arc4random)
            let oldIndex = cardsBackup.index(of: randomCard)!
            if selectedCardsIndicesBackup.contains(oldIndex) {
                selectedCardsIndices.append(cards.count)
            }
            cards.append(randomCard)
        }
    }
    
    /// Puts initial 12 cards from `deck` to `cards`.
    mutating func initialize() {
        cards = dealCards(amount: 12) ?? []
    }
    
    /// A deck of shuffled Set cards.
    private(set) lazy var deck: [SetCard] = {
        var sortedDeck = [SetCard]()
        SetCard.Color.cases.forEach { color in
            SetCard.Number.cases.forEach { number in
                SetCard.Shading.cases.forEach { shading in
                    SetCard.Symbol.cases.forEach { symbol in
                        sortedDeck.append(SetCard(number: number, symbol: symbol, shading: shading, color: color))
                    }
                }
            }
        }
        var deck = [SetCard]()
        while !sortedDeck.isEmpty {
            deck.append(sortedDeck.remove(at: sortedDeck.count.arc4random))
        }
        return deck
    }()
    
    /// The pile of matched cards.
    private(set) var pile = [SetCard]()
    
}

extension Array where Iterator.Element: Equatable {
    /// Removes the element from the array if it is there.
    mutating func remove(_ element: Element) {
        if let index = self.index(of: element) {
            self.remove(at: index)
        }
    }
}

//
//  Concentration.swift
//  Concentration
//
//  Created by Denis Avdeev on 12.01.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import Foundation

struct Concentration
{
    private struct Score {
        static let match = 10
        static let mismatch = -1
    }
    
    /// An array of cards currently in game.
    private(set) var cards = [ConcentrationCard]()
    
    /// The card flips counter.
    private(set) var flipCount = 0
    
    /// The game score.
    private(set) var score = 0
    
    private var lastScoringTime = Date()
    
    private var indexOfOneAndOnlyFaceUpCard: Int? {
        get {
            return cards.indices.filter { index in
                cards[index].isFaceUp
            }.oneAndOnly
        }
        set {
            cards.indices.forEach { index in
                cards[index].isFaceUp = index == newValue
            }
        }
    }
    
    /// Selects or deselects a card in `cards` chosen by `index`;
    /// turns one and only selected card face up;
    /// turns two previously selected cards face down if they are face up;
    /// calculates and updates `score` and `flipCount`.
    mutating func chooseCard(at index: Int) {
        assert(cards.indices.contains(index), "Concentration.chooseCard(at: \(index): no such card")
        if !cards[index].isMatched, !cards[index].isFaceUp {
            if let matchIndex = indexOfOneAndOnlyFaceUpCard, matchIndex != index {
                let interval = -Int(lastScoringTime.timeIntervalSinceNow) + 1
                lastScoringTime = Date()
                if cards[matchIndex] == cards[index] {
                    cards[matchIndex].isMatched = true
                    cards[index].isMatched = true
                    score += Score.match / interval
                } else {
                    [matchIndex, index].forEach { index in
                        if cards[index].hasAppeared {
                            score += Score.mismatch * interval
                        }
                        cards[index].hasAppeared = true
                    }
                }
                cards[index].isFaceUp = true
            } else {
                indexOfOneAndOnlyFaceUpCard = index
            }
            flipCount += 1
        }
    }
    
    /// Creates an instance with `cards` containing `numberOfPairsOfCards`
    /// pairs of identical cards, then shuffles `cards`.
    init(numberOfPairsOfCards: Int) {
        assert(numberOfPairsOfCards > 0, "Concentration.init(\(numberOfPairsOfCards): at least one pair of cards required")
        ConcentrationCard.resetDeck()
        var sortedCards = [ConcentrationCard]()
        (1...numberOfPairsOfCards).forEach { _ in
            let card = ConcentrationCard()
            sortedCards += [card, card]
        }
        while sortedCards.count > 0 {
            cards.append(sortedCards.remove(at: sortedCards.count.arc4random))
        }
    }
}

extension Collection {
    /// The one and only element in `self`, or `nil` if `self` contains different number of elements.
    var oneAndOnly: Element? {
        return count == 1 ? first : nil
    }
}

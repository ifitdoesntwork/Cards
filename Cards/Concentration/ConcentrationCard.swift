//
//  Card.swift
//  Concentration
//
//  Created by Denis Avdeev on 12.01.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import Foundation

struct ConcentrationCard: Hashable
{
    var hashValue: Int {
        return identifier
    }
    
    static func ==(lhs: ConcentrationCard, rhs: ConcentrationCard) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    /// A boolean value that determines whether the card is face up.
    var isFaceUp = false
    /// A boolean value that determines whether the card is matched.
    var isMatched = false
    /// A boolean value that determines whether the card has already appeared in the current game.
    var hasAppeared = false
    
    private var identifier: Int
    
    private static var identifierFactory = -1
    
    /// Resets the card deck to initial state.
    static func resetDeck() {
        identifierFactory = -1
    }
    
    private static func makeUniqueIdentifier() -> Int {
        identifierFactory += 1
        return identifierFactory
    }
    
    /// Creates a unique instance.
    init() {
        self.identifier = ConcentrationCard.makeUniqueIdentifier()
    }
}

//
//  Card.swift
//  Set
//
//  Created by Denis Avdeev on 23.01.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import Foundation

struct SetCard: Equatable {
    
    static func ==(lhs: SetCard, rhs: SetCard) -> Bool {
        return lhs.color == rhs.color && lhs.number == rhs.number && lhs.shading == rhs.shading && lhs.symbol == rhs.symbol
    }
    
    enum Number: Int, CardProperty {
        case one, two, three
    }
    
    enum Symbol: Int, CardProperty {
        case diamond, squiggle, oval
    }
    
    enum Shading: Int, CardProperty {
        case solid, striped, open
    }
    
    enum Color: Int, CardProperty {
        case red, green, purple
    }
    
    /// A property of the Set card.
    let number: Number
    /// A property of the Set card.
    let symbol: Symbol
    /// A property of the Set card.
    let shading: Shading
    /// A property of the Set card.
    let color: Color
    
}

protocol CardProperty: RawRepresentable where Self.RawValue == Int {
    /// All the possible cases of a card property.
    static var cases: [Self] { get }
}

extension CardProperty {
    /// All the possible cases of a card property.
    /// - Complexity: O(1)
    static var cases: [Self] {
        return (0...2).map { index in
            Self(rawValue: index)!
        }
    }
}

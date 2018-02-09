//
//  CardBehavior.swift
//  Set
//
//  Created by Denis Avdeev on 03.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class CardBehavior: UIDynamicBehavior {

    private struct Constants {
        static let itemElasticity: CGFloat = 0.5
        static let itemResistance: CGFloat = 3.0
        static let itemAngularResistance: CGFloat = 3.0
        static let referenceCardPushMagnitude: CGFloat = 2.0
        static let referenceCardArea: CGFloat = 40.0 * 40.0 * 5 / 3
        static let basicPushAngularVelocity: CGFloat = 0.5
    }
    
    private lazy var collisionBehavior: UICollisionBehavior = {
        let behavior = UICollisionBehavior()
        behavior.translatesReferenceBoundsIntoBoundary = true
        return behavior
    }()
    
    private lazy var itemBehavior: UIDynamicItemBehavior = {
        let behavior = UIDynamicItemBehavior()
        behavior.elasticity = Constants.itemElasticity
        behavior.resistance = Constants.itemResistance
        behavior.angularResistance = Constants.itemAngularResistance
        return behavior
    }()
    
    private func push(_ item: UIDynamicItem) {
        let push = UIPushBehavior(items: [item], mode: .instantaneous)
        push.angle = (2 * CGFloat.pi).arc4random
        let basicMagnitude = Constants.referenceCardPushMagnitude * item.bounds.width * item.bounds.height / Constants.referenceCardArea
        push.magnitude = basicMagnitude + CGFloat(basicMagnitude).arc4random
        itemBehavior.addAngularVelocity((2 * Constants.basicPushAngularVelocity).arc4random - Constants.basicPushAngularVelocity, for: item)
        push.action = { [unowned push, weak self] in
            self?.removeChildBehavior(push)
        }
        addChildBehavior(push)
    }
    
    /// Adds a dynamic item to the behavior.
    func addItem(_ item: UIDynamicItem) {
        collisionBehavior.addItem(item)
        itemBehavior.addItem(item)
        push(item)
    }
    
    /// Removes a dynamic item from the behavior.
    func removeItem(_ item: UIDynamicItem) {
        collisionBehavior.removeItem(item)
        itemBehavior.removeItem(item)
    }
    
    override init() {
        super.init()
        addChildBehavior(collisionBehavior)
        addChildBehavior(itemBehavior)
    }
    
    convenience init(animator: UIDynamicAnimator) {
        self.init()
        animator.addBehavior(self)
    }
    
}

extension CGFloat {
    /// A uniformly random number between 0 and `self`.
    var arc4random: CGFloat {
        let precision: CGFloat = 1_000_000.0
        if self > 0 {
            return CGFloat(arc4random_uniform(UInt32(self * precision))) / precision
        } else if self < 0 {
            return -CGFloat(arc4random_uniform(UInt32(-self * precision))) / precision
        } else {
            return 0
        }
    }
}

//
//  SetGameView.swift
//  Set
//
//  Created by Denis Avdeev on 02.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

@IBDesignable
class SetGameView: UIView, UIDynamicAnimatorDelegate {

    private struct Constants {
        static let cardAspectRatio: CGFloat = 3 / 5
        static let shuffleTime = 0.25
        static let dealAnimationDuration = 0.6
        static let numberOfSpins = 2
        static let chaosDuration = 1.0
        static let moveToPileDuration = 0.3
        static let flipAnimationDuration = 0.5
        static let moveToGridDuration = 0.3
        static let cardInGridInset: CGFloat = 5.0
    }
    
    // MARK: - Updating UI
    
    /// The game view delegate.
    var delegate: SetGameViewDelegate?
    
    /// The game view data source.
    var dataSource: SetGameViewDataSource?
    
    /// Updates the game view according to changes in the `dataSource`.
    func updateFromDataSource() {
        let cardsCount = dataSource?.cardsCount ?? self.cardsCount
        grid.cellCount = cardsCount
        let cardsBackup = cards
        cards.removeAll()
        (0..<cardsCount).forEach { index in
            let existingCard = cardsBackup.filter { card in
                if let (number, symbol, shading, color, _, _) = dataSource?.propertiesOfCard(at: index) {
                    return number == card.number && symbol == card.symbol && shading == card.shading && color == card.color
                }
                return false
            }.first
            if let card = existingCard {
                cards.append(card)
            } else {
                addCard(at: index)
            }
        }
        (subviews as? [SetCardView])?.filter { card in
            !(cards + cardsToRemove).contains(card)
        }.forEach { card in
                removeCard(card)
        }
        cards.forEach { card in
            if let index = cards.index(of: card), let (_, _, _, _, state, color) = dataSource?.propertiesOfCard(at: index) {
                card.state = cardsToDeal.contains(card) ? .facedown : state
                card.selectionColor = color
            }
        }
        if cards.count == cardsBackup.count && cards != cardsBackup {
            shuffleCards()
        }
        setNeedsLayout()
    }

    private var grid = Grid(layout: .aspectRatio(Constants.cardAspectRatio))
    
    private var cards = [SetCardView]()

    private var cardsToShuffle = [SetCardView]()
    
    private func shuffleCards() {
        cards.forEach { card in
            if !cardsToDeal.contains(card) {
                cardsToShuffle.append(card)
                cardBehavior.addItem(card)
                Timer.scheduledTimer(withTimeInterval: Constants.shuffleTime, repeats: false) { [weak self] _ in
                    self?.cardBehavior.removeItem(card)
                    card.transform = .identity
                    self?.cardsToShuffle.remove(card)
                    self?.setNeedsLayout()
                }
            }
        }
    }
    
    // MARK: - Dealing Cards
    
    private var cardsToDeal = [SetCardView]()

    private func addCard(at index: Int) {
        let card = SetCardView()
        cards.insert(card, at: index)
        if let properties = dataSource?.propertiesOfCard(at: index) {
            (card.number, card.symbol, card.shading, card.color, _, _) = properties
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(SetGameView.selectCard))
        card.addGestureRecognizer(tap)
        if let topCardToDeal = cardsToDeal.last {
            insertSubview(card, aboveSubview: topCardToDeal)
        } else if let topStaticCard = (subviews as? [SetCardView])?.reduce(
            nil as SetCardView?,
            { lastStaticCard, subviewCard in
                cards.contains(subviewCard) ? subviewCard : lastStaticCard
            }
        ) {
            insertSubview(card, aboveSubview: topStaticCard)
        } else {
            insertSubview(card, at: 0)
        }
        card.frame = delegate?.deckFrame ?? .zero
        if cardsToDeal.isEmpty {
            delegate?.cardsWereAppearedInDeck()
        }
        #if !TARGET_INTERFACE_BUILDER
            cardsToDeal.append(card)
        #endif
        deal()
    }
    
    private var dealIsInProgress = false

    private func deal() {
        guard let card = cardsToDeal.first, !dealIsInProgress else {
            return
        }
        dealIsInProgress = true
        rotateCard(card)
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: Constants.dealAnimationDuration,
            delay: 0,
            options: [],
            animations: {
                let finalFrame = self.gridFrame(for: card)
                card.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
                card.bounds = CGRect(origin: .zero, size: finalFrame.size)
            },
            completion: { _ in
                self.cardsToDeal.remove(card)
                if self.cards.contains(card) {
                    card.frame = self.gridFrame(for: card)
                    self.flipCard(card)
                }
                self.dealIsInProgress = false
                self.deal()
            }
        )
    }
    
    private func rotateCard(_ card: SetCardView) {
        let phaseDuration = Constants.dealAnimationDuration / TimeInterval(Constants.numberOfSpins) / 3
        (0..<Constants.numberOfSpins * 3).forEach { index in
            let animationStyle: UIViewAnimationOptions
            if index == 0 {
                animationStyle = .curveEaseIn
            } else if index == Constants.numberOfSpins * 3 - 1 {
                animationStyle = .curveEaseOut
            } else {
                animationStyle = .curveLinear
            }
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: phaseDuration,
                delay: phaseDuration * TimeInterval(index),
                options: animationStyle,
                animations: {
                    card.transform = card.transform.rotated(by: CGFloat.pi * 2 / 3)
                }
            )
        }
    }

    // MARK: - Removing Cards
    
    private lazy var animator: UIDynamicAnimator = {
        let animator = UIDynamicAnimator(referenceView: delegate?.referenceView ?? self)
        animator.delegate = self
        return animator
    }()
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        (animator.items(in: animator.referenceView?.bounds ?? bounds) as? [SetCardView])?.forEach { card in
            cardBehavior.removeItem(card)
            moveCardToPile(card)
        }
    }
    
    private lazy var cardBehavior = CardBehavior(animator: animator)

    private var cardsToRemove = [SetCardView]()

    private func removeCard(_ card: SetCardView) {
        cardsToRemove.append(card)
        if !cardsToDeal.contains(card) {
            cardBehavior.addItem(card)
            Timer.scheduledTimer(withTimeInterval: Constants.chaosDuration, repeats: false) { [weak self] _ in
                self?.cardBehavior.removeItem(card)
                self?.moveCardToPile(card)
            }
        } else {
            cardsToDeal.remove(card)
            moveCardToPile(card)
        }
    }
    
    private func moveCardToPile(_ card: SetCardView) {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: Constants.moveToPileDuration,
            delay: 0,
            options: [.beginFromCurrentState],
            animations: {
                card.transform = .identity
                card.frame = self.delegate?.pileFrame ?? .zero
            },
            completion: { _ in
                if card.state == .facedown {
                    card.removeFromSuperview()
                } else {
                    self.flipCard(card)
                }
            }
        )
    }
    
    private func flipCard(_ card: SetCardView) {
        UIView.transition(
            with: card,
            duration: Constants.flipAnimationDuration,
            options: [.transitionFlipFromLeft],
            animations: {
                card.state = card.state == .facedown ? .deselected : .facedown
        }) { _ in
            if card.state == .facedown {
                self.delegate?.cardsWereRemovedToPile()
                self.cardsToRemove.remove(card)
                card.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Lifecycle
    
    @IBInspectable private var cardsCount: Int = 12
    
    override func prepareForInterfaceBuilder() {
        updateFromDataSource()
        cards.forEach { card in
            card.state = .deselected
            card.frame = gridFrame(for: card)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        grid.frame = bounds
        cards.forEach { card in
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: Constants.moveToGridDuration,
                delay: 0,
                options: [],
                animations: {
                    if !(self.cardsToDeal + self.cardsToShuffle).contains(card) {
                        card.frame = self.gridFrame(for: card)
                    }
                    if self.cardsToDeal.contains(card) && card != self.cardsToDeal.first {
                        card.frame = self.delegate?.deckFrame ?? .zero
                    }
                }
            )
        }
    }
    
    private func gridFrame(for card: SetCardView) -> CGRect {
        if let index = cards.index(of: card), let frame = self.grid[index] {
            return frame.insetBy(dx: Constants.cardInGridInset, dy: Constants.cardInGridInset)
        }
        return card.frame
    }
    
    @objc func selectCard(_ sender: UITapGestureRecognizer) {
        guard let card = sender.view as? SetCardView, let cardIndex = cards.index(of: card) else {
            return
        }
        switch sender.state {
        case .ended:
            delegate?.gameView(self, didSelectCardAt: cardIndex)
        default:
            break
        }
    }

}

protocol SetGameViewDelegate {
    /// The view where dynamic animations should take place;
    /// an appropriate candidate would be the `superview` of a game view.
    var referenceView: UIView { get }
    
    /// The frame of the deck in game view's coordinates.
    var deckFrame: CGRect { get }
    
    /// The frame of the pile in game view's coordinates.
    var pileFrame: CGRect { get }
    
    /// Informs the controller that a card positioned at `index`
    /// in the grid was just selected in `gameView`.
    func gameView(_ gameView: SetGameView, didSelectCardAt index: Int)
    
    /// Informs the controller that some cards were just taken from the deck
    /// and will be displayed by a game view from now on.
    func cardsWereAppearedInDeck()
    
    /// Informs the controller that more cards were just removed to the pile
    /// and should be displayed by the controller from now on.
    func cardsWereRemovedToPile()
}

protocol SetGameViewDataSource {
    /// The number of cards in the data source.
    var cardsCount: Int { get }
    
    /// Properties to display of a card positioned at `index` in the grid.
    func propertiesOfCard(at index: Int) -> (number: SetCard.Number, symbol: SetCard.Symbol, shading: SetCard.Shading, color: SetCard.Color, state: SetCardView.State, selectionColor: UIColor?)?
}

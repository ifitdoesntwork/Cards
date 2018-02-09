//
//  ThemeViewController.swift
//  Concentration
//
//  Created by Denis Avdeev on 04.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class ThemeViewController: UIViewController, UISplitViewControllerDelegate {

    private static let segueIdentifier = "Choose Theme"
    
    private var splitViewDetail: ConcentrationViewController? {
        return splitViewController?.viewControllers.last?.contents as? ConcentrationViewController
    }
    
    @IBAction private func changeTheme(_ sender: Any) {
        if let controller = splitViewDetail {
            prepare(controller, from: sender)
        } else if let controller = lastSeguedToController?.contents as? ConcentrationViewController {
            prepare(controller, from: sender)
            navigationController?.pushViewController(lastSeguedToController!, animated: true)
        } else {
            performSegue(withIdentifier: ThemeViewController.segueIdentifier, sender: sender)
        }
    }
    
    private func prepare(_ controller: ConcentrationViewController, from sender: Any) {
        if let button = sender as? UIButton, let theme = button.superview?.subviews.index(of: button) {
            controller.currentTheme = theme
            controller.title = button.currentTitle
        }
    }
    
    private var lastSeguedToController: UIViewController?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ThemeViewController.segueIdentifier {
            if let controller = segue.destination.contents as? ConcentrationViewController {
                prepare(controller, from: sender as Any)
                lastSeguedToController = controller
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        splitViewController?.delegate = self
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return lastSeguedToController == nil
    }

}

extension UIViewController {
    /// The controller contained in `self` if `self` is `UINavigationController`; otherwise `self`.
    var contents: UIViewController {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController ?? self
        } else {
            return self
        }
    }
}

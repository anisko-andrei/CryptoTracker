//
//  FadePushAnimator.swift
//  CryptoTracker
//
//  Created by anisko on 26.05.25.
//

import UIKit

final class FadePushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.35 }
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let toView = context.view(forKey: .to) else { return }
        let container = context.containerView
        toView.alpha = 0
        container.addSubview(toView)
        UIView.animate(withDuration: 0.35, animations: {
            toView.alpha = 1
        }, completion: { finished in
            context.completeTransition(finished)
        })
    }
}

//
//  AppCoordinator.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import UIKit

final class AppCoordinator: Coordinator {
    private let window: UIWindow
    private let dependencyContainer: DependencyContainer
    
    init(window: UIWindow, dependencyContainer: DependencyContainer) {
        self.window = window
        self.dependencyContainer = dependencyContainer
    }
    
    func start() {
        let tabBarController = RootTabBarController(dependencyContainer: dependencyContainer)
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
}

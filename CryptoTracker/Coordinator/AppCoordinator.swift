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
        // Main tab
        let mainListViewModel = MainListViewModel(
            cryptoService: dependencyContainer.cryptoService
        )
        let mainListVC = MainListViewController(viewModel: mainListViewModel)
        mainListVC.tabBarItem = UITabBarItem(title: "All", image: UIImage(systemName: "list.bullet"), tag: 0)
        
        // Favorites tab
        let favoritesListViewModel = FavoritesListViewModel(cryptoService: dependencyContainer.cryptoService)
        let favoritesListVC = FavoritesListViewController(viewModel: favoritesListViewModel)
        favoritesListVC.tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "star.fill"), tag: 1)
        
        // Tab Bar Controller
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            UINavigationController(rootViewController: mainListVC),
            UINavigationController(rootViewController: favoritesListVC)
        ]
        
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
}

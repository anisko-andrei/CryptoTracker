//
//  AppCoordinator.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import UIKit

final class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    private let dependencyContainer: DependencyContainer
    
    init(navigationController: UINavigationController,
         dependencyContainer: DependencyContainer) {
        self.navigationController = navigationController
        self.dependencyContainer = dependencyContainer
    }
    
    func start() {
        let mainListViewModel = MainListViewModel(
            cryptoService: dependencyContainer.cryptoService
        )
        let mainListVC = MainListViewController(viewModel: mainListViewModel)
        navigationController.viewControllers = [mainListVC]
    }
}

//
//  RootTabBarController.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cryptoService = CryptoService()
        let mainListVM = MainListViewModel(cryptoService: cryptoService)
        let mainVC = MainListViewController(viewModel: mainListVM)
        mainVC.tabBarItem = UITabBarItem(title: "All", image: UIImage(systemName: "list.bullet"), tag: 0)
        
        let favoritesVM = FavoritesListViewModel(cryptoService: cryptoService)
        let favoritesVC = FavoritesListViewController(viewModel: favoritesVM)
        
        viewControllers = [
            UINavigationController(rootViewController: mainVC),
            UINavigationController(rootViewController: favoritesVC)
        ]
    }
}

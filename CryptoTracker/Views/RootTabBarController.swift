//
//  RootTabBarController.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.



import UIKit

final class RootTabBarController: UITabBarController {
    private let dependencyContainer: DependencyContainer
    
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        let mainListVM = MainListViewModel(
            cryptoService: dependencyContainer.cryptoService,
            cacheService: dependencyContainer.mainCryptoCache
        )
        let mainVC = MainListViewController(viewModel: mainListVM)
        mainVC.tabBarItem = UITabBarItem(title: "All", image: UIImage(systemName: "list.bullet"), tag: 0)
        
        let favoritesVM = FavoritesListViewModel(
            cryptoService: dependencyContainer.cryptoService,
            cacheService: dependencyContainer.favoritesCache
        )
        let favoritesVC = FavoritesListViewController(viewModel: favoritesVM)
        favoritesVC.tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "star.fill"), tag: 1)
        
        viewControllers = [
            UINavigationController(rootViewController: mainVC),
            UINavigationController(rootViewController: favoritesVC)
        ]
    }
}

extension RootTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        if let fromView = selectedViewController?.view,
           let toView = viewController.view,
           fromView != toView {
            UIView.transition(from: fromView,
                              to: toView,
                              duration: 0.3,
                              options: [.transitionCrossDissolve]) 
        }
        return true
    }
}

//
//  MainListViewController.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//

import UIKit

final class MainListViewController: UIViewController {
    private let viewModel: MainListViewModel
    
    init(viewModel: MainListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "CryptoTracker"
    }
}

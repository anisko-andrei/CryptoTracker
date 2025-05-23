//
//  MainListViewController.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//

import UIKit
import Combine

final class MainListViewController: UIViewController {
    private let viewModel: MainListViewModel
    private var cancellables = Set<AnyCancellable>()

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

        viewModel.fetchCryptos()

        viewModel.$cryptos
            .sink { cryptos in
                print(cryptos.map { $0.name ?? "-" })
            }
            .store(in: &cancellables)

        viewModel.$error
            .sink { error in
                if let error = error {
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
}

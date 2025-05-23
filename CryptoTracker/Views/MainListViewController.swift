//
//  MainListViewController.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//

import UIKit
import Combine
import SnapKit

final class MainListViewController: UIViewController {
    private let viewModel: MainListViewModel
    private var cancellables = Set<AnyCancellable>()
    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()
    private let refreshControl = UIRefreshControl()
    
    init(viewModel: MainListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchCryptos()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "CryptoTracker"
        
        // TableView
        tableView.register(CryptoCell.self, forCellReuseIdentifier: CryptoCell.identifier)
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // Error Label
        errorLabel.textAlignment = .center
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.font = .systemFont(ofSize: 16, weight: .medium)
        view.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        view.bringSubviewToFront(activityIndicator)
        view.bringSubviewToFront(errorLabel)
    }
    
    @objc private func handleRefresh() {
        print("Refresh triggered")
        viewModel.fetchCryptos()
    }
    
    private func bindViewModel() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        errorLabel.isHidden = true
        
        viewModel.$cryptos
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] cryptos in
                self?.activityIndicator.stopAnimating()
                self?.activityIndicator.isHidden = true
                self?.refreshControl.endRefreshing()
                self?.errorLabel.isHidden = true
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.activityIndicator.stopAnimating()
                    self?.activityIndicator.isHidden = true
                    self?.refreshControl.endRefreshing()
                    self?.errorLabel.text = "Ошибка: \(error.localizedDescription)"
                    self?.errorLabel.isHidden = false
                } else {
                    self?.errorLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension MainListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.cryptos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CryptoCell.identifier, for: indexPath) as? CryptoCell else {
            return UITableViewCell()
        }
        let crypto = viewModel.cryptos[indexPath.row]
        cell.configure(with: crypto)
        return cell
    }
}

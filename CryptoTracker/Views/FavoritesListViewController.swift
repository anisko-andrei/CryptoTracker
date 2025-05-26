//
//  FavoritesListViewController.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import UIKit
import Combine
import SnapKit

final class FavoritesListViewController: UIViewController {
    private let viewModel: FavoritesListViewModel
    private var cancellables = Set<AnyCancellable>()
    private let tableView = UITableView()
    private let emptyLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let offlineIconView = UIImageView(image: UIImage(systemName: "wifi.slash"))
    private var offlineBarButtonItem: UIBarButtonItem?
    
    init(viewModel: FavoritesListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "star.fill"), tag: 1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchFavorites()
        navigationController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchFavorites()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Favorites"
        
        //OFFLINE ICON
        offlineIconView.tintColor = .systemRed
        offlineIconView.contentMode = .scaleAspectFit
        offlineIconView.snp.makeConstraints { make in
            make.width.height.equalTo(22)
        }
        offlineBarButtonItem = UIBarButtonItem(customView: offlineIconView)
        offlineBarButtonItem?.isEnabled = false
        offlineBarButtonItem?.customView?.isHidden = true
        navigationItem.leftBarButtonItem = offlineBarButtonItem
        
        // TableView
        tableView.register(CryptoCell.self, forCellReuseIdentifier: CryptoCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Empty Label
        emptyLabel.text = "No favorites yet"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func bindViewModel() {
        viewModel.$cryptos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cryptos in
                self?.activityIndicator.stopAnimating()
                self?.emptyLabel.isHidden = !cryptos.isEmpty
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$isOfflineData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isOffline in
                self?.offlineBarButtonItem?.customView?.isHidden = !isOffline
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading { self?.activityIndicator.startAnimating() }
                else { self?.activityIndicator.stopAnimating() }
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension FavoritesListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.cryptos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CryptoCell.identifier, for: indexPath) as? CryptoCell else {
            return UITableViewCell()
        }
        let crypto = viewModel.cryptos[indexPath.row]
        cell.configure(with: crypto, isFavorite: FavoritesManager.shared.isFavorite(id: crypto.id ?? ""))
        cell.onFavoriteTapped = { [weak self] in
            guard let id = crypto.id else { return }
            FavoritesManager.shared.toggle(id: id)
            self?.viewModel.fetchFavorites()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let crypto = viewModel.cryptos[indexPath.row]
        let detailVM = CryptoDetailViewModel(crypto: crypto, cryptoService: viewModel.cryptoService)
        let detailVC = CryptoDetailViewController(viewModel: detailVM)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension FavoritesListViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                             animationControllerFor operation: UINavigationController.Operation,
                             from fromVC: UIViewController,
                             to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return FadePushAnimator()
    }
}

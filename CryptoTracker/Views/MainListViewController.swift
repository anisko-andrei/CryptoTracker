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
    private let searchController = UISearchController(searchResultsController: nil)
    
    init(viewModel: MainListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchCryptos()
        setupKeyboardObservers()
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        let bottomInset = keyboardHeight - view.safeAreaInsets.bottom
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        tableView.contentInset.bottom = 0
        tableView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "CryptoTracker"
        
        // SEARCH
        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.delegate = self
        
        // SORT BUTTON (иконка)
        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down.square"),
            style: .plain,
            target: self,
            action: #selector(showSortMenu)
        )
        
        // FILTER BUTTON (иконка)
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(showFilterMenu)
        )
        
        navigationItem.rightBarButtonItems = [filterButton, sortButton]
        
        // TableView
        tableView.register(CryptoCell.self, forCellReuseIdentifier: CryptoCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
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
    
    @objc private func showSortMenu() {
        let alert = UIAlertController(title: "Sort by", message: nil, preferredStyle: .actionSheet)
        let currentSort = viewModel.sortType
        
        func addSortAction(type: MainListViewModel.SortType, style: UIAlertAction.Style = .default) {
            let isSelected = currentSort == type
            let action = UIAlertAction(
                title: type.rawValue,
                style: style,
                handler: { [weak self] _ in
                    guard let self else { return }
                    self.viewModel.sortType = type
                    self.viewModel.applySearchAndSort()
                }
            )
            if isSelected {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            alert.addAction(action)
        }
        
        addSortAction(type: .nameAsc)
        addSortAction(type: .nameDesc)
        addSortAction(type: .priceAsc)
        addSortAction(type: .priceDesc)
        addSortAction(type: .none, style: .destructive)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first(where: { $0.action == #selector(showSortMenu) })
        }
        present(alert, animated: true)
    }
    
    @objc private func showFilterMenu() {
        let alert = UIAlertController(title: "Filter by Price", message: "Set min and/or max price (USD)", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Min price"
            tf.keyboardType = .decimalPad
            if let min = self.viewModel.minPrice { tf.text = "\(min)" }
        }
        alert.addTextField { tf in
            tf.placeholder = "Max price"
            tf.keyboardType = .decimalPad
            if let max = self.viewModel.maxPrice { tf.text = "\(max)" }
        }
        alert.addAction(UIAlertAction(title: "Apply", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let minText = alert.textFields?[0].text ?? ""
            let maxText = alert.textFields?[1].text ?? ""
            let min = Double(minText)
            let max = Double(maxText)
            self.viewModel.minPrice = min
            self.viewModel.maxPrice = max
            self.viewModel.applySearchAndSort()
        }))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            self.viewModel.minPrice = nil
            self.viewModel.maxPrice = nil
            self.viewModel.applySearchAndSort()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func handleRefresh() {
        guard viewModel.searchText.isEmpty else {
            refreshControl.endRefreshing()
            return
        }
        viewModel.fetchCryptos(reset: true)
    }
    
    private func bindViewModel() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        errorLabel.isHidden = true
        
        viewModel.$cryptos
            .dropFirst(2)
            .receive(on: DispatchQueue.main)
           
            .sink { [weak self] c in
                print(c)
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
        
        viewModel.$searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.refreshControl.isEnabled = text.isEmpty
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension MainListViewController: UITableViewDataSource, UITableViewDelegate {
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
            self?.tableView.reloadRows(at: [indexPath], with: .none)
        }
        viewModel.loadNextPageIfNeeded(index: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if viewModel.isLoadingPage && viewModel.cryptos.count > 0 {
            let footer = UIActivityIndicatorView(style: .medium)
            footer.startAnimating()
            return footer
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        (viewModel.isLoadingPage && viewModel.cryptos.count > 0) ? 44 : 0
    }
}

// MARK: - UISearchBarDelegate

extension MainListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
        viewModel.applySearchAndSort()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else { return }
        viewModel.searchRemote(for: query)
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.searchText = ""
        viewModel.fetchCryptos(reset: true)
    }
}

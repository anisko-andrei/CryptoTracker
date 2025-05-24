//
//  MainListViewModel.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//

import Foundation
import Combine

final class MainListViewModel {
    enum SortType: String, CaseIterable {
        case none = "Disable sorting"
        case nameAsc = "Name ↑"
        case nameDesc = "Name ↓"
        case priceAsc = "Price ↑"
        case priceDesc = "Price ↓"
    }
    
    private let cryptoService: CryptoServiceProtocol
    private let cacheService: CacheService<CryptoCurrency>
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var cryptos: [CryptoCurrency] = []
    @Published private(set) var error: NetworkError?
    @Published private(set) var isLoadingPage = false
    @Published private(set) var hasMore = true
    @Published var isOfflineData = false
    
    private var currentPage = 1
    private let perPage = 50
    
    @Published var searchText: String = ""
    private var allCryptos: [CryptoCurrency] = []
    
    @Published var sortType: SortType = .none
    @Published var minPrice: Double?
    @Published var maxPrice: Double?
    
    init(cryptoService: CryptoServiceProtocol, cacheService: CacheService<CryptoCurrency>) {
        self.cryptoService = cryptoService
        self.cacheService = cacheService
        setupSearch()
        loadCacheIfNeeded()
    }
    
    private func setupSearch() {
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySearchAndSort()
            }
            .store(in: &cancellables)
    }
    
    private func loadCacheIfNeeded() {
        if let cached = cacheService.load() {
            self.allCryptos = cached
            self.isOfflineData = true
            self.applySearchAndSort()
        }
    }
    
    func applySearchAndSort() {
        var filtered: [CryptoCurrency]
        if searchText.isEmpty {
            filtered = allCryptos
        } else {
            let lowercased = searchText.lowercased()
            filtered = allCryptos.filter {
                $0.name?.lowercased().contains(lowercased) == true ||
                $0.symbol?.lowercased().contains(lowercased) == true
            }
        }
        if let min = minPrice {
            filtered = filtered.filter { ($0.currentPrice ?? 0) >= min }
        }
        if let max = maxPrice {
            filtered = filtered.filter { ($0.currentPrice ?? 0) <= max }
        }
        cryptos = sort(cryptos: filtered, by: sortType)
    }
    
    private func sort(cryptos: [CryptoCurrency], by type: SortType) -> [CryptoCurrency] {
        switch type {
        case .none:
            return cryptos
        case .nameAsc:
            return cryptos.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .nameDesc:
            return cryptos.sorted { ($0.name ?? "") > ($1.name ?? "") }
        case .priceAsc:
            return cryptos.sorted { ($0.currentPrice ?? 0) < ($1.currentPrice ?? 0) }
        case .priceDesc:
            return cryptos.sorted { ($0.currentPrice ?? 0) > ($1.currentPrice ?? 0) }
        }
    }
    
    func searchRemote(for query: String) {
        isLoadingPage = true
        error = nil

        cryptoService.searchCryptocurrencies(query: query)
            .flatMap { [weak self] coins -> AnyPublisher<[CryptoCurrency], NetworkError> in
                let ids = coins.compactMap { $0.id }
                guard !ids.isEmpty else { return Just([]).setFailureType(to: NetworkError.self).eraseToAnyPublisher() }
                return self?.cryptoService.fetchCryptosByIds(ids: ids, vsCurrency: "usd") ?? Just([]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingPage = false
                if case let .failure(err) = completion {
                    self?.error = err
                }
            }, receiveValue: { [weak self] coinsWithPrice in
                self?.allCryptos = coinsWithPrice
                self?.isOfflineData = false
                self?.applySearchAndSort()
            })
            .store(in: &cancellables)
    }
    
    func fetchCryptos(reset: Bool = false) {
        if isLoadingPage { return }
        isLoadingPage = true
        error = nil
        
        if reset {
            currentPage = 1
            hasMore = true
        }
        
        cryptoService.fetchCryptocurrencies(page: currentPage, perPage: perPage)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoadingPage = false
                if case let .failure(err) = completion {
                    self.error = err
                    if let cached = self.cacheService.load(), self.currentPage == 1 {
                        self.allCryptos = cached
                        self.isOfflineData = true
                        self.applySearchAndSort()
                    }
                }
            }, receiveValue: { [weak self] newCryptos in
                guard let self = self else { return }
                if self.currentPage == 1 {
                    self.allCryptos = newCryptos
                } else {
                    let new = newCryptos.filter { newCoin in
                        !self.allCryptos.contains(where: { $0.id == newCoin.id })
                    }
                    self.allCryptos.append(contentsOf: new)
                }
                self.hasMore = newCryptos.count == self.perPage
                if self.hasMore { self.currentPage += 1 }
                self.isOfflineData = false
                self.applySearchAndSort()
                if self.currentPage == 2 {
                    self.cacheService.save(self.allCryptos)
                }
            })
            .store(in: &cancellables)
    }
    
    func loadNextPageIfNeeded(index: Int) {
        guard hasMore, !isLoadingPage, index >= cryptos.count - 10, searchText.isEmpty else { return }
        fetchCryptos()
    }
}

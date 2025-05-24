//
//  FavoritesListViewModel.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import Foundation
import Combine

final class FavoritesListViewModel {
    private let cryptoService: CryptoServiceProtocol
    private let cacheService: CacheService<CryptoCurrency>
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var cryptos: [CryptoCurrency] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: NetworkError?
    @Published var isOfflineData = false

    init(cryptoService: CryptoServiceProtocol, cacheService: CacheService<CryptoCurrency>) {
        self.cryptoService = cryptoService
        self.cacheService = cacheService
        loadCacheIfNeeded()
    }

    private func loadCacheIfNeeded() {
        if let cached = cacheService.load() {
            self.cryptos = cached
            self.isOfflineData = true
        }
    }

    func fetchFavorites() {
        let ids = FavoritesManager.shared.getFavorites()
        guard !ids.isEmpty else {
            self.cryptos = []
            cacheService.clear()
            return
        }
        isLoading = true
        error = nil

        cryptoService.fetchCryptosByIds(ids: ids, vsCurrency: "usd")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case let .failure(err) = completion {
                    self.error = err
                    if let cached = self.cacheService.load() {
                        self.cryptos = cached
                        self.isOfflineData = true
                    }
                }
            }, receiveValue: { [weak self] coins in
                guard let self = self else { return }
                self.cryptos = coins
                self.isOfflineData = false
                self.cacheService.save(coins)
            })
            .store(in: &cancellables)
    }
}

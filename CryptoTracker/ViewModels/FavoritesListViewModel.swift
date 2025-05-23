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
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var cryptos: [CryptoCurrency] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: NetworkError?
    
    init(cryptoService: CryptoServiceProtocol) {
        self.cryptoService = cryptoService
    }
    
    func fetchFavorites() {
        let ids = FavoritesManager.shared.getFavorites()
        guard !ids.isEmpty else {
            self.cryptos = []
            return
        }
        isLoading = true
        error = nil
        
        cryptoService.fetchCryptosByIds(ids: ids, vsCurrency: "usd")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(err) = completion {
                    self?.error = err
                }
            }, receiveValue: { [weak self] coins in
                self?.cryptos = coins
            })
            .store(in: &cancellables)
    }
}

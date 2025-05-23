//
//  MainListViewModel.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//

import Foundation
import Combine

final class MainListViewModel {
    private let cryptoService: CryptoServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var cryptos: [CryptoCurrency] = []
    @Published private(set) var error: NetworkError?
    @Published private(set) var isLoadingPage = false
    @Published private(set) var hasMore = true
    
    private var currentPage = 1
    private let perPage = 50
    
    init(cryptoService: CryptoServiceProtocol) {
        self.cryptoService = cryptoService
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
                self?.isLoadingPage = false
                if case let .failure(err) = completion {
                    self?.error = err
                }
            }, receiveValue: { [weak self] newCryptos in
                guard let self = self else { return }
                if self.currentPage == 1 {
                    self.cryptos = newCryptos
                } else {
                    let new = newCryptos.filter { newCoin in
                        !self.cryptos.contains(where: { $0.id == newCoin.id })
                    }
                    self.cryptos.append(contentsOf: new)
                }
                self.hasMore = newCryptos.count == self.perPage
                if self.hasMore { self.currentPage += 1 }
            })
            .store(in: &cancellables)
    }
    
    func loadNextPageIfNeeded(index: Int) {
        guard hasMore, !isLoadingPage, index >= cryptos.count - 10 else { return }
        fetchCryptos()
    }
}

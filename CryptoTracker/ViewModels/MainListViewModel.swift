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

    init(cryptoService: CryptoServiceProtocol) {
        self.cryptoService = cryptoService
    }

    func fetchCryptos() {
        cryptoService.fetchCryptocurrencies()
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(err) = completion {
                    self?.error = err
                }
            }, receiveValue: { [weak self] cryptos in
                self?.cryptos = cryptos
            })
            .store(in: &cancellables)
    }
}

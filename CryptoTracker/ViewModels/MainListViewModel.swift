//
//  MainListViewModel.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//

import Foundation

final class MainListViewModel {
    private let cryptoService: CryptoServiceProtocol
    
    init(cryptoService: CryptoServiceProtocol) {
        self.cryptoService = cryptoService
    }
    
    func fetchCryptos() {
        cryptoService.fetchCryptocurrencies { result in
        }
    }
}

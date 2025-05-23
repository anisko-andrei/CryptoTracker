//
//  CryptoService.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import Foundation
import Combine

protocol CryptoServiceProtocol {
    func fetchCryptocurrencies(page: Int, perPage: Int) -> AnyPublisher<[CryptoCurrency], NetworkError>
}

final class CryptoService: CryptoServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchCryptocurrencies(page: Int, perPage: Int) -> AnyPublisher<[CryptoCurrency], NetworkError> {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=\(perPage)&page=\(page)&sparkline=false") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return networkService.fetch(url: url)
    }
}

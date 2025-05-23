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
    func searchCryptocurrencies(query: String) -> AnyPublisher<[CryptoCurrency], NetworkError>
    func fetchCryptosByIds(ids: [String], vsCurrency: String) -> AnyPublisher<[CryptoCurrency], NetworkError>
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
    
    func searchCryptocurrencies(query: String) -> AnyPublisher<[CryptoCurrency], NetworkError> {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return networkService.fetch(url: url)
            .tryMap { (result: SearchResponse) in
                result.coins
            }
            .mapError { error in
                error as? NetworkError ?? .unknown
            }
            .eraseToAnyPublisher()
    }

    func fetchCryptosByIds(ids: [String], vsCurrency: String = "usd") -> AnyPublisher<[CryptoCurrency], NetworkError> {
        let idsString = ids.joined(separator: ",")
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=\(vsCurrency)&ids=\(idsString)&order=market_cap_desc") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return networkService.fetch(url: url)
    }
}

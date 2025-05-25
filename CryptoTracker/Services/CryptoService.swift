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
    func fetchChartData(cryptoId: String, days: String) -> AnyPublisher<ChartDataResponse, NetworkError>
       func fetchCryptoDetails(cryptoId: String) -> AnyPublisher<CryptoCurrency, NetworkError>
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
    
      func fetchChartData(cryptoId: String, days: String) -> AnyPublisher<ChartDataResponse, NetworkError> {
          // days: "1" / "7" / "30"
          let urlString = "https://api.coingecko.com/api/v3/coins/\(cryptoId)/market_chart?vs_currency=usd&days=\(days)"
          guard let url = URL(string: urlString) else {
              return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
          }
          return networkService.fetch(url: url)
      }

      func fetchCryptoDetails(cryptoId: String) -> AnyPublisher<CryptoCurrency, NetworkError> {
          let urlString = "https://api.coingecko.com/api/v3/coins/\(cryptoId)?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false"
          guard let url = URL(string: urlString) else {
              return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
          }
          return networkService.fetch(url: url)
      }
}

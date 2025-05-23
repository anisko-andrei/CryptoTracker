//
//  NetworkService.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import Foundation
import Combine

enum NetworkError: Error {
    case invalidURL
    case decodingError
    case network(Error)
    case unknown
}

protocol NetworkServiceProtocol {
    func fetch<T: Decodable>(url: URL) -> AnyPublisher<T, NetworkError>
}

final class NetworkService: NetworkServiceProtocol {
    func fetch<T: Decodable>(url: URL) -> AnyPublisher<T, NetworkError> {
        URLSession.shared.dataTaskPublisher(for: url)
            .mapError { NetworkError.network($0) }
            .flatMap { data, _ -> AnyPublisher<T, NetworkError> in
                Just(data)
                    .decode(type: T.self, decoder: JSONDecoder())
                    .mapError { _ in NetworkError.decodingError }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

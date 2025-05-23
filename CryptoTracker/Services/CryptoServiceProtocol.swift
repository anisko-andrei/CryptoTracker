//
//  CryptoServiceProtocol.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import Foundation

protocol CryptoServiceProtocol {
    func fetchCryptocurrencies(completion: @escaping (Result<[CryptoCurrency], Error>) -> Void)
}

final class CryptoService: CryptoServiceProtocol {
    func fetchCryptocurrencies(completion: @escaping (Result<[CryptoCurrency], Error>) -> Void) {
        //TODO: Implement the network request
        completion(.success([]))
    }
}

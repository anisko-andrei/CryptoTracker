//
//  DependencyContainer.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import Foundation

final class DependencyContainer {
    lazy var networkService: NetworkServiceProtocol = NetworkService()
    lazy var cryptoService: CryptoServiceProtocol = CryptoService(networkService: networkService)
}

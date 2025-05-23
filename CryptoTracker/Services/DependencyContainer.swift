//
//  DependencyContainer.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import Foundation

final class DependencyContainer {
    lazy var cryptoService: CryptoServiceProtocol = CryptoService()
}

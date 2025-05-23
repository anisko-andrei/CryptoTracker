//
//  SearchResponse.swift
//  CryptoTracker
//
//  Created by anisko on 24.05.25.
//


import Foundation

struct SearchResponse: Decodable {
    let coins: [CryptoCurrency]
}

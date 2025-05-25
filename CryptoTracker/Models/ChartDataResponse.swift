//
//  ChartDataResponse.swift
//  CryptoTracker
//
//  Created by anisko on 25.05.25.
//


import Foundation

struct ChartDataResponse: Codable {
    let prices: [[Double]]
}

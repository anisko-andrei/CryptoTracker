//
//  CryptoDetailViewModel.swift
//  CryptoTracker
//
//  Created by anisko on 25.05.25.
//


import Foundation
import Combine

final class CryptoDetailViewModel {
    @Published private(set) var crypto: CryptoCurrency
    @Published private(set) var priceHistory: [Double] = []
    @Published private(set) var timestamps: [Date] = []
    @Published private(set) var error: NetworkError?
    @Published private(set) var isLoading = false
    @Published private(set) var isFavorite: Bool

    private let cryptoService: CryptoServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(crypto: CryptoCurrency, cryptoService: CryptoServiceProtocol) {
        self.crypto = crypto
        self.cryptoService = cryptoService
        self.isFavorite = FavoritesManager.shared.isFavorite(id: crypto.id ?? "")
        fetchDetails()
    }

    func fetchDetails() {
        guard let id = crypto.id else { return }
        isLoading = true
        cryptoService.fetchCryptoDetails(cryptoId: id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(err) = completion {
                    self?.error = err
                }
            }, receiveValue: { [weak self] details in
                self?.crypto = details
            })
            .store(in: &cancellables)
    }

    func fetchHistory(period: Period) {
        isLoading = true
        error = nil
        cryptoService.fetchChartData(cryptoId: crypto.id ?? "", days: period.days)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(err) = completion {
                    self?.error = err
                }
            }, receiveValue: { [weak self] chartData in
                self?.priceHistory = chartData.prices.map { $0[1] }
                self?.timestamps = chartData.prices.compactMap {
                    Date(timeIntervalSince1970: $0[0] / 1000)
                }
            })
            .store(in: &cancellables)
    }

    enum Period: String, CaseIterable {
        case day = "1D"
        case week = "1W"
        case month = "1M"

        var days: String {
            switch self {
            case .day: return "1"
            case .week: return "7"
            case .month: return "30"
            }
        }
    }

    func toggleFavorite() {
        guard let id = crypto.id else { return }
        FavoritesManager.shared.toggle(id: id)
        isFavorite = FavoritesManager.shared.isFavorite(id: id)
    }
}

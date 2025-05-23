//
//  MainListViewModel.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//

import Foundation
import Combine

final class MainListViewModel {
    private let cryptoService: CryptoServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var cryptos: [CryptoCurrency] = []
    @Published private(set) var error: NetworkError?
    @Published private(set) var isLoadingPage = false
    @Published private(set) var hasMore = true
    
    private var currentPage = 1
    private let perPage = 50

    @Published var searchText: String = ""
    private var allCryptos: [CryptoCurrency] = []
    
    init(cryptoService: CryptoServiceProtocol) {
        self.cryptoService = cryptoService
        setupSearch()
    }
    
    private func setupSearch() {
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.applySearch(text: text)
            }
            .store(in: &cancellables)
    }
    
    private func applySearch(text: String) {
        guard !text.isEmpty else {
            cryptos = allCryptos
            return
        }
        let lowercased = text.lowercased()
        cryptos = allCryptos.filter {
            $0.name?.lowercased().contains(lowercased) == true ||
            $0.symbol?.lowercased().contains(lowercased) == true
        }
    }
    
    func searchRemote(for query: String) {
        isLoadingPage = true
        error = nil

        cryptoService.searchCryptocurrencies(query: query)
            .flatMap { [weak self] coins -> AnyPublisher<[CryptoCurrency], NetworkError> in
                let ids = coins.compactMap { $0.id }
                guard !ids.isEmpty else { return Just([]).setFailureType(to: NetworkError.self).eraseToAnyPublisher() }
                return self?.cryptoService.fetchCryptosByIds(ids: ids, vsCurrency: "usd") ?? Just([]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingPage = false
                if case let .failure(err) = completion {
                    self?.error = err
                }
            }, receiveValue: { [weak self] coinsWithPrice in
                self?.cryptos = coinsWithPrice
            })
            .store(in: &cancellables)
    }
    
    func fetchCryptos(reset: Bool = false) {
        if isLoadingPage { return }
        isLoadingPage = true
        error = nil
        
        if reset {
            currentPage = 1
            hasMore = true
        }
        
        cryptoService.fetchCryptocurrencies(page: currentPage, perPage: perPage)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingPage = false
                if case let .failure(err) = completion {
                    self?.error = err
                }
            }, receiveValue: { [weak self] newCryptos in
                guard let self = self else { return }
                if self.currentPage == 1 {
                    self.allCryptos = newCryptos
                } else {
                    let new = newCryptos.filter { newCoin in
                        !self.allCryptos.contains(where: { $0.id == newCoin.id })
                    }
                    self.allCryptos.append(contentsOf: new)
                }
                self.hasMore = newCryptos.count == self.perPage
                if self.hasMore { self.currentPage += 1 }
                self.applySearch(text: self.searchText)
            })
            .store(in: &cancellables)
    }
    
    func loadNextPageIfNeeded(index: Int) {
        guard hasMore, !isLoadingPage, index >= cryptos.count - 10, searchText.isEmpty else { return }
        fetchCryptos()
    }
}

//
//  FavoritesManager.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import Foundation

final class FavoritesManager {
    static let shared = FavoritesManager()
    private let key = "favorite_crypto_ids"
    
    private init() {}
    
    func getFavorites() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    func isFavorite(id: String) -> Bool {
        getFavorites().contains(id)
    }
    
    func add(id: String) {
        var favs = getFavorites()
        if !favs.contains(id) {
            favs.append(id)
            UserDefaults.standard.setValue(favs, forKey: key)
        }
    }
    
    func remove(id: String) {
        var favs = getFavorites()
        if let idx = favs.firstIndex(of: id) {
            favs.remove(at: idx)
            UserDefaults.standard.setValue(favs, forKey: key)
        }
    }
    
    func toggle(id: String) {
        isFavorite(id: id) ? remove(id: id) : add(id: id)
    }
}

//
//  CacheService.swift
//  CryptoTracker
//
//  Created by anisko on 24.05.25.
//


import Foundation

final class CacheService<T: Codable> {
    private let fileName: String

    init(fileName: String) {
        self.fileName = fileName
    }

    private var cacheURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    func save(_ objects: [T]) {
        guard let url = cacheURL else { return }
        do {
            let data = try JSONEncoder().encode(objects)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Cache save error for \(fileName): \(error)")
        }
    }

    func load() -> [T]? {
        guard let url = cacheURL else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let objects = try JSONDecoder().decode([T].self, from: data)
            return objects
        } catch {
            print("Cache load error for \(fileName): \(error)")
            return nil
        }
    }

    func clear() {
        guard let url = cacheURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

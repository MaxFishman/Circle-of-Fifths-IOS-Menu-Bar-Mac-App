import Foundation
import Combine

struct Favorite: Codable, Equatable, Identifiable {
    let id: UUID
    let majorKey: String
    let mode: KeyMode
    let progressionID: String?

    init(majorKey: String, mode: KeyMode, progressionID: String? = nil) {
        self.id = UUID()
        self.majorKey = majorKey
        self.mode = mode
        self.progressionID = progressionID
    }
}

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: [Favorite] = []
    @Published private(set) var error: String?
    private let defaults: UserDefaults
    private let storageKey = "circleOfFifths.favorites"
    private var canSave = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        guard let savedValue = defaults.object(forKey: storageKey) else { return }
        guard let data = savedValue as? Data else {
            canSave = false
            error = "Favorites could not be loaded: invalid saved data."
            return
        }
        do {
            let saved = try JSONDecoder().decode([Favorite].self, from: data)
            guard saved.allSatisfy({ favorite in
                guard let profile = TheoryData.circle.first(where: { $0.majorKey == favorite.majorKey }) else {
                    return false
                }
                return favorite.progressionID.map { id in
                    profile.progressions(for: favorite.mode).contains { $0.id == id }
                } ?? true
            }) else {
                throw CocoaError(.coderReadCorrupt)
            }
            favorites = saved
        } catch {
            canSave = false
            self.error = "Favorites could not be loaded: \(error.localizedDescription)"
        }
    }

    func contains(profile: KeyProfile, mode: KeyMode, progressionID: String? = nil) -> Bool {
        favorites.contains { $0.majorKey == profile.majorKey && $0.mode == mode && $0.progressionID == progressionID }
    }

    func toggle(profile: KeyProfile, mode: KeyMode, progressionID: String? = nil) {
        var updated = favorites
        if let index = updated.firstIndex(where: {
            $0.majorKey == profile.majorKey && $0.mode == mode && $0.progressionID == progressionID
        }) {
            updated.remove(at: index)
        } else {
            updated.append(Favorite(majorKey: profile.majorKey, mode: mode, progressionID: progressionID))
        }
        save(updated)
    }

    func remove(_ favorite: Favorite) {
        save(favorites.filter { $0.id != favorite.id })
    }

    private func save(_ updated: [Favorite]) {
        guard canSave else { return }
        do {
            let data = try JSONEncoder().encode(updated)
            defaults.set(data, forKey: storageKey)
            favorites = updated
            error = nil
        } catch {
            self.error = "Favorites could not be saved: \(error.localizedDescription)"
        }
    }
}

import Foundation
import XCTest
@testable import CircleOfFifthsMenuBarApp

final class FavoritesStoreTests: XCTestCase {
    @MainActor
    func testFavoritesPersistAndCanBeRemoved() throws {
        let suite = "FavoritesStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let profile = TheoryData.circle[0]
        let store = FavoritesStore(defaults: defaults)
        let progression = profile.progressions(for: .harmonicMinor)[0]

        store.toggle(profile: profile, mode: .harmonicMinor)
        store.toggle(profile: profile, mode: .harmonicMinor, progressionID: progression.id)
        XCTAssertEqual(store.favorites.count, 2)

        let reloaded = FavoritesStore(defaults: defaults)
        XCTAssertTrue(reloaded.contains(profile: profile, mode: .harmonicMinor))
        XCTAssertTrue(reloaded.contains(profile: profile, mode: .harmonicMinor, progressionID: progression.id))
        XCTAssertFalse(reloaded.contains(profile: profile, mode: .naturalMinor))
        reloaded.toggle(profile: profile, mode: .harmonicMinor)
        reloaded.remove(try XCTUnwrap(reloaded.favorites.first))
        XCTAssertTrue(FavoritesStore(defaults: defaults).favorites.isEmpty)
    }

    @MainActor
    func testCorruptFavoritesAreReportedAndNotOverwritten() throws {
        let suite = "FavoritesStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let corrupt = Data("invalid".utf8)
        defaults.set(corrupt, forKey: "circleOfFifths.favorites")

        let store = FavoritesStore(defaults: defaults)
        XCTAssertNotNil(store.error)
        store.toggle(profile: TheoryData.circle[0], mode: .major)
        XCTAssertEqual(defaults.data(forKey: "circleOfFifths.favorites"), corrupt)
    }
}

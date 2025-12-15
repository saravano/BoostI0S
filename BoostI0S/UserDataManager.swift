import Foundation

class UserDataManager {
    private let defaults = UserDefaults.standard
    private let selectedCardsKey = "selectedCards"
    
    // MARK: - Save Data
    
    func saveString(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    func saveInt(_ value: Int, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    func saveBool(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    func saveArray(_ value: [String], forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    func saveCodable<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    // MARK: - Read Data
    
    func getString(forKey key: String) -> String? {
        return defaults.string(forKey: key)
    }
    
    func getInt(forKey key: String) -> Int {
        return defaults.integer(forKey: key)
    }
    
    func getBool(forKey key: String) -> Bool {
        return defaults.bool(forKey: key)
    }
    
    func getArray(forKey key: String) -> [String]? {
        return defaults.stringArray(forKey: key)
    }
    
    func getCodable<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - Delete Data
    
    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    // MARK: - Boost Card Selection (Async helpers)

    /// Returns the saved set of selected card names. Defaults to empty set.
    var selectedCards: Set<String> {
        get async {
            let array = defaults.stringArray(forKey: selectedCardsKey) ?? []
            return Set(array)
        }
    }

    /// Saves the entire set of selected card names.
    /// - Parameter cards: The set of card identifiers to persist.
    func saveCardSelection(_ cards: Set<String>) async {
        let array = Array(cards)
        defaults.set(array, forKey: selectedCardsKey)
    }
}

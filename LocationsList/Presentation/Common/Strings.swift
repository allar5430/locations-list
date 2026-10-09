import Foundation

enum Strings {
    enum Key: String {
        case places = "places"
        case addLocation = "add_location"
        case loadingLocations = "loading_locations"
        case locationsUnavailable = "locations_unavailable"
        case locationName = "location_name"
        case unknown = "unknown"
        case coordinatePlaceholder = "coordinate_placeholder"
        case coordinateAccessibility = "coordinate_accessibility"
        case openWikipediaHint = "open_wikipedia_hint"
        case unableToLoadLocations = "unable_to_load_locations"
        case customLocation = "custom_location"
        case useCurrentLocation = "use_current_location"
        case cancel = "cancel"
        case done = "done"
        case location = "location"
        case unableToFindLocation = "unable_to_find_location"
    }

    static func string(
        for key: Key,
        locale: Locale = .current
    ) -> String {
        localizationBundle.localizedString(
            forKey: key.rawValue,
            value: key.rawValue,
            table: "Localizable"
        )
    }

    static func coordinateAccessibility(
        latitude: String,
        longitude: String,
        locale: Locale = .current
    ) -> String {
        let format = string(for: .coordinateAccessibility, locale: locale)
        return String(format: format, locale: locale, arguments: [latitude, longitude])
    }

    private static var localizationBundle: Bundle {
        .main
    }
}

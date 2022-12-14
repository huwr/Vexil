//
//  Configuration.swift
//  Vexil
//
//  Created by Rob Amos on 25/5/20.
//

import Foundation

/// A configuration struct passed into the `FlagPole` to configure it.
///
public struct VexilConfiguration {

    /// The strategy to use when calculating the keys of all `Flag`s within the `FlagPole`.
    var codingPathStrategy: CodingKeyStrategy

    /// An optional prefix to apply to the calculated keys
    var prefix: String?

    /// A separator to use to `joined()` the different levels of the flag tree together.
    /// For example. If your separator is `/` and you access a flag via the KeyPath
    /// `flagPole.myGroup.secondGroup.someFlag` the "key" would be calculated as
    /// `my-group/second-group/some-flag`.
    ///
    var separator: String

    /// Initialises a new `VexilConfiguration` struct with the supplied info.
    ///
    /// - Parameters:
    ///   - codingPathStrategy:     How to calculate each `Flag`s "key". Defaults to `CodingKeyStrategy.default` (aka `.kebabcase`)
    ///   - prefix:                 An optional prefix to apply to each calculated key,. This is treated as a separate "level" of the tree.
    ///                             So if your prefix is "magic", your flag keys would be `magic.abc-flag`
    ///   - separator:              A separator to use by `joined()` to combine different levels of the flag tree together.
    ///
    public init(codingPathStrategy: VexilConfiguration.CodingKeyStrategy = .default, prefix: String? = nil, separator: String = ".") {
        self.codingPathStrategy = codingPathStrategy
        self.prefix = prefix
        self.separator = separator
    }

    /// The "default" `VexilConfiguration`
    ///
    public static var `default`: VexilConfiguration {
        return VexilConfiguration()
    }
}


// MARK: - KeyNamingStrategy

public extension VexilConfiguration {

    /// An enumeration describing how keys should be calculated by `Flag` and `FlagGroup`s.
    ///
    /// Each `Flag` and `FlagGroup` can specify its own behaviour. This is the default behaviour
    /// to use when they don't.
    ///
    enum CodingKeyStrategy {

        /// Follow the default behaviour. This is basically a synonym for `.kebabcase`
        case `default`

        /// Converts the property name into a kebab-case string. e.g. myPropertyName becomes my-property-name
        case kebabcase

        /// Converts the property name into a snake_case string. e.g. myPropertyName becomes my_property_name
        case snakecase

        internal func codingKey (label: String) -> CodingKeyAction {
            switch self {
            case .kebabcase, .default:
                return .append(label.convertedToSnakeCase(separator: "-"))

            case .snakecase:
                return .append(label.convertedToSnakeCase())
            }
        }
    }
}


// MARK: - KeyNamingStrategy - FlagGroup

public extension FlagGroup {

    /// An enumeration describing how the key should be calculated for this specific `FlagGroup`.
    ///
    enum CodingKeyStrategy {

        /// Follow the default behaviour applied to the `FlagPole`
        case `default`

        /// Converts the property name into a kebab-case string. e.g. myPropertyName becomes my-property-name
        case kebabcase

        /// Converts the property name into a snake_case string. e.g. myPropertyName becomes my_property_name
        case snakecase

        /// Skips this `FlagGroup` from the key generation
        case skip

        /// Manually specifies the key name for this `FlagGroup`.
        case customKey(String)

        internal func codingKey (label: String) -> CodingKeyAction {
            switch self {
            case .default:                  return .default
            case .kebabcase:                return .append(label.convertedToSnakeCase(separator: "-"))
            case .snakecase:                return .append(label.convertedToSnakeCase())
            case .skip:                     return .skip
            case .customKey(let custom):    return .append(custom)
            }
        }
    }
}


// MARK: - KeyNamingStrategy - Flag

public extension Flag {

    /// An enumeration describing how the key should be calculated for this specific `Flag`.
    ///
    enum CodingKeyStrategy: Sendable {

        /// Follow the default behaviour applied to the `FlagPole`
        case `default`

        /// Converts the property name into a kebab-case string. e.g. myPropertyName becomes my-property-name
        case kebabcase

        /// Converts the property name into a snake_case string. e.g. myPropertyName becomes my_property_name
        case snakecase

        /// Manually specifies the key name for this `Flag`.
        ///
        /// This is combined with the keys from the parent groups to create the final key.
        ///
        case customKey(String)

        /// Manually specifices a fully qualified key path for this flag.
        ///
        /// This is the absolute key name. It is NOT combined with the keys from the parent groups.
        case customKeyPath(String)

        internal func codingKey (label: String) -> CodingKeyAction {
            switch self {
            case .default:                      return .default
            case .kebabcase:                    return .append(label.convertedToSnakeCase(separator: "-"))
            case .snakecase:                    return .append(label.convertedToSnakeCase())
            case .customKey(let custom):        return .append(custom)
            case .customKeyPath(let custom):    return .absolute(custom)
            }
        }
    }
}


// MARK: - Coding Key Actions

/// An internal enum to give instructions to the key calculation steps on how a particular strategy should be applied
/// to the current process
///
internal enum CodingKeyAction: Equatable {

    /// Apply the default behaviour according to the current circumstances
    case `default`

    /// Skip the current component (only applies to groups)
    case skip

    /// Append the string to the key path
    case append(String)

    /// Use the string as the absolute key path
    case absolute(String)

}


// MARK: - Helper

private extension String {
    /// Returns a new string with the camel-case-based words of this string
    /// split by the specified separator.
    ///
    /// Examples:
    ///
    ///     "myProperty".convertedToSnakeCase()
    ///     // my_property
    ///     "myURLProperty".convertedToSnakeCase()
    ///     // my_url_property
    ///     "myURLProperty".convertedToSnakeCase(separator: "-")
    ///     // my-url-property
    func convertedToSnakeCase(separator: Character = "_") -> String {
        guard !isEmpty else { return self }
        var result = ""
        // Whether we should append a separator when we see a uppercase character.
        var separateOnUppercase = true
        for index in indices {
            let nextIndex = self.index(after: index)
            let character = self[index]
            if character.isUppercase {
                if separateOnUppercase && !result.isEmpty {
                    // Append the separator.
                    result += "\(separator)"
                }
                // If the next character is uppercase and the next-next character is lowercase, like "L" in "URLSession", we should separate words.
                separateOnUppercase = nextIndex < endIndex
                    && self[nextIndex].isUppercase
                    && self.index(after: nextIndex) < endIndex
                    && self[self.index(after: nextIndex)].isLowercase

            } else {
                // If the character is `separator`, we do not want to append another separator when we see the next uppercase character.
                separateOnUppercase = character != separator
            }
            // Append the lowercased character.
            result += character.lowercased()
        }
        return result
    }

}

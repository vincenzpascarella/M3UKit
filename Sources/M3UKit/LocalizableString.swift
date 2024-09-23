//
//  File.swift
//  
//
//  Created by Vincenzo Pascarella on 10/09/24.
//

import Foundation

struct LocalizableString {
    static let invalidSource = String(localized: "The playlist is invalid", bundle: .module)
    static let invalidSourcePrefix = String(localized: "The playlist's prefix is invalid", bundle: .module)
    static let missingDuration = String(localized: "Missing duration in line", bundle: .module)
}

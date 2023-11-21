//
//  Message.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 23/05/23.
//

import Foundation

public struct MessageConstant {
    private init() {}
    static let restrictToCreatePost = "You do not have permission to create a %@."
    static let restrictToCommentOnPost = "You do not have permission to comment."
    static let postingInProgress = "A %@ is already uploading!"
    static let nofiticationFeedDataNotFound = "Oops! You don't have any notification yet."
}

enum WordAction: Int {
    case firstLetterCapitalSingular
    case allCapitalSingular
    case allSmallSingular
    case firstLetterCapitalPlural
    case allCapitalPlural
    case allSmallPlural
}

func pluralizeOrCapitalize(to value: String, withAction action: WordAction) -> String {
    switch action {
    case .firstLetterCapitalSingular:
        return value.capitalized
    case .allCapitalSingular:
        return value.uppercased()
    case .allSmallSingular:
        return value.lowercased()
    case .firstLetterCapitalPlural:
        return (value + "s").capitalized
    case .allCapitalPlural:
        return (value + "s").uppercased()
    case .allSmallPlural:
        return (value + "s").lowercased()
    }
}

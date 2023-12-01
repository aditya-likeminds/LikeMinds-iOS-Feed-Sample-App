//
//  Message.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 23/05/23.
//

import Foundation

public struct StringConstant {
    private init() {}
    static var restrictToCreatePost: String {
        String(format: "You do not have permission to create a %@.", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .allSmallSingular))
    }
    static let restrictToCommentOnPost = "You do not have permission to comment."
    static var postingInProgress: String {  String(format: "A %@ is already uploading!", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .allSmallSingular))
    }
    static let nofiticationFeedDataNotFound = "Oops! You don't have any notification yet."
    
    struct PostDetail {
        private init() {}
        static var screenTitle: String { String(format: "%@", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .firstLetterCapitalSingular))
        }
    }
    
    struct EditPost {
        private init() {}
        static var screenTitle: String { String(format: "Edit %@", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .firstLetterCapitalSingular))
        }
    }
    struct HomeFeed {
        private init() {}
        static var unpinThisPost: String {
            String(format: "Unpin this %@", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .firstLetterCapitalSingular))
        }
        static var pinThisPost: String {
            String(format: "Pin this %@", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .firstLetterCapitalSingular))
        }
        static var creatingResource: String {
            String(format: "Creating %@", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .firstLetterCapitalSingular))
        }
        static var newPost: String {
            String(format: "NEW %@", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .allCapitalSingular))
        }
    }
    
    struct CreatePost {
        private init() {}
        static var screenTitle: String {
            String(format: "Create a %@", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .allSmallSingular))
        }
    }
    
    struct ReportPost {
        private init() {}
        static var reportSubtitle: String {
            String(format: "You would be able to report this %@ after selecting a problem.", pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .allSmallSingular))
        }
    }

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
        return value.pluralize().capitalized
    case .allCapitalPlural:
        return value.pluralize().uppercased()
    case .allSmallPlural:
        return value.pluralize().lowercased()
    }
}

//
//  UserDefault+Extension.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 30/03/23.
//

import Foundation
import LikeMindsFeed

public struct LocalPreferencesKey {
    public static let userDetails = "user_details"
    public static let memberStates = "member_state"
    public static let deviceId = "device_uuid"
    public static let feedApiKey = "feed_api_key"
    public static let clientDomainUrl = "client_domain_url"
    public static let communityConfigurations = "community_configurations"

}

class LocalPrefrerences {
    
    static let userDefault = UserDefaults.standard
    static var postVariable: String?
    
    static func save(_ value: Any, forKey: String) {
        let defaults = UserDefaults.standard
        defaults.setValue(value, forKey: forKey)
        defaults.synchronize()
    }
    
    static func saveObject<T: Encodable>(_ object: T, forKey: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: forKey)
        }
    }
    
    static func uuid() -> String {
        return Self.getUserData()?.clientUUID ?? ""
    }
    
    static func getUserData() -> User? {
        let defaults = UserDefaults.standard
        if let savedData = defaults.object(forKey: LocalPreferencesKey.userDetails) as? Data {
            do {
                let decoder = JSONDecoder()
                let saved = try decoder.decode(User.self, from: savedData)
                return saved
            } catch let error {
                print("Error getting cart from defaults \(error)")
            }
        }
        return nil
    }
    
    static func getCommunityConfiguration(withConfigurationType type: String) -> CommunityConfiguration? {
        let defaults = UserDefaults.standard
        if let savedData = defaults.object(forKey: LocalPreferencesKey.communityConfigurations) as? Data {
            do {
                let decoder = JSONDecoder()
                let savedConfigurations = try decoder.decode([CommunityConfiguration].self, from: savedData)
                let config = savedConfigurations.first(where: {$0.type == type })
                return config
            } catch let error {
                print("Error getting cart from defaults \(error)")
            }
        }
        return nil
    }
    
    static func getMemberStateData() -> GetMemberStateResponse? {
        let defaults = UserDefaults.standard
        if let savedData = defaults.object(forKey: LocalPreferencesKey.memberStates) as? Data {
            do {
                let decoder = JSONDecoder()
                let saved = try decoder.decode(GetMemberStateResponse.self, from: savedData)
                return saved
            } catch let error {
                print("Error getting cart from defaults \(error)")
            }
        }
        return nil
    }
    
    static var getPostVariable: String {
        guard let variable = postVariable else {
            postVariable = getCommunityConfiguration(withConfigurationType: "feed_metadata")?.value?.post
            return postVariable ?? "post"
        }
        return variable
    }
}

//
//  LikeMindsFeedSX.swift
//  FeedSX
//
//  Created by Pushpendra Singh on 30/05/23.
//

import Foundation
import UIKit
import LikeMindsFeed
import FirebaseMessaging

public class LikeMindsFeedSX {
    public static let shared = LikeMindsFeedSX()
    private init() {}
    
    public func configureLikeMindsFeed(lmCallback: LMCallback, branding: SetBrandingRequest = SetBrandingRequest()) {
        LMBranding.shared.setBranding(branding)
        AWSS3Manager.shared.initializeS3()
        let _ = LMFeedClient.builder()
            .lmCallback(lmCallback)
            .build()
    }
    
    public func initiateLikeMindsFeed(withViewController viewController: UIViewController, apiKey: String, username: String, userId: String) {
        
        let request = InitiateUserRequest.builder()
            .apiKey(apiKey)
            .userName(username)
            .uuid(userId)
            .isGuest(false)
            .build()
        LMFeedClient.shared.initiateUser(request: request) { [weak self] response in
            print(response)
            guard let user = response.data?.user, let weakSelf = self else {
                viewController.presentAlert(message: response.errorMessage ?? "")
                return
            }
            if response.data?.appAccess == false {
                self?.logout(response.data?.refreshToken ?? "", deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "")
                return
            }
            LocalPrefrerences.save(apiKey, forKey: LocalPreferencesKey.feedApiKey)
            if response.success == true {
                weakSelf.registerDeviceToken()
            }
            LocalPrefrerences.saveObject(user, forKey: LocalPreferencesKey.userDetails)
            weakSelf.getCommunityConfiguration()
            let homeFeedVC = UINavigationController(rootViewController: HomeFeedViewControler())
            homeFeedVC.modalPresentationStyle = .fullScreen
            viewController.navigationController?.present(homeFeedVC, animated: true)
        }
    }

    func registerDeviceToken() {
        guard let deviceid = UIDevice.current.identifierForVendor?.uuidString, !deviceid.isEmpty else {
            print("Device id not available")
            return
        }
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                let request = RegisterDeviceRequest.builder()
                    .token(token)
                    .deviceId(deviceid)
                    .build()
                LMFeedClient.shared.registerDevice(request: request) { response in
                    print(response)
                }
            }
        }
    }
    
    func getCommunityConfiguration() {
        LMFeedClient.shared.getCommunityConfiguration(GetCommunityConfigurationRequest.builder()) { response in
            guard let configurations = response.data?.communityConfigurations else {
                return
            }
            print("------Configuration Data----- \(configurations)")
            LocalPrefrerences.saveObject(configurations, forKey: LocalPreferencesKey.userDetails)
        }
    }
    
    /**
     Call this method in AppDelegate in didReceiveRemoteNotification
     @param userInfo The info dict with the push
     */
    public func didReceieveNotification(userInfo: [AnyHashable: Any]) -> Bool {
        guard let route = userInfo["route"] as? String, UIApplication.shared.applicationState == .inactive else {return false }
        DeepLinkManager.sharedInstance.notificationRoute(routeUrl: route, fromNotification: true, fromDeeplink: false)
        return true
    }
    
    /**
     Call this method when deeplink decoded url has received
     @param deeplinkRequest: deeplink url with userid and username details
     */
    public func parseDeepLink(routeUrl: String) {
        DeepLinkManager.sharedInstance.deeplinkRoute(routeUrl: routeUrl, fromNotification: false, fromDeeplink: true)
    }
    
    public func logout(_ refreshToken: String, deviceId: String) {
        let request = LogoutRequest.builder()
            .refreshToken(refreshToken)
            .deviceId(deviceId)
            .build()
        LMFeedClient.shared.logout(request: request) { response in
            // do somthing on success or failure
        }
    }
}


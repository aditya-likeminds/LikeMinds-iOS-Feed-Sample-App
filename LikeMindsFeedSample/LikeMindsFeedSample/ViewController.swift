//
//  ViewController.swift
//  LikeMindsFeedSample
//
//  Created by Pushpendra Singh on 26/02/23.
//

import UIKit
import Photos
import FeedSX
import FirebaseMessaging

class ViewController: UIViewController {
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var userId: UITextField!
    @IBOutlet weak var apiKey: UITextField!
    let userDefault = UserDefaults.standard
    var button: UIButton?
    var ApiKey: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        username.isHidden = true
        userId.isHidden = true
        self.apiKey.text = "a0891a93-d37d-41a0-88b4-73f02c2d3663"
        let un =  userDefault.string(forKey: "username") ?? ""
        let ui = userDefault.string(forKey: "userid") ?? ""
        if !un.isEmpty && !ui.isEmpty {
            likeMindsApp(apiKey: userDefault.string(forKey: "apikey") ?? "", username: un, userId: ui)
        } else {
            checkApiKeySaved()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.apiKey.isHidden {
            username.isHidden = false
            userId.isHidden = false
        }
    }
    
    func checkApiKeySaved() {
        let api = userDefault.string(forKey: "apikey") ?? ""
        if api.isEmpty {
            apiKey.isHidden = false
            username.isHidden = true
            userId.isHidden = true
        } else {
            apiKey.isHidden = true
            username.isHidden = false
            userId.isHidden = false
        }
    }
    
    @IBAction func guestUser(_ sender: UIButton) {
    }
    
    @IBAction func openLikemindsApp(_ sender: UIButton) {
        button = sender
        button?.isEnabled = false
        if self.apiKey.isHidden {
            let userName = username.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let userid = userId.text?.trimmingCharacters(in: .whitespaces) ?? ""
            userDefault.set(userName, forKey: "username")
            userDefault.set(userid, forKey: "userid")
            userDefault.synchronize()
            guard !userName.isEmpty, !userid.isEmpty else {return}
            likeMindsApp(apiKey: userDefault.string(forKey: "apikey") ?? "",username: userName, userId: userid)
        } else {
            let apiKey = apiKey.text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !apiKey.isEmpty else {
                button?.isEnabled = true
                return
            }
            userDefault.set(apiKey, forKey: "apikey")
            userDefault.synchronize()
            
            let alert = UIAlertController(title: "Api key saved", message: "Please restart the app", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .cancel) { alertv in
                exit(0)
            }
            alert.addAction(action)
            self.present(alert, animated: true)
        }
    }
    
    func likeMindsApp(apiKey: String, username: String, userId: String) {
        LikeMindsFeedSX.shared.initiateLikeMindsFeed(withViewController: self, apiKey: apiKey, username: username, userId: userId)
    }
}

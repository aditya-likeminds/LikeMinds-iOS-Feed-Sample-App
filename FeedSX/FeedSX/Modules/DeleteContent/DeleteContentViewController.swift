//
//  DeleteContentViewController.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 13/04/23.
//

import UIKit

protocol DeleteContentViewProtocol: AnyObject {
    func didReceivedDeletePostResponse(postId: String, commentId: String?)
}


class DeleteContentViewController: BaseViewController {
    
    @IBOutlet weak var btnLeft: LMButton!
    @IBOutlet weak var btnRight: LMButton!
    @IBOutlet weak var lblPopupTitle: LMLabel!
    
    @IBOutlet weak var lblMessage: LMLabel!
    @IBOutlet weak var textField: LMTextField!
    @IBOutlet weak var btnDropDown: LMButton!
    @IBOutlet weak var reasonPickerView: UIPickerView!
    @IBOutlet weak var reasonTextView: LMTextView!
    @IBOutlet weak var pickerViewContainer: UIView!
    @IBOutlet weak var reasonTextViewHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var pickerviewHeightConstraints: NSLayoutConstraint!
    weak var delegate: DeleteContentViewProtocol?
    var placeholderLabel: LMLabel = {
        let label = LMLabel()
        label.numberOfLines = 1
        label.font = LMBranding.shared.font(16, .regular)
        label.textColor = .lightGray
        label.text = "Write Other reason.."
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var isAdminRemoving: Bool = false
    var postId: String?
    var commentId: String?
    var commentRepliyId: String?
    private let popupTitle = "Delete %@?"
    private let popupMessage = "Are you sure you want to delete this %@? This action cannot be reversed."
    private let viewModel = DeleteContentViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        initialSetups()
        validateUserView()
        reasonTextViewHideAndShow()
    }
    
    func validateUserView() {
        if !isAdminRemoving {
            self.pickerViewContainer.isHidden = true
            self.reasonTextView.superview?.isHidden = true
        } else {
            viewModel.fetchReportTags(type: 0)
        }
    }
    
    
    func initialSetups()  {
        self.reasonPickerView.dataSource = self
        self.reasonPickerView.delegate = self
        self.pickerviewHeightConstraints.constant = 0
        self.textField.superview?.superview?.layer.cornerRadius = 10
        self.textField.superview?.superview?.layer.borderWidth = 1
        self.textField.superview?.superview?.layer.borderColor = UIColor.gray.cgColor
        self.setTitleAndMessage()
        self.btnLeft.setTitleColor(LMBranding.shared.buttonColor, for: .normal)
        self.btnRight.setTitleColor(LMBranding.shared.buttonColor, for: .normal)
        self.btnLeft.addTarget(self, action: #selector(leftButtonClicked(sender:)), for: .touchUpInside)
        self.btnRight.addTarget(self, action: #selector(rightButtonClicked(sender:)), for: .touchUpInside)
        self.btnDropDown.addTarget(self, action: #selector(dropDownButtonClicked(sender:)), for: .touchUpInside)
        reasonTextView.delegate = self
        reasonTextView.addSubview(placeholderLabel)
        //        placeholderLabel.topAnchor.constraint(equalTo: reasonTextView.topAnchor, constant: 8).isActive = true
        //        placeholderLabel.rightAnchor.constraint(equalTo: reasonTextView.rightAnchor, constant: 8).isActive = true
        placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.isHidden = !reasonTextView.text.isEmpty
        reasonTextView.superview?.layer.cornerRadius = 8
        reasonTextView.superview?.layer.borderWidth = 1
        reasonTextView.superview?.layer.borderColor = ColorConstant.likeTextColor.cgColor
    }
    
    private func setTitleAndMessage()  {
        let deleteContentType = commentId == nil ? pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .allSmallSingular) : "comment"
        self.lblPopupTitle.text = String(format: popupTitle, deleteContentType)
        self.lblMessage.text = String(format: popupMessage, deleteContentType)
    }
    
    
    @objc func dropDownButtonClicked(sender: UIButton)  {
        if self.pickerviewHeightConstraints.constant == 0{
            UIView.animate(withDuration: 0.1,
                           delay: 0.1,
                           options: .transitionCurlDown,
                           animations: { () -> Void in
                self.pickerviewHeightConstraints.constant = 165
            }, completion: { (finished) -> Void in
            })
            
        }else{
            UIView.animate(withDuration: 0.1,
                           delay: 0.1,
                           options: .transitionCurlUp,
                           animations: { () -> Void in
                self.pickerviewHeightConstraints.constant = 0
            }, completion: { (finished) -> Void in
            })
        }
    }
    
    @objc func leftButtonClicked(sender: UIButton)  {
        self.dismissViewController()
    }
    
    @objc func rightButtonClicked(sender: UIButton)  {
        if !isAdminRemoving {
            deleteContent(reason: nil)
        } else {
            guard let reason = self.viewModel.selectedReason?.name else { return }
            let otherReason = reasonTextView.trimmedText()
            if reason.lowercased() == "others", !otherReason.isEmpty {
                deleteContent(reason: otherReason)
            } else if reason.lowercased() != "others" {
                deleteContent(reason: reason)
            }
        }
    }
    
    func deleteContent(reason: String?) {
        guard let postId = self.postId else { return }
        guard let commentId = self.commentId else {
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Post.deleted, eventProperties: ["post_id": postId, "user_state": self.isAdminRemoving ? "CM" : "member"])
            self.viewModel.deletePost(postId: postId, reasonText: reason) {[weak self] in
                self?.dismissViewController()
            }
            return
        }
        self.viewModel.deleteComment(postId: postId, commentId: commentId, reasonText: reason) {[weak self] in
            self?.dismissViewController()
        }
    }
    
    @objc func dismissViewController()  {
        self.dismiss(animated: false, completion: nil)
    }
    
    func reasonTextViewHideAndShow() {
        if (viewModel.selectedReason?.name ?? "").lowercased() == "others" {
            reasonTextView.superview?.isHidden = false
            reasonTextView.becomeFirstResponder()
        } else {
            reasonTextView.resignFirstResponder()
            reasonTextView.superview?.isHidden = true
        }
    }
    
    @objc
    override func keyboardWillShow(_ sender: Notification) {

        guard let keyboardSize = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        var shouldMoveViewUp = false
        let bottomOfTextField = reasonTextView.convert(reasonTextView.superview!.bounds, to: self.view).maxY;
        
        let topOfKeyboard = self.view.frame.height - keyboardSize.height
        
        // if the bottom of Textfield is below the top of keyboard, move up
        if bottomOfTextField > topOfKeyboard {
            shouldMoveViewUp = true
        }
        if(shouldMoveViewUp) {
            self.view.frame.origin.y = 0 - (keyboardSize.height - 80)
        }
    }
    
    @objc
    override func keyboardWillHide(_ sender: Notification) {
        self.view.frame.origin.y = 0
        self.view.layoutIfNeeded()
    }
    
}

extension DeleteContentViewController: UIPickerViewDataSource, UIPickerViewDelegate{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.reasons?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: LMLabel? = (view as? LMLabel)
        if pickerLabel == nil {
            pickerLabel = LMLabel()
            pickerLabel?.font = LMBranding.shared.font(20, .regular)
            pickerLabel?.textAlignment = .center
        }
        viewModel.selectedReason = viewModel.reasons?[row]
        pickerLabel?.text = viewModel.reasons?[row].name
//        reasonTextViewHideAndShow()
        return pickerLabel!
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.selectedReason = viewModel.reasons?[row]
        self.textField.text = viewModel.selectedReason?.name
        // self.btnRight.setTitleColor(.turquoise(), for: .normal)
        // self.btnRight.isEnabled = true
        reasonTextViewHideAndShow()
    }
    
}

extension DeleteContentViewController: DeleteContentViewModelProtocol {
    func didReceivedReportTags() {
        self.reasonPickerView.reloadAllComponents()
    }
    
    func didReceivedDeletePostResponse(postId: String, commentId: String?) {
        self.delegate?.didReceivedDeletePostResponse(postId: postId, commentId: commentId)
    }
    
    func didReceivedDeletePostResponse(with error: String?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.presentAlert(message: error ?? "")
        }
    }
}

extension DeleteContentViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = true
    }
}

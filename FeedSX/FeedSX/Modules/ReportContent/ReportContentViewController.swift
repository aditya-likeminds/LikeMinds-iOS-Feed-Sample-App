//
//  ReportContentViewController.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 13/04/23.
//

import UIKit
import LikeMindsFeed

class ReportContentViewController: BaseViewController {
    
    @IBOutlet weak var reportCollectionView: UICollectionView!
    @IBOutlet weak var otherTextView: LMTextView!
    @IBOutlet weak var otherTextViewBottomLine: UIView!
    @IBOutlet weak var reportButton: LMButton!
    @IBOutlet weak var reportSubtitle: UILabel!
    
    var placeholderLabel: LMLabel = {
        let label = LMLabel()
        label.numberOfLines = 1
        label.font = LMBranding.shared.font(16, .regular)
        label.textColor = .lightGray
        label.text = "Write Description"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var viewModel: ReportContentViewModel!
    var postId: String?
    var commentId: String?
    var commentRepliyId: String?
    var entityId: String?
    var uuid: String?
    var reportEntityType: ReportEntityType = .post
    @IBOutlet weak var collectionViewHeightContraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ReportContentViewModel()
        viewModel.entityId = self.entityId
        viewModel.uuid = self.uuid
        viewModel.reportEntityType = self.reportEntityType
        setupViews()
        viewModel.fetchReportTags()
        self.setTitleAndSubtile(title: "Report Abuse", subTitle: nil)
        self.reportSubtitle.text = StringConstant.ReportPost.reportSubtitle
    }
    
    func setupViews() {
        reportCollectionView.register(ReportTagCollectionViewCell.self, forCellWithReuseIdentifier: ReportTagCollectionViewCell.reuseIdentifier)
        reportCollectionView.delegate = self
        reportCollectionView.dataSource = self
        let layout = TagFlowLayout()
        layout.estimatedItemSize = CGSize(width: 140, height: 40)
        reportCollectionView.collectionViewLayout = layout
        viewModel.delegate = self
        reportButton.backgroundColor = .lightGray //LMBranding.shared.buttonColor
        reportButton.isEnabled = false
        self.reportButton.addTarget(self, action: #selector(reportButtonClicked), for: .touchUpInside)
        otherTextView.superview?.isHidden = true
        otherTextViewBottomLine.backgroundColor = LMBranding.shared.buttonColor
        otherTextView.delegate = self
        otherTextView.addSubview(placeholderLabel)
        placeholderLabel.centerYAnchor.constraint(equalTo: otherTextView.centerYAnchor).isActive = true
        placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.isHidden = !otherTextView.text.isEmpty
    }
    
    func showTextView(_ tag: String) {
        reportButton.backgroundColor = LMBranding.shared.buttonColor
        reportButton.isEnabled = true
        self.otherTextView.superview?.isHidden = !(tag.lowercased() == "others")
    }
    
    @objc func reportButtonClicked() {
        guard let tag = self.viewModel.selected.first, let tagName = tag.name else { return }
        if (tagName.lowercased() == "others") {
            let otherReason = otherTextView.text.trimmingCharacters(in: .newlines)
            guard !otherReason.isEmpty else {
                self.presentAlert(message: "Please enter the reason!")
                return
            }
            viewModel.reportContent(reason: otherReason)
        } else {
            viewModel.reportContent(reason: tagName)
        }
    }
}

extension ReportContentViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.reportTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReportTagCollectionViewCell.reuseIdentifier,
                                                            for: indexPath) as? ReportTagCollectionViewCell else {
            return ReportTagCollectionViewCell()
        }
        cell.tagLabel.text = viewModel.reportTags[indexPath.row].name
        cell.tagLabel.preferredMaxLayoutWidth = collectionView.frame.width - 16
        let tag = viewModel.reportTags[indexPath.row]
        if viewModel.selected.contains(where: {$0.name == tag.name}) {
            cell.highLightCell()
        } else {
            cell.unhighLightCell()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ReportTagCollectionViewCell else {return}
        viewModel.selected.removeAll()
        let tag = viewModel.reportTags[indexPath.row]
        viewModel.selected.append(tag)
        showTextView(tag.name ?? "")
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 200, height: 30)
    }
}

extension ReportContentViewController: ReportContentViewModelDelegate {
    
    func didReceivedReportRespone(_ errorMessage: String?) {
        let reportContentType = viewModel.reportEntityType == .post ? pluralizeOrCapitalize(to: LocalPrefrerences.getPostVariable, withAction: .firstLetterCapitalSingular) : "Comment"
        let title = String(format: "%@ is reported for review", reportContentType)
        let message = String(format: "Our team will look into your feedback and will take appropriate action on this %@", reportContentType)
        guard let error = errorMessage else {
            self.presentAlert(title: title, message: message) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            return
        }
        self.presentAlert(message: error, handler: nil)
    }

    func reloadReportTags() {
        self.reportCollectionView.reloadData()
        let height = self.reportCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.collectionViewHeightContraint.constant = height
        self.view.layoutIfNeeded()
    }
}

extension ReportContentViewController: UITextViewDelegate {
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

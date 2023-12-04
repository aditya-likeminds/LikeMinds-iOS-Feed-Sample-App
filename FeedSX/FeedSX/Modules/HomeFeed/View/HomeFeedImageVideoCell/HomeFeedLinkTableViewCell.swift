//
//  HomeFeedLinkTableViewCell.swift
//  FeedSX
//
//  Created by Pushpendra Singh on 05/06/23.
//

import UIKit

class HomeFeedLinkTableViewCell: UITableViewCell {
    
    static let nibName: String = "HomeFeedLinkTableViewCell"
    static let bundle = Bundle(for: HomeFeedLinkTableViewCell.self)
    weak var delegate: HomeFeedTableViewCellDelegate?
    
    @IBOutlet private weak var profileSectionView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var actionsSectionView: UIView!
    @IBOutlet private weak var captionLabel: LMTextView!
    @IBOutlet private weak var captionSectionView: UIView!
    @IBOutlet private weak var linkDetailContainerView: UIView!
    @IBOutlet private weak var linkThumbnailImageView: UIImageView!
    @IBOutlet private weak var linkTitleLabel: LMLabel!
    @IBOutlet private weak var linkDescriptionLabel: LMLabel!
    @IBOutlet private weak var linkLabel: LMLabel!
    @IBOutlet private weak var topicFeedView: LMTopicView!
    
    let profileSectionHeader: ProfileHeaderView = {
        let profileSection = ProfileHeaderView()
        profileSection.translatesAutoresizingMaskIntoConstraints = false
        return profileSection
    }()
    
    let actionFooterSectionView: ActionsFooterView = {
        let actionsSection = ActionsFooterView()
        actionsSection.translatesAutoresizingMaskIntoConstraints = false
        return actionsSection
    }()
    
    let postCaptionView: PostCaptionView = {
        let captionView = PostCaptionView()
        captionView.translatesAutoresizingMaskIntoConstraints = false
        return captionView
    }()
    
    var feedData: PostFeedDataView?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        self.captionLabel.tintColor = LMBranding.shared.textLinkColor
        linkTitleLabel.textColor = ColorConstant.textBlackColor
        setupProfileSectionHeader()
        setupActionSectionFooter()
        let textViewTapGesture = LMTapGesture(target: self, action: #selector(tappedTextView(tapGesture:)))
        captionLabel.isUserInteractionEnabled = true
        captionLabel.addGestureRecognizer(textViewTapGesture)
        linkDetailContainerView.layer.borderWidth = 1
        linkDetailContainerView.layer.cornerRadius = 8
        linkDetailContainerView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
        linkThumbnailImageView.tintColor = ColorConstant.likeTextColor
        linkDetailContainerView.clipsToBounds = true
        linkThumbnailImageView.contentMode = .scaleAspectFill
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
        
    @objc func tappedTextView(tapGesture: LMTapGesture) {
        guard let textView = tapGesture.view as? LMTextView else { return }
        guard let position = textView.closestPosition(to: tapGesture.location(in: textView)) else { return }
        if let url = textView.textStyling(at: position, in: .forward)?[NSAttributedString.Key.link] as? URL {
            UIApplication.shared.open(url)
        } else {
            delegate?.didTapOnCell(self.feedData)
        }
    }
    
    fileprivate func setupActionSectionFooter() {
        self.actionsSectionView.addSubview(actionFooterSectionView)
        actionFooterSectionView.addConstraints(equalToView: self.actionsSectionView)
    }
    
    fileprivate func setupProfileSectionHeader() {
        self.profileSectionView.addSubview(profileSectionHeader)
        profileSectionHeader.addConstraints(equalToView: self.profileSectionView)
    }
    
    @objc func moreButtonClick() {
        self.tableView()?.beginUpdates()
        self.tableView()?.endUpdates()
    }
    
    func setupFeedCell(_ feedDataView: PostFeedDataView, withDelegate delegate: HomeFeedTableViewCellDelegate?, isSepratorShown: Bool = true) {
        self.feedData = feedDataView
        self.delegate = delegate
        profileSectionHeader.setupProfileSectionData(feedDataView, delegate: delegate)
        setupCaption()
        actionFooterSectionView.setupActionFooterSectionData(feedDataView, delegate: delegate)
        setupLinkCell(feedDataView.linkAttachment?.title, description: feedDataView.linkAttachment?.description, link: feedDataView.linkAttachment?.url, linkThumbnailUrl: feedDataView.linkAttachment?.linkThumbnailUrl)
        topicFeedView.configure(with: feedDataView.topics, isSepratorShown: isSepratorShown)
        topicFeedView.superview?.isHidden = feedDataView.topics.count < 1
        layoutIfNeeded()
    }
    
    func setupLinkCell(_ title: String?, description: String?, link: String?, linkThumbnailUrl: String?) {
        self.linkTitleLabel.text = title
        self.linkDescriptionLabel.text = description
        self.linkLabel.text = link?.lowercased()
        if let linkThumbnailUrl = linkThumbnailUrl, !linkThumbnailUrl.isEmpty {
            let placeholder = UIImage(named: "link_icon", in: Bundle(for: HomeFeedLinkTableViewCell.self), with: nil)
            self.linkThumbnailImageView.kf.setImage(with: URL(string: linkThumbnailUrl), placeholder: placeholder)
        } else {
            self.linkThumbnailImageView.image = nil
        }
        self.containerView.layoutIfNeeded()
    }
    
    private func setupCaption() {
        let caption = self.feedData?.caption ?? ""
        self.captionLabel.text = caption
        self.captionSectionView.isHidden = caption.isEmpty
        self.captionLabel.attributedText = TaggedRouteParser.shared.getTaggedParsedAttributedString(with: caption, forTextView: true, withTextColor: ColorConstant.postCaptionColor)
    }
    
    @IBAction func clickedLinkView(_ sender: UIButton) {
        if let linkAttachment = self.feedData?.linkAttachment,
           let urlString = linkAttachment.url {
            let myURL:URL?
            if urlString.hasPrefix("https://") || urlString.hasPrefix("http://"){
                myURL = URL(string: urlString)
            }else {
                let correctedURL = "http://\(urlString)"
                myURL = URL(string: correctedURL)
            }
            guard let url = myURL else { return }
            UIApplication.shared.open(url)
        }
    }
}

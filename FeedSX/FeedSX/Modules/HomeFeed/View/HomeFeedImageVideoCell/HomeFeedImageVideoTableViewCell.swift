//
//  HomeFeedTableViewCell.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 27/03/23.
//

import UIKit
import Kingfisher

protocol HomeFeedTableViewCellDelegate: AnyObject {
    func didTapOnFeedCollection(_ feedDataView: PostFeedDataView?)
    func didTapOnCell(_ feedDataView: PostFeedDataView?)
}

extension HomeFeedTableViewCellDelegate {
    func didTapOnFeedCollection(_ feedDataView: PostFeedDataView?) {}
    func didTapOnCell(_ feedDataView: PostFeedDataView?) {}
}

class HomeFeedImageVideoTableViewCell: UITableViewCell {
    
    static let nibName: String = "HomeFeedImageVideoTableViewCell"
    static let bundle = Bundle(for: HomeFeedImageVideoTableViewCell.self)
    weak var delegate: HomeFeedTableViewCellDelegate?
    
    @IBOutlet private weak var profileSectionView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var actionsSectionView: UIView!
    @IBOutlet private weak var captionLabel: LMTextView!
    @IBOutlet private weak var pageControl: UIPageControl?
    @IBOutlet private weak var pageControlView: UIView?
    @IBOutlet private weak var imageVideoCollectionView: UICollectionView!
    @IBOutlet private weak var captionSectionView: UIView!
    @IBOutlet private weak var collectionSuperViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var topicFeed: LMTopicView!
    
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
        self.captionLabel.tintColor = LMBranding.shared.textLinkColor
        setupImageCollectionView()
        setupProfileSectionHeader()
        setupActionSectionFooter()
        let textViewTapGesture = LMTapGesture(target: self, action: #selector(tappedTextView(tapGesture:)))
        captionLabel.isUserInteractionEnabled = true
        captionLabel.addGestureRecognizer(textViewTapGesture)
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
            delegate?.didTapOnFeedCollection(self.feedData)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    fileprivate func setupActionSectionFooter() {
        self.actionsSectionView.addSubview(actionFooterSectionView)
        actionFooterSectionView.addConstraints(equalToView: self.actionsSectionView)
    }
    
    fileprivate func setupProfileSectionHeader() {
        self.profileSectionView.addSubview(profileSectionHeader)
        profileSectionHeader.addConstraints(equalToView: self.profileSectionView)
    }
    
    fileprivate func setupCaptionSectionView() {}
    
    func setupFeedCell(_ feedDataView: PostFeedDataView, withDelegate delegate: HomeFeedTableViewCellDelegate?, isSepratorShown: Bool = true) {
        self.feedData = feedDataView
        self.delegate = delegate
        profileSectionHeader.setupProfileSectionData(feedDataView, delegate: delegate)
        setupCaption()
        actionFooterSectionView.setupActionFooterSectionData(feedDataView, delegate: delegate)
        topicFeed.configure(with: feedDataView.topics, isSepratorShown: isSepratorShown)
        topicFeed.superview?.isHidden = feedDataView.topics.count < 1
        setupContainerData()
        layoutIfNeeded()
    }
    
    func setupImageCollectionView() {
        
        self.imageVideoCollectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.cellIdentifier)
        self.imageVideoCollectionView.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.cellIdentifier)
        let linkNib = UINib(nibName: "LinkCollectionViewCell", bundle: Bundle(for: LinkCollectionViewCell.self))
        self.imageVideoCollectionView.register(linkNib, forCellWithReuseIdentifier: LinkCollectionViewCell.cellIdentifier)
        
        imageVideoCollectionView.dataSource = self
        imageVideoCollectionView.delegate = self
        
        self.pageControl?.currentPageIndicatorTintColor = LMBranding.shared.buttonColor
    }
    
    private func setupContainerData() {
        switch self.feedData?.postAttachmentType() ?? .unknown {
        case .link:
            containerView.isHidden = false
            pageControlView?.isHidden = true
            imageVideoCollectionView.reloadData()
        case .image, .video:
            containerView.isHidden = false
            let imageCount = self.feedData?.imageVideos?.count ?? 0
            pageControlView?.isHidden = imageCount < 2
            pageControl?.numberOfPages = imageCount
            imageVideoCollectionView.reloadData()
        case .document:
            containerView.isHidden = false
            pageControlView?.isHidden = true
            imageVideoCollectionView.reloadData()
        default:
            containerView.isHidden = true
            pageControlView?.isHidden = true
        }
    }
    
    private func setupCaption() {
        let caption = self.feedData?.caption ?? ""
        self.captionLabel.text = caption
        self.captionSectionView.isHidden = caption.isEmpty
        self.captionLabel.attributedText = TaggedRouteParser.shared.getTaggedParsedAttributedString(with: caption, forTextView: true, withTextColor: ColorConstant.postCaptionColor)
    }
    
}

extension HomeFeedImageVideoTableViewCell:  UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.feedData?.postAttachmentType() ?? .unknown {
        case .link:
            return 1
        case .image, .video:
            return self.feedData?.imageVideos?.count ?? 0
        default:
            break
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var defaultCell = UICollectionViewCell()
        if let imageVideoItem = self.feedData?.imageVideos?[indexPath.row]{
            switch imageVideoItem.fileType {
            case .image:
                guard let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.cellIdentifier, for: indexPath) as? ImageCollectionViewCell else { return defaultCell}
                cell.setupImageVideoView(imageVideoItem.url)
                cell.removeButton.alpha = 0
                defaultCell = cell
            case .video:
                guard let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionViewCell.cellIdentifier, for: indexPath) as? VideoCollectionViewCell else { return defaultCell}
                cell.setupVideoData(url: imageVideoItem.url ?? "")
                cell.removeButton.alpha = 0
                defaultCell = cell
            default:
                break
            }
           
        } else if let linkAttachment = self.feedData?.linkAttachment,
                    let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: LinkCollectionViewCell.cellIdentifier, for: indexPath) as? LinkCollectionViewCell {
            cell.setupLinkCell(linkAttachment.title, description: linkAttachment.description, link: linkAttachment.url, linkThumbnailUrl: linkAttachment.linkThumbnailUrl)
            cell.removeButton.alpha = 0
            defaultCell = cell
        }
        return defaultCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch self.feedData?.postAttachmentType() ?? .unknown {
        case .image, .video:
            self.collectionSuperViewHeightConstraint.constant = UIScreen.main.bounds.width
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        case .link:
            self.collectionSuperViewHeightConstraint.constant = UIScreen.main.bounds.width
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        default:
            break
        }
        return CGSize(width: UIScreen.main.bounds.width - 2, height: UIScreen.main.bounds.width - 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        } else {
            if let cell  = collectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell {
                cell.playVideo()
            }
            delegate?.didTapOnFeedCollection(self.feedData)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCollectionViewCell)?.pauseVideo()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCollectionViewCell)?.pauseVideo()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x  / self.frame.width)
        pageControl?.currentPage = index
        pauseAllInVisibleVideos()
        guard let cell = imageVideoCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? VideoCollectionViewCell  else {return}
        cell.playVideo()
    }
    
    func pauseAllInVisibleVideos() {
        for cell in imageVideoCollectionView.visibleCells {
            (cell as? VideoCollectionViewCell)?.pauseVideo()
        }
    }
    
    func playVisibleVideo() {
        for cell in imageVideoCollectionView.visibleCells {
            (cell as? VideoCollectionViewCell)?.playVideo()
            return
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pauseAllInVisibleVideos()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
    
}

class LMTapGesture: UITapGestureRecognizer {
    var index = Int()
}

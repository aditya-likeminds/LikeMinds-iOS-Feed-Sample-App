//
//  HomeFeedViewController.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 27/03/23.
//

import Foundation
import UIKit
import Kingfisher
import LikeMindsFeed

public final class HomeFeedViewControler: BaseViewController {
    
    let feedTableView: UITableView = UITableView()
    let homeFeedViewModel = HomeFeedViewModel()
    let refreshControl = UIRefreshControl()
    var bottomLoadSpinner: UIActivityIndicatorView!
    fileprivate var lastKnowScrollViewContentOfsset: CGFloat = 0
    private var createButtonWidthConstraints: NSLayoutConstraint?
    
    let createPostButton: LMButton = {
        let createPost = LMButton()
        createPost.setImage(UIImage(systemName: ImageIcon.calenderBadgePlus), for: .normal)
        createPost.setTitle(StringConstant.HomeFeed.newPost, for: .normal)
        createPost.titleLabel?.font = LMBranding.shared.font(13, .medium)
        createPost.tintColor = .white
        createPost.backgroundColor = LMBranding.shared.buttonColor
        createPost.clipsToBounds = true
        createPost.translatesAutoresizingMaskIntoConstraints = false
        return createPost
    }()
    
    let postingProgressSuperStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.backgroundColor = .white
        sv.spacing = 0
        sv.layoutMargins = .init(top: .zero, left: 8, bottom: .zero, right: 30)
        sv.isLayoutMarginsRelativeArrangement = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let postingProgressStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = .zero
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let postingImageView: UIImageView = {
        let imageSize = 50.0
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        imageView.image = UIImage(systemName: "person.circle")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setSizeConstraint(width: imageSize, height: imageSize)
        return imageView
    }()
    
    let postingImageSuperView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setSizeConstraint(width: 70, height: 70)
        return view
    }()
    
    let postingLabel: LMLabel = {
        let label = LMLabel()
        label.font = LMBranding.shared.font(16, .medium)
        label.text = StringConstant.HomeFeed.creatingResource
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    let leftTitleLabel: LMLabel = {
        let label = LMLabel()
        label.font = LMBranding.shared.font(24, .medium)
        label.textColor = LMBranding.shared.headerColor.isDarkColor ? .white : ColorConstant.navigationTitleColor
        label.text = "Community"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var spaceView: UIView = {
        let uiView = UIView()
        uiView.translatesAutoresizingMaskIntoConstraints = false
        return uiView
    }()
    
    let progressIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    var notificationBarItem: UIBarButtonItem!
    let notificationBellButton: LMButton = {
        let button = LMButton(frame: CGRect(x: 0, y: 5, width: 44, height: 44))
        button.setImage(UIImage(systemName: ImageIcon.bellFillIcon), for: .normal)
        button.tintColor = ColorConstant.likeTextColor
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 22), forImageIn: .normal)
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let notificationBadgeLabel: LMPaddedLabel = {
        let badgeSize = 20
        let label = LMPaddedLabel(frame: CGRect(x: 0, y: 0, width: badgeSize, height: badgeSize))
        label.paddingLeft = 2
        label.paddingRight = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.textColor = .white
        label.font = LMBranding.shared.font(12, .regular)
        label.backgroundColor = .systemRed
        return label
    }()
    var isPostCreatingInProgress: Bool = false
    
    private var topicFeedStackView: UIStackView = {
        let sv = UIStackView()
        sv.backgroundColor = .white
        sv.axis  = .horizontal
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 8
        sv.layoutMargins = .init(top: 8, left: 16, bottom: 8, right: 16)
        sv.isLayoutMarginsRelativeArrangement = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private var topicCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = .init(width: 100, height: 30)
        let tc = UICollectionView(frame: .zero, collectionViewLayout: layout)
        tc.register(UINib(nibName: HomeFeedTopicCell.identifier, bundle: Bundle(for: HomeFeedTopicCell.self)), forCellWithReuseIdentifier: HomeFeedTopicCell.identifier)
        tc.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "defaultCell")
        tc.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tc.showsHorizontalScrollIndicator = false
        tc.showsVerticalScrollIndicator = false
        tc.backgroundColor = .clear
        tc.translatesAutoresizingMaskIntoConstraints = false
        return tc
    }()
    
    private var clearTopicBtn: LMButton = {
        let btn = LMButton()
        btn.setTitle("Clear", for: .normal)
        btn.setTitle("Clear", for: .selected)
        btn.setImage(nil, for: .normal)
        btn.setImage(nil, for: .selected)
        btn.setTitleColor(ColorConstant.postCaptionColor, for: .normal)
        btn.setTitleColor(ColorConstant.postCaptionColor, for: .selected)
        btn.titleLabel?.font = LMBranding.shared.font(16, .regular)
        btn.tintColor = LMBranding.shared.buttonColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.contentEdgeInsets = .zero
        btn.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return btn
    }()
    
    private var allTopicsBtn: LMButton = {
        let btn = LMButton()
        btn.setTitle("All Topics", for: .normal)
        btn.setTitle("All Topics", for: .selected)
        btn.titleLabel?.font = LMBranding.shared.font(16, .regular)
        btn.setTitleColor(ColorConstant.postCaptionColor, for: .normal)
        btn.setTitleColor(ColorConstant.postCaptionColor, for: .selected)
        btn.tintColor = ColorConstant.postCaptionColor
        btn.setImage(UIImage(systemName: "arrow.down"), for: .normal)
        btn.setImage(UIImage(systemName: "arrow.down"), for: .selected)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.semanticContentAttribute = .forceRightToLeft
        btn.titleEdgeInsets = .init(top: .zero, left: -4, bottom: .zero, right: 4)
        btn.contentEdgeInsets = .init(top: .zero, left: 4, bottom: .zero, right: .zero)
        btn.imageEdgeInsets = .zero
        btn.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return btn
    }()
    
    private var topics: [HomeFeedTopicCell.ViewModel] = []
    
    public override func loadView() {
        super.loadView()
        
        view.addSubview(postingProgressSuperStackView)
        view.addSubview(feedTableView)
        view.addSubview(createPostButton)
        view.addSubview(topicFeedStackView)
        
        setupTopicFeed()
        setupPostingProgress()
        setupTableView()
        setupSpinner()
        setupCreateButton()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = ColorConstant.backgroudColor
        
        topicCollection.dataSource = self
        topicCollection.delegate = self
        
        createPostButton.isHidden = true
        homeFeedViewModel.delegate = self
        
        self.postingImageSuperView.superview?.isHidden = true
        homeFeedViewModel.getFeed()
        homeFeedViewModel.getTopics()
        createPostButton.addTarget(self, action: #selector(createNewPost), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(postEditCompleted), name: .postEditCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postCreationCompleted), name: .postCreationCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postCreationStarted), name: .postCreationStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshFeed), name: .refreshHomeFeedData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDataObject), name: .refreshHomeFeedDataObject, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorMessage), name: .errorInApi, object: nil)
        
        allTopicsBtn.addTarget(self, action: #selector(didTapAllTopics), for: .touchUpInside)
        clearTopicBtn.addTarget(self, action: #selector(didTapClearTopics), for: .touchUpInside)
        topicFeedStackView.subviews.forEach {
            $0.isHidden = true
        }
        
        self.setRightItemsOfNavigationBar()
        self.setLeftItemOfNavigationBar()
        LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Feed.opened, eventProperties: ["feed_type": "universal_feed"])
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        homeFeedViewModel.getMemberState()
        homeFeedViewModel.getUnreadNotificationCount()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseAllVideo()
    }
    
    @objc func refreshDataObject(notification: Notification) {
        if let postData = notification.object as? PostFeedDataView {
            self.homeFeedViewModel.refreshFeedDataObject(postData)
            guard let index = homeFeedViewModel.feeds.firstIndex(where: {$0.postId == postData.postId}) else {return }
            self.feedTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }

    func setRightItemsOfNavigationBar() {
        let containView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let profileImageview = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 34))
        profileImageview.center = containView.center
        profileImageview.makeCircleView()
        profileImageview.setImage(withUrl: LocalPrefrerences.getUserData()?.imageUrl ?? "", placeholder: UIImage.generateLetterImage(with:  LocalPrefrerences.getUserData()?.name ?? ""))
        
        containView.addSubview(profileImageview)
        let profileBarButton = UIBarButtonItem(customView: containView)
        setNotificationBarItem()
        self.navigationItem.rightBarButtonItems = [profileBarButton, notificationBarItem]
    }
    
    func setNotificationBarItem() {
        notificationBarItem = UIBarButtonItem(customView: notificationBellButton)
        notificationBellButton.addTarget(self, action: #selector(notificationIconClicked), for: .touchUpInside)
        NSLayoutConstraint.activate([
            notificationBellButton.widthAnchor.constraint(equalToConstant: 44),
            notificationBellButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    func showBadge(withCount count: Int) {
        notificationBadgeLabel.text = count > 99 ? "99+" : "\(count)"
        notificationBellButton.addSubview(notificationBadgeLabel)
        NSLayoutConstraint.activate([
            notificationBadgeLabel.leftAnchor.constraint(equalTo: notificationBellButton.leftAnchor, constant: 16),
            notificationBadgeLabel.topAnchor.constraint(equalTo: notificationBellButton.topAnchor, constant: 4),
            notificationBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            notificationBadgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func setLeftItemOfNavigationBar() {
        let leftItem = UIBarButtonItem(customView: leftTitleLabel)
        self.navigationItem.leftBarButtonItem = leftItem
    }
    
    @objc func postCreationStarted(notification: Notification) {
        print("postCreationStarted")
        self.isPostCreatingInProgress = true
        self.postingImageSuperView.superview?.isHidden = false
        if let image = notification.object as? UIImage {
            postingImageView.superview?.isHidden = false
            postingImageView.image = image
        } else {
            self.postingImageView.isHidden = true
        }
        if homeFeedViewModel.feeds.count > 0 {
            self.feedTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    @objc func postCreationCompleted(notification: Notification) {
        print("postCreationCompleted")
        self.isPostCreatingInProgress = false
        self.postingImageSuperView.superview?.isHidden = true
        if let error = notification.object as? String {
            self.presentAlert(message: error)
            return
        }
        refreshFeed()
        if homeFeedViewModel.feeds.count > 0 {
            self.feedTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    @objc func postEditingStarted(notification: Notification) {
        print("postEditingStarted")
        self.postingImageSuperView.superview?.isHidden = false
        if let image = notification.object as? UIImage {
            postingImageView.superview?.isHidden = false
            postingImageView.image = image
        } else {
            self.postingImageView.isHidden = true
        }
    }
    
    @objc func postEditCompleted(notification: Notification) {
        print("postEditCompleted")
        self.postingImageSuperView.superview?.isHidden = true
        let notificationObject = notification.object
        if let error = notificationObject as? String {
            self.presentAlert(message: error)
            return
        }
        let updatedAtIndex = self.homeFeedViewModel.updateEditedPost(postDetail: notificationObject as? PostFeedDataView)
        self.feedTableView.reloadRows(at: [IndexPath(row: updatedAtIndex, section: 0)], with: .none)
    }
        
    func setupTableView() {
        feedTableView.translatesAutoresizingMaskIntoConstraints = false
        feedTableView.topAnchor.constraint(equalTo: topicFeedStackView.bottomAnchor, constant: 0).isActive = true
        feedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        feedTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        feedTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        feedTableView.showsVerticalScrollIndicator = false
        feedTableView.register(UINib(nibName: HomeFeedImageVideoTableViewCell.nibName, bundle: HomeFeedImageVideoTableViewCell.bundle), forCellReuseIdentifier: HomeFeedImageVideoTableViewCell.nibName)
        feedTableView.register(UINib(nibName: HomeFeedDocumentTableViewCell.nibName, bundle: HomeFeedDocumentTableViewCell.bundle), forCellReuseIdentifier: HomeFeedDocumentTableViewCell.nibName)
        feedTableView.register(UINib(nibName: HomeFeedLinkTableViewCell.nibName, bundle: HomeFeedLinkTableViewCell.bundle), forCellReuseIdentifier: HomeFeedLinkTableViewCell.nibName)
        feedTableView.backgroundColor = .clear
        feedTableView.delegate = self
        feedTableView.dataSource = self
        feedTableView.separatorStyle = .none
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
        feedTableView.refreshControl = refreshControl
    }
    
    func setupSpinner(){
        bottomLoadSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height:40))
        bottomLoadSpinner.color = .gray
        self.feedTableView.tableFooterView = bottomLoadSpinner
        bottomLoadSpinner.hidesWhenStopped = true
    }
    
    func setupCreateButton() {
        createPostButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
        createPostButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        createButtonWidthConstraints = createPostButton.widthAnchor.constraint(equalToConstant: 150)
        createButtonWidthConstraints?.isActive = true
        createPostButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        createPostButton.setInsets(forContentPadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), imageTitlePadding: 10)
        createPostButton.layer.cornerRadius = 25
    }
    
    func setupPostingProgress() {
        postingProgressSuperStackView.addArrangedSubview(postingProgressStackView)
        postingProgressStackView.addArrangedSubview(postingImageSuperView)
        postingProgressStackView.addArrangedSubview(postingLabel)
        postingProgressStackView.addArrangedSubview(spaceView)
        postingProgressStackView.addArrangedSubview(progressIndicator)
        postingImageSuperView.addSubview(postingImageView)
        postingImageView.centerYAnchor.constraint(equalTo: self.postingImageSuperView.centerYAnchor).isActive = true
        postingImageView.centerXAnchor.constraint(equalTo: self.postingImageSuperView.centerXAnchor).isActive = true
        spaceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        postingProgressSuperStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        postingProgressSuperStackView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        postingProgressSuperStackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    }
    
    private func setupTopicFeed() {
        topicFeedStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: .zero).isActive = true
        topicFeedStackView.trailingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: .zero).isActive = true
        topicFeedStackView.topAnchor.constraint(equalTo: postingProgressSuperStackView.bottomAnchor).isActive = true
        
        topicFeedStackView.addArrangedSubview(allTopicsBtn)
        topicFeedStackView.addArrangedSubview(topicCollection)
        topicFeedStackView.addArrangedSubview(clearTopicBtn)
    }
    
    @objc func createNewPost() {
        if self.isPostCreatingInProgress {
            self.presentAlert(message: StringConstant.postingInProgress)
            return
        }
        guard self.homeFeedViewModel.hasRightForCreatePost() else  {
            self.presentAlert(message: StringConstant.restrictToCreatePost)
            return
        }
        let createView = CreatePostViewController(nibName: "CreatePostViewController", bundle: Bundle(for: CreatePostViewController.self))
        LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Post.creationStarted, eventProperties: nil)
        self.navigationController?.pushViewController(createView, animated: true)
    }
    
    func enableCreateNewPostButton(isEnable: Bool) {
        if isEnable {
            self.createPostButton.backgroundColor = LMBranding.shared.buttonColor
        } else {
            self.createPostButton.backgroundColor = .lightGray
        }
    }
    
    @objc func refreshFeed() {
        homeFeedViewModel.pullToRefresh()
    }
    
    @objc func notificationIconClicked() {
        let notificationFeedVC = NotificationFeedViewController()
        self.navigationController?.pushViewController(notificationFeedVC, animated: true)
    }
    
    func newPostButtonExapndAndCollapes(_ offsetY: CGFloat) {
        if offsetY > self.lastKnowScrollViewContentOfsset {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration:0.2) { [weak self] in
                guard let weakSelf = self else {return}
                weakSelf.createPostButton.setTitle(nil, for: .normal)
                weakSelf.createPostButton.setInsets(forContentPadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), imageTitlePadding: 0)
                self?.createButtonWidthConstraints?.isActive = false
                self?.createButtonWidthConstraints = self?.createPostButton.widthAnchor.constraint(equalToConstant: 50.0)
                self?.createButtonWidthConstraints?.isActive = true
                weakSelf.view.layoutIfNeeded()
            }
        }
        else {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.2) {[weak self] in
                guard let weakSelf = self else {return}
                weakSelf.createPostButton.setTitle(StringConstant.HomeFeed.newPost, for: .normal)
                weakSelf.createPostButton.setInsets(forContentPadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), imageTitlePadding: 10)
                self?.createButtonWidthConstraints?.isActive = false
                self?.createButtonWidthConstraints = self?.createPostButton.widthAnchor.constraint(equalToConstant: 150.0)
                self?.createButtonWidthConstraints?.isActive = true
                weakSelf.view.layoutIfNeeded()
            }
        }
    }
    
    func setHomeFeedEmptyView() {
        let emptyView = EmptyHomeFeedView(frame: CGRect(x: 0, y: 0, width: feedTableView.bounds.size.width, height: feedTableView.bounds.size.height))
        emptyView.delegate = self
        feedTableView.backgroundView = emptyView
        feedTableView.separatorStyle = .none
    }
    
    @objc
    private func didTapAllTopics() {
        let vc = SelectTopicViewController(selectedTopics: homeFeedViewModel.selectedTopics, isShowAllTopics: true, delegate: self, isEnabledState: false)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc
    private func didTapClearTopics() {
        homeFeedViewModel.removeAllTopics()
    }
}

extension HomeFeedViewControler: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        homeFeedViewModel.feeds.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feed = homeFeedViewModel.feeds[indexPath.row]
        switch feed.postAttachmentType() {
        case .document:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedDocumentTableViewCell.nibName, for: indexPath) as! HomeFeedDocumentTableViewCell
            cell.setupFeedCell(feed, withDelegate: self, isSepratorShown: false)
            return cell
        case .link:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedLinkTableViewCell.nibName, for: indexPath) as! HomeFeedLinkTableViewCell
            cell.setupFeedCell(feed, withDelegate: self, isSepratorShown: false)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedImageVideoTableViewCell.nibName, for: indexPath) as! HomeFeedImageVideoTableViewCell
            cell.setupFeedCell(feed, withDelegate: self, isSepratorShown: false)
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? HomeFeedImageVideoTableViewCell {
            cell.pauseAllInVisibleVideos()
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? HomeFeedImageVideoTableViewCell {
            cell.pauseAllInVisibleVideos()
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let postData = homeFeedViewModel.feeds[indexPath.row]
        let postId = postData.postId 
        let postDetail = PostDetailViewController(nibName: "PostDetailViewController", bundle: Bundle(for: PostDetailViewController.self))
        postDetail.postId = postId
        self.navigationController?.pushViewController(postDetail, animated: true)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        self.lastKnowScrollViewContentOfsset = scrollView.contentOffset.y

        checkWhichVideoToEnable()
        if offsetY > contentHeight - (scrollView.frame.height + 60) && !homeFeedViewModel.isFeedLoading
        {
            homeFeedViewModel.getFeed()
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        newPostButtonExapndAndCollapes(offsetY)
    }
    
    func checkWhichVideoToEnable() {
        
        for cell in feedTableView.visibleCells as [UITableViewCell] {
            
            if let cell = cell as? HomeFeedImageVideoTableViewCell {
                
                let indexPath = feedTableView.indexPath(for: cell)
                let cellRect = feedTableView.rectForRow(at: indexPath!)
                let superView = feedTableView.superview
                
                let convertedRect = feedTableView.convert(cellRect, to: superView)
                let intersect = CGRectIntersection(feedTableView.frame, convertedRect)
                let visibleHeight = CGRectGetHeight(intersect)
                cell.pauseAllInVisibleVideos()
                if visibleHeight > self.view.bounds.size.height * 0.6 {  // only if 60% of the cell is visible.
                    //cell is visible more than 60%
                    cell.playVisibleVideo()
                }
            } else {
                pauseAllVideo()
            }
        }
    }
    
    func pauseAllVideo() {
        for cell in feedTableView.visibleCells as [UITableViewCell] {
            (cell as? HomeFeedImageVideoTableViewCell)?.pauseAllInVisibleVideos()
        }
    }
    
}

extension HomeFeedViewControler: HomeFeedViewModelDelegate {
   func didReceivedFeedData(success: Bool) {
        if homeFeedViewModel.feeds.isEmpty {
            setHomeFeedEmptyView()
            self.createPostButton.isHidden = true
        } else {
            feedTableView.restore()
            self.createPostButton.isHidden = false
        }
        bottomLoadSpinner.stopAnimating()
        refreshControl.endRefreshing()
        guard success else {return}
        feedTableView.reloadData()
    }
    
    func didReceivedMemberState() {
        if self.homeFeedViewModel.hasRightForCreatePost() {
            self.createPostButton.backgroundColor = LMBranding.shared.buttonColor
        } else {
            self.createPostButton.backgroundColor = .lightGray
        }
    }
    
    func reloadSection(_ indexPath: IndexPath) {
        self.feedTableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func updateNotificationFeedCount(_ count: Int){
        if count > 0 {
            showBadge(withCount: count)
        } else {
            notificationBadgeLabel.removeFromSuperview()
        }
    }
    
    func updateTopicFeedView(with cells: [HomeFeedTopicCell.ViewModel], isShowTopicFeed: Bool) {
        topicFeedStackView.subviews.forEach {
            $0.isHidden = !isShowTopicFeed
        }
        
        if isShowTopicFeed {
            topics = cells
            allTopicsBtn.isHidden = !cells.isEmpty
            clearTopicBtn.isHidden = cells.isEmpty
            topicCollection.reloadData()
        }
    }
}

extension HomeFeedViewControler: ProfileHeaderViewDelegate {
    func didTapOnMoreButton(selectedPost: PostFeedDataView?) {
        guard let menues = selectedPost?.postMenuItems else { return }
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for menu in menues {
            switch menu.id {
            case .report:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    let reportContent = ReportContentViewController(nibName: "ReportContentViewController", bundle: Bundle(for: ReportContentViewController.self))
                    reportContent.entityId = selectedPost?.postId
                    reportContent.uuid = selectedPost?.postByUser?.uuid
                    reportContent.reportEntityType = .post
                    self?.navigationController?.pushViewController(reportContent, animated: true)
                }
            case .delete:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    let deleteController = DeleteContentViewController(nibName: "DeleteContentViewController", bundle: Bundle(for: DeleteContentViewController.self))
                    deleteController.modalPresentationStyle = .overCurrentContext
                    deleteController.postId = selectedPost?.postId
                    deleteController.delegate = self
                    deleteController.isAdminRemoving = LocalPrefrerences.uuid() != (selectedPost?.postByUser?.uuid ?? "") ? (self?.homeFeedViewModel.isAdmin() ?? false) :  false
                    self?.navigationController?.present(deleteController, animated: false)
                }
            case .edit:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    guard let postId = selectedPost?.postId else {return}
                    self?.homeFeedViewModel.trackPostActionEvent(postId: postId, creatorId: selectedPost?.postByUser?.uuid ?? "", eventName: LMFeedAnalyticsEventName.Post.edited, postType: selectedPost?.postAttachmentType().rawValue ?? "")
                    let editPost = EditPostViewController(nibName: "EditPostViewController", bundle: Bundle(for: EditPostViewController.self))
                    editPost.postId = postId
                    self?.navigationController?.pushViewController(editPost, animated: true)
                }
            case .pin:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    guard let postId = selectedPost?.postId else {return}
                    self?.homeFeedViewModel.trackPostActionEvent(postId: postId, creatorId: selectedPost?.postByUser?.uuid ?? "", eventName: LMFeedAnalyticsEventName.Post.pinned, postType: selectedPost?.postAttachmentType().rawValue ?? "")
                    self?.homeFeedViewModel.pinUnpinPost(postId: postId)
                }
            case .unpin:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    guard let postId = selectedPost?.postId else {return}
                    self?.homeFeedViewModel.trackPostActionEvent(postId: postId, creatorId: selectedPost?.postByUser?.uuid ?? "", eventName: LMFeedAnalyticsEventName.Post.unpinned, postType: selectedPost?.postAttachmentType().rawValue ?? "")
                    self?.homeFeedViewModel.pinUnpinPost(postId: postId)
                }
            default:
                break
            }
        }
        actionSheet.addCancelAction(withOptions: "Cancel", actionHandler: nil)
        self.present(actionSheet, animated: true)
    }
    
    func didTapOnFeedCollection(_ feedDataView: PostFeedDataView?) {
        guard let postId = feedDataView?.postId else {return}
        let postDetail = PostDetailViewController(nibName: "PostDetailViewController", bundle: Bundle(for: PostDetailViewController.self))
        postDetail.postId = postId
        self.navigationController?.pushViewController(postDetail, animated: true)
    }
}

extension HomeFeedViewControler: ActionsFooterViewDelegate {
   
    func didTappedAction(withActionType actionType: CellActionType, postData: PostFeedDataView?) {
        switch actionType {
        case .like:
            guard let postId = postData?.postId else { return }
            homeFeedViewModel.likePost(postId: postId)
        case .savePost:
            guard let postId = postData?.postId else { return }
            homeFeedViewModel.savePost(postId: postId)
        case .comment:
            guard let postId = postData?.postId else { return }
            let postDetail = PostDetailViewController(nibName: "PostDetailViewController", bundle: Bundle(for: PostDetailViewController.self))
            postDetail.postId = postId
            postDetail.isViewPost = false
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Comment.listOpened, eventProperties: ["post_id": postId])
            self.navigationController?.pushViewController(postDetail, animated: true)
        case .likeCount:
            guard let postId = postData?.postId, (postData?.likedCount ?? 0) > 0 else { return }
            let likedUserListView = LikedUserListViewController()
            likedUserListView.viewModel = .init(postId: postId, commentId: nil)
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Post.likeListOpen, eventProperties: ["post_id": postId])
            self.navigationController?.pushViewController(likedUserListView, animated: true)
        case .sharePost:
            guard let postId = postData?.postId else { return }
            ShareContentUtil.sharePost(viewController: self, domainUrl: "lmfeed://yourdomain.com", postId: postId)
        default:
            break
        }
    }
}

extension HomeFeedViewControler: DeleteContentViewProtocol {
    
    func didReceivedDeletePostResponse(postId: String, commentId: String?) {
        homeFeedViewModel.feeds.removeAll(where: {$0.postId == postId})
        feedTableView.reloadData()
    }
}
extension HomeFeedViewControler: HomeFeedTableViewCellDelegate {
    func didTapOnCell(_ feedDataView: PostFeedDataView?) {
        guard let postId = feedDataView?.postId else { return }
        let postDetail = PostDetailViewController(nibName: "PostDetailViewController", bundle: Bundle(for: PostDetailViewController.self))
        postDetail.postId = postId
        self.navigationController?.pushViewController(postDetail, animated: true)
    }
}


extension HomeFeedViewControler: EmptyHomeFeedViewDelegate {
    func clickedOnNewPostButton() {
        self.createNewPost()
    }
}

// MARK: LMTopicViewDelegate
extension HomeFeedViewControler: LMTopicViewDelegate {
    func didTapRemoveCell(topicId: String) {
        homeFeedViewModel.removeTopic(for: topicId)
    }
}

extension HomeFeedViewControler: SelectTopicViewDelegate {
    func updateSelection(with data: [TopicFeedDataModel]) {
        homeFeedViewModel.updateTopics(with: data)
    }
}

// MARK: UICollectionView
extension HomeFeedViewControler: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        topics.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeFeedTopicCell.identifier, for: indexPath) as? HomeFeedTopicCell {
            cell.configure(with: topics[indexPath.row]) { [weak self] in
                guard let self else { return }
                self.homeFeedViewModel.removeTopic(for: topics[indexPath.row].topicID)
            } openSelection: { [weak self] in
                self?.didTapAllTopics()
            }
            return cell
        }
        
        let defaultCell = collectionView.dequeueReusableCell(withReuseIdentifier: "defaultCell", for: indexPath)
        return defaultCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = topics[indexPath.row].topicName.sizeOfString(with: LMBranding.shared.font(14, .regular)).width + 20 + 2 + 16
        return .init(width: width, height: 30)
    }
}

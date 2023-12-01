//
//  CreatePostViewController.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 04/04/23.
//

import UIKit
import BSImagePicker
import PDFKit
import LikeMindsFeed

class CreatePostViewController: BaseViewController {
    
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var usernameLabel: LMLabel!
    @IBOutlet weak var addMoreButton: LMButton! {
        didSet {
            addMoreButton.layer.borderWidth = 1
            addMoreButton.layer.borderColor = LMBranding.shared.buttonColor.cgColor
            addMoreButton.tintColor = LMBranding.shared.buttonColor
            addMoreButton.layer.cornerRadius = 8
            addMoreButton.addTarget(self, action: #selector(addMoreAction), for: .touchUpInside)
            addMoreButton.superview?.isHidden = true
        }
    }
    @IBOutlet weak var postinLabel: LMLabel!
    @IBOutlet weak var captionTextView: LMTextView! {
        didSet{
            captionTextView.textColor = ColorConstant.textBlackColor
        }
    }
    @IBOutlet weak var pageControl: UIPageControl?
    @IBOutlet weak var attachmentView: UIView!
    @IBOutlet weak var attachmentCollectionView: UICollectionView! {
        didSet {
            attachmentCollectionView.dataSource = self
            attachmentCollectionView.delegate = self
            attachmentCollectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.cellIdentifier)
            attachmentCollectionView.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.cellIdentifier)
            attachmentCollectionView.register(DocumentCollectionCell.self, forCellWithReuseIdentifier: DocumentCollectionCell.cellIdentifier)
            attachmentCollectionView.register(UINib(nibName: LinkCollectionViewCell.nibName, bundle: Bundle(for: LinkCollectionViewCell.self)), forCellWithReuseIdentifier: LinkCollectionViewCell.cellIdentifier)
            attachmentCollectionView.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.cellIdentifier)
            attachmentCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "defaultCell")
        }
    }
    @IBOutlet weak var uploadAttachmentActionsView: UIView!
    @IBOutlet weak var uploadActionsTableView: UITableView! {
        didSet {
            uploadActionsTableView.dataSource = self
            uploadActionsTableView.delegate = self
            uploadActionsTableView.layoutMargins = UIEdgeInsets.zero
            uploadActionsTableView.separatorInset = UIEdgeInsets.zero
        }
    }
    @IBOutlet weak var collectionSuperViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var uploadAttachmentSuperViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var captionTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var uploadActionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var taggingListViewContainer: UIView!
    @IBOutlet weak var taggingViewHeightConstraint: NSLayoutConstraint!
    
    
    @IBOutlet private weak var topicFeedView: LMTopicView!
    @IBOutlet private weak var topicFeedViewHeightConstraint: NSLayoutConstraint!
    
    var debounceForDecodeLink:Timer?
    var uploadActionsHeight:CGFloat = 54 * 3
    
    var placeholderLabel: LMLabel = {
        let label = LMLabel()
        label.numberOfLines = 1
        label.font = LMBranding.shared.font(16, .regular)
        label.textColor = .lightGray
        label.text = " Write Description"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
   
    let viewModel: CreatePostViewModel = CreatePostViewModel()
    let taggingUserList: TaggedUserList =  {
        guard let userList = TaggedUserList.nibView() else { return TaggedUserList() }
        return userList
    }()
    var isTaggingViewHidden = true
    var isReloadTaggingListView = true
    var typeTextRangeInTextView: NSRange?
    var postButtonItem: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItems()
        NotificationCenter.default.addObserver(self, selector: #selector(errorMessage), name: .errorInApi, object: nil)
        viewModel.getTopics()
        
        userProfileImage.makeCircleView()
        
        captionTextView.delegate = self
        captionTextView.addSubview(placeholderLabel)
        
        topicFeedView.delegate = self
        
        placeholderLabel.centerYAnchor.constraint(equalTo: captionTextView.centerYAnchor).isActive = true
        placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.isHidden = !captionTextView.text.isEmpty
        
        viewModel.delegate = self
        
        setupProfileData()
        setTitleAndSubtile(title: StringConstant.CreatePost.screenTitle, subTitle: nil)
        hideTaggingViewContainer()
        pageControl?.currentPageIndicatorTintColor = LMBranding.shared.buttonColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setupTaggingView()
    }
    
    func setupTaggingView() {
        self.taggingListViewContainer.addSubview(taggingUserList)
        taggingUserList.addConstraints(equalToView: self.taggingListViewContainer)
        taggingUserList.setUp()
        taggingUserList.delegate = self
        self.taggingListViewContainer.layer.borderWidth = 1
        self.taggingListViewContainer.layer.borderColor = ColorConstant.disableButtonColor.cgColor
        taggingListViewContainer.layer.cornerRadius = 8
    }
    
    func setupNavigationItems() {
         postButtonItem = UIBarButtonItem(title: "Create",
                        style: .done,
                        target: self,
                        action: #selector(createPost))
        postButtonItem?.tintColor = LMBranding.shared.buttonColor
        self.navigationItem.rightBarButtonItem = postButtonItem
        postButtonItem?.isEnabled = false
    }
    
    func setupProfileData() {
        guard let user = LocalPrefrerences.getUserData() else {
            return
        }
        let placeholder = UIImage.generateLetterImage(with: user.name)
        self.userProfileImage.setImage(withUrl: user.imageUrl ?? "", placeholder: placeholder)
        self.usernameLabel.text = user.name
    }
    
    @objc func createPost() {
        self.view.endEditing(true)
        let text = self.captionTextView.trimmedText()
        if (self.viewModel.currentSelectedUploadeType == .link),
           text.detectedFirstLink != nil {
            self.viewModel.verifyOgTagsAndCreatePost(message: text) {[weak self] in
                self?.viewModel.createPost(text)
                self?.navigationController?.popViewController(animated: true)
            }
        } else {
            self.viewModel.createPost(text)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func openImagePicker(_ mediaType: Settings.Fetch.Assets.MediaTypes, forAddMore: Bool = false) {
        let imagePicker = ImagePickerController()
        imagePicker.settings.selection.max = (10 - self.viewModel.imageAndVideoAttachments.count)
        imagePicker.settings.theme.selectionStyle = .numbered
        imagePicker.settings.fetch.assets.supportedMediaTypes = forAddMore ? [.image, .video] : [mediaType]
        imagePicker.settings.selection.unselectOnReachingMax = true
        self.viewModel.currentSelectedUploadeType = mediaType == .image ? .image : .video
        let start = Date()
        self.presentImagePicker(imagePicker, select: {[weak self] (asset) in
            asset.getURL { responseURL in
                guard let url = responseURL else {return }
                let mediaType: CreatePostViewModel.AttachmentUploadType = asset.mediaType == .image ? .image : .video
                self?.viewModel.addImageVideoAttachment(fileUrl: url, type: mediaType)
            }
        }, deselect: {[weak self] (asset) in
            asset.getURL { responseURL in
                self?.viewModel.imageAndVideoAttachments.removeAll(where: {$0.url == responseURL?.absoluteString})
            }
        }, cancel: { (assets) in
        }, finish: {[weak self] (assets) in
            self?.viewModel.currentSelectedUploadeType =  (self?.viewModel.imageAndVideoAttachments.count ?? 0) > 0 ? .image : .unknown
            self?.reloadCollectionView()
            
        }, completion: {
            let finish = Date()
            print(finish.timeIntervalSince(start))
        })
    }
    
    func openDocumentPicker() {
        let types: [String] = [
            "com.adobe.pdf"
        ]
        let documentPicker = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.viewModel.currentSelectedUploadeType = .document
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    @objc func addMoreAction() {
        switch self.viewModel.currentSelectedUploadeType {
        case .image:
            openImagePicker(.image, forAddMore: true)
        case .video:
            openImagePicker(.video, forAddMore: true)
        case .document:
            openDocumentPicker()
        default:
            break
        }
    }
    
    func enablePostButton() {
        let imageVideoCount = self.viewModel.imageAndVideoAttachments.count != 0
        let documentCount = self.viewModel.documentAttachments.count != 0
        let captionText = !captionTextView.trimmedText().isEmpty
        postButtonItem?.isEnabled = imageVideoCount || documentCount || captionText
    }
}

extension CreatePostViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.viewModel.currentSelectedUploadeType {
        case .video, .image:
            return viewModel.imageAndVideoAttachments.count
        case .document:
            return viewModel.documentAttachments.count
        case .link:
            return  self.viewModel.linkAttatchment == nil ? 0 : 1
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var defaultCell = collectionView.dequeueReusableCell(withReuseIdentifier: "defaultCell", for: indexPath)
        switch self.viewModel.currentSelectedUploadeType {
        case .link:
            if let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: LinkCollectionViewCell.cellIdentifier, for: indexPath) as? LinkCollectionViewCell {
                let linkAttachment = self.viewModel.linkAttatchment
                cell.setupLinkCell(linkAttachment?.title, description: linkAttachment?.description, link: linkAttachment?.url, linkThumbnailUrl: linkAttachment?.linkThumbnailUrl)
                cell.delegate = self
                defaultCell = cell
            }
        case .video, .image:
            let item = self.viewModel.imageAndVideoAttachments[indexPath.row]
            if  item.fileType == .image,
                let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.cellIdentifier, for: indexPath) as? ImageCollectionViewCell {
                cell.setupImageVideoView(self.viewModel.imageAndVideoAttachments[indexPath.row].url)
                cell.delegate = self
                defaultCell = cell
            } else if item.fileType == .video,
                      let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionViewCell.cellIdentifier, for: indexPath) as? VideoCollectionViewCell,
                      let url = item.url {
                cell.setupVideoData(url: url)
                cell.delegate = self
                defaultCell = cell
            }
            
        case .document:
            let item = self.viewModel.documentAttachments[indexPath.row]
            if  let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: DocumentCollectionCell.cellIdentifier, for: indexPath) as? DocumentCollectionCell {
                cell.setupDocumentCell(item.attachmentName(), documentDetails: item.attachmentDetails())
                cell.delegate = self
                defaultCell = cell
            }
        default:
            break
        }
        return defaultCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch self.viewModel.currentSelectedUploadeType {
        case .link, .image, .video:
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        case .document:
            return CGSize(width: UIScreen.main.bounds.width, height: 90)
        default:
            break
        }
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .zero
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        .zero
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl?.currentPage = Int(scrollView.contentOffset.x  / self.view.frame.width)
    }
}

extension CreatePostViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.attachmentUploadTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.text = viewModel.attachmentUploadTypes[indexPath.row].rawValue
        switch viewModel.attachmentUploadTypes[indexPath.row] {
        case .image:
            cell.imageView?.tintColor = .orange
            cell.imageView?.image = UIImage(systemName: "photo")
        case .video:
            cell.imageView?.tintColor = .blue
            cell.imageView?.image = UIImage(systemName: "video.fill")
        case .document:
            cell.imageView?.image = UIImage(systemName: "paperclip")
        default:
            return cell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.attachmentUploadTypes[indexPath.row] {
        case .image:
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Post.clickedOnAttachment, eventProperties: ["type": "image"])
            openImagePicker(.image)
        case .video:
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Post.clickedOnAttachment, eventProperties: ["type": "video"])
            openImagePicker(.video)
        case .document:
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Post.clickedOnAttachment, eventProperties: ["type": "file"])
            openDocumentPicker()
        default:
            break
        }
    }
}

extension CreatePostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = true
        enablePostButton()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        enablePostButton()
        taggingUserList.textViewDidChange(textView)
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        taggingUserList.textViewDidChangeSelection(textView)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        enablePostButton()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        placeholderLabel.isHidden = true
        if (self.viewModel.currentSelectedUploadeType == .unknown || self.viewModel.currentSelectedUploadeType == .link) && (self.viewModel.currentSelectedUploadeType != .dontAttachOgTag) {
            debounceForDecodeLink?.invalidate()
            debounceForDecodeLink = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {[weak self] _ in
                let enteredString = textView.text + text
                self?.viewModel.parseMessageForLink(message: enteredString)
            }
        }
        self.typeTextRangeInTextView = range
        if text != "" {
            typeTextRangeInTextView?.location += 1
        }
        taggingUserList.textView(textView, shouldChangeTextIn: range, replacementText: text)
        enablePostButton()
        let numLines = Int(textView.contentSize.height/textView.font!.lineHeight)
        textView.isScrollEnabled = (textView.bounds.height >= 145) && (numLines > 6)
        return true
    }
}

extension CreatePostViewController: AttachmentCollectionViewCellDelegate {
    func removeAttachment(_ cell: UICollectionViewCell) {
        guard let indexPath = self.attachmentCollectionView.indexPath(for: cell) else { return }
        print(indexPath.row)
        switch self.viewModel.currentSelectedUploadeType {
        case .video, .image:
            self.viewModel.imageAndVideoAttachments.remove(at: indexPath.row)
            reloadAttachmentsView()
        case .document:
            self.viewModel.documentAttachments.remove(at: indexPath.row)
            reloadAttachmentsView()
        case .link:
            self.viewModel.linkAttatchment = nil
            self.viewModel.currentSelectedUploadeType = .dontAttachOgTag
            reloadAttachmentsView()
        default:
            break
        }
        if self.viewModel.documentAttachments.count == 0 && self.viewModel.imageAndVideoAttachments.count == 0 && (self.viewModel.currentSelectedUploadeType != .dontAttachOgTag) {
            self.viewModel.currentSelectedUploadeType = .unknown
            self.uploadActionViewHeightConstraint.constant = uploadActionsHeight
        }
    }
}

//MARK: - Ext. Delegate DocumentPicker
extension CreatePostViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        print(url)
        self.viewModel.addDocumentAttachment(fileUrl: url)
        controller.dismiss(animated: true)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

//MARK: - Delegate view model

extension CreatePostViewController: CreatePostViewModelDelegate {
    
    func showError(errorMessage: String?) {
        self.showErrorAlert(message: errorMessage)
    }
    
    func reloadAttachmentsView() {
        var isCountGreaterThanZero = false
        switch viewModel.currentSelectedUploadeType {
        case .image, .video:
             isCountGreaterThanZero = viewModel.imageAndVideoAttachments.count > 0
            self.uploadActionViewHeightConstraint.constant = isCountGreaterThanZero ? 0 : uploadActionsHeight
            self.collectionSuperViewHeightConstraint.constant = 393
            let imageCount = viewModel.imageAndVideoAttachments.count
            pageControl?.superview?.isHidden = imageCount < 2
            pageControl?.numberOfPages = imageCount
        case .document:
             isCountGreaterThanZero = viewModel.documentAttachments.count > 0
            self.uploadActionViewHeightConstraint.constant = isCountGreaterThanZero ? 0 : uploadActionsHeight
            let docHeight = CGFloat(viewModel.documentAttachments.count * 90)
            self.collectionSuperViewHeightConstraint.constant = docHeight < 393 ? 393 : docHeight
            pageControl?.superview?.isHidden = true
        default:
            self.uploadActionViewHeightConstraint.constant = uploadActionsHeight
            self.collectionSuperViewHeightConstraint.constant = 393
            pageControl?.superview?.isHidden = true
            break
        }
        enablePostButton()
        attachmentCollectionView.reloadData()
        addMoreButton.superview?.isHidden = !isCountGreaterThanZero
        if hasReachedMaximumAttachment() {
            addMoreButton.superview?.isHidden = true
            self.uploadActionViewHeightConstraint.constant = 0
        }
    }
    
    func reloadCollectionView() {
        reloadAttachmentsView()
    }
    
    func reloadActionTableView() {
        self.uploadActionsTableView.reloadData()
    }
    
    func hasReachedMaximumAttachment() -> Bool {
        (viewModel.imageAndVideoAttachments.count > 0 && viewModel.imageAndVideoAttachments.count == 10) || (viewModel.documentAttachments.count > 0 && viewModel.documentAttachments.count == 10)
    }
    
    func showHideTopicView(topics: [TopicViewCollectionCell.ViewModel]) {
        topicFeedView.configure(with: topics)
    }
}

extension CreatePostViewController: TaggedUserListDelegate {
    
    func didChangedTaggedList(taggedList: [TaggedUser]) {
        hideTaggingViewContainer()
        viewModel.taggedUsers = taggedList
    }

    func hideTaggingViewContainer() {
        isTaggingViewHidden = true
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .showHideTransitionViews, animations: {
            self.taggingListViewContainer.alpha = 0
            self.taggingViewHeightConstraint.constant = 48
            self.view.layoutIfNeeded()
        }) { finished in
        }
    }
    
    func unhideTaggingViewContainer(heightValue: CGFloat) {
        if !isReloadTaggingListView {return}
        isTaggingViewHidden = false
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlUp, animations: {
            self.taggingListViewContainer.alpha = 1
            self.taggingViewHeightConstraint.constant = heightValue
            self.taggingUserList.frame = self.taggingListViewContainer.bounds
            self.view.layoutIfNeeded()
            
        }) { finished in
        }
    }
}

// MARK: SelectTopicViewDelegate
extension CreatePostViewController: SelectTopicViewDelegate {
    func updateSelection(with data: [TopicFeedDataModel]) {
        viewModel.updateSelectedTopics(with: data)
    }
}

// MARK: LMTopicViewDelegate
extension CreatePostViewController: LMTopicViewDelegate {
    func didTapEditTopics() {
        let vc = SelectTopicViewController(selectedTopics: viewModel.selectedTopics, isShowAllTopics: false, delegate: self)
        navigationController?.pushViewController(vc, animated: true)
    }
}

//
//  HomeFeedViewModel.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 30/03/23.
//

import Foundation
import LikeMindsFeed

protocol HomeFeedViewModelDelegate: AnyObject {
    func didReceivedFeedData(success: Bool)
    func didReceivedMemberState()
    func reloadSection(_ indexPath: IndexPath)
    func updateNotificationFeedCount(_ count: Int)
    func updateTopicFeedView(with cells: [HomeFeedTopicCell.ViewModel], isShowTopicFeed: Bool)
}

class HomeFeedViewModel: BaseViewModel {
    weak var delegate: HomeFeedViewModelDelegate?
    var feeds: [PostFeedDataView] = []
    var currentPage: Int = 1
    var pageSize = 20
    var isFeedLoading: Bool = false
    var isReachedLastPage: Bool = false
    private var isShowTopicFeed = false
    var selectedTopics: [TopicFeedDataModel] = []
    private var selectedTopicIds: [String] {
        selectedTopics.map {
            $0.topicID
        }
    }

    func getFeed() {
        self.isFeedLoading = true
        let requestFeed = GetFeedRequest.builder()
            .page(currentPage)
            .pageSize(pageSize)
            .topics(selectedTopicIds)
            .build()
        LMFeedClient.shared.getFeed(requestFeed) { [weak self] result in
            self?.isFeedLoading = false
            if result.success,
               let postsData = result.data?.posts,
               let users = result.data?.users, !postsData.isEmpty {
                let topics: [TopicFeedResponse.TopicResponse] = result.data?.topics?.compactMap {
                    $0.value
                } ?? []
                self?.prepareHomeFeedDataView(postsData, users: users, topics: topics)
                self?.currentPage += 1
            } else {
                self?.isReachedLastPage = result.data?.posts?.isEmpty ?? false
                print(result.errorMessage ?? "")
                self?.delegate?.didReceivedFeedData(success: false)
                self?.postErrorMessageNotification(error: result.errorMessage)
            }
        }
    }
    
    func getTopics() {
        let request = TopicFeedRequest.builder()
            .setEnableState(true)
            .build()
        
        LMFeedClient.shared.getTopicFeed(request) { [weak self] response in
            self?.isShowTopicFeed = !(response.data?.topics?.isEmpty ?? true)
            self?.setupTopicFeed()
        }
    }
    
    func pullToRefresh() {
        self.currentPage = 1
        getFeed()
    }
    
    func refreshFeedDataObject(_ postData: PostFeedDataView) {
        guard let index = self.feeds.firstIndex(where: {$0.postId == postData.postId}) else {return }
        self.feeds[index] = postData
    }
    
    func getMemberState() {
        LMFeedClient.shared.getMemberState() { [weak self] result in
            print(result)
            if result.success,
               let memberState = result.data {
                LocalPrefrerences.saveObject(memberState, forKey: LocalPreferencesKey.memberStates)
            } else {
                print(result.errorMessage ?? "")
            }
            self?.delegate?.didReceivedMemberState()
        }
    }
    
    func likePost(postId: String) {
        let request = LikePostRequest.builder()
            .postId(postId)
            .build()
        LMFeedClient.shared.likePost(request) { [weak self] response in
            if !response.success {
                guard let index = self?.feeds.firstIndex(where: {$0.postId == postId}), let feed = self?.feeds[index] else {
                    return
                }
                let isLike = !(feed.isLiked)
                feed.isLiked = isLike
                feed.likedCount += isLike ? 1 : -1
                self?.delegate?.reloadSection(IndexPath(row: index, section: 0))
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
        }
    }
    
    func savePost(postId: String) {
        let request = SavePostRequest.builder()
            .postId(postId)
            .build()
        LMFeedClient.shared.savePost(request) { [weak self] response in
            if !response.success {
                guard let index = self?.feeds.firstIndex(where: {$0.postId == postId}), let feed = self?.feeds[index] else {
                    return
                }
                feed.isSaved = !(feed.isSaved)
                self?.delegate?.reloadSection(IndexPath(row: index, section: 0))
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
        }
    }
    
    func pinUnpinPost(postId: String) {
        let request = PinPostRequest.builder()
            .postId(postId)
            .build()
        LMFeedClient.shared.pinPost(request) {[weak self] response in
            if response.success {
                guard let index = self?.feeds.firstIndex(where: {$0.postId == postId}), let feed = self?.feeds[index] else {
                    return
                }
                feed.isPinned = !(feed.isPinned)
                feed.updatePinUnpinMenu()
                self?.delegate?.reloadSection(IndexPath(row: index, section: 0))
            } else {
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
        }
    }
    
    func updateEditedPost(postDetail: PostFeedDataView?) -> Int {
        guard let postDetail = postDetail, let index = feeds.firstIndex(where: {$0.postId == postDetail.postId}) else { return 0 }
        feeds[index] = postDetail
        return index
    }
    
    func getUnreadNotificationCount() {
        LMFeedClient.shared.getUnreadNotificationCount() {[weak self] response in
            if response.success, let count = response.data?.count {
                print("notification cout: \(count)")
                self?.delegate?.updateNotificationFeedCount(count)
            } else {
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
        }
    }
    
    func prepareHomeFeedDataView(_ posts: [Post], users: [String: User], topics: [TopicFeedResponse.TopicResponse]) {
        if self.currentPage > 1 {
            feeds.append(contentsOf: posts.map { PostFeedDataView(post: $0, user: users[$0.uuid ?? ""], topics: topics)})
        } else {
            feeds = posts.map { PostFeedDataView(post: $0, user: users[$0.uuid ?? ""], topics: topics)}
        }
        delegate?.didReceivedFeedData(success:  true)
    }
    
    func hasRightForCreatePost() -> Bool {
        if self.isAdmin() { return true }
        guard let rights = LocalPrefrerences.getMemberStateData()?.memberRights,
              let right = rights.filter({$0.state == .createPost}).first else {
            return true
        }
        return right.isSelected ?? true
    }
    
    func isAdmin() -> Bool {
        guard let member = LocalPrefrerences.getMemberStateData()?.member else { return false }
        return member.state == 1
    }
    
    func isOwnPost(index: Int) -> Bool {
        guard let member = LocalPrefrerences.getMemberStateData()?.member else { return false }
        let post = feeds[index]
        return post.postByUser?.uuid == member.clientUUID
    }
    
    func trackPostActionEvent(postId: String, creatorId: String, eventName: String, postType: String) {
        LMFeedAnalytics.shared.track(eventName: eventName,
                                     eventProperties:["created_by_id": creatorId,
                                                      "post_id": postId,
                                                      "post_type": postType
        ])
    }
    
    func updateTopics(with list: [TopicFeedDataModel]) {
        selectedTopics = list
        updateFeed()
    }
    
    func removeTopic(for topicId: String) {
        guard let idx = selectedTopics.firstIndex(where: { $0.topicID == topicId }) else { return }
        selectedTopics.remove(at: idx)
        updateFeed()
    }
    
    func removeAllTopics() {
        selectedTopics.removeAll()
        updateFeed()
    }
}

private extension HomeFeedViewModel {
    func setupTopicFeed() {
        let transformedCells: [HomeFeedTopicCell.ViewModel] = selectedTopics.map {
            .init(topicName: $0.title, topicID: $0.topicID)
        }
        
        delegate?.updateTopicFeedView(with: transformedCells, isShowTopicFeed: isShowTopicFeed)
    }
    
    func updateFeed() {
        currentPage = 1
        feeds.removeAll()
        setupTopicFeed()
        getFeed()
        delegate?.didReceivedFeedData(success: true)
    }
}

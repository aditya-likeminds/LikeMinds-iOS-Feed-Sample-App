//
//  NotificationFeedViewController.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 22/05/23.
//

import UIKit

class NotificationFeedViewController: BaseViewController {
    
    let notificationFeedTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    } ()
    
    let refreshControl = UIRefreshControl()
    var bottomLoadSpinner: UIActivityIndicatorView!
    let viewModel = NotificationFeedViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        viewModel.delegate = self
        setupTableView()
        setTitleAndSubtile(title: "Notifications", subTitle: nil)
        viewModel.getNotificationFeed()
        LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Notification.pageOpened, eventProperties: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorMessage), name: .errorInApi, object: nil)
    }
    
    func setupTableView() {
        self.view.addSubview(notificationFeedTableView)
        notificationFeedTableView.translatesAutoresizingMaskIntoConstraints = false
        notificationFeedTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        notificationFeedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        notificationFeedTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        notificationFeedTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        notificationFeedTableView.register(UINib(nibName: NotificationFeedTableViewCell.nibName, bundle: NotificationFeedTableViewCell.bundle), forCellReuseIdentifier: NotificationFeedTableViewCell.nibName)
        notificationFeedTableView.delegate = self
        notificationFeedTableView.dataSource = self
        notificationFeedTableView.separatorStyle = .none
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
        notificationFeedTableView.refreshControl = refreshControl
        setupSpinner()
    }
    
    func setupSpinner(){
        bottomLoadSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height:40))
        bottomLoadSpinner.color = .gray
        self.notificationFeedTableView.tableFooterView = bottomLoadSpinner
        bottomLoadSpinner.hidesWhenStopped = true
    }
    
    func showAndHideBottomSpinner(_ show: Bool) {
        if show {
            bottomLoadSpinner.startAnimating()
            self.notificationFeedTableView.tableFooterView = bottomLoadSpinner
        } else {
            bottomLoadSpinner.stopAnimating()
            self.notificationFeedTableView.tableFooterView = nil
        }
    }
    
    @objc func refreshFeed() {
        viewModel.pullToRefreshData()
    }

}

extension NotificationFeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.activities.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationFeedTableViewCell.nibName, for: indexPath) as! NotificationFeedTableViewCell
        cell.setupNotificationFeedCell(dataView: viewModel.activities[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activity = viewModel.activities[indexPath.row]
        activity.isRead = true
        tableView.reloadRows(at: [indexPath], with: .none)
        self.viewModel.markReadNotification(activityId: activity.activity.id)
        guard let cta = activity.activity.cta else {
            return
        }
        let route = Routes(route: cta)
        route.fetchRoute {[weak self] viewController in
            guard let viewController = viewController else { return }
            self?.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {}
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if offsetY > contentHeight - (scrollView.frame.height + 60) && !viewModel.isNotificationFeedLoading
        {
            viewModel.getNotificationFeed()
        }
    }
    
}

extension NotificationFeedViewController: NotificationFeedTableViewCellDelegate {
    
    func menuButtonClicked(_ cell: UITableViewCell) {
        print("menu clicked")
    }
    
}

extension NotificationFeedViewController: NotificationFeedViewModelDelegate {
    
    func didReceiveNotificationFeedsResponse() {
        if viewModel.activities.count == 0 {
            let emptyPlaceholder = UIImage(named: ImageIcon.emptyDataImage, in: Bundle(for: NotificationFeedViewController.self), with: nil) ?? UIImage()
            notificationFeedTableView.setEmptyMessage(StringConstant.nofiticationFeedDataNotFound, emptyImage: emptyPlaceholder)
        } else {
            notificationFeedTableView.restore()
        }
        bottomLoadSpinner.stopAnimating()
        refreshControl.endRefreshing()
        notificationFeedTableView.reloadData()
    }
    
    func didReceiveMarkReadNotificationResponse() {
        
    }

}

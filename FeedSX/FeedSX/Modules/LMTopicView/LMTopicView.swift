//
//  LMTopicView.swift
//  FeedSX
//
//  Created by Devansh Mohata on 22/09/23.
//

import UIKit

protocol LMTopicViewDelegate: AnyObject {
    func didTapRemoveCell(topicId: String)
    func didTapEditTopics()
}

extension LMTopicViewDelegate {
    func didTapRemoveCell(topicId: String) { }
    func didTapEditTopics() { }
}

final class LMTopicView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var topicCollectionView: DynamicCollectionView! {
        didSet {
            topicCollectionView.dataSource = self
            topicCollectionView.delegate = self
            topicCollectionView.translatesAutoresizingMaskIntoConstraints = false
            topicCollectionView.register(UINib(nibName: TopicViewCollectionCell.identifier, bundle: Bundle(for: TopicViewCollectionCell.self)), forCellWithReuseIdentifier: TopicViewCollectionCell.identifier)
            topicCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "defaultCell")
            topicCollectionView.collectionViewLayout = TagsLayout()
            topicCollectionView.isScrollEnabled = false
        }
    }
    @IBOutlet private weak var sepratorView: UIView!
    
    private var topics: [TopicViewCollectionCell.ViewModel] = []
    
    weak var delegate: LMTopicViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        Bundle(for: LMTopicView.self).loadNibNamed("LMTopicView", owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configure(with topics: [TopicViewCollectionCell.ViewModel], isSepratorShown: Bool = true) {
        self.topics = topics
        topicCollectionView.reloadData()
        sepratorView.isHidden = !isSepratorShown
        layoutIfNeeded()
    }
}

extension LMTopicView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        topics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TopicViewCollectionCell.identifier, for: indexPath) as? TopicViewCollectionCell {
            cell.configure(with: topics[indexPath.row]) { [weak self] in
                if self?.topics[indexPath.row].isEditCell == true {
                    self?.delegate?.didTapEditTopics()
                }
            }
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let data = topics[indexPath.row]
        let size = data.title?.sizeOfString(with: LMBranding.shared.font(14, .regular)) ?? .zero
        var width = size.width
        
        if data.image == "pencil" {
            width = 24
        }
        
        return .init(width: width, height: 50)
    }
}


// MARK: DynamicCollectionView
class DynamicCollectionView: UICollectionView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        return contentSize
    }
}

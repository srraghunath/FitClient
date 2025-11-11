//
//  ScheduleCardCell.swift
//  FitClient
//
//  Created by admin6 on 11/11/25.
//

import UIKit

protocol ScheduleCardCellDelegate: AnyObject {
    func scheduleCardCell(_ cell: ScheduleCardCell, didTapExpandFor item: ScheduleItem)
}

class ScheduleCardCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var expandArrowImageView: UIImageView!
    @IBOutlet private weak var expandButton: UIButton!
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var expandedContentView: UIView!
    @IBOutlet private weak var expandedContentHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Properties
    weak var delegate: ScheduleCardCellDelegate?
    private var scheduleItem: ScheduleItem?
    private var isCurrentlyExpanded: Bool = false
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Card styling
        cardView.backgroundColor = UIColor(hex: "#303131")
        cardView.layer.cornerRadius = 12
        cardView.clipsToBounds = true
        
        // Labels styling
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = .white
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        
        // Arrow styling
        expandArrowImageView.tintColor = .white
        expandArrowImageView.image = UIImage(systemName: "chevron.down")
        
        // Button setup
        expandButton.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
        
        // Hide expanded content initially
        expandedContentView?.isHidden = true
    }
    
    // MARK: - Configure
    func configure(with item: ScheduleItem) {
        self.scheduleItem = item
        self.isCurrentlyExpanded = item.isExpanded
        
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        
        updateExpandedState(animated: false)
    }
    
    // MARK: - Actions
    @objc private func expandButtonTapped() {
        guard let item = scheduleItem else { return }
        
        isCurrentlyExpanded.toggle()
        var updatedItem = item
        updatedItem.isExpanded = isCurrentlyExpanded
        
        delegate?.scheduleCardCell(self, didTapExpandFor: updatedItem)
        updateExpandedState(animated: true)
    }
    
    // MARK: - Private Methods
    private func updateExpandedState(animated: Bool) {
        let rotationAngle: CGFloat = isCurrentlyExpanded ? CGFloat.pi : 0
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.expandArrowImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
                self.expandedContentView?.alpha = self.isCurrentlyExpanded ? 1 : 0
            }
        } else {
            self.expandArrowImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
            self.expandedContentView?.alpha = isCurrentlyExpanded ? 1 : 0
        }
        
        expandedContentView?.isHidden = !isCurrentlyExpanded
    }
}

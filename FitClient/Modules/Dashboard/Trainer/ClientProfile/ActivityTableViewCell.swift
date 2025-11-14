import UIKit

class ActivityTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet private weak var cardBackgroundView: UIView!
    @IBOutlet private weak var activityIconContainer: UIView!
    @IBOutlet private weak var activityIconImageView: UIImageView!
    @IBOutlet private weak var activityTitleLabel: UILabel!
    @IBOutlet private weak var activityCategoryLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    
    // MARK: - Setup
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cardBackgroundView.backgroundColor = .cardBackground
        cardBackgroundView.layer.cornerRadius = 12
        cardBackgroundView.layer.masksToBounds = true
        contentView.clipsToBounds = false
        selectionStyle = .none
        
        activityIconContainer.backgroundColor = UIColor(named: "SecondaryBackground") ?? .darkGray
        activityIconContainer.layer.cornerRadius = 8
        activityIconContainer.layer.masksToBounds = true
        
        activityTitleLabel.textColor = .textPrimary
        activityTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        activityTitleLabel.textAlignment = .left
        activityTitleLabel.numberOfLines = 0
        activityTitleLabel.lineBreakMode = .byWordWrapping
        activityTitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        activityTitleLabel.setContentHuggingPriority(.required, for: .vertical)
        activityTitleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        activityCategoryLabel.textColor = .textSecondary
        activityCategoryLabel.font = .systemFont(ofSize: 14, weight: .regular)
        activityCategoryLabel.textAlignment = .left
        activityCategoryLabel.numberOfLines = 0
        activityCategoryLabel.lineBreakMode = .byWordWrapping
        activityCategoryLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        activityCategoryLabel.setContentHuggingPriority(.required, for: .vertical)
        activityCategoryLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        timeLabel.textColor = .primaryGreen
        timeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        timeLabel.textAlignment = .right
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    func configure(with activity: ClientActivity) {
        activityTitleLabel.text = activity.type
        activityCategoryLabel.text = activity.category
        timeLabel.text = activity.daysAgoText
        
        // Set icon based on category
        let iconName = getIconName(for: activity.category)
        activityIconImageView.image = UIImage(systemName: iconName)
        activityIconImageView.tintColor = .primaryGreen
    }
    
    private func getIconName(for category: String) -> String {
        switch category.lowercased() {
        case "strength training":
            return "dumbbell.fill"
        case "cardio":
            return "figure.run"
        case "flexibility":
            return "figure.flexibility"
        default:
            return "figure.strengthtraining.traditional"
        }
    }
}

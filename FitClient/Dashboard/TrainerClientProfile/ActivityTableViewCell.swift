import UIKit

class ActivityTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
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
        backgroundColor = .black
        selectionStyle = .none
        
        activityIconContainer.backgroundColor = UIColor(named: "SecondaryBackground") ?? .darkGray
        activityIconContainer.layer.cornerRadius = 8
        
        activityTitleLabel.textColor = .textPrimary
        activityTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        activityCategoryLabel.textColor = .textSecondary
        activityCategoryLabel.font = .systemFont(ofSize: 14, weight: .regular)
        
        timeLabel.textColor = .textSecondary
        timeLabel.font = .systemFont(ofSize: 14, weight: .regular)
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
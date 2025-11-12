//
//  DietCardCell.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

class DietCardCell: UITableViewCell {
    
    @IBOutlet weak var mealImageView: UIImageView!
    @IBOutlet weak var mealTypeLabel: UILabel!
    @IBOutlet weak var mealNameLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        selectionStyle = .none
        
        // Image
        mealImageView.contentMode = .scaleAspectFill
        mealImageView.clipsToBounds = true
        mealImageView.layer.cornerRadius = 8
        mealImageView.backgroundColor = .backgroundLight
        
        // Labels
        mealTypeLabel.textColor = .primaryGreen
        mealTypeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        
        mealNameLabel.textColor = .textPrimary
        mealNameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        caloriesLabel.textColor = .textSecondary
        caloriesLabel.font = .systemFont(ofSize: 14, weight: .regular)
        
        timeLabel.textColor = .textTertiary
        timeLabel.font = .systemFont(ofSize: 12, weight: .regular)
    }
    
    func configure(with meal: TodayMeal) {
        mealTypeLabel.text = meal.mealType.uppercased()
        mealNameLabel.text = meal.name
        caloriesLabel.text = meal.calories
        timeLabel.text = meal.time
        
        // Load image from URL
        if let url = URL(string: meal.imageUrl) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.mealImageView.image = image
                    }
                }
            }.resume()
        }
    }
}

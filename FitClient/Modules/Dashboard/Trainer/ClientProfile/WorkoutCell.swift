//
//  WorkoutCell.swift
//  FitClient
//

import UIKit

// Simple image cache to prevent reloading
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

class WorkoutCell: UITableViewCell {
    
    @IBOutlet weak var workoutImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var checkboxButton: UIButton!  // Native iOS checkbox
    
    private var imageLoadTask: URLSessionDataTask?
    private var currentWorkoutId: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        // Don't clear image - will be set from cache or reloaded
        currentWorkoutId = nil
    }
    
    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        selectionStyle = .none
        
        workoutImageView.layer.cornerRadius = 8
        workoutImageView.clipsToBounds = true
        workoutImageView.contentMode = .scaleAspectFill
        
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        descriptionLabel.textColor = UIColor(hex: "#d7ccc8")
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.numberOfLines = 2
        
        // Configure native iOS checkbox button
        checkboxButton.isUserInteractionEnabled = false  // Cell tap handles selection
        checkboxButton.tintColor = .primaryGreen
    }
    
    func configure(with workout: Workout) {
        currentWorkoutId = workout.id
        nameLabel.text = workout.name
        if let summary = workout.targetSummary, workout.isSelected {
            descriptionLabel.text = summary
        } else {
            descriptionLabel.text = workout.description
        }
        
        // Configure checkbox with proper SF Symbol and color
        if workout.isSelected {
            // Selected state: filled checkbox with checkmark
            checkboxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
            checkboxButton.tintColor = .primaryGreen
        } else {
            // Unselected state: empty square
            checkboxButton.setImage(UIImage(systemName: "square"), for: .normal)
            checkboxButton.tintColor = UIColor.white.withAlphaComponent(0.6)
        }
        
        // Ensure proper size
        checkboxButton.imageView?.contentMode = .scaleAspectFit
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium, scale: .large)
        checkboxButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        
        // Load image from cache or network
        loadImage(from: workout.imageUrl, workoutId: workout.id)
    }
    
    private func loadImage(from urlString: String, workoutId: String) {
        // Check cache first
        if let cachedImage = ImageCache.shared.getImage(forKey: workoutId) {
            workoutImageView.image = cachedImage
            return
        }
        
        // Load from network
        guard let url = URL(string: urlString) else { return }
        
        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            // Cache the image
            ImageCache.shared.setImage(image, forKey: workoutId)
            
            DispatchQueue.main.async {
                // Only set if still showing the same workout
                if self?.currentWorkoutId == workoutId {
                    self?.workoutImageView.image = image
                }
            }
        }
        imageLoadTask?.resume()
    }
}

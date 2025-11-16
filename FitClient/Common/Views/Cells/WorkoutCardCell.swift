//
//  WorkoutCardCell.swift
//  FitClient
//
//  Created by admin8 on 13/11/25.
//

import UIKit

class WorkoutCardCell: UITableViewCell {
    
    @IBOutlet weak var workoutImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var checkboxButton: UIButton!
    
    private var imageLoadTask: URLSessionDataTask?
    private var currentWorkoutId: String?
    var showCheckbox: Bool = false {
        didSet {
            checkboxButton?.isHidden = !showCheckbox
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        currentWorkoutId = nil
    }
    
    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        selectionStyle = .none
        
        // Image view
        workoutImageView.layer.cornerRadius = 8
        workoutImageView.clipsToBounds = true
        workoutImageView.contentMode = .scaleAspectFill
        
        // Labels
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        descriptionLabel.textColor = UIColor(hex: "#d7ccc8")
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        // Checkbox
        checkboxButton.isUserInteractionEnabled = false
        checkboxButton.tintColor = .primaryGreen
        checkboxButton.isHidden = !showCheckbox
    }
    
    func configure(with workout: TodayWorkout, showCheckbox: Bool = false) {
        self.showCheckbox = showCheckbox
        currentWorkoutId = workout.id
        nameLabel.text = workout.name
        descriptionLabel.text = workout.reps
        

        
        if showCheckbox {
            // Configure checkbox if needed
            checkboxButton.setImage(UIImage(systemName: "square"), for: .normal)
            checkboxButton.tintColor = UIColor.white.withAlphaComponent(0.6)
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium, scale: .large)
            checkboxButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        }
        
        loadImage(from: workout.imageUrl, workoutId: workout.id)
    }
    
    func configure(with workout: Workout) {
        self.showCheckbox = true
        currentWorkoutId = workout.id
        nameLabel.text = workout.name
        descriptionLabel.text = workout.description
        
        if workout.isSelected {
            checkboxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
            checkboxButton.tintColor = .primaryGreen
        } else {
            checkboxButton.setImage(UIImage(systemName: "square"), for: .normal)
            checkboxButton.tintColor = UIColor.white.withAlphaComponent(0.6)
        }
        
        checkboxButton.imageView?.contentMode = .scaleAspectFit
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium, scale: .large)
        checkboxButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        
        loadImage(from: workout.imageUrl, workoutId: workout.id)
    }
    
    private func loadImage(from urlString: String, workoutId: String) {
        // Check cache first
        if let cachedImage = ImageCache.shared.getImage(forKey: workoutId) {
            print("✅ [WorkoutCardCell] Image loaded from cache for: \(workoutId)")
            workoutImageView.image = cachedImage
            return
        }
        
        // Load from network
        guard let url = URL(string: urlString) else {
            print("❌ [WorkoutCardCell] Invalid URL: \(urlString)")
            return
        }
        
        print("🌐 [WorkoutCardCell] Loading image from network: \(urlString)")
        
        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ [WorkoutCardCell] Image load error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("❌ [WorkoutCardCell] Failed to create image from data")
                return
            }
            
            print("✅ [WorkoutCardCell] Image loaded successfully for: \(workoutId)")
            
            // Cache the image
            ImageCache.shared.setImage(image, forKey: workoutId)
            
            DispatchQueue.main.async {
                if self?.currentWorkoutId == workoutId {
                    self?.workoutImageView.image = image
                    print("✅ [WorkoutCardCell] Image set to imageView for: \(workoutId)")
                }
            }
        }
        imageLoadTask?.resume()
    }
}

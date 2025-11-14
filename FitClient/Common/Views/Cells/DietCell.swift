//
//  DietCell.swift
//  FitClient
//

import UIKit

class DietCell: UITableViewCell {
    
    @IBOutlet weak var dietImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nutritionLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    private var imageLoadTask: URLSessionDataTask?
    private var currentDietId: String?
    private var onQuantityChanged: ((Int) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        currentDietId = nil
        onQuantityChanged = nil
    }
    
    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        selectionStyle = .none
        
        containerView.backgroundColor = UIColor(hex: "#1a1a1a")
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        
        dietImageView.layer.cornerRadius = 8
        dietImageView.clipsToBounds = true
        dietImageView.contentMode = .scaleAspectFill
        
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        nutritionLabel.textColor = UIColor(hex: "#d7ccc8")
        nutritionLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        nutritionLabel.numberOfLines = 2
        
        // Configure stepper
        quantityStepper.minimumValue = 1
        quantityStepper.maximumValue = 10
        quantityStepper.stepValue = 1
        quantityStepper.tintColor = .primaryGreen
        quantityStepper.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)
        
        quantityLabel.textColor = .primaryGreen
        quantityLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        quantityLabel.textAlignment = .right
    }
    
    func configure(with diet: Diet, onQuantityChanged: @escaping (Int) -> Void) {
        currentDietId = diet.id
        self.onQuantityChanged = onQuantityChanged
        
        nameLabel.text = diet.name
        
        // Format nutrition info: "150g | P: 25g | C: 40g | F: 10g | 350 cal"
        nutritionLabel.text = "\(diet.grams)g | P: \(String(format: "%.1f", diet.protein))g | C: \(String(format: "%.1f", diet.carbs))g | F: \(String(format: "%.1f", diet.fat))g | \(diet.calories) cal"
        
        // Configure selection state
        if diet.isSelected {
            containerView.backgroundColor = UIColor.primaryGreen.withAlphaComponent(0.15)
            containerView.layer.borderColor = UIColor.primaryGreen.cgColor
            containerView.layer.borderWidth = 1.5
            quantityStepper.isHidden = false
            quantityLabel.isHidden = false
            quantityStepper.value = Double(diet.quantity)
            quantityLabel.text = "Qty: \(diet.quantity)"
        } else {
            containerView.backgroundColor = UIColor(hex: "#1a1a1a")
            containerView.layer.borderWidth = 0
            quantityStepper.isHidden = true
            quantityLabel.isHidden = true
        }
        
        // Load image
        loadImage(from: diet.imageUrl, dietId: diet.id)
    }

    // Display-only configuration for client dashboard (no selection/stepper UI)
    func configureDisplayOnly(with diet: Diet) {
        currentDietId = diet.id
        onQuantityChanged = nil

        nameLabel.text = diet.name
        nutritionLabel.text = "\(diet.grams)g | P: \(String(format: "%.1f", diet.protein))g | C: \(String(format: "%.1f", diet.carbs))g | F: \(String(format: "%.1f", diet.fat))g | \(diet.calories) cal"

    // Always plain card for client; hide stepper but SHOW quantity value
        containerView.backgroundColor = UIColor(hex: "#1a1a1a")
        containerView.layer.borderWidth = 0
    quantityStepper.isHidden = true
    quantityLabel.isHidden = false
    quantityLabel.text = "\(diet.quantity)"

        loadImage(from: diet.imageUrl, dietId: diet.id)
    }
    
    @objc private func stepperValueChanged() {
        let newQuantity = Int(quantityStepper.value)
        quantityLabel.text = "Qty: \(newQuantity)"
        onQuantityChanged?(newQuantity)
    }
    
    private func loadImage(from urlString: String, dietId: String) {
        // Check cache first
        if let cachedImage = ImageCache.shared.getImage(forKey: dietId) {
            dietImageView.image = cachedImage
            return
        }
        
        // Load from network
        guard let url = URL(string: urlString) else {
            dietImageView.image = UIImage(systemName: "photo")
            return
        }
        
        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.dietImageView.image = UIImage(systemName: "photo")
                }
                return
            }
            
            // Cache the image
            ImageCache.shared.setImage(image, forKey: dietId)
            
            DispatchQueue.main.async {
                guard self?.currentDietId == dietId else { return }
                self?.dietImageView.image = image
            }
        }
        imageLoadTask?.resume()
    }
}

//
//  SliderCardCell.swift
//  FitClient
//
//  Created by admin6 on 11/11/25.
//

import UIKit

protocol SliderCardCellDelegate: AnyObject {
    func sliderCardCell(_ cell: SliderCardCell, didUpdateValue value: Double, for sliderItem: SliderItem)
}

class SliderCardCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    @IBOutlet private weak var minValueLabel: UILabel!
    @IBOutlet private weak var maxValueLabel: UILabel!
    @IBOutlet private weak var slider: UISlider!
    
    // MARK: - Properties
    weak var delegate: SliderCardCellDelegate?
    private var sliderItem: SliderItem?
    
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
        
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = UIColor(hex: "#aefe14")
        
        minValueLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        minValueLabel.textColor = .white
        
        maxValueLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        maxValueLabel.textColor = .white
        
        // Slider styling
        slider.tintColor = UIColor(hex: "#aefe14")
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }
    
    // MARK: - Configure
    func configure(with item: SliderItem) {
        self.sliderItem = item
        
        titleLabel.text = item.title
        valueLabel.text = String(format: "%.1f%@", item.currentValue, item.unit)
        minValueLabel.text = "0\(item.unit)"
        maxValueLabel.text = "\(Int(item.maxValue))\(item.unit)"
        
        slider.minimumValue = Float(item.minValue)
        slider.maximumValue = Float(item.maxValue)
        slider.value = Float(item.currentValue)
    }
    
    // MARK: - Actions
    @objc private func sliderValueChanged(_ sender: UISlider) {
        guard var item = sliderItem else { return }
        
        let newValue = Double(sender.value)
        item.updateValue(newValue)
        self.sliderItem = item
        
        valueLabel.text = String(format: "%.1f%@", item.currentValue, item.unit)
        
        delegate?.sliderCardCell(self, didUpdateValue: newValue, for: item)
    }
}

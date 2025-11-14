//
//  HeatmapCell.swift
//  FitClient
//
//  Created by admin on 14/11/25.
//

import UIKit

// MARK: - Heatmap Cell (Shared between Client and Trainer Progress Views)
class HeatmapCell: UICollectionViewCell {
    static let id = "HeatmapCell"
    private let box = UIView()
    private let dayLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        box.layer.masksToBounds = true
        box.layer.borderWidth = 1
        box.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(box)
        NSLayoutConstraint.activate([
            box.topAnchor.constraint(equalTo: contentView.topAnchor),
            box.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            box.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            box.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        dayLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(dayLabel)
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Set corner radius after layout so frame is calculated correctly
        // CRITICAL: Make it a perfect circle
        let size = min(box.bounds.width, box.bounds.height)
        box.layer.cornerRadius = size / 2.0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dayLabel.text = nil
    }

    func configure(day: Int?, level: Int) {
        if let day = day {
            dayLabel.text = "\(day)"
        } else {
            dayLabel.text = ""
        }
        dayLabel.textAlignment = .center
        dayLabel.adjustsFontSizeToFitWidth = true
        
        // CRITICAL: Set corner radius immediately after configure to ensure circles
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let size = min(self.box.bounds.width, self.box.bounds.height)
            self.box.layer.cornerRadius = size / 2.0
        }

        // 0 = ALMOST BLACK (future dates after today or no data)
        // 1 = LIGHT GREY (0 activities completed) 
        // 2 = LIGHT YELLOW (1-2 activities completed)
        // 3 = BRIGHT GREEN (3-5 activities - all completed)
        switch level {
        case 0:
            box.backgroundColor = UIColor(hex: "#1A1A1A") // Almost black for future dates
            box.layer.borderColor = UIColor(hex: "#0F0F0F").cgColor
            dayLabel.textColor = UIColor(hex: "#666666")
        case 1:
            box.backgroundColor = UIColor(hex: "#E0E0E0") // Light grey for nothing completed
            box.layer.borderColor = UIColor(hex: "#BDBDBD").cgColor
            dayLabel.textColor = UIColor(hex: "#202020")
        case 2:
            box.backgroundColor = UIColor(hex: "#FFE082") // Light yellow for partial (1-2 activities)
            box.layer.borderColor = UIColor(hex: "#FFA726").cgColor
            dayLabel.textColor = UIColor(hex: "#3E2723")
        case 3:
            box.backgroundColor = UIColor(hex: "#AEFE14") // Bright primary green (matches schedule for 3-5 activities)
            box.layer.borderColor = UIColor(hex: "#6EBE00").cgColor
            dayLabel.textColor = UIColor(hex: "#2F3B00")
        default:
            box.backgroundColor = UIColor(hex: "#1A1A1A") // Almost black default
            box.layer.borderColor = UIColor(hex: "#0F0F0F").cgColor
            dayLabel.textColor = UIColor(hex: "#666666")
        }
    }
}

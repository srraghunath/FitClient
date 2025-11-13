//
//
//  TrainerClientProgressViewControlller.swift
//  FitClient
//
//  Created by admin2 on 11/11/25.
//

import UIKit

// MARK: - Models
struct DayActivity {
    let date: Date
    let activityLevel: Int // 0 = grey (future), 1 = white (0 completed), 2 = mild green (1-2 completed), 3 = full green (3-5 completed)
}

struct ProgressSegment {
    let title: String
    let percentage: Double
    let color: UIColor
}

struct ClientActivityData: Codable {
    let clientId: String
    let monthlyData: [String: [DailyActivityItem]] // "2025-11" -> array of activities
}

struct DailyActivityItem: Codable {
    let date: String
    let workout: Bool
    let diet: Bool
    let sleep: Bool
    let waterIntake: Bool
    let cardio: Bool
    
    var totalCompleted: Int {
        var count = 0
        if workout { count += 1 }
        if diet { count += 1 }
        if sleep { count += 1 }
        if waterIntake { count += 1 }
        if cardio { count += 1 }
        return count
    }
}

class TrainerClientProgressViewControlller: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet private weak var monthLabel: UILabel!
    @IBOutlet private weak var calendarButton: UIButton!
    @IBOutlet private weak var heatmapContainerView: UIView!
    @IBOutlet private weak var heatmapCollectionView: UICollectionView!
    @IBOutlet private weak var heatmapTitleLabel: UILabel!
    @IBOutlet private weak var heatmapSubtitleLabel: UILabel!
    @IBOutlet private weak var weekdayHeaderStackView: UIStackView! // Add weekday header
    @IBOutlet private weak var pieChartContainerView: UIView!
    @IBOutlet private weak var pieChartView: PieChartView!
    @IBOutlet private weak var pieChartTitleLabel: UILabel!
    @IBOutlet private weak var pieChartSubtitleLabel: UILabel!
    @IBOutlet private weak var legendStackView: UIStackView!
    
    // MARK: - Properties
    private var currentMonth = Date()
    private var activities: [DayActivity] = []
    private var segments: [ProgressSegment] = []
    private var selectedDate = Date()
    private let calendar = Calendar.current
    private var clientActivityData: ClientActivityData?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        updateUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#000000")
        
        // Heatmap Container
        heatmapContainerView.backgroundColor = UIColor(hex: "#303131")
        heatmapContainerView.layer.cornerRadius = 16
        
        // Pie Chart Container
        pieChartContainerView.backgroundColor = UIColor(hex: "#303131")
        pieChartContainerView.layer.cornerRadius = 13
        pieChartContainerView.layer.borderWidth = 0.8
        pieChartContainerView.layer.borderColor = UIColor(hex: "#303131").cgColor
        
        // Setup Collection View
        heatmapCollectionView.delegate = self
        heatmapCollectionView.dataSource = self
        heatmapCollectionView.backgroundColor = .clear
        heatmapCollectionView.register(HeatmapCell.self, forCellWithReuseIdentifier: HeatmapCell.id)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 3  // Reduced to 3px for tighter spacing
        layout.minimumLineSpacing = 3        // Reduced to 3px for tighter spacing
        layout.scrollDirection = .vertical
        heatmapCollectionView.collectionViewLayout = layout
        
        // Calendar Button
        calendarButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        calendarButton.tintColor = UIColor(hex: "#F5F5F5")
        
        // Setup Weekday Headers
        setupWeekdayHeaders()
        
        // Setup Legend
        setupLegend()
    }
    
    private func setupWeekdayHeaders() {
        weekdayHeaderStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        weekdayHeaderStackView.isHidden = false
        if let headerHeightConstraint = weekdayHeaderStackView.constraints.first(where: { $0.firstAttribute == .height }) {
            headerHeightConstraint.constant = 15
        }
        if let cvTopConstraint = heatmapContainerView.constraints.first(where: { $0.identifier == "cv-top" }) {
            cvTopConstraint.constant = 8
        }

        // Determine the weekday of the first day of the current month
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return }
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) // 1=Sun ... 7=Sat

        // Base order starting from Sunday so we can rotate depending on the month
        let allWeekdays = ["S", "M", "T", "W", "T", "F", "S"]
        let firstDayIndex = (firstWeekday - 1) % 7

        var rotated: [String] = []
        for i in 0..<7 {
            rotated.append(allWeekdays[(firstDayIndex + i) % 7])
        }

        for symbol in rotated {
            let label = UILabel()
            label.text = symbol
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = UIColor(hex: "#F5F5F5")
            label.textAlignment = .center
            weekdayHeaderStackView.addArrangedSubview(label)
        }
    }
    
    private func setupLegend() {
        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Order: Workout, Diet, Sleep, Water, Cardio
        let legendItems = [
            ("Workout", "#FFD74D"),
            ("Diet", "#FE14A5"),
            ("Sleep", "#A514FE"),
            ("Water", "#14FEFF"),
            ("Cardio", "#FF8C14")
        ]
        
        for (title, color) in legendItems {
            let containerView = UIView()
            
            let colorBox = UIView()
            colorBox.backgroundColor = UIColor(hex: color)
            colorBox.layer.cornerRadius = 5.5
            colorBox.translatesAutoresizingMaskIntoConstraints = false
            
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(colorBox)
            containerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                colorBox.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                colorBox.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                colorBox.widthAnchor.constraint(equalToConstant: 11),
                colorBox.heightAnchor.constraint(equalToConstant: 11),
                label.leadingAnchor.constraint(equalTo: colorBox.trailingAnchor, constant: 7),
                label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
            
            legendStackView.addArrangedSubview(containerView)
        }
    }
    
    // MARK: - Data Loading
    private func loadData() {
        // Load JSON data
        loadClientActivityData()
        
        activities.removeAll()
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        let selectedMonthKey = monthFormatter.string(from: currentMonth)
        
        let today = Date()
        let currentMonthKey = monthFormatter.string(from: today)
        
        // Determine if this is current month, future month, or past month
        let isCurrentMonth = selectedMonthKey == currentMonthKey
        let isFutureMonth = currentMonth > today
        let isPastMonth = currentMonth < calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        print("Selected month: \(selectedMonthKey)")
        print("Current month: \(currentMonthKey)")
        print("Is current: \(isCurrentMonth), Is future: \(isFutureMonth), Is past: \(isPastMonth)")
        
    // Get activity data for this specific month
    let monthActivities = clientActivityData?.monthlyData[selectedMonthKey]
    let hasMonthData = (monthActivities?.isEmpty == false)
        
        // NO EMPTY BOXES - just add the actual days starting from day 1
        for day in 1...range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                let dateString = dateFormatter.string(from: date)
                
                if isFutureMonth {
                    // FUTURE MONTH: All boxes grey (level 0)
                    activities.append(DayActivity(date: date, activityLevel: 0))
                    if day <= 3 {
                        print("   Day \(day): FUTURE MONTH (grey)")
                    }
                } else if isPastMonth && !hasMonthData {
                    // Past month without data: grey boxes
                    activities.append(DayActivity(date: date, activityLevel: 0))
                    if day <= 3 {
                        print("   Day \(day): PAST MONTH NO DATA (grey)")
                    }
                } else {
                    // CURRENT MONTH or PAST MONTH WITH DATA: Show actual data
                    let todayComponents = calendar.dateComponents([.day], from: today)
                    let currentDay = todayComponents.day ?? 0
                    
                    if isCurrentMonth && day > currentDay {
                        // Future days in current month are grey
                        activities.append(DayActivity(date: date, activityLevel: 0))
                        if day <= currentDay + 3 {
                            print("   Day \(day): FUTURE (grey)")
                        }
                    } else {
                        // Find activity data for this date
                        if let dailyActivity = monthActivities?.first(where: { $0.date == dateString }) {
                            let completedCount = dailyActivity.totalCompleted
                            let level: Int
                            if completedCount == 0 {
                                level = 1 // WHITE - nothing completed
                            } else if completedCount >= 1 && completedCount <= 2 {
                                level = 2 // MILD GREEN - 1-2 activities
                            } else {
                                level = 3 // FULL GREEN - 3-5 activities
                            }
                            activities.append(DayActivity(date: date, activityLevel: level))
                            if day <= 5 {
                                print("   Day \(day) (\(dateString)): \(completedCount) activities -> level \(level)")
                            }
                        } else {
                            // No data - treat as nothing completed
                            activities.append(DayActivity(date: date, activityLevel: 1))
                            if day <= 5 {
                                print("   Day \(day) (\(dateString)): NO DATA -> level 1 (WHITE)")
                            }
                        }
                    }
                }
            }
        }
        
        // Calculate percentages for pie chart from actual data
        calculateProgressSegments()
    }
    
    private func calculateProgressSegments() {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        let selectedMonthKey = monthFormatter.string(from: currentMonth)
        
        let today = Date()
        let currentMonthKey = monthFormatter.string(from: today)
        
        let isFutureMonth = currentMonth > today
        
        if isFutureMonth {
            segments = [
                ProgressSegment(title: "Workout", percentage: 0, color: UIColor(hex: "#FFD74D")),
                ProgressSegment(title: "Diet", percentage: 0, color: UIColor(hex: "#FE14A5")),
                ProgressSegment(title: "Sleep", percentage: 0, color: UIColor(hex: "#A514FE")),
                ProgressSegment(title: "Water", percentage: 0, color: UIColor(hex: "#14FEFF")),
                ProgressSegment(title: "Cardio", percentage: 0, color: UIColor(hex: "#FF8C14"))
            ]
            print("Future month - showing 0% for all activities")
            return
        }
        
        // Get activity data for this specific month
        guard let monthActivities = clientActivityData?.monthlyData[selectedMonthKey], !monthActivities.isEmpty else {
            segments = [
                ProgressSegment(title: "Workout", percentage: 0, color: UIColor(hex: "#FFD74D")),
                ProgressSegment(title: "Diet", percentage: 0, color: UIColor(hex: "#FE14A5")),
                ProgressSegment(title: "Sleep", percentage: 0, color: UIColor(hex: "#A514FE")),
                ProgressSegment(title: "Water", percentage: 0, color: UIColor(hex: "#14FEFF")),
                ProgressSegment(title: "Cardio", percentage: 0, color: UIColor(hex: "#FF8C14"))
            ]
            print("No activity data for this month")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Count only days up to today for current month, all days for past months
        let validActivities: [DailyActivityItem]
        if selectedMonthKey == currentMonthKey {
            validActivities = monthActivities.filter { activityItem in
                if let date = dateFormatter.date(from: activityItem.date) {
                    return calendar.compare(date, to: today, toGranularity: .day) != .orderedDescending
                }
                return false
            }
        } else {
            // For past months, use all recorded days
            validActivities = monthActivities
        }
        
        let totalDays = Double(validActivities.count)
        
        print("Calculating pie chart from \(Int(totalDays)) days of data:")
        
        if totalDays == 0 {
            segments = [
                ProgressSegment(title: "Workout", percentage: 0, color: UIColor(hex: "#FFD74D")),
                ProgressSegment(title: "Diet", percentage: 0, color: UIColor(hex: "#FE14A5")),
                ProgressSegment(title: "Sleep", percentage: 0, color: UIColor(hex: "#A514FE")),
                ProgressSegment(title: "Water", percentage: 0, color: UIColor(hex: "#14FEFF")),
                ProgressSegment(title: "Cardio", percentage: 0, color: UIColor(hex: "#FF8C14"))
            ]
            print("   No days, showing 0% each")
            return
        }
        
        // Calculate actual percentages from JSON
        let workoutCompleted = Double(validActivities.filter { $0.workout }.count)
        let dietCompleted = Double(validActivities.filter { $0.diet }.count)
        let sleepCompleted = Double(validActivities.filter { $0.sleep }.count)
        let waterCompleted = Double(validActivities.filter { $0.waterIntake }.count)
        let cardioCompleted = Double(validActivities.filter { $0.cardio }.count)
        
        let workoutPct = (workoutCompleted / totalDays) * 100
        let dietPct = (dietCompleted / totalDays) * 100
        let sleepPct = (sleepCompleted / totalDays) * 100
        let waterPct = (waterCompleted / totalDays) * 100
        let cardioPct = (cardioCompleted / totalDays) * 100
        
        print("   Workout: \(Int(workoutCompleted))/\(Int(totalDays)) = \(Int(workoutPct))%")
        print("   Diet: \(Int(dietCompleted))/\(Int(totalDays)) = \(Int(dietPct))%")
        print("   Sleep: \(Int(sleepCompleted))/\(Int(totalDays)) = \(Int(sleepPct))%")
        print("   Water: \(Int(waterCompleted))/\(Int(totalDays)) = \(Int(waterPct))%")
        print("   Cardio: \(Int(cardioCompleted))/\(Int(totalDays)) = \(Int(cardioPct))%")
        
        // PIE CHART ORDER: WORKOUT, DIET, SLEEP, WATER, CARDIO (percentages are ACTUAL from JSON)
        segments = [
            ProgressSegment(title: "Workout", percentage: workoutPct, color: UIColor(hex: "#FFD74D")),
            ProgressSegment(title: "Diet", percentage: dietPct, color: UIColor(hex: "#FE14A5")),
            ProgressSegment(title: "Sleep", percentage: sleepPct, color: UIColor(hex: "#A514FE")),
            ProgressSegment(title: "Water", percentage: waterPct, color: UIColor(hex: "#14FEFF")),
            ProgressSegment(title: "Cardio", percentage: cardioPct, color: UIColor(hex: "#FF8C14"))
        ]
        
        print("All 5 segments created with actual percentages from JSON")
    }
    
    private func loadClientActivityData() {
        guard let url = Bundle.main.url(forResource: "clientActivityData", withExtension: "json") else {
            print("JSON file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            clientActivityData = try JSONDecoder().decode(ClientActivityData.self, from: data)
            let totalMonths = clientActivityData?.monthlyData.count ?? 0
            print("Successfully loaded activity data: \(totalMonths) months")
            if let monthData = clientActivityData?.monthlyData["2025-11"]?.first {
                print("   November first entry: \(monthData.date) - workout:\(monthData.workout) diet:\(monthData.diet)")
            }
            if let octoberData = clientActivityData?.monthlyData["2025-10"] {
                print("October has \(octoberData.count) days of data")
            }
            if let septemberData = clientActivityData?.monthlyData["2025-09"] {
                print("   September has \(septemberData.count) days of data (all 100%)")
            }
        } catch {
            print("Error loading JSON: \(error)")
        }
    }
    
    private func updateUI() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: currentMonth)
        monthLabel.textAlignment = .center
        
        // Update weekday headers based on the new month
        setupWeekdayHeaders()
        
        heatmapCollectionView.reloadData()
        pieChartView.configure(with: segments)
    }
    
    // MARK: - Actions
    @IBAction func calendarButtonTapped(_ sender: UIButton) {
        // Create picker view for month and year selection only
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.delegate = self
        pickerView.dataSource = self
        
        // Get current month and year
        let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let currentYear = currentComponents.year ?? 2025
        let currentMonthIndex = (currentComponents.month ?? 1) - 1
        
        // Set initial selection
        let yearIndex = currentYear - 2020  // Starting from 2020
        pickerView.selectRow(currentMonthIndex, inComponent: 0, animated: false)
        pickerView.selectRow(yearIndex, inComponent: 1, animated: false)
        
        let alert = UIAlertController(title: "Select Month & Year", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        
        alert.view.addSubview(pickerView)
        
        NSLayoutConstraint.activate([
            pickerView.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor),
            pickerView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
            pickerView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        alert.addAction(UIAlertAction(title: "Select", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let selectedMonth = pickerView.selectedRow(inComponent: 0) + 1
            let selectedYear = pickerView.selectedRow(inComponent: 1) + 2020
            print("📅 Trainer picker chose month: \(selectedMonth) year: \(selectedYear)")
            
            var components = DateComponents()
            components.year = selectedYear
            components.month = selectedMonth
            components.day = 1
            
            if let newDate = self.calendar.date(from: components) {
                self.currentMonth = newDate
                self.loadData()
                self.updateUI()
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension TrainerClientProgressViewControlller: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = activities.count
        print("Collection view will show \(count) boxes for \(count) days")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeatmapCell.id, for: indexPath) as! HeatmapCell
        
        if indexPath.item < activities.count {
            let activity = activities[indexPath.item]
            let level = activity.activityLevel
            let dayNumber = calendar.component(.day, from: activity.date)
            cell.configure(day: dayNumber, level: level)
            if indexPath.item < 7 {
                print("Box \(indexPath.item + 1): day \(dayNumber) level \(level)")
            }
        } else {
            cell.configure(day: nil, level: 0) // Grey filler
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // FORCE 7 columns EXACTLY with SMALLER boxes (3px spacing)
        let totalSpacing: CGFloat = 6 * 3.0 // 6 gaps between 7 items at 3px each
        let availableWidth = collectionView.bounds.width - totalSpacing
        let cellWidth = floor(availableWidth / 7.0) // EXACTLY 7 columns
        
        print("Cell size: \(cellWidth) x \(cellWidth) for 7 columns (total width: \(collectionView.bounds.width))")
        
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Touch on heatmap boxes should do nothing - removed functionality
    }
}

// MARK: - Heatmap Cell
class HeatmapCell: UICollectionViewCell {
    static let id = "HeatmapCell"
    private let box = UIView()
    private let dayLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        box.layer.cornerRadius = 6
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

        // 0 = DARK GREY (future dates after today)
        // 1 = WHITE (0 activities completed) 
        // 2 = MILD GREEN (1-2 activities completed)
        // 3 = FULL PRIMARY GREEN (3-5 activities - all completed)
        switch level {
        case 0:
            box.backgroundColor = UIColor(hex: "#1F1F1F") // Dark grey for future dates (higher contrast)
            box.layer.borderColor = UIColor(hex: "#353535").cgColor
            dayLabel.textColor = UIColor(hex: "#7B7B7B")
        case 1:
            box.backgroundColor = UIColor(hex: "#F2F2F2") // Soft white for nothing completed
            box.layer.borderColor = UIColor(hex: "#C8C8C8").cgColor
            dayLabel.textColor = UIColor(hex: "#202020")
        case 2:
            box.backgroundColor = UIColor(hex: "#D8FF7C") // Light primary green for 1-2 activities
            box.layer.borderColor = UIColor(hex: "#9ACF35").cgColor
            dayLabel.textColor = UIColor(hex: "#314400")
        case 3:
            box.backgroundColor = UIColor(hex: "#AEFE14") // Primary green for 3-5 activities
            box.layer.borderColor = UIColor(hex: "#6EBE00").cgColor
            dayLabel.textColor = UIColor(hex: "#2F3B00")
        default:
            box.backgroundColor = UIColor(hex: "#1F1F1F") // Dark grey default
            box.layer.borderColor = UIColor(hex: "#353535").cgColor
            dayLabel.textColor = UIColor(hex: "#7B7B7B")
        }
    }
}

// MARK: - Pie Chart View
class PieChartView: UIView {
    private var segments: [ProgressSegment] = []
    private let centerLabel = UILabel()
    private let avgLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        
        avgLabel.text = "Average"
        avgLabel.font = .systemFont(ofSize: 9, weight: .bold)
        avgLabel.textColor = UIColor(hex: "#A0A0A0")
        avgLabel.textAlignment = .center
        avgLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avgLabel)
        
        centerLabel.font = .systemFont(ofSize: 20, weight: .bold)
        centerLabel.textColor = UIColor(hex: "#AEFE14")
        centerLabel.textAlignment = .center
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerLabel)
        
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 5),
            avgLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            avgLabel.bottomAnchor.constraint(equalTo: centerLabel.topAnchor, constant: -2)
        ])
    }
    
    func configure(with segments: [ProgressSegment]) {
        self.segments = segments
        let avg = segments.isEmpty ? 0.0 : segments.reduce(0.0) { $0 + $1.percentage } / Double(segments.count)
        centerLabel.text = "\(Int(avg))%"
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard !segments.isEmpty else { return }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 10
        let innerRadius = radius * 0.60
        var startAngle: CGFloat = -.pi / 2
        let gapAngle: CGFloat = 0.08 // Gap between slices
        
        // Each slice gets EXACTLY 20% of the circle (360° / 5 = 72° per slice)
        let sliceAngle = (2 * .pi / 5.0) - gapAngle
        
        // Grey color for unfilled portion
        let greyColor = UIColor(hex: "#3A3A3A")
        
        print("Drawing pie chart with \(segments.count) equal slices:")
        
        for (index, segment) in segments.enumerated() {
            let endAngle = startAngle + sliceAngle
            
            // Calculate how much of this slice should be filled with color (based on percentage)
            let fillRatio = CGFloat(segment.percentage / 100.0)
            let colorEndAngle = startAngle + (sliceAngle * fillRatio)
            
            print("   \(segment.title): \(Int(segment.percentage))% - slice \(index + 1)/5")
            
            // Draw GREY background (full slice)
            let greyPath = UIBezierPath()
            greyPath.move(to: CGPoint(x: center.x + innerRadius * cos(startAngle), y: center.y + innerRadius * sin(startAngle)))
            greyPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            greyPath.addLine(to: CGPoint(x: center.x + innerRadius * cos(endAngle), y: center.y + innerRadius * sin(endAngle)))
            greyPath.addArc(withCenter: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
            greyPath.close()
            
            greyColor.setFill()
            greyPath.fill()
            
            // Draw COLORED portion (only the percentage that's completed)
            if segment.percentage > 0 {
                let colorPath = UIBezierPath()
                colorPath.move(to: CGPoint(x: center.x + innerRadius * cos(startAngle), y: center.y + innerRadius * sin(startAngle)))
                colorPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: colorEndAngle, clockwise: true)
                colorPath.addLine(to: CGPoint(x: center.x + innerRadius * cos(colorEndAngle), y: center.y + innerRadius * sin(colorEndAngle)))
                colorPath.addArc(withCenter: center, radius: innerRadius, startAngle: colorEndAngle, endAngle: startAngle, clockwise: false)
                colorPath.close()
                
                segment.color.setFill()
                colorPath.fill()
            }
            
            // Draw percentage text in the middle of the slice
            let midAngle = (startAngle + endAngle) / 2
            let textRadius = (radius + innerRadius) / 2
            let textPoint = CGPoint(x: center.x + textRadius * cos(midAngle), y: center.y + textRadius * sin(midAngle))
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let text = "\(Int(segment.percentage))%"
            let size = (text as NSString).size(withAttributes: attrs)
            (text as NSString).draw(in: CGRect(x: textPoint.x - size.width/2, y: textPoint.y - size.height/2, width: size.width, height: size.height), withAttributes: attrs)
            
            startAngle = endAngle + gapAngle
        }
        
        print("Pie chart drawn with all \(segments.count) equal slices, colors filled by percentage")
    }
}

// MARK: - UIPickerView DataSource & Delegate
extension TrainerClientProgressViewControlller: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2 // Month and Year
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 12 // 12 months
        } else {
            return 20 // Years from 2020 to 2039
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            let months = ["January", "February", "March", "April", "May", "June", 
                         "July", "August", "September", "October", "November", "December"]
            return months[row]
        } else {
            return "\(2020 + row)"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 0 {
            return 200 // Month column wider
        } else {
            return 80 // Year column narrower
        }
    }
}

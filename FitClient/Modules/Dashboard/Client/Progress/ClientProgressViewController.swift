//
//  ClientProgressViewController.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

final class ClientProgressViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var monthLabel: UILabel!
    @IBOutlet private weak var calendarButton: UIButton!
    @IBOutlet private weak var heatmapContainerView: UIView!
    @IBOutlet private weak var heatmapCollectionView: UICollectionView!
    @IBOutlet private weak var heatmapTitleLabel: UILabel!
    @IBOutlet private weak var heatmapSubtitleLabel: UILabel!
    @IBOutlet private weak var weekdayHeaderStackView: UIStackView!
    @IBOutlet private weak var pieChartContainerView: UIView!
    @IBOutlet private weak var pieChartView: PieChartView!
    @IBOutlet private weak var pieChartTitleLabel: UILabel!
    @IBOutlet private weak var pieChartSubtitleLabel: UILabel!
    @IBOutlet private weak var legendStackView: UIStackView!
    
    // MARK: - Properties
    private var currentMonth = Date()
    private var activities: [DayActivity] = []
    private var segments: [ProgressSegment] = []
    private let calendar = Calendar.current
    private var clientActivityData: ClientActivityData?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        setupUI()
        loadData()
        updateUI()
    }
    
    // MARK: - Setup
    private func configureNavigationBar() {
        title = "Progress"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .textPrimary
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .backgroundBlack
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func setupUI() {
        view.backgroundColor = .backgroundBlack
        heatmapContainerView.backgroundColor = UIColor(hex: "#303131")
        heatmapContainerView.layer.cornerRadius = 16
        pieChartContainerView.backgroundColor = UIColor(hex: "#303131")
        pieChartContainerView.layer.cornerRadius = 13
        pieChartContainerView.layer.borderWidth = 0.8
        pieChartContainerView.layer.borderColor = UIColor(hex: "#303131").cgColor
        heatmapTitleLabel.textColor = .white
        heatmapSubtitleLabel.textColor = UIColor(hex: "#F5F5F5")
        pieChartTitleLabel.textColor = .white
        pieChartSubtitleLabel.textColor = UIColor(hex: "#F5F5F5")
        monthLabel.textColor = .textPrimary
        calendarButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        calendarButton.tintColor = UIColor(hex: "#F5F5F5")
        
        heatmapCollectionView.delegate = self
        heatmapCollectionView.dataSource = self
        heatmapCollectionView.backgroundColor = .clear
        heatmapCollectionView.showsVerticalScrollIndicator = false
        heatmapCollectionView.register(HeatmapCell.self, forCellWithReuseIdentifier: HeatmapCell.id)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 3  // 3px spacing between items
        layout.minimumLineSpacing = 3        // 3px spacing between rows
        layout.scrollDirection = .vertical
        layout.sectionInset = .zero         // No padding on sides - crucial for square calculation
        heatmapCollectionView.collectionViewLayout = layout
        
        setupWeekdayHeaders()
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
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return }
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
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
        let legendItems = [
            ("Workout", "#FFD74D"),
            ("Diet", "#FE14A5"),
            ("Sleep", "#A514FE"),
            ("Water", "#14FEFF"),
            ("Cardio", "#FF8C14")
        ]
        
        for (title, colorHex) in legendItems {
            let containerView = UIView()
            let colorBox = UIView()
            colorBox.backgroundColor = UIColor(hex: colorHex)
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
        loadClientActivityData()
        activities.removeAll()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return }
        let range = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        let selectedMonthKey = monthFormatter.string(from: currentMonth)
        let today = Date()
        let currentMonthKey = monthFormatter.string(from: today)
        let isCurrentMonth = selectedMonthKey == currentMonthKey
        let isFutureMonth = currentMonth > today
        let isPastMonth = currentMonth < calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
    let monthActivities = clientActivityData?.monthlyData[selectedMonthKey]
    let hasMonthData = (monthActivities?.isEmpty == false)
        
        for day in 1...range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if isFutureMonth {
                activities.append(DayActivity(date: date, activityLevel: 0))
                continue
            }
            if isPastMonth && !hasMonthData {
                activities.append(DayActivity(date: date, activityLevel: 0))
                continue
            }
            let currentDay = calendar.component(.day, from: today)
            if isCurrentMonth && day > currentDay {
                activities.append(DayActivity(date: date, activityLevel: 0))
                continue
            }
            if let dailyActivity = monthActivities?.first(where: { $0.date == dateString }) {
                let completedCount = dailyActivity.totalCompleted
                let level: Int
                if completedCount == 0 {
                    level = 1
                } else if completedCount <= 2 {
                    level = 2
                } else {
                    level = 3
                }
                activities.append(DayActivity(date: date, activityLevel: level))
            } else {
                activities.append(DayActivity(date: date, activityLevel: 1))
            }
        }
        
        calculateProgressSegments()
    }
    
    private func calculateProgressSegments() {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        let selectedMonthKey = monthFormatter.string(from: currentMonth)
        let today = Date()
        let currentMonthKey = monthFormatter.string(from: today)
        let isFutureMonth = currentMonth > today
        let isPastMonth = currentMonth < calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        if isFutureMonth {
            segments = [
                ProgressSegment(title: "Workout", percentage: 0, color: UIColor(hex: "#FFD74D")),
                ProgressSegment(title: "Diet", percentage: 0, color: UIColor(hex: "#FE14A5")),
                ProgressSegment(title: "Sleep", percentage: 0, color: UIColor(hex: "#A514FE")),
                ProgressSegment(title: "Water", percentage: 0, color: UIColor(hex: "#14FEFF")),
                ProgressSegment(title: "Cardio", percentage: 0, color: UIColor(hex: "#FF8C14"))
            ]
            return
        }
        
        guard let monthActivities = clientActivityData?.monthlyData[selectedMonthKey], !monthActivities.isEmpty else {
            segments = [
                ProgressSegment(title: "Workout", percentage: 0, color: UIColor(hex: "#FFD74D")),
                ProgressSegment(title: "Diet", percentage: 0, color: UIColor(hex: "#FE14A5")),
                ProgressSegment(title: "Sleep", percentage: 0, color: UIColor(hex: "#A514FE")),
                ProgressSegment(title: "Water", percentage: 0, color: UIColor(hex: "#14FEFF")),
                ProgressSegment(title: "Cardio", percentage: 0, color: UIColor(hex: "#FF8C14"))
            ]
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let validActivities: [DailyActivityItem]
        if selectedMonthKey == currentMonthKey {
            validActivities = monthActivities.filter { item in
                guard let date = dateFormatter.date(from: item.date) else { return false }
                return calendar.compare(date, to: today, toGranularity: .day) != .orderedDescending
            }
        } else {
            validActivities = monthActivities
        }
        
        let totalDays = Double(validActivities.count)
        guard totalDays > 0 else {
            segments = [
                ProgressSegment(title: "Workout", percentage: 0, color: UIColor(hex: "#FFD74D")),
                ProgressSegment(title: "Diet", percentage: 0, color: UIColor(hex: "#FE14A5")),
                ProgressSegment(title: "Sleep", percentage: 0, color: UIColor(hex: "#A514FE")),
                ProgressSegment(title: "Water", percentage: 0, color: UIColor(hex: "#14FEFF")),
                ProgressSegment(title: "Cardio", percentage: 0, color: UIColor(hex: "#FF8C14"))
            ]
            return
        }
        
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
        
        segments = [
            ProgressSegment(title: "Workout", percentage: workoutPct, color: UIColor(hex: "#FFD74D")),
            ProgressSegment(title: "Diet", percentage: dietPct, color: UIColor(hex: "#FE14A5")),
            ProgressSegment(title: "Sleep", percentage: sleepPct, color: UIColor(hex: "#A514FE")),
            ProgressSegment(title: "Water", percentage: waterPct, color: UIColor(hex: "#14FEFF")),
            ProgressSegment(title: "Cardio", percentage: cardioPct, color: UIColor(hex: "#FF8C14"))
        ]
    }
    
    private func loadClientActivityData() {
        guard clientActivityData == nil else { return }
        guard let url = Bundle.main.url(forResource: "clientActivityData", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            clientActivityData = try JSONDecoder().decode(ClientActivityData.self, from: data)
        } catch {
            print("Error loading client activity data: \(error)")
        }
    }
    
    private func updateUI() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: currentMonth)
        monthLabel.textAlignment = .center
        setupWeekdayHeaders()
        heatmapCollectionView.reloadData()
        pieChartView.configure(with: segments)
    }
    
    // MARK: - Actions
    @IBAction private func calendarButtonTapped(_ sender: UIButton) {
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.delegate = self
        pickerView.dataSource = self

        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        let currentYear = components.year ?? 2025
        let currentMonthIndex = max(0, min(11, (components.month ?? 1) - 1))
        let initialYearIndex = max(0, min(19, currentYear - 2020))

        let alert = UIAlertController(
            title: "Select Month & Year",
            message: "\n\n\n\n\n\n\n\n",
            preferredStyle: .actionSheet
        )

        alert.view.addSubview(pickerView)

        NSLayoutConstraint.activate([
            pickerView.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor),
            pickerView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
            pickerView.heightAnchor.constraint(equalToConstant: 200)
        ])

        pickerView.selectRow(currentMonthIndex, inComponent: 0, animated: false)
        pickerView.selectRow(initialYearIndex, inComponent: 1, animated: false)

        alert.addAction(UIAlertAction(title: "Select", style: .default) { [weak self] _ in
            guard let self = self else { return }

            let selectedMonthIndex = pickerView.selectedRow(inComponent: 0)
            let selectedYearIndex = pickerView.selectedRow(inComponent: 1)

            let selectedMonth = selectedMonthIndex + 1
            let selectedYear = 2020 + selectedYearIndex

            print("📅 Client picker chose month: \(selectedMonth) year: \(selectedYear)")

            var components = DateComponents()
            components.year = selectedYear
            components.month = selectedMonth
            components.day = 1

            guard let newDate = self.calendar.date(from: components) else { return }

            self.currentMonth = newDate
            self.loadData()
            self.updateUI()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }

        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ClientProgressViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeatmapCell.id, for: indexPath) as! HeatmapCell
        if indexPath.item < activities.count {
            let activity = activities[indexPath.item]
            let dayNumber = calendar.component(.day, from: activity.date)
            cell.configure(day: dayNumber, level: activity.activityLevel)
        } else {
            cell.configure(day: nil, level: 0)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // FORCE 7 columns EXACTLY - ALL CELLS MUST BE PERFECT SQUARES
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpacing: CGFloat = 6 * layout.minimumInteritemSpacing // 6 gaps × 3px spacing
        let availableWidth = collectionView.bounds.width - layout.sectionInset.left - layout.sectionInset.right - totalSpacing
        let cellSize = floor(availableWidth / 7.0) // Divide by exactly 7 columns
        
        // CRITICAL: Return square size (width == height) to ensure circles
        let squareSize = CGSize(width: cellSize, height: cellSize)
        
        return squareSize
    }
}

// MARK: - UIPickerView DataSource & Delegate
extension ClientProgressViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        component == 0 ? 12 : 20
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            let months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
            return months[row]
        }
        return "\(2020 + row)"
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        component == 0 ? 200 : 80
    }
}

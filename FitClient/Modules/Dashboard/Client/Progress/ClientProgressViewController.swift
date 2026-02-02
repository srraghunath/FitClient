//
//  ClientProgressViewController.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

// MARK: - Local Models (namespaced to avoid conflicts)
private struct ClientProgressDayActivity {
    let date: Date?
    let dayNumber: Int?
    let activityLevel: Int // 0 = future/placeholder, 1 = none, 2 = partial, 3 = full
}

private struct ClientProgressSegment {
    let title: String
    let percentage: Double
    let color: UIColor
}

private struct ClientDailyActivityItem: Codable {
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
    private var activities: [ClientProgressDayActivity] = []
    private var segments: [ClientProgressSegment] = []
    private let calendar = Calendar.current
    private var monthActivities: [ClientDailyActivityItem] = []
    private var uiLabels: UILabelsData?
    private var heatmapContainerHeightConstraint: NSLayoutConstraint?
    private var heatmapCollectionHeightConstraint: NSLayoutConstraint?
    private var heatmapCollectionBottomConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        setupUI()
        cacheLayoutConstraints()
        loadUILabels()
        loadData()
        updateUI()
    }
    
    private func loadUILabels() {
        DataService.shared.loadUILabels { [weak self] result in
            switch result {
            case .success(let labels):
                self?.uiLabels = labels
            case .failure(let error):
                print("Failed to load UI labels: \(error)")
            }
        }
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
        applyHeatmapLegend()
        setupLegend()
    }

    private func cacheLayoutConstraints() {
        heatmapContainerHeightConstraint = heatmapContainerView.constraints.first { $0.identifier == "hc-height" }
        heatmapCollectionHeightConstraint = heatmapCollectionView.constraints.first { $0.identifier == "cv-height" }
        heatmapCollectionBottomConstraint = heatmapContainerView.constraints.first { $0.identifier == "cv-bottom" }
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
        
        let weekdaySymbols = weekdaysStartingMonday(from: uiLabels?.weekdays.short)

        for symbol in weekdaySymbols {
            let label = UILabel()
            label.text = symbol
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = UIColor(hex: "#F5F5F5")
            label.textAlignment = .center
            weekdayHeaderStackView.addArrangedSubview(label)
        }
    }

    private func weekdaysStartingMonday(from symbols: [String]?) -> [String] {
        guard var symbols = symbols, symbols.count == 7 else {
            return ["M", "T", "W", "T", "F", "S", "S"]
        }
        if let mondayIndex = symbols.firstIndex(where: { $0.lowercased().hasPrefix("m") }) {
            var mondayFirst: [String] = []
            for offset in 0..<7 {
                mondayFirst.append(symbols[(mondayIndex + offset) % 7])
            }
            return mondayFirst
        }
        return ["M", "T", "W", "T", "F", "S", "S"]
    }
    
    private func applyHeatmapLegend() {
        let entries: [(UIColor, String)] = [
            (.primaryGreen, "All 5 Done"),
            (.primaryGreenSoft, "1-2 Done"),
            (UIColor(hex: "#E0E0E0"), "Did Nothing"),
            (UIColor(hex: "#1A1A1A"), "Upcoming")
        ]
        let font = heatmapSubtitleLabel.font ?? UIFont.systemFont(ofSize: 12, weight: .semibold)
        let textColor = heatmapSubtitleLabel.textColor ?? UIColor(hex: "#F5F5F5")
        let bullet = "●"
        let attributed = NSMutableAttributedString()
        for (index, entry) in entries.enumerated() {
            if index > 0 {
                let spacer = NSAttributedString(string: "     ", attributes: [
                    .font: font,
                    .foregroundColor: textColor
                ])
                attributed.append(spacer)
            }
            let bulletAttr = NSAttributedString(string: bullet, attributes: [
                .font: font,
                .foregroundColor: entry.0
            ])
            let labelAttr = NSAttributedString(string: " \(entry.1)", attributes: [
                .font: font,
                .foregroundColor: textColor
            ])
            attributed.append(bulletAttr)
            attributed.append(labelAttr)
        }
        heatmapSubtitleLabel.attributedText = attributed
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
        DayActivityService.shared.fetchActivitiesForCurrentClient(month: currentMonth) { [weak self] (result: Result<[DayActivityDTO], Error>) in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let rows):
                    self.monthActivities = rows.map {
                        ClientDailyActivityItem(
                            date: $0.activityDate,
                            workout: $0.workoutDone,
                            diet: $0.dietDone,
                            sleep: $0.sleepDone,
                            waterIntake: $0.waterDone,
                            cardio: $0.cardioDone
                        )
                    }
                    self.rebuildData()
                case .failure(let error):
                    self.monthActivities = []
                    self.activities = []
                    self.segments = self.emptySegments()
                    self.updateUI()
                    self.showAlert(title: "Error", message: "Failed to load activity data. Please try again.")
                    print("❌ Client progress fetch error: \(error)")
                }
            }
        }
    }

    private func rebuildData() {
        activities.removeAll()

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count else { return }

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingPlaceholders = (firstWeekday + 5) % 7 // shift so Monday (2) yields 0
        for _ in 0..<leadingPlaceholders {
            activities.append(ClientProgressDayActivity(date: nil, dayNumber: nil, activityLevel: 0))
        }

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
        let hasMonthData = !monthActivities.isEmpty

        for day in 1...daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { continue }
            let dateString = dateFormatter.string(from: date)

            if isFutureMonth {
                activities.append(ClientProgressDayActivity(date: date, dayNumber: calendar.component(.day, from: date), activityLevel: 0))
                continue
            }

            if isPastMonth && !hasMonthData {
                activities.append(ClientProgressDayActivity(date: date, dayNumber: calendar.component(.day, from: date), activityLevel: 0))
                continue
            }

            let currentDay = calendar.component(.day, from: today)
            if isCurrentMonth && day > currentDay {
                activities.append(ClientProgressDayActivity(date: date, dayNumber: calendar.component(.day, from: date), activityLevel: 0))
                continue
            }

            if let dailyActivity = monthActivities.first(where: { $0.date == dateString }) {
                let completedCount = dailyActivity.totalCompleted
                let level: Int
                if completedCount == 0 {
                    level = 1
                } else if completedCount <= 2 {
                    level = 2
                } else {
                    level = 3
                }
                let dayNumber = calendar.component(.day, from: date)
                activities.append(ClientProgressDayActivity(date: date, dayNumber: dayNumber, activityLevel: level))
            } else {
                activities.append(ClientProgressDayActivity(date: date, dayNumber: calendar.component(.day, from: date), activityLevel: 1))
            }
        }

        let remainder = activities.count % 7
        if remainder != 0 {
            let trailingPlaceholders = 7 - remainder
            for _ in 0..<trailingPlaceholders {
                activities.append(ClientProgressDayActivity(date: nil, dayNumber: nil, activityLevel: 0))
            }
        }

        calculateProgressSegments()
        updateUI()
    }

    private func calculateProgressSegments() {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        let selectedMonthKey = monthFormatter.string(from: currentMonth)
        let today = Date()
        let currentMonthKey = monthFormatter.string(from: today)
        let isFutureMonth = currentMonth > today

        if isFutureMonth {
            segments = emptySegments()
            return
        }

        guard !monthActivities.isEmpty else {
            segments = emptySegments()
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let validActivities: [ClientDailyActivityItem]
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
            segments = emptySegments()
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
            ClientProgressSegment(title: "Workout", percentage: workoutPct, color: UIColor(hex: "#FFD74D")),
            ClientProgressSegment(title: "Diet", percentage: dietPct, color: UIColor(hex: "#FE14A5")),
            ClientProgressSegment(title: "Sleep", percentage: sleepPct, color: UIColor(hex: "#A514FE")),
            ClientProgressSegment(title: "Water", percentage: waterPct, color: UIColor(hex: "#14FEFF")),
            ClientProgressSegment(title: "Cardio", percentage: cardioPct, color: UIColor(hex: "#FF8C14"))
        ]
    }

    private func emptySegments() -> [ClientProgressSegment] {
        return [
            ClientProgressSegment(title: "Workout", percentage: 0, color: UIColor(hex: "#FFD74D")),
            ClientProgressSegment(title: "Diet", percentage: 0, color: UIColor(hex: "#FE14A5")),
            ClientProgressSegment(title: "Sleep", percentage: 0, color: UIColor(hex: "#A514FE")),
            ClientProgressSegment(title: "Water", percentage: 0, color: UIColor(hex: "#14FEFF")),
            ClientProgressSegment(title: "Cardio", percentage: 0, color: UIColor(hex: "#FF8C14"))
        ]
    }
    
    private func updateUI() {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    monthLabel.text = formatter.string(from: currentMonth)
    monthLabel.textAlignment = .center

    setupWeekdayHeaders()

    heatmapCollectionView.reloadData()
    heatmapCollectionView.layoutIfNeeded()
    updateHeatmapSizing()

    let mappedSegments = segments.map {
        ProgressSegment(title: $0.title, percentage: $0.percentage, color: $0.color)
    }
    pieChartView.configure(with: mappedSegments)
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
            cell.configure(day: activity.dayNumber, level: activity.activityLevel)
        } else {
            cell.configure(day: nil, level: 0)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSide = calculateCellSide(for: collectionView)
        return CGSize(width: cellSide, height: cellSide)
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
            let months = uiLabels?.months.full ?? ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
            return months[row]
        }
        return "\(2020 + row)"
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        component == 0 ? 200 : 80
    }
}

// MARK: - Layout Helpers
private extension ClientProgressViewController {
    func calculateCellSide(for collectionView: UICollectionView) -> CGFloat {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        let totalSpacing = 6 * layout.minimumInteritemSpacing
        let availableWidth = collectionView.bounds.width - layout.sectionInset.left - layout.sectionInset.right - totalSpacing
        return floor(availableWidth / 7.0)
    }

func updateHeatmapSizing() {
    guard heatmapCollectionView.bounds.width > 0 else { return }

    let cellSide = calculateCellSide(for: heatmapCollectionView)
    let rows = Int(ceil(Double(max(activities.count, 1)) / 7.0))

    guard let layout = heatmapCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

    let rowSpacing = CGFloat(max(rows - 1, 0)) * layout.minimumLineSpacing
    let collectionHeight = CGFloat(rows) * cellSide + rowSpacing

    heatmapCollectionHeightConstraint?.constant = collectionHeight

    let headerBottomY = weekdayHeaderStackView.frame.maxY
    let topPadding = headerBottomY + 8
    let bottomPadding = heatmapCollectionBottomConstraint?.constant ?? 15

    heatmapContainerHeightConstraint?.constant =
        topPadding + collectionHeight + bottomPadding
}
}

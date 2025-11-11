//
//  TrainerClientProfileScheduleViewController.swift
//  FitClient
//
//  Created by admin6 on 11/11/25.
//

import UIKit

class TrainerClientProfileScheduleViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet private weak var weekdayStackView: UIStackView!
    @IBOutlet private weak var scheduleTableView: UITableView!
    
    // MARK: - Properties
    var clientId: String?
    private var clientScheduleData: ClientScheduleData?
    private var selectedDay: Weekday = .monday
    private var weekdayButtons: [UIButton] = []
    private var expandedIndexPaths: Set<IndexPath> = []
    private var currentDayData: DayScheduleData?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadScheduleData()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .black
        setupWeekdayCircles()
    }
    
    private func setupWeekdayCircles() {
        weekdayStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        weekdayButtons.removeAll()
        
        for weekday in Weekday.allCases {
            let containerView = createWeekdayButton(for: weekday)
            weekdayStackView.addArrangedSubview(containerView)
        }
        
        weekdayStackView.distribution = .equalSpacing
        weekdayStackView.spacing = 4
    }
    
    private func createWeekdayButton(for weekday: Weekday) -> UIView {
        // Create container view
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Circle button
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.tag = weekday.index
        
        // Set initial colors
        let hasData = hasScheduleData(for: weekday)
        let isSelected = (weekday == selectedDay)
        updateWeekdayButton(button, hasData: hasData, isSelected: isSelected)
        
        button.addTarget(self, action: #selector(weekdayButtonTapped(_:)), for: .touchUpInside)
        
        // Add button to container
        container.addSubview(button)
        
        // Button constraints
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        // Label below button
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = weekday.rawValue
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        
        container.addSubview(label)
        
        // Label constraints
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 6),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.widthAnchor.constraint(equalToConstant: 20)
        ])
        
        // Container size
        container.widthAnchor.constraint(equalToConstant: 40).isActive = true
        container.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // Store button reference for later updates
        weekdayButtons.append(button)
        
        return container
    }
    
    private func updateWeekdayButton(_ button: UIButton, hasData: Bool, isSelected: Bool) {
        button.subviews.forEach { $0.removeFromSuperview() }
        
        // Set background color based on data availability
        if hasData {
            button.backgroundColor = UIColor(hex: "#aefe14")  // Green for has data
        } else {
            button.backgroundColor = UIColor(hex: "#fe1414")  // Red for no data
        }
        
        // Add selection border
        if isSelected {
            button.layer.borderWidth = 3
            button.layer.borderColor = UIColor.blue.cgColor
        } else {
            button.layer.borderWidth = 0
        }
        
        // Inner circle
        let innerView = UIView()
        innerView.backgroundColor = .black
        innerView.layer.cornerRadius = 7
        innerView.clipsToBounds = true
        innerView.isUserInteractionEnabled = false
        button.addSubview(innerView)
        
        innerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerView.widthAnchor.constraint(equalToConstant: 14),
            innerView.heightAnchor.constraint(equalToConstant: 14),
            innerView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            innerView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
    }
    
    private func hasScheduleData(for weekday: Weekday) -> Bool {
        guard let scheduleData = clientScheduleData else { 
            return false 
        }
        let dayName = getDayName(from: weekday)
        guard let dayData = scheduleData.weekSchedule[dayName] else { 
            return false 
        }
        return dayData.isActive
    }
    
    private func getDayName(from weekday: Weekday) -> String {
        switch weekday {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
    
    private func setupTableView() {
        scheduleTableView.delegate = self
        scheduleTableView.dataSource = self
        scheduleTableView.backgroundColor = .black
        scheduleTableView.separatorStyle = .none
        
        scheduleTableView.register(UINib(nibName: "ScheduleCardCell", bundle: nil), forCellReuseIdentifier: "ScheduleCardCell")
        scheduleTableView.register(UINib(nibName: "SliderCardCell", bundle: nil), forCellReuseIdentifier: "SliderCardCell")
        scheduleTableView.register(UINib(nibName: "CardioInputCell", bundle: nil), forCellReuseIdentifier: "CardioInputCell")
    }
    
    // MARK: - Data Loading
    private func loadScheduleData() {
        guard let clientId = clientId else { return }
        
        DataService.shared.loadClientSchedule(forClientId: clientId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let scheduleData):
                    self?.clientScheduleData = scheduleData
                    self?.updateAllWeekdayButtons()
                    self?.loadDayData(for: self?.selectedDay ?? .monday)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: "Failed to load schedule data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadDayData(for weekday: Weekday) {
        guard let scheduleData = clientScheduleData else { return }
        let dayName = getDayName(from: weekday)
        currentDayData = scheduleData.weekSchedule[dayName]
        scheduleTableView.reloadData()
    }
    
    private func updateAllWeekdayButtons() {
        for (index, button) in weekdayButtons.enumerated() {
            guard let weekday = Weekday.allCases.first(where: { $0.index == index }) else { continue }
            let hasData = hasScheduleData(for: weekday)
            let isSelected = (weekday == selectedDay)
            updateWeekdayButton(button, hasData: hasData, isSelected: isSelected)
        }
    }
    
    // MARK: - Actions
    @objc private func weekdayButtonTapped(_ sender: UIButton) {
        guard let weekday = Weekday.allCases.first(where: { $0.index == sender.tag }) else { return }
        
        // Update selected day
        selectedDay = weekday
        
        // Update all buttons to show selection
        updateAllWeekdayButtons()
        
        // Load data for selected day
        loadDayData(for: weekday)
    }
    
    private func clearCurrentDaySchedule() {
        guard let scheduleData = clientScheduleData else { return }
        let dayName = getDayName(from: selectedDay)
        
        // Update the schedule data
        var updatedSchedule = scheduleData
        updatedSchedule.weekSchedule[dayName] = DayScheduleData(
            isActive: false,
            sleepHours: 0,
            waterIntake: 0,
            cardioNotes: ""
        )
        
        clientScheduleData = updatedSchedule
        currentDayData = updatedSchedule.weekSchedule[dayName]
        
        // Update UI
        updateAllWeekdayButtons()
        scheduleTableView.reloadData()
        
        // Persist changes
        persistSchedule()
    }
    
    // MARK: - Button Actions
    @IBAction func clearButtonTapped(_ sender: Any) {
        let alert = UIAlertController(
            title: "Clear Schedule",
            message: "Are you sure you want to clear this day's schedule?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.clearCurrentDaySchedule()
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        // Save to JSON file
        saveScheduleToJSON()
        
        // Show success feedback
        let alert = UIAlertController(
            title: "Success",
            message: "Schedule saved successfully!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func saveScheduleToJSON() {
        guard let schedule = clientScheduleData,
              let fileURL = Bundle.main.url(forResource: "clientSchedulesData", withExtension: "json") else {
            return
        }
        
        do {
            // Read existing data
            let data = try Data(contentsOf: fileURL)
            var response = try JSONDecoder().decode(ClientSchedulesResponse.self, from: data)
            
            // Update or add this client's schedule
            if let index = response.schedules.firstIndex(where: { $0.clientId == schedule.clientId }) {
                response.schedules[index] = schedule
            } else {
                response.schedules.append(schedule)
            }
            
            // Write back to file
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(response)
            
            // Get writable path in Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let writableURL = documentsPath.appendingPathComponent("clientSchedulesData.json")
            try jsonData.write(to: writableURL)
            
            print("✅ Schedule saved to: \(writableURL.path)")
        } catch {
            print("❌ Error saving schedule: \(error)")
        }
    }
    
    // MARK: - Persistence
    private func persistSchedule() {
        guard let schedule = clientScheduleData else { return }
        
        if let encoded = try? JSONEncoder().encode(schedule) {
            UserDefaults.standard.set(encoded, forKey: "ClientSchedule_\(schedule.clientId)")
        }
    }
}

// MARK: - UITableViewDataSource
extension TrainerClientProfileScheduleViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // Collapsible items (Workout, Diet Plan)
            return 2
        } else if section == 1 {
            // Slider items (Sleep Schedule, Water Intake)
            return 2
        } else if section == 2 {
            // Text input items (Cardio)
            return 1
        } else {
            // Buttons (Clear, Save)
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // Collapsible items
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCardCell", for: indexPath) as? ScheduleCardCell else {
                return UITableViewCell()
            }
            
            if indexPath.row == 0 {
                let item = ScheduleItem(id: "1", title: "Workout", description: "Tap to view details", type: .collapsible)
                cell.configure(with: item)
            } else {
                let item = ScheduleItem(id: "2", title: "Diet Plan", description: "Tap to view details", type: .collapsible)
                cell.configure(with: item)
            }
            
            cell.delegate = self
            return cell
        } else if indexPath.section == 1 {
            // Slider items
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCardCell", for: indexPath) as? SliderCardCell else {
                return UITableViewCell()
            }
            
            let dayData = currentDayData
            
            if indexPath.row == 0 {
                // Sleep Schedule
                let sliderItem = SliderItem(
                    id: "sleep",
                    title: "Sleep Schedule",
                    unit: "h",
                    minValue: 0,
                    maxValue: 12,
                    currentValue: dayData?.sleepHours ?? 7.5,
                    displayValue: "\(dayData?.sleepHours ?? 7.5)h"
                )
                cell.configure(with: sliderItem)
            } else {
                // Water Intake
                let sliderItem = SliderItem(
                    id: "water",
                    title: "Water Intake",
                    unit: "L",
                    minValue: 0,
                    maxValue: 8,
                    currentValue: dayData?.waterIntake ?? 3.0,
                    displayValue: "\(dayData?.waterIntake ?? 3.0)L"
                )
                cell.configure(with: sliderItem)
            }
            
            cell.delegate = self
            return cell
        } else if indexPath.section == 2 {
            // Text input (Cardio)
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CardioInputCell", for: indexPath) as? CardioInputCell else {
                return UITableViewCell()
            }
            
            cell.configure(with: currentDayData?.cardioNotes ?? "")
            cell.delegate = self
            return cell
        } else {
            // Buttons section
            let cell = UITableViewCell(style: .default, reuseIdentifier: "ButtonCell")
            cell.backgroundColor = .black
            cell.selectionStyle = .none
            
            // Container for buttons
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(containerView)
            
            // Clear button
            let clearButton = UIButton(type: .system)
            clearButton.translatesAutoresizingMaskIntoConstraints = false
            clearButton.setTitle("Clear", for: .normal)
            clearButton.setTitleColor(.white, for: .normal)
            clearButton.backgroundColor = UIColor(hex: "#fe1414")
            clearButton.titleLabel?.font = UIFont(name: "WorkSans-SemiBold", size: 16)
            clearButton.layer.cornerRadius = 12
            clearButton.addTarget(self, action: #selector(clearButtonTapped(_:)), for: .touchUpInside)
            containerView.addSubview(clearButton)
            
            // Save button
            let saveButton = UIButton(type: .system)
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            saveButton.setTitle("Save", for: .normal)
            saveButton.setTitleColor(.black, for: .normal)
            saveButton.backgroundColor = UIColor(hex: "#aefe14")
            saveButton.titleLabel?.font = UIFont(name: "WorkSans-SemiBold", size: 16)
            saveButton.layer.cornerRadius = 12
            saveButton.addTarget(self, action: #selector(saveButtonTapped(_:)), for: .touchUpInside)
            containerView.addSubview(saveButton)
            
            // Constraints
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 20),
                containerView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -20),
                containerView.heightAnchor.constraint(equalToConstant: 50),
                
                clearButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                clearButton.topAnchor.constraint(equalTo: containerView.topAnchor),
                clearButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                
                saveButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: 20),
                saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                saveButton.topAnchor.constraint(equalTo: containerView.topAnchor),
                saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                saveButton.widthAnchor.constraint(equalTo: clearButton.widthAnchor)
            ])
            
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension TrainerClientProfileScheduleViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80  // Collapsible items
        } else if indexPath.section == 1 {
            return 160  // Slider items
        } else {
            return 100  // Text input items
        }
    }
}

// MARK: - ScheduleCardCellDelegate
extension TrainerClientProfileScheduleViewController: ScheduleCardCellDelegate {
    
    func scheduleCardCell(_ cell: ScheduleCardCell, didTapExpandFor item: ScheduleItem) {
        // Handle card expansion
        persistSchedule()
    }
}

// MARK: - SliderCardCellDelegate
extension TrainerClientProfileScheduleViewController: SliderCardCellDelegate {
    
    func sliderCardCell(_ cell: SliderCardCell, didUpdateValue value: Double, for sliderItem: SliderItem) {
        guard var scheduleData = clientScheduleData, var dayData = currentDayData else { return }
        let dayName = getDayName(from: selectedDay)
        
        // Update the appropriate value
        if sliderItem.id == "sleep" {
            dayData = DayScheduleData(
                isActive: dayData.isActive,
                sleepHours: value,
                waterIntake: dayData.waterIntake,
                cardioNotes: dayData.cardioNotes
            )
        } else if sliderItem.id == "water" {
            dayData = DayScheduleData(
                isActive: dayData.isActive,
                sleepHours: dayData.sleepHours,
                waterIntake: value,
                cardioNotes: dayData.cardioNotes
            )
        }
        
        // Update schedule data
        var updatedSchedule = scheduleData.weekSchedule
        updatedSchedule[dayName] = dayData
        clientScheduleData = ClientScheduleData(clientId: scheduleData.clientId, weekSchedule: updatedSchedule)
        currentDayData = dayData
        
        persistSchedule()
    }
}

// MARK: - CardioInputCellDelegate
extension TrainerClientProfileScheduleViewController: CardioInputCellDelegate {
    
    func cardioInputCell(_ cell: CardioInputCell, didUpdateValue text: String) {
        guard var scheduleData = clientScheduleData, var dayData = currentDayData else { return }
        let dayName = getDayName(from: selectedDay)
        
        // Update cardio notes
        dayData = DayScheduleData(
            isActive: dayData.isActive,
            sleepHours: dayData.sleepHours,
            waterIntake: dayData.waterIntake,
            cardioNotes: text
        )
        
        // Update schedule data
        var updatedSchedule = scheduleData.weekSchedule
        updatedSchedule[dayName] = dayData
        clientScheduleData = ClientScheduleData(clientId: scheduleData.clientId, weekSchedule: updatedSchedule)
        currentDayData = dayData
        
        persistSchedule()
    }
}


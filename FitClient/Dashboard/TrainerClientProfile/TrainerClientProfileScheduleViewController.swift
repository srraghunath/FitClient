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
    private var clientSchedule: ClientSchedule?
    private var weekdayButtons: [UIButton] = []
    private var expandedIndexPaths: Set<IndexPath> = []
    
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
        // Clear existing buttons
        weekdayStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        weekdayButtons.removeAll()
        
        // Create circles for each weekday
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
        let isActive = clientSchedule?.isActiveDays(on: weekday) ?? true
        updateWeekdayButton(button, isActive: isActive)
        
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
    
    private func updateWeekdayButton(_ button: UIButton, isActive: Bool) {
        if isActive {
            button.backgroundColor = UIColor(hex: "#aefe14")
            
            // Inner circle background
            let innerView = UIView()
            innerView.backgroundColor = .black
            innerView.layer.cornerRadius = 7
            innerView.clipsToBounds = true
            button.subviews.forEach { $0.removeFromSuperview() }
            button.addSubview(innerView)
            
            innerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                innerView.widthAnchor.constraint(equalToConstant: 14),
                innerView.heightAnchor.constraint(equalToConstant: 14),
                innerView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                innerView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])
            
            button.layer.borderWidth = 0
        } else {
            button.backgroundColor = UIColor(hex: "#fe1414")
            button.setTitle(nil, for: .normal)
            button.subviews.forEach { $0.removeFromSuperview() }
            
            // Inner circle
            let innerView = UIView()
            innerView.backgroundColor = .black
            innerView.layer.cornerRadius = 7
            innerView.clipsToBounds = true
            button.addSubview(innerView)
            
            innerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                innerView.widthAnchor.constraint(equalToConstant: 14),
                innerView.heightAnchor.constraint(equalToConstant: 14),
                innerView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                innerView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])
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
        // Create sample schedule data matching Figma design
        let scheduleItems = [
            ScheduleItem(id: "1", title: "Workout", description: "Tap to view details", type: .collapsible),
            ScheduleItem(id: "2", title: "Diet Plan", description: "Tap to view details", type: .collapsible),
            ScheduleItem(id: "3", title: "Sleep Schedule", description: "Tap to view details", type: .slider),
            ScheduleItem(id: "4", title: "Water Intake", description: "Tap to view details", type: .slider),
            ScheduleItem(id: "5", title: "Cardio", description: "Enter cardio plan", type: .textInput)
        ]
        
        let sliderItems = [
            SliderItem(id: "sleep", title: "Sleep Schedule", unit: "h", minValue: 0, maxValue: 12, currentValue: 7.5, displayValue: "7.5h"),
            SliderItem(id: "water", title: "Water Intake", unit: "L", minValue: 0, maxValue: 8, currentValue: 7.0, displayValue: "7.0L")
        ]
        
        let daySchedule = DaySchedule(
            day: .monday,
            isActive: true,
            scheduleItems: scheduleItems
        )
        
        clientSchedule = ClientSchedule(
            clientId: "client123",
            weekSchedule: [daySchedule],
            sliderItems: sliderItems
        )
        
        scheduleTableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func weekdayButtonTapped(_ sender: UIButton) {
        guard let weekday = Weekday.allCases.first(where: { $0.index == sender.tag }) else { return }
        
        clientSchedule?.toggleDay(weekday)
        
        // Find the matching button and update it
        if let index = weekdayButtons.firstIndex(where: { $0.tag == sender.tag }) {
            updateWeekdayButton(weekdayButtons[index], isActive: clientSchedule?.isActiveDays(on: weekday) ?? true)
        }
        
        // Persist to UserDefaults
        persistSchedule()
    }
    
    // MARK: - Persistence
    private func persistSchedule() {
        guard let schedule = clientSchedule else { return }
        
        if let encoded = try? JSONEncoder().encode(schedule) {
            UserDefaults.standard.set(encoded, forKey: "ClientSchedule_\(schedule.clientId)")
        }
    }
    
    private func loadPersistedSchedule() {
        guard let clientId = clientSchedule?.clientId,
              let data = UserDefaults.standard.data(forKey: "ClientSchedule_\(clientId)"),
              let schedule = try? JSONDecoder().decode(ClientSchedule.self, from: data) else {
            return
        }
        
        clientSchedule = schedule
        scheduleTableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension TrainerClientProfileScheduleViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let schedule = clientSchedule else { return 0 }
        
        if section == 0 {
            // Collapsible items (Workout, Diet Plan)
            return schedule.weekSchedule.first?.scheduleItems.filter { $0.type == .collapsible }.count ?? 0
        } else if section == 1 {
            // Slider items (Sleep Schedule, Water Intake)
            return schedule.sliderItems.count
        } else {
            // Text input items (Cardio)
            return schedule.weekSchedule.first?.scheduleItems.filter { $0.type == .textInput }.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let schedule = clientSchedule else {
            return UITableViewCell()
        }
        
        if indexPath.section == 0 {
            // Collapsible items
            guard let collapsibleItems = schedule.weekSchedule.first?.scheduleItems.filter({ $0.type == .collapsible }),
                  indexPath.row < collapsibleItems.count else {
                return UITableViewCell()
            }
            
            let item = collapsibleItems[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCardCell", for: indexPath) as? ScheduleCardCell else {
                return UITableViewCell()
            }
            
            cell.configure(with: item)
            cell.delegate = self
            return cell
        } else if indexPath.section == 1 {
            // Slider items
            guard indexPath.row < schedule.sliderItems.count else {
                return UITableViewCell()
            }
            
            let sliderItem = schedule.sliderItems[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCardCell", for: indexPath) as? SliderCardCell else {
                return UITableViewCell()
            }
            
            cell.configure(with: sliderItem)
            cell.delegate = self
            return cell
        } else {
            // Text input items (Cardio)
            guard let textInputItems = schedule.weekSchedule.first?.scheduleItems.filter({ $0.type == .textInput }),
                  indexPath.row < textInputItems.count else {
                return UITableViewCell()
            }
            
            let item = textInputItems[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CardioInputCell", for: indexPath) as? CardioInputCell else {
                return UITableViewCell()
            }
            
            cell.configure()
            cell.delegate = self
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
        // Update slider item in schedule
        if let index = clientSchedule?.sliderItems.firstIndex(where: { $0.id == sliderItem.id }) {
            clientSchedule?.sliderItems[index] = sliderItem
        }
        
        persistSchedule()
    }
}

// MARK: - CardioInputCellDelegate
extension TrainerClientProfileScheduleViewController: CardioInputCellDelegate {
    
    func cardioInputCell(_ cell: CardioInputCell, didUpdateValue text: String) {
        // Update cardio text in schedule
        persistSchedule()
    }
}


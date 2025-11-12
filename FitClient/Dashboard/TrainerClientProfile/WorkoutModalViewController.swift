//
//  WorkoutModalViewController.swift
//  FitClient
//

import UIKit

class WorkoutModalViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
    private var searchBar: UISearchBar!
    private var allWorkouts: [Workout] = []
    private var displayedWorkouts: [Workout] = []
    private var filteredWorkouts: [Workout] = []
    private var selectedWorkoutIds: Set<String> = []
    private var searchText: String = ""
    
    var initialSelectedIds: [String] = []
    var onSave: (([String]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set selected IDs FIRST before loading workouts
        selectedWorkoutIds = Set(initialSelectedIds)
        logDebug("Modal initialized with \(initialSelectedIds.count) pre-selected workout IDs: \(initialSelectedIds)")
        
        setupUI()
        setupTableView()
        setupSegmentedControl()
        loadWorkouts()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        titleLabel.text = "Schedule Workout"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        closeButton.backgroundColor = UIColor(hex: "#212121")
        closeButton.layer.cornerRadius = 15
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        saveButton.applyPrimaryStyle(title: "Save")
        
        // Setup search bar
        setupSearchBar()
    }
    
    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search workouts..."
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .black
        searchBar.barTintColor = .black
        searchBar.tintColor = .primaryGreen
        
        // Style the search text field
        if let textField = searchBar.searchTextField as UITextField? {
            textField.backgroundColor = UIColor(hex: "#303131")
            textField.textColor = .white
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search workouts...",
                attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
            )
            textField.leftView?.tintColor = .white
        }
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Position search bar between segmented control and table view
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Adjust table view top constraint to be below search bar
        for constraint in view.constraints {
            if constraint.firstItem as? UITableView == tableView && constraint.firstAnchor == tableView.topAnchor {
                constraint.isActive = false
            }
        }
        tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8).isActive = true
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        
        let nib = UINib(nibName: "WorkoutCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "WorkoutCell")
    }
    
    private func setupSegmentedControl() {
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegment(withTitle: "Upper Body", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Lower Body", at: 1, animated: false)
        segmentedControl.insertSegment(withTitle: "Full Body", at: 2, animated: false)
        segmentedControl.selectedSegmentIndex = 0  // Start with Upper Body
        
        segmentedControl.backgroundColor = UIColor(hex: "#313232")
        segmentedControl.selectedSegmentTintColor = .primaryGreen
        
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ], for: .normal)
        
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .selected)
    }
    
    private func loadWorkouts() {
        DataService.shared.loadWorkouts { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let workouts):
                    self?.allWorkouts = workouts
                    self?.logDebug("Loaded \(workouts.count) total workouts from DataService")
                    self?.filterWorkouts()
                case .failure(let error):
                    self?.logDebug("Failed to load workouts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func filterWorkouts() {
        let category: WorkoutCategory
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            category = .upperBody
        case 1:
            category = .lowerBody
        case 2:
            category = .fullBody
        default:
            category = .upperBody
        }
        
        logDebug("Filtering for category: \(category.rawValue), selectedWorkoutIds has \(selectedWorkoutIds.count) items: \(Array(selectedWorkoutIds)), searchText: '\(searchText)'")
        
        // Filter by category first
        var workouts = allWorkouts.filter { $0.category == category }
        
        // Apply search filter if search text exists
        if !searchText.isEmpty {
            workouts = workouts.filter { workout in
                workout.name.lowercased().contains(searchText.lowercased()) ||
                workout.description.lowercased().contains(searchText.lowercased())
            }
            logDebug("After search filter: \(workouts.count) workouts match '\(searchText)'")
        }
        
        // Apply selection state
        displayedWorkouts = workouts.map { workout in
            var mutableWorkout = workout
            let isSelected = selectedWorkoutIds.contains(workout.id)
            mutableWorkout.isSelected = isSelected
            if isSelected {
                logDebug("  -> Workout \(workout.id) (\(workout.name)) IS SELECTED")
            }
            return mutableWorkout
        }
        
        let selectedCount = displayedWorkouts.filter { $0.isSelected }.count
        logDebug("Final filtered workouts for \(category.rawValue): \(displayedWorkouts.count) total, \(selectedCount) PRE-SELECTED")
        
        // Reload with animation disabled for immediate update
        UIView.setAnimationsEnabled(false)
        tableView.reloadData()
        UIView.setAnimationsEnabled(true)
        
        logDebug("Table reloaded, visible cells: \(tableView.visibleCells.count)")
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        filterWorkouts()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        let selectedIds = Array(selectedWorkoutIds)
        onSave?(selectedIds)
        logDebug("Saving \(selectedIds.count) selected workouts: \(selectedIds)")
        dismiss(animated: true)
    }
    
    private func logDebug(_ message: String) {
        let logMessage = "[WorkoutModal] \(message)\n"
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logURL = documentsPath.appendingPathComponent("workout_debug.log")
            if let data = logMessage.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: logURL)
                }
            }
        }
    }
}

extension WorkoutModalViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedWorkouts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as! WorkoutCell
        let workout = displayedWorkouts[indexPath.row]
        cell.configure(with: workout)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let workout = displayedWorkouts[indexPath.row]
        
        if selectedWorkoutIds.contains(workout.id) {
            selectedWorkoutIds.remove(workout.id)
            logDebug("Deselected workout: \(workout.name)")
        } else {
            selectedWorkoutIds.insert(workout.id)
            logDebug("Selected workout: \(workout.name)")
        }
        
        displayedWorkouts[indexPath.row].isSelected.toggle()
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

// MARK: - UISearchBarDelegate
extension WorkoutModalViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        logDebug("Search text changed to: '\(searchText)'")
        filterWorkouts()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchText = ""
        searchBar.resignFirstResponder()
        filterWorkouts()
    }
}

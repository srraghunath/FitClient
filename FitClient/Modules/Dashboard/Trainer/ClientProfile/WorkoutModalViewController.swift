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
    private var selectedWorkoutSet: Set<String> = []
    private var selectedWorkoutOrder: [String] = []
    private var workoutDetails: [String: WorkoutScheduleDetail] = [:]
    private var searchText: String = ""
    
    var initialSelectedIds: [String] = []
    var initialWorkoutDetails: [WorkoutScheduleDetail] = []
    var onSave: ((_ selectedIds: [String], _ workoutDetails: [WorkoutScheduleDetail]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set selected IDs FIRST before loading workouts
        selectedWorkoutSet = Set(initialSelectedIds)
        selectedWorkoutOrder = initialSelectedIds
        workoutDetails = initialWorkoutDetails.reduce(into: [:]) { result, detail in
            result[detail.workoutId] = detail
        }
        for detail in initialWorkoutDetails where !selectedWorkoutSet.contains(detail.workoutId) {
            selectedWorkoutSet.insert(detail.workoutId)
            selectedWorkoutOrder.append(detail.workoutId)
        }
        logDebug("Modal initialized with \(selectedWorkoutSet.count) pre-selected workout IDs: \(selectedWorkoutOrder)")
        
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
        
    let activeOrder = selectedWorkoutOrder.filter { selectedWorkoutSet.contains($0) }
    logDebug("Filtering for category: \(category.rawValue), selectedWorkoutIds has \(selectedWorkoutSet.count) items: \(activeOrder), searchText: '\(searchText)'")
        
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
            let isSelected = selectedWorkoutSet.contains(workout.id)
            mutableWorkout.isSelected = isSelected
            if let detail = workoutDetails[workout.id] {
                mutableWorkout.targetReps = detail.targetReps
                mutableWorkout.targetWeight = detail.targetWeight
            }
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
        let orderedIds = selectedWorkoutOrder.filter { selectedWorkoutSet.contains($0) }
        let details = orderedIds.map { workoutDetails[$0] ?? WorkoutScheduleDetail(workoutId: $0, targetReps: nil, targetWeight: nil) }
        onSave?(orderedIds, details)
        logDebug("Saving \(orderedIds.count) selected workouts: \(orderedIds) with details: \(details.map { $0.shortSummary })")
        dismiss(animated: true)
    }
    
    private func ensureSelection(for workout: Workout) {
        if !selectedWorkoutSet.contains(workout.id) {
            selectedWorkoutSet.insert(workout.id)
            selectedWorkoutOrder.append(workout.id)
            logDebug("Selected workout: \(workout.name)")
        }
    }
    
    private func removeSelection(for workout: Workout) {
        if selectedWorkoutSet.remove(workout.id) != nil {
            logDebug("Deselected workout: \(workout.name)")
        }
        selectedWorkoutOrder.removeAll { $0 == workout.id }
        workoutDetails[workout.id] = nil
        refreshRow(for: workout.id)
    }
    
    private func refreshRow(for workoutId: String) {
        guard let index = displayedWorkouts.firstIndex(where: { $0.id == workoutId }) else { return }
        displayedWorkouts[index].isSelected = selectedWorkoutSet.contains(workoutId)
        displayedWorkouts[index].targetReps = workoutDetails[workoutId]?.targetReps
        displayedWorkouts[index].targetWeight = workoutDetails[workoutId]?.targetWeight
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    private func presentDetailInput(for workout: Workout, isNewSelection: Bool) {
        let alert = UIAlertController(
            title: workout.name,
            message: "Set target reps and weight (optional).",
            preferredStyle: .alert
        )
        let existingDetail = workoutDetails[workout.id]
        alert.addTextField { textField in
            textField.placeholder = "Reps"
            textField.keyboardType = .numberPad
            if let reps = existingDetail?.targetReps {
                textField.text = String(reps)
            }
        }
        alert.addTextField { [weak self] textField in
            textField.placeholder = "Weight (kg)"
            textField.keyboardType = .decimalPad
            if let weight = existingDetail?.targetWeight, let formatted = self?.weightModalFormattedString(weight) {
                textField.text = formatted
            }
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }
            let reps = self.parseInt(from: alert.textFields?.first?.text)
            let weight = self.parseDouble(from: alert.textFields?.last?.text)
            let detail = WorkoutScheduleDetail(workoutId: workout.id, targetReps: reps, targetWeight: weight)
            self.ensureSelection(for: workout)
            self.workoutDetails[workout.id] = detail
            self.refreshRow(for: workout.id)
        }
        alert.addAction(saveAction)
        
        if isNewSelection {
            let skipAction = UIAlertAction(title: "Skip", style: .default) { [weak self] _ in
                guard let self else { return }
                self.ensureSelection(for: workout)
                if self.workoutDetails[workout.id] == nil {
                    self.workoutDetails[workout.id] = WorkoutScheduleDetail(workoutId: workout.id, targetReps: nil, targetWeight: nil)
                }
                self.refreshRow(for: workout.id)
            }
            alert.addAction(skipAction)
        } else {
            let clearAction = UIAlertAction(title: "Clear Targets", style: .default) { [weak self] _ in
                guard let self else { return }
                self.ensureSelection(for: workout)
                self.workoutDetails[workout.id] = WorkoutScheduleDetail(workoutId: workout.id, targetReps: nil, targetWeight: nil)
                self.refreshRow(for: workout.id)
            }
            alert.addAction(clearAction)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentSelectionOptions(for workout: Workout, at indexPath: IndexPath) {
        let message: String
        if let detail = workoutDetails[workout.id], detail.hasTargets {
            message = "Current target: \(detail.shortSummary)"
        } else {
            message = "No targets set."
        }
        let actionSheet = UIAlertController(title: workout.name, message: message, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Edit Targets", style: .default) { [weak self] _ in
            self?.presentDetailInput(for: workout, isNewSelection: false)
        })
        if let detail = workoutDetails[workout.id], detail.hasTargets {
            actionSheet.addAction(UIAlertAction(title: "Clear Targets", style: .default) { [weak self] _ in
                guard let self else { return }
                self.ensureSelection(for: workout)
                self.workoutDetails[workout.id] = WorkoutScheduleDetail(workoutId: workout.id, targetReps: nil, targetWeight: nil)
                self.refreshRow(for: workout.id)
            })
        }
        actionSheet.addAction(UIAlertAction(title: "Remove Workout", style: .destructive) { [weak self] _ in
            self?.removeSelection(for: workout)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            if let cell = tableView.cellForRow(at: indexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            } else {
                popover.sourceView = tableView
                popover.sourceRect = CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: 1, height: 1)
            }
        }
        present(actionSheet, animated: true)
    }
    
    private func parseInt(from text: String?) -> Int? {
        guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        return Int(raw)
    }
    
    private func parseDouble(from text: String?) -> Double? {
        guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        let sanitized = raw.replacingOccurrences(of: ",", with: ".")
        return Double(sanitized)
    }
    
    private func weightModalFormattedString(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
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
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let workout = displayedWorkouts[indexPath.row]
        if selectedWorkoutSet.contains(workout.id) {
            presentSelectionOptions(for: workout, at: indexPath)
        } else {
            presentDetailInput(for: workout, isNewSelection: true)
        }
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

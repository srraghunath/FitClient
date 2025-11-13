//
//  DietModalViewController.swift
//  FitClient
//

import UIKit

class DietModalViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
    private var searchBar: UISearchBar!
    private var allDiets: [Diet] = []
    private var displayedDiets: [Diet] = []
    private var selectedDietItems: [String: (dietId: String, quantity: Int)] = [:] // Key: dietId, Value: (dietId, quantity)
    private var searchText: String = ""
    
    var initialSelectedDiets: [(dietId: String, quantity: Int)] = []
    var onSave: (([(dietId: String, quantity: Int)]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set selected diets FIRST before loading diets (exactly like WorkoutModal)
        for item in initialSelectedDiets {
            selectedDietItems[item.dietId] = item
        }
        logDebug("Modal initialized with \(initialSelectedDiets.count) pre-selected diet items: \(initialSelectedDiets)")
        
        setupUI()
        setupTableView()
        setupSegmentedControl()
        loadDiets()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        titleLabel.text = "Schedule Diet"
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
        searchBar.placeholder = "Search dishes..."
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .black
        searchBar.barTintColor = .black
        searchBar.tintColor = .primaryGreen
        
        // Style the search text field
        if let textField = searchBar.searchTextField as UITextField? {
            textField.backgroundColor = UIColor(hex: "#303131")
            textField.textColor = .white
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search dishes...",
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
        
        let nib = UINib(nibName: "DietCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "DietCell")
    }
    
    private func setupSegmentedControl() {
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegment(withTitle: "Breakfast", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Lunch", at: 1, animated: false)
        segmentedControl.insertSegment(withTitle: "Dinner", at: 2, animated: false)
        segmentedControl.selectedSegmentIndex = 0  // Start with Breakfast
        
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
    
    private func loadDiets() {
        DataService.shared.loadDiets { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let diets):
                    self?.allDiets = diets
                    self?.logDebug("Loaded \(diets.count) total diets from DataService")
                    self?.filterDiets()
                case .failure(let error):
                    self?.logDebug("Failed to load diets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func filterDiets() {
        let mealType: MealType
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            mealType = .breakfast
        case 1:
            mealType = .lunch
        case 2:
            mealType = .dinner
        default:
            mealType = .breakfast
        }
        
        logDebug("Filtering for meal type: \(mealType.rawValue), selectedDietItems has \(selectedDietItems.count) items, searchText: '\(searchText)'")
        
        // Filter by meal type first
        var diets = allDiets.filter { $0.mealType == mealType }
        
        // Apply search filter if search text exists
        if !searchText.isEmpty {
            diets = diets.filter { diet in
                diet.name.lowercased().contains(searchText.lowercased())
            }
            logDebug("After search filter: \(diets.count) diets match '\(searchText)'")
        }
        
        // Apply selection state and quantity
        displayedDiets = diets.map { diet in
            var mutableDiet = diet
            if let selectedItem = selectedDietItems[diet.id] {
                mutableDiet.isSelected = true
                mutableDiet.quantity = selectedItem.quantity
                logDebug("  -> Diet \(diet.id) (\(diet.name)) IS SELECTED with quantity \(selectedItem.quantity)")
            } else {
                mutableDiet.isSelected = false
                mutableDiet.quantity = 1
            }
            return mutableDiet
        }
        
        let selectedCount = displayedDiets.filter { $0.isSelected }.count
        logDebug("Final filtered diets for \(mealType.rawValue): \(displayedDiets.count) total, \(selectedCount) PRE-SELECTED")
        
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
        filterDiets()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        let selectedItems = Array(selectedDietItems.values)
        onSave?(selectedItems)
        logDebug("Saving \(selectedItems.count) selected diets")
        dismiss(animated: true)
    }
    
    private func logDebug(_ message: String) {
        let logMessage = "[DietModal] \(message)\n"
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logURL = documentsPath.appendingPathComponent("diet_debug.log")
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

extension DietModalViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Section Headers
    func numberOfSections(in tableView: UITableView) -> Int {
        return DietType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dietType = DietType.allCases[section]
        let count = displayedDiets.filter { $0.dietType == dietType }.count
        return count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let dietType = DietType.allCases[section]
        let dietsInSection = displayedDiets.filter { $0.dietType == dietType }
        
        guard !dietsInSection.isEmpty else { return nil }
        
        let headerView = UIView()
        headerView.backgroundColor = .black
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = dietType.displayName
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .primaryGreen
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let dietType = DietType.allCases[section]
        let dietsInSection = displayedDiets.filter { $0.dietType == dietType }
        return dietsInSection.isEmpty ? 0 : 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DietCell", for: indexPath) as! DietCell
        
        let dietType = DietType.allCases[indexPath.section]
        let dietsInSection = displayedDiets.filter { $0.dietType == dietType }
        let diet = dietsInSection[indexPath.row]
        
        cell.configure(with: diet) { [weak self] newQuantity in
            guard let self = self else { return }
            
            // Find the diet in displayedDiets and update quantity
            if let index = self.displayedDiets.firstIndex(where: { $0.id == diet.id }) {
                self.displayedDiets[index].quantity = newQuantity
                
                // Update selectedDietItems if this diet is selected
                if self.selectedDietItems[diet.id] != nil {
                    self.selectedDietItems[diet.id] = (dietId: diet.id, quantity: newQuantity)
                    self.logDebug("Updated quantity for \(diet.name) to \(newQuantity)")
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let dietType = DietType.allCases[indexPath.section]
        let dietsInSection = displayedDiets.filter { $0.dietType == dietType }
        let diet = dietsInSection[indexPath.row]
        
        // Find the actual index in displayedDiets
        guard let actualIndex = displayedDiets.firstIndex(where: { $0.id == diet.id }) else { return }
        
        if selectedDietItems[diet.id] != nil {
            selectedDietItems.removeValue(forKey: diet.id)
            displayedDiets[actualIndex].isSelected = false
            logDebug("Deselected diet: \(diet.name)")
        } else {
            let quantity = displayedDiets[actualIndex].quantity
            selectedDietItems[diet.id] = (dietId: diet.id, quantity: quantity)
            displayedDiets[actualIndex].isSelected = true
            logDebug("Selected diet: \(diet.name) with quantity \(quantity)")
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

// MARK: - UISearchBarDelegate
extension DietModalViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        logDebug("Search text changed to: '\(searchText)'")
        filterDiets()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchText = ""
        searchBar.resignFirstResponder()
        filterDiets()
    }
}

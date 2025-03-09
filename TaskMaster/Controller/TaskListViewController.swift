

import UIKit
import UserNotifications
import CoreLocation

class TaskListViewController: UIViewController, TaskCreationDelegate, UISearchBarDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var taskListTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var taskRepository: TaskRepositoryProtocol!
    var tasks: [Task] = []
    var filteredTasks: [Task] = []
    
    var groupedTasks: [String: [Task]] = [:]
    var sortedCategories: [String] = []
    let refreshControl = UIRefreshControl()
    
    var currentSortCriteria: SortCriteria = .dueDate
    
    enum SortCriteria {
        case dueDate
        case priority
        case category
    }
    
    // Location Manager for handling user location
    var locationManager: CLLocationManager!
    var userLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taskListTableView.register(UINib(nibName: "TaskListTableViewCell", bundle: nil), forCellReuseIdentifier: "TaskListTableViewCell")
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        taskRepository = TaskRepository(context: context)
        
        tasks = taskRepository.fetchAllTasks()
        filteredTasks = tasks
        
        searchBar.delegate = self
        setupRefreshControl()
        groupTasksByCategory()
        scheduleNotificationsForTasks()
        
        // Set up location manager to track user location
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        taskListTableView.reloadData()
        
        toggleSearchBarVisibility()
    }
    
    func setupRefreshControl() {
        taskListTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    @objc func refreshData() {
        tasks = taskRepository.fetchAllTasks()
        filteredTasks = tasks
        groupTasksByCategory()
        scheduleNotificationsForTasks()
        taskListTableView.reloadData()
        toggleSearchBarVisibility()
        refreshControl.endRefreshing()
    }
    func toggleSearchBarVisibility() {
        if tasks.isEmpty {
            searchBar.isHidden = true
        } else {
            searchBar.isHidden = false
        }
    }
    
    
    func groupTasksByCategory() {
        groupedTasks = [:]
        
        for task in filteredTasks {
            let category = task.category
            if groupedTasks[category ?? ""] == nil {
                groupedTasks[category ?? ""] = []
            }
            groupedTasks[category ?? ""]?.append(task)
        }
        
        sortedCategories = groupedTasks.keys.sorted()
    }
    
    func scheduleNotificationsForTasks() {
        for task in filteredTasks {
            if let dueDate = task.dueDate, let dueTime = task.dueTime {
                scheduleLocalNotification(for: task)
            }
        }
    }
    
    func scheduleLocalNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = task.title ?? "Task"
        content.body = task.descriptionField ?? "No description available"
        content.sound = .default
        
        // Check if the task is overdue
        if task.eventStatus == "Overdue" {
            content.body = "Overdue: " + (task.descriptionField ?? "No description available")
        }
        
        if task.eventStatus == "Overdue" {
            if let dueDate = task.dueDate, let dueTime = task.dueTime {
                let calendar = Calendar.current
                let dueDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: dueTime),
                                                minute: calendar.component(.minute, from: dueTime),
                                                second: calendar.component(.second, from: dueTime),
                                                of: dueDate)
                
                if let dueDateTime = dueDateTime {
                    let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dueDateTime), repeats: true)
                    
                    let request = UNNotificationRequest(identifier: task.objectID.uriRepresentation().absoluteString, content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling daily notification: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            // For tasks that are not overdue, schedule the notification as usual (one-time notification)
            if let dueDate = task.dueDate, let dueTime = task.dueTime {
                let calendar = Calendar.current
                let dueDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: dueTime),
                                                minute: calendar.component(.minute, from: dueTime),
                                                second: calendar.component(.second, from: dueTime),
                                                of: dueDate)
                
                if let dueDateTime = dueDateTime {
                    let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dueDateTime), repeats: false)
                    
                    let request = UNNotificationRequest(identifier: task.objectID.uriRepresentation().absoluteString, content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling notification: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func sortTasks() {
        switch currentSortCriteria {
        case .dueDate:
            filteredTasks.sort { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        case .priority:
            filteredTasks.sort { ($0.priority ?? 0) < ($1.priority ?? 0) }
        case .category:
            filteredTasks.sort { ($0.category ?? "") < ($1.category ?? "") }
        }
        groupTasksByCategory()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredTasks = tasks
        } else {
            filteredTasks = tasks.filter { task in
                let lowercasedSearchText = searchText.lowercased()
                let matchesTitle = task.title?.lowercased().contains(lowercasedSearchText) ?? false
                let matchesDescription = task.descriptionField?.lowercased().contains(lowercasedSearchText) ?? false
                let matchesCategory = task.category?.lowercased().contains(lowercasedSearchText) ?? false
                
                let matchesDueDate = task.dueDate?.formattedDateString.contains(lowercasedSearchText) ?? false
                
                let matchesPriority = "\(task.priority ?? 0)".contains(lowercasedSearchText) ||
                task.priority.description.lowercased().contains(lowercasedSearchText) ?? false
                
                return matchesTitle || matchesDescription || matchesCategory || matchesDueDate || matchesPriority
            }
        }
        sortTasks()
        taskListTableView.reloadData()
        toggleSearchBarVisibility()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filteredTasks = tasks
        sortTasks()
        taskListTableView.reloadData()
    }
    
    func didCreateTask() {
        tasks = taskRepository.fetchAllTasks()
        filteredTasks = tasks
        sortTasks()
        taskListTableView.reloadData()
    }
    
    @IBAction func createTaskTapped(_ sender: UIButton) {
        let createTaskVC = storyboard?.instantiateViewController(identifier: "CreateTaskViewController") as! CreateTaskViewController
        createTaskVC.delegate = self
        present(createTaskVC, animated: true)
    }
    
    // CLLocationManager Delegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        userLocation = newLocation
        checkForNearbyTasks()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
    
    func checkForNearbyTasks() {
        guard let userLocation = userLocation else { return }
        
        for task in filteredTasks {
            if task.latitude > 0 && task.longitude > 0 {
                let taskLocation = CLLocation(latitude: task.latitude, longitude: task.longitude)
                let distance = userLocation.distance(from: taskLocation)
                
                if distance < 100 {
                    sendPushNotification(for: task)
                }
            }
        }
    }
    
    func sendPushNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "You're near a task!"
        content.body = "Reminder: \(task.title ?? "No title") is near you."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.objectID.uriRepresentation().absoluteString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    
    func sortAndGroupTasks() {
        
        filteredTasks.sort { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        
        groupedTasks = [:]
        for task in filteredTasks {
            guard let category = task.category else { continue }
            if groupedTasks[category] == nil {
                groupedTasks[category] = []
            }
            
            groupedTasks[category]?.append(task)
        }
        
        sortedCategories = groupedTasks.keys.sorted()
        
        taskListTableView.reloadData()
    }
    
    @IBAction func sortTapped(_ sender: UIButton) {
        sortAndGroupTasks()
        taskListTableView.reloadData()
    }
}

extension TaskListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if sortedCategories.isEmpty {
            tableView.setEmptyMessage("No Tasks added yet")
        } else {
            tableView.restore()
            return sortedCategories.count
        }
        return sortedCategories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let category = sortedCategories[section]
        if let tasksInCategory = groupedTasks[category], !tasksInCategory.isEmpty {
            return tasksInCategory.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedCategories[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListTableViewCell", for: indexPath) as! TaskListTableViewCell
        cell.selectionStyle = .none
        
        let category = sortedCategories[indexPath.section]
        if let tasksInCategory = groupedTasks[category] {
            let task = tasksInCategory[indexPath.row]
            cell.titleLbl.text = task.title
            cell.eventStatus.text = task.eventStatus
            cell.setDateLabel(with: task.dueDate)
            
            switch task.eventStatus {
            case "Overdue":
                cell.eventStatus.textColor = .red
            case "Complete":
                cell.eventStatus.textColor = .green
            case "Pending":
                cell.eventStatus.textColor = .yellow
            default:
                cell.eventStatus.textColor = .black
            }
            
            cell.flagComplete.tag = indexPath.row
            cell.flagComplete.addTarget(self, action: #selector(flagCompleteTapped(_:)), for: .touchUpInside)
            
            if task.isComplete {
                cell.flagComplete.isEnabled = false
                cell.flagComplete.tintColor = .green
            } else {
                cell.flagComplete.isEnabled = true
                cell.flagComplete.tintColor = .darkGray
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    @objc func flagCompleteTapped(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint.zero, to: taskListTableView)
        if let indexPath = taskListTableView.indexPathForRow(at: buttonPosition) {
            let category = sortedCategories[indexPath.section]
            if let tasksInCategory = groupedTasks[category], indexPath.row < tasksInCategory.count {
                var task = tasksInCategory[indexPath.row]
                task.isComplete.toggle()
                let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                
                if task.isComplete {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.objectID.uriRepresentation().absoluteString])
                }
                
                do {
                    try context.save()
                } catch {
                    print("Error saving task: \(error)")
                }
                
                tasks = taskRepository.fetchAllTasks()
                filteredTasks = tasks
                sortTasks()
                taskListTableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let category = sortedCategories[indexPath.section]
            
            if var tasksInCategory = groupedTasks[category], indexPath.row < tasksInCategory.count {
                let task = tasksInCategory[indexPath.row]
                let success = taskRepository.deleteTask(task: task)
                
                if success {
                    tasksInCategory.remove(at: indexPath.row)
                    groupedTasks[category] = tasksInCategory
                    if tasksInCategory.isEmpty {
                        groupedTasks.removeValue(forKey: category)
                    }
                    sortedCategories = groupedTasks.keys.sorted()
                    if groupedTasks[category]?.isEmpty ?? true {
                        tableView.deleteSections([indexPath.section], with: .automatic)
                    } else {
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                    tasks = taskRepository.fetchAllTasks()
                    if sortedCategories.isEmpty {
                        tableView.setEmptyMessage("No Tasks added yet")
                    } else {
                        tableView.restore()
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = sortedCategories[indexPath.section]
        if let tasksInCategory = groupedTasks[category], indexPath.row < tasksInCategory.count {
            let task = tasksInCategory[indexPath.row]
            let vc = storyboard?.instantiateViewController(identifier: "CreateTaskViewController") as! CreateTaskViewController
            vc.task = task
            vc.editType = true
            self.present(vc, animated: true)
        }
    }
}

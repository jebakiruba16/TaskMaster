//Added From Github
import UIKit
import MapKit

protocol TaskCreationDelegate: AnyObject {
    func didCreateTask()
}
class CreateTaskViewController: UIViewController, UITextFieldDelegate {
    weak var delegate: TaskCreationDelegate?
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var dateBtn: UIButton!
    @IBOutlet weak var timeBtn: UIButton!
    @IBOutlet weak var dateSwitch: UISwitch!
    @IBOutlet weak var timeSwitch: UISwitch!
    @IBOutlet weak var priorityLbl: UILabel!
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var locationLblDisplayView: UIView!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var categoryLbl: UILabel!
    
    var datePicker: UIDatePicker!
    var timePicker: UIDatePicker!
    
    var tappedCoordinate: CLLocationCoordinate2D?
    var taskRepository: TaskRepositoryProtocol!
    
    var task: Task?
    var editType = Bool()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.isHidden = true
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.isHidden = true
        timePicker.addTarget(self, action: #selector(timeChanged(_:)), for: .valueChanged)
        
        
        view.addSubview(datePicker)
        view.addSubview(timePicker)
        
        if let task = task {
            titleTextView.text = task.title
            descriptionTextView.text = task.descriptionField
            categoryLbl.text = task.category

            priorityLbl.text = TaskPriority(rawValue: task.priority)?.description ?? "None"
            if let dueDate = task.dueDate {
                dateBtn.setTitle(dueDate.formattedDateString, for: .normal)
                dateSwitch.isOn = true
            }
            
            if let dueTime = task.dueTime {
                timeBtn.setTitle(dueTime.formattedTimeString, for: .normal)
                timeSwitch.isOn = true
            }
            
            if let location = task.location {
                locationLbl.text = location
                locationLblDisplayView.isHidden = false
                locationSwitch.isOn = true
            }
        } else {
            
            dateBtn.setTitle("Pick a Date", for: .normal)
            timeBtn.setTitle("Pick a Time", for: .normal)
            dateSwitch.isOn = false
            timeSwitch.isOn = false
            locationSwitch.isOn = false
            locationLblDisplayView.isHidden = true
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        taskRepository = TaskRepository(context: context)
        
        
        dateToggle(dateSwitch)
        timeToggle(timeSwitch)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged), name: NetworkManager.networkStatusChangedNotification, object: nil)
        
    
    }

    
    deinit {
           NotificationCenter.default.removeObserver(self, name: NetworkManager.networkStatusChangedNotification, object: nil)
       }
    
    @objc func networkStatusChanged() {
          if !NetworkManager.shared.isConnected() {
              showNetworkErrorAlert()
          }
      }
    
    func showNetworkErrorAlert() {
        let alert = UIAlertController(
            title: "No Network Connection",
            message: "You are not connected to the internet. Please check your network settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func doneBtnTapped(_ sender: UIButton) {
        guard let title = titleTextView.text, !title.isEmpty,
              let description = descriptionTextView.text else {
            return
        }
        
        let selectedDate = dateSwitch.isOn ? datePicker.date : nil
        let selectedTime = timeSwitch.isOn ? timePicker.date : nil
        let location = locationLbl.text
        let latitude = tappedCoordinate?.latitude ?? 0
        let longitude = tappedCoordinate?.longitude ?? 0
        let category = categoryLbl.text ?? "Other"
        
        let priorityString = priorityLbl.accessibilityValue ?? "\(TaskPriority.none.rawValue)"
           let priority = TaskPriority(rawValue: Int16(priorityString) ?? TaskPriority.none.rawValue)
        let priorityValue = priority?.rawValue ?? TaskPriority.none.rawValue
        if editType, let task = task {
            let updated = taskRepository.updateTask(
                task: task,
                title: title,
                description: description,
                date: selectedDate,
                time: selectedTime,
                location: location,
                latitude: latitude,
                longitude: longitude,
                priority: priorityValue,
                category: category
            )
            if updated {
                print("Task updated successfully!")
                delegate?.didCreateTask()
                dismiss(animated: true)
            } else {
                print("Failed to update task")
            }
        } else {
            print("Task is nil or not in edit mode.")
            let priorityValue = priority?.rawValue ?? TaskPriority.none.rawValue
            task = taskRepository.saveTask(title: title,
                                           description: description,
                                           date: selectedDate,
                                           time: selectedTime,
                                           location: location,
                                           latitude: latitude,
                                           longitude: longitude,
                                           priority: priorityValue,
                                           category: category)
            
            if task != nil {
                print("Task saved successfully!")
                delegate?.didCreateTask()
                dismiss(animated: true)
            } else {
                print("Failed to save task")
            }
            
        }
        
    }
    
    @IBAction func locationToggle(_ sender: UISwitch) {
            if !NetworkManager.shared.isConnected() {
                showNetworkErrorAlert()
                return
            }
          
            if sender.isOn {
                let vc = storyboard?.instantiateViewController(identifier: "MapKitViewController") as! MapKitViewController
                vc.delegate = self
                self.present(vc, animated: true)
            } else {
                locationLbl.text = "Location not selected"
            }
        }

    @IBAction func viewLocationTapped(_ sender: UIButton) {
        
        if let task = task ,editType == true{
            let vc = storyboard?.instantiateViewController(identifier: "MapKitViewController") as! MapKitViewController
            vc.selectedLocation = task.location
            let coordinate = CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)
            vc.coordinate = coordinate
            self.present(vc, animated: true)
        }
        else{
            guard let location = locationLbl.text, !location.isEmpty else {
                print("No location selected")
                return
            }
            let vc = storyboard?.instantiateViewController(identifier: "MapKitViewController") as! MapKitViewController
            vc.selectedLocation = location
            vc.coordinate = tappedCoordinate
            self.present(vc, animated: true)
        }
        
    }
    
    @IBAction func closeBtnTapped(_ sender:UIButton){
        dismiss(animated: true)
    }
}

extension CreateTaskViewController: LocationSelectionDelegate {
    
    func didSelectLocation(_ location: String,coordinate: CLLocationCoordinate2D) {
        if location.isEmpty {
            locationSwitch.isOn = false
            locationLbl.text = ""
            locationLblDisplayView.isHidden = true
        } else {
            locationSwitch.isOn = true
            locationLbl.text = location
            locationLblDisplayView.isHidden = false
            tappedCoordinate = coordinate
        }
    }
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        let selectedDate = sender.date
        dateBtn.setTitle(selectedDate.formattedDateString, for: .normal)
        datePicker.isHidden = true
    }
    
    @objc func timeChanged(_ sender: UIDatePicker) {
        let selectedTime = sender.date
        timeBtn.setTitle(selectedTime.formattedTimeString, for: .normal)
        timePicker.isHidden = true
    }
    
    @IBAction func dateToggle(_ sender: UISwitch) {
        if sender.isOn {
            datePicker.isHidden = false
//            let selectedDate = Date()
//            dateBtn.setTitle(selectedDate.formattedDateString, for: .normal)
//           datePicker.isHidden = true
            datePicker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                datePicker.topAnchor.constraint(equalTo: dateBtn.bottomAnchor, constant: 10),
                datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                datePicker.heightAnchor.constraint(equalToConstant: 200)
            ])
        } else {
            dateBtn.setTitle("Pick a Date", for: .normal)
           
            datePicker.isHidden = true
        }
    }
    
    @IBAction func timeToggle(_ sender: UISwitch) {
        if sender.isOn {
            timePicker.isHidden = false
            timePicker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                timePicker.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 10),
                timePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                timePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                timePicker.heightAnchor.constraint(equalToConstant: 200)
            ])
        } else {
            timeBtn.setTitle("Pick a Time", for: .normal)
            timePicker.isHidden = true
        }
    }
    
    
    @IBAction func categoryTapped(_ sender: UIButton) {  
        let alert = UIAlertController(title: "Select Category", message: nil, preferredStyle: .actionSheet)
        
        
        let workAction = UIAlertAction(title: TaskCategory.work.rawValue, style: .default) { _ in
            self.categoryLbl.text = TaskCategory.work.rawValue
        }
        let personalAction = UIAlertAction(title: TaskCategory.personal.rawValue, style: .default) { _ in
            self.categoryLbl.text = TaskCategory.personal.rawValue
        }
        let urgentAction = UIAlertAction(title: TaskCategory.urgent.rawValue, style: .default) { _ in
            self.categoryLbl.text = TaskCategory.urgent.rawValue
        }
        let studyAction = UIAlertAction(title: TaskCategory.study.rawValue, style: .default) { _ in
            self.categoryLbl.text = TaskCategory.study.rawValue
        }
        let noneAction = UIAlertAction(title: TaskCategory.other.rawValue, style: .default) { _ in
            self.categoryLbl.text = TaskCategory.other.rawValue
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(workAction)
        alert.addAction(personalAction)
        alert.addAction(urgentAction)
        alert.addAction(studyAction)
        alert.addAction(noneAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func priorityTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Select Priority", message: nil, preferredStyle: .actionSheet)
        
        let highAction = UIAlertAction(title: "High", style: .default) { _ in
            self.priorityLbl.text = "High"
            self.priorityLbl.accessibilityValue = "\(TaskPriority.high.rawValue)"  // Store the Int16 value
        }
        let mediumAction = UIAlertAction(title: "Medium", style: .default) { _ in
            self.priorityLbl.text = "Medium"
            self.priorityLbl.accessibilityValue = "\(TaskPriority.medium.rawValue)"  // Store the Int16 value
        }
        let lowAction = UIAlertAction(title: "Low", style: .default) { _ in
            self.priorityLbl.text = "Low"
            self.priorityLbl.accessibilityValue = "\(TaskPriority.low.rawValue)"  // Store the Int16 value
        }
        let noneAction = UIAlertAction(title: "None", style: .default) { _ in
            self.priorityLbl.text = "None"
            self.priorityLbl.accessibilityValue = "\(TaskPriority.none.rawValue)"  // Store the Int16 value
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(highAction)
        alert.addAction(mediumAction)
        alert.addAction(lowAction)
        alert.addAction(noneAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }

    @IBAction func dateChangedTapped(_ sender: UIButton) {
//        let selectedDate = sender.date
//        dateBtn.setTitle(selectedDate.formattedDateString, for: .normal)
        datePicker.isHidden = false
    }
    
    @IBAction func timeChangedTapped(_ sender: UIButton) {
//        let selectedTime = sender.date
//        timeBtn.setTitle(selectedTime.formattedTimeString, for: .normal)
        timePicker.isHidden = false
    }
   
}

enum TaskCategory: String {
    case work = "Work"
    case personal = "Personal"
    case urgent = "Urgent"
    case study = "Study"
    case other = "Other"
}

enum TaskPriority: Int16 {
    case high = 1
    case medium = 2
    case low = 3
    case none = 0

    var description: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .none: return "None"
        }
    }
}

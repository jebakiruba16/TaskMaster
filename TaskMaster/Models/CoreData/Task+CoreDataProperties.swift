

import Foundation
import CoreData

extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var descriptionField: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var dueTime: Date?
    @NSManaged public var title: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var location: String?
    @NSManaged public var priority: Int16
    @NSManaged public var category: String?
    @NSManaged public var isComplete: Bool
    @NSManaged public var eventStaus: String?
   

    var eventStatus: String {
        if isComplete {
            return "Complete"
        }
        
        if let dueDate = dueDate, let dueTime = dueTime {
            let calendar = Calendar.current
            let dueDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: dueTime),
                                            minute: calendar.component(.minute, from: dueTime),
                                            second: calendar.component(.second, from: dueTime),
                                            of: dueDate)
            
            if let dueDateTime = dueDateTime, dueDateTime < Date() {
                return "Overdue"
            }
        }
 
        return "Pending"
    }
}
extension Task : Identifiable {
}



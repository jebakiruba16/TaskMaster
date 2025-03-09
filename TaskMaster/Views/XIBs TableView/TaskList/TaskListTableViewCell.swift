
import UIKit

class TaskListTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var eventStatus: UILabel!
    @IBOutlet weak var flagComplete: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
 
    func setDateLabel(with date: Date?) {
        guard let date = date else {
            dateLbl.text = "No date available"
            return
        }
        
        let calendar = Calendar.current
        let currentDate = Date()
     
        if calendar.isDateInToday(date) {
            dateLbl.text = "Today"
        }
        else if calendar.isDateInYesterday(date) {
            dateLbl.text = "Yesterday"
        }
      
        else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateLbl.text = dateFormatter.string(from: date)
        }
    }
}



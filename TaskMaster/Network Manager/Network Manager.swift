
import Foundation
import Network

class NetworkManager {
    
    static let shared = NetworkManager()
    
    private var monitor: NWPathMonitor?
    private var isNetworkConnected = true
    

    static let networkStatusChangedNotification = Notification.Name("networkStatusChangedNotification")
    
    private init() {

        monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitorQueue")
        monitor?.start(queue: queue)
        
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkConnected = path.status == .satisfied
                NotificationCenter.default.post(name: NetworkManager.networkStatusChangedNotification, object: nil)
            }
        }
    }

    func isConnected() -> Bool {
        return isNetworkConnected
    }
}


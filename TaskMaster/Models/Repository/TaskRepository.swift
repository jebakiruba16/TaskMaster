//
//  TaskRepository.swift
//  TaskMaster
//
//  Created by Lexicon Systems on 08/03/25.
//

import Foundation
import CoreData

protocol TaskRepositoryProtocol {
    func saveTask(title: String, description: String, date: Date?, time: Date?, location: String?, latitude: Double, longitude: Double, priority: Int16,category:String) -> Task?
    func fetchAllTasks() -> [Task]
    func deleteTask(task: Task) -> Bool
    func updateTask(task: Task, title: String?, description: String?, date: Date?, time: Date?, location: String?, latitude: Double?, longitude: Double?, priority: Int16, category:String?) -> Bool
}

class TaskRepository: TaskRepositoryProtocol {
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func saveTask(title: String, description: String, date: Date?, time: Date?, location: String?, latitude: Double, longitude: Double, priority: Int16, category:String) -> Task? {
        let task = Task(context: context)
        task.title = title
        task.descriptionField = description
        task.dueDate = date
        task.dueTime = time
        task.location = location
        task.latitude = latitude
        task.longitude = longitude
        task.priority = priority
        task.category = category
        do {
            try context.save()
            return task
        } catch {
            print("Error saving task: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchAllTasks() -> [Task] {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching tasks: \(error.localizedDescription)")
            return []
        }
    }
    
  
    func deleteTask(task: Task) -> Bool {
        context.delete(task)
        do {
            try context.save()
            return true
        } catch {
            print("Error deleting task: \(error.localizedDescription)")
            return false
        }
    }
    
   
    func updateTask(task: Task, title: String?, description: String?, date: Date?, time: Date?, location: String?, latitude: Double?, longitude: Double?, priority: Int16, category:String?) -> Bool {
      
        if let title = title {
            task.title = title
        }
        if let description = description {
            task.descriptionField = description
        }
        if let date = date {
            task.dueDate = date
        }
        if let time = time {
            task.dueTime = time
        }
        if let location = location {
            task.location = location
        }
        if let latitude = latitude {
            task.latitude = latitude
        }
        if let longitude = longitude {
            task.longitude = longitude
        }
//        if let priority = priority {
//            task.priority = priority
//        }
        task.priority = priority
        
        do {
            try context.save()
            return true
        } catch {
            print("Error updating task: \(error.localizedDescription)")
            return false
        }
    }
}


//
//  ViewController.swift
//  CoreDataTutorial
//
//  Created by James Rochabrun on 3/1/17.
//  Copyright © 2017 James Rochabrun. All rights reserved.
//

import UIKit
import CoreData



class PhotoVC: UITableViewController {
    
    private let cellID = "cellID"
    //MARK:// WITH FETCH REQUEST CONTROLLER
    lazy var fetcedhResultController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Photo.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "author", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    //1 create photo array
    //var photoArray: [Photo]?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Photos Feed"

        do {
            try self.fetcedhResultController.performFetch()
            print("COUNT FETCHED FIRST: \(self.fetcedhResultController.sections?[0].numberOfObjects)")
        } catch let error  {
            print("ERROR: \(error)")
        }
        
        view.backgroundColor = .white
        tableView.register(PhotoCell.self, forCellReuseIdentifier: cellID)
    // clearData()
    test()
    }
    
    func test() {
        
        let apiService = APIService()
        apiService.getDataWith { (result) in
            switch result {
            case .Success(let data):
                self.clearData()
                self.saveInCoreDataWith(array: data)
            case .Error(let message):
                print("Error: \(message)")
                
                DispatchQueue.main.async {
                   self.showAlertWith(title: "Error", message: message)
                }
            }
        }
    }
    
    func showAlertWith(title: String, message: String, style: UIAlertControllerStyle = .alert) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: title, style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! PhotoCell
        
        if let photo = fetcedhResultController.object(at: indexPath) as? Photo {
            cell.setPhotoCellWith(photo: photo)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let count = fetcedhResultController.sections?.first?.numberOfObjects {
            return count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.width + 100 //100 = sum of labels height + height of divider line
    }

    
    //MARK: // WITHOUT FETCH REQUEST CONTROLLER
    
    private func createPhotoEntityFrom(dictionary: [String: AnyObject]) -> NSManagedObject? {
        
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        if let photoEntity = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context) as? Photo {
            photoEntity.author = dictionary["author"] as? String
            photoEntity.tags = dictionary["tags"] as? String
            let mediaDictionary = dictionary["media"] as? [String: AnyObject]
            photoEntity.mediaURL = mediaDictionary?["m"] as? String
            return photoEntity
        }
        return nil
    }
    
    //SAVE
    private func saveInCoreDataWith(array: [[String: AnyObject]]) {
        _ = array.map{self.createPhotoEntityFrom(dictionary: $0)}
        do {
            try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
        } catch let error {
            print(error)
        }
    }
    
    //FETCH unused
//    func fetchdataFromCoredata() -> [Photo]? {
//        
//        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
//        do {
//            let photoArray = try context.fetch(fetchRequest) as? [Photo]
//            return photoArray
//        } catch let error {
//            print("ERROR FETHCING FROM CONTEXT : \(error)")
//        }
//        return nil
//    }
    
    //DELETE
    private func clearData() {
        do {
            
            let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            do {
                let objects  = try context.fetch(fetchRequest) as? [NSManagedObject]
                _ = objects.map{$0.map{context.delete($0)}}
                CoreDataStack.sharedInstance.saveContext()
            } catch let error {
                print("ERROR DELETING : \(error)")
            }
        }
    }
}


extension PhotoVC: NSFetchedResultsControllerDelegate {


    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
//        if type == .insert {
//            
//            DispatchQueue.main.async {
//                print("INDEX \(indexPath), NEW INDEX: \(newIndexPath)")
//            }
//        } else if == .dele
        
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("end updates")
        self.tableView.endUpdates()
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
        print("begin updates")
    }

}








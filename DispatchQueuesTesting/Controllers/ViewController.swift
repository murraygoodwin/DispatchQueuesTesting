//
//  ViewController.swift
//  DispatchQueuesTesting
//
//  Created by Murray Goodwin on 07/12/2020.
//

/// This demo simulates retrieving 'coffee shops' data (e.g. from JSON) on a background queue,
/// saving / updating it in Realm and updating a user interface on the main thread.

import UIKit
import RealmSwift

final class ViewController: UIViewController {
  
  private let backgroundQueue = DispatchQueue(label: "com.murraygoodwin.dispatchqueuestesting.backgroundqueue", qos: .userInitiated)
  
  private var coffeeShops: [CoffeeShop] = [] {
    didSet {
        self.updateUI()
    }
  }
  
  @IBOutlet private weak var coffeeShopsLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Print the local file path to allow us to view the Realm database using Realm Studio:
    // https://docs.realm.io/sync/realm-studio#download-the-latest-version
    //    printLocalFolderPath()
    
    backgroundQueue.async { [weak self] in
      guard let self = self else { return }
      
      self.loadExistingCoffeeShopsFromRealm { [weak self] (coffeeShops) in
        guard let self = self else { return }
        self.coffeeShops = coffeeShops
      }
    }
  }
  
  private func printLocalFolderPath() {
    
    let path = FileManager
      .default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .last?
      .absoluteString
      .replacingOccurrences(of: "file://", with: "")
      .removingPercentEncoding
    
    print(path ?? "Not found")
  }
  
  // MARK: - Save to Realm
  private func saveToRealm(coffeeShops: [CoffeeShop]) {
    
    let realm = try! Realm()
    
    try! realm.write {
      realm.add(coffeeShops)
    }
  }
  
  // MARK: - Load From Realm
  private func loadExistingCoffeeShopsFromRealm(completionHandler: @escaping ([CoffeeShop]) -> ()) {
    
    backgroundQueue.async {
      print("LOADING EXISTING COFFEE SHOPS FROM REALM")
      var existingShops: [CoffeeShop] = []
      
      let realm = try! Realm()
      existingShops = Array(realm.objects(CoffeeShop.self))
      completionHandler(existingShops)
    }
  }
  
  // MARK: - Fetch New Data
  @IBAction func downloadTotallyNewShops(_ sender: UIButton) {
    
    backgroundQueue.async { [weak self] in
      guard let self = self else { return }
      
      self.deleteAllCoffeeShopsFromRealm {
      
        print("DOWNLOADING NEW COFFEE SHOPS")
        
        var coffeeShopsArray: [CoffeeShop] = []
        
        for i in 1...3 {
          coffeeShopsArray.append(CoffeeShop(name: "☕️ Coffee Shop \(i)"))
          print("☕️ Coffee Shop \(i)")
          sleep(1)
        }
        
        self.saveToRealm(coffeeShops: coffeeShopsArray)
        self.coffeeShops = coffeeShopsArray
      }
    }
  }
  
  // MARK: - Append Existing Data
  @IBAction func addSomeNewShopsToTheExistingList(_ sender: UIButton) {
    
    backgroundQueue.async { [weak self] in
      guard let self = self, self.coffeeShops.count > 0 else { return }
      
      print("DOWNLOADING ADDITIONAL COFFEE SHOPS")
      
      var coffeeShopsArray: [CoffeeShop] = []
      
      for i in 4...6 {
        coffeeShopsArray.append(CoffeeShop(name: "☕️ Coffee Shop \(i)"))
        print("☕️ Coffee Shop \(i)")
        sleep(1)
      }
      
      self.saveToRealm(coffeeShops: coffeeShopsArray)
      self.loadExistingCoffeeShopsFromRealm { (coffeeShops) in
        self.coffeeShops = coffeeShops
      }
    }
  }
  
  // MARK: - Delete Existing Data
  private func deleteAllCoffeeShopsFromRealm(completionHandler: @escaping () -> ()) {
    
    backgroundQueue.async {
      
      let realm = try! Realm()
      
      try! realm.write {
        let existingRecords = realm.objects(CoffeeShop.self)
        print("REALM: DELETING \(existingRecords.count) EXISITNG COFFEESHOPS FROM REALM")
        realm.delete(existingRecords)
      }
      completionHandler()
    }
  }
  
  // MARK: - UI Updates
  private func updateUI() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.coffeeShopsLabel.text = "\(self.coffeeShops.count)"
    }
  }
}

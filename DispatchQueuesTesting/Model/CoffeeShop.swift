//
//  CoffeeShop.swift
//  DispatchQueuesTesting
//
//  Created by Murray Goodwin on 07/12/2020.
//

import UIKit
import RealmSwift

class CoffeeShop: Object {
  @objc dynamic var name: String = ""
  
  convenience init(name: String) {
    self.init()
    self.name = name
  }
}

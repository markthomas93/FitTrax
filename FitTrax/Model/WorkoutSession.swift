//  DC Fitness App
//
//  Version 1.0
//
//  Created by Kevin Cattran Sr
//

import Foundation

enum WorkoutSessionState {
  case notStarted
  case active
  case finished
}

class WorkoutSession {
  
  var state : WorkoutSessionState = .notStarted
  
  func start() {
    state = .active
//    print("Starting WorkoutSession")
  }
  
  func end() {
    state = .finished
//    print("Ending WorkoutSession")
  }
  
  func clear() {
    state = .notStarted
//    print("Clearing WorkoutSession")
  }
}

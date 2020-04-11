//
//  User.swift
//  DC Fitness
//
//  Created by Kevin Cattran Sr on 5/10/18.
//  Copyright © 2018 Kevin D Cattran Sr. All rights reserved.
//

import UIKit
import HealthKit

class User: UIViewController {

    //MARK: - Class instances
    let healthKit = HealthKit()
    
    //MARK: - Variables and Constants
    var userAge : Int = 0
    var userWeightInPounds : Double = 0.0
    var userWeightInKilo : Double = 0.0
    var userRestingHeartRate : Double = 0.0
    var userHeartRate : Double = 0.0
    let heartRateUnit : HKUnit = HKUnit(from: "count/min")
    var maxHeartRate : Int = 0
    var heartRateReserve : Int = 0
    var warmUpZone : Double = 0
    var fatBurningZone : Double = 0
    var cardioZone : Double = 0
    var peakZone : Double = 0
    var targetZoneUpper : Double = 0
    var targetZoneLower : Double = 0
    var duration : String = ""
    
    //MARK: - Get Age
    func loadGetAge(){
        
//        print("loadGetAge()")
        
        do {
            
            let loadUserAge = try healthKit.getAge()
            userAge = loadUserAge
            
        } catch {
            
            self.displayAgeAlert()
        }
    }
    
    func checkWeightStatus () {
        
        if userWeightInKilo == 0 {
            
            self.displayWeightAlert()
            
        }
    }
    
    //MARK: - Get Resting Heart Rate
    func getRestingHeartRate(mostRecentSample : HKQuantitySample) {
        
//        print("Resting Heart Rate: \(mostRecentSample.quantity.doubleValue(for: heartRateUnit))")
        userRestingHeartRate = mostRecentSample.quantity.doubleValue(for: heartRateUnit)
        
    }
    
    //MARK: - Get Heart Rate
    func getHeartRate(mostRecentSample : HKQuantitySample) {
        
//        print("Heart Rate: \(mostRecentSample.quantity.doubleValue(for: heartRateUnit))")
//        userHeartRate = mostRecentSample.quantity.doubleValue(for: heartRateUnit)
  
        userHeartRate = 180
    }
    
    //MARK: - Load Heart Rate
    func loadHeartRates() {
        
//        print("Calling healthKit.getUsersRestingHeartRate(completion)")
        healthKit.getUsersRestingHeartRate(completion: getRestingHeartRate)
        
//        print("Calling healthKit.getUsersHeartRate(completion)")
        healthKit.getUsersHeartRate(completion: getHeartRate)
        
    }
    
    //MARK: - Display Age Alert
    private func displayAgeAlert() {
        
//        print("displayAgeAlert()")
        let alert = UIAlertController(title: "FitTrax",
                                      message: "Missing Information!!!!\n\nPlease enter your age in the Health app to continue.\n\nIt is needed to calculate your maximum heart rate.",
                                      preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "OK",
                                       style: .default) { (action) in
                                        print("Calling viewDidLoad()")
//                                        self.viewController.viewDidLoad()
                                        
        }
        
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Display Weight Alert
    private func displayWeightAlert() {
        
//        print("displayWeightAlert()")
        let alert = UIAlertController(title: "FitTrax",
                                      message: "Missing Information!!!!\n\nPlease enter your weight in the Health app to continue.\n\nIt is needed to calculate your workout's calories per hour.",
                                      preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "OK",
                                       style: .default) { (action) in
                                        print("Calling viewDidLoad()")
                                        
        }
        
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Calculate Maximum Heart Rate
    func calculateMaxHeartRate() -> Int {
        
        maxHeartRate = 220 - userAge
        
        return maxHeartRate
    }
    
    //MARK: - Calculate Heart Rate Reserve
    // Used to determine the upper and lower target zones
    func calculateHeartRateReserve() -> Int {
        
        heartRateReserve = calculateMaxHeartRate() - Int(userRestingHeartRate)
        
        return heartRateReserve
    }
    
    //MARK: - Calculate Warm Up Zone
    func calculateWarmUpZone() -> Double {
        
        warmUpZone = Double(maxHeartRate) * 0.60
        
        return warmUpZone
    }
    
    //MARK: - Calculate Fat Burning Zone
    func calculateFatBurningZone() -> Double {
        
        fatBurningZone = Double(maxHeartRate) * 0.60
        
        return fatBurningZone
    }
    
    //MARK: - Calculate Cardio Zone
    func calculateCardioZone() -> Double {
        
        cardioZone = Double(maxHeartRate) * 0.75
        
        return cardioZone
    }
    
    //MARK: - Calculate Peak Zone
    func calculatePeakZone() -> Double {
        
        peakZone = Double(maxHeartRate) * 0.85
        
        return peakZone
    }
    
    //MARK: - Calculate Lower Target Zone
    func calculateLowerTargetZone() -> Double {
        
        targetZoneLower = Double(calculateHeartRateReserve()) * 0.70 + Double(userRestingHeartRate)
        
        return targetZoneLower
    }
    
    //MARK: - Calculate Upper Target Zone
    func calculateUpperTargetZone() -> Double {
        
        targetZoneUpper = Double(calculateHeartRateReserve()) * 0.85 + Double(userRestingHeartRate)
        
        return targetZoneUpper
    }
}

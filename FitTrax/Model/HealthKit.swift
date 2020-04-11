//  DC Fitness App
//
//  Version 1.0
//
//  Created by Kevin Cattran Sr
//

import UIKit
import HealthKit

class HealthKit {
    
    // 1. Create an instance of HKHealthStore
    //MARK: - Class instances
    let healthKitStore = HKHealthStore()
    
    // 2. Get data from view controller by assigning values within ViewController for each of the variables below
    //MARK: - Constants and Variables
    var workoutStartTime = Date()
    var workoutEndTime = Date()
    var distance : Double = 0.0
    var userWeightInPounds : Double = 0.0
    var userWeightInKilo : Double = 0.0
    var activityType : HKWorkoutActivityType = .other
    var workoutDescription : String = ""
    var workoutCaloriesPerHour : Double = 0
    var savedWorkout : Bool = true
    var HKMetadataKeyWorkoutBrandName: String = ""
    
    // workoutDuration must be of type time interval (AKA Double) which is the number of seconds
    var workoutDuration : TimeInterval = 3600
    
    //MARK: - Get Health Kit Permissions
    // 3. A Function to read/write data from health kit and called in ViewController's viewDidLoad()
    func getHealthKitPermission() {
        
//        print("Getting HealthKit Permissions and setting permissions")
        
        let sampleTypesToWrite: Set<HKSampleType> = [.workoutType(),
                                                     HKSampleType.quantityType(forIdentifier: .heartRate)!,
                                                     HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                                     HKSampleType.quantityType(forIdentifier: .distanceCycling)!,
                                                     HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!]

        // changed Set<> to super class HKObjectType from HKSampleType to allow both quantityTypes and characteristicTypes
        let sampleTypesToRead: Set<HKObjectType> = [.workoutType(),
                                                    HKSampleType.quantityType(forIdentifier: .heartRate)!,
                                                    HKSampleType.quantityType(forIdentifier: .restingHeartRate)!,
                                                    HKSampleType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
                                                    HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                                    HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
                                                    HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!,
                                                    HKSampleType.quantityType(forIdentifier: .distanceCycling)!,
                                                    HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                                    HKSampleType.quantityType(forIdentifier: .flightsClimbed)!,
                                                    HKSampleType.quantityType(forIdentifier: .stepCount)!,
                                                    HKSampleType.quantityType(forIdentifier: .bodyMass)!,
                                                    HKSampleType.quantityType(forIdentifier: .leanBodyMass)!,
                                                    HKSampleType.quantityType(forIdentifier: .height)!,
                                                    HKSampleType.quantityType(forIdentifier: .dietaryProtein)!,
                                                    HKSampleType.quantityType(forIdentifier: .dietaryFatTotal)!,
                                                    HKSampleType.quantityType(forIdentifier: .dietaryFatSaturated)!,
                                                    HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
                                                    HKSampleType.quantityType(forIdentifier: .dietaryCholesterol)!,
                                                    HKSampleType.quantityType(forIdentifier: .dietarySugar)!,
                                                    HKSampleType.quantityType(forIdentifier: .dietaryFiber)!,
                                                    HKSampleType.quantityType(forIdentifier: .dietarySodium)!,
                                                    HKSampleType.quantityType(forIdentifier: .bodyFatPercentage)!,
                                                    HKSampleType.characteristicType(forIdentifier: .dateOfBirth)!]
        
        //Check authorization from Healthkit and if it exists, let the user know.  If the check fails, let the user know.
        healthKitStore.requestAuthorization(toShare: sampleTypesToWrite, read: sampleTypesToRead) { (success, error) in
            if success {
                
                print("Permissions Approved!")
                
            } else {
                
                if error != nil {
                    print(error ?? "")
                }
                
                print("Permissions Denied!")
                
            }
        }
        
        self.getWeight()
        
    }
    
    //MARK: - Get Most Recent Sample
    //A query to get the most recent sample for whatever you would like to retreive
    func getMostRecentSample(for sampleType: HKSampleType,
                             completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
        
//        print("getMostRecentSample()")
        
        //1. Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date(),
                                                              options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        
        let limit = 1
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            //2. Always dispatch to the main thread when complete.
            DispatchQueue.main.async {
                
                guard let samples = samples,
                    let mostRecentSample = samples.first as? HKQuantitySample else {
                        
                        completion(nil, error)
                        return
                }
                
                completion(mostRecentSample, nil)
            }
        }
        
        HKHealthStore().execute(sampleQuery)
    }
    
    //MARK: - Get Weight
    func getWeight() {
        
//        print("getWeight()")
        
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            
            print("Weight Sample Type is no longer available in HealthKit")
            
            return
        }
        
        self.getMostRecentSample(for: weightSampleType, completion: { (sample, error) in
            
            guard let sample = sample else {
                
                return
            }
            
            self.userWeightInKilo = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            print("getWeight() assignment to userWeightInKilo ", self.userWeightInKilo)
            
            self.userWeightInPounds = sample.quantity.doubleValue(for: HKUnit.pound())
//            print("getWeight() assignment to userWeightInPounds ", self.userWeightInPounds)

        })
        
    }
    
    //MARK: - Get Age
    func getAge() throws -> (Int) {
        
//        print("healthKit.getAge()")
        
        var userAge : Int = 0
        
        do {
            
            //1. This method throws an error if this data is not available.
            let birthdayComponents =  try healthKitStore.dateOfBirthComponents()
            
            //2. Use Calendar to calculate age.
            let today = Date()
            
            let calendar = Calendar.current
            
            let todayDateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            
            let yearDifference = todayDateComponents.year! - birthdayComponents.year!
            
            if todayDateComponents.month! <= birthdayComponents.month!{
                
                userAge = yearDifference - 1
//                print("User's age is \(userAge)")
                
                if todayDateComponents.month! <= birthdayComponents.month! {
                    
                    if todayDateComponents.day! < birthdayComponents.day! {
                        
                        
                    } else {
                        
//                        print("User's birthday is: \(birthdayComponents.month!) \(birthdayComponents.day!) \(birthdayComponents.year!)")
                    }
                }
            } else {
                
                userAge = yearDifference
            }
            
            return (userAge)
        }
    }
    
    //MARK: - Get Users Resting Heart Rate
    func getUsersRestingHeartRate(completion: @escaping (HKQuantitySample) -> Void) {
        
//        print("getUsersRestingHeartRate(Completion)")
        
        guard let restingHeartRateSampleType = HKSampleType.quantityType(forIdentifier: .restingHeartRate) else {
            print("Resting Heart Rate Sample Type is no longer available in HealthKit")
            return
        }
        
        //1. Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date(),
                                                              options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let sampleQuery = HKSampleQuery(sampleType: restingHeartRateSampleType,
                                        predicate: mostRecentPredicate,
                                        limit: HKObjectQueryNoLimit,
                                        sortDescriptors:
        [sortDescriptor]) { (query, samples, error) in
            DispatchQueue.main.async {
                guard let samples = samples,
                    let mostRecentSample = samples.first as? HKQuantitySample else {
                        print("getUserRestingHeartRate sample is missing")
                        return
                }
                completion(mostRecentSample)
            }
        }
        HKHealthStore().execute(sampleQuery)
    }
    
    //MARK: - Get Users Heart Rate
    func getUsersHeartRate(completion: @escaping (HKQuantitySample) -> Void) {
        
//        print("getUsersHeartRate(Completion)")
        
        guard let heartRateSampleType = HKSampleType.quantityType(forIdentifier: .heartRate) else {
            print("Resting Heart Rate Sample Type is no longer available in HealthKit")
            return
        }
        
        //1. Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date(),
                                                              options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let sampleQuery = HKSampleQuery(sampleType: heartRateSampleType,
                                        predicate: mostRecentPredicate,
                                        limit: HKObjectQueryNoLimit,
                                        sortDescriptors:
        [sortDescriptor]) { (query, samples, error) in
            DispatchQueue.main.async {
                guard let samples = samples,
                    let mostRecentSample = samples.first as? HKQuantitySample else {
                        print("getUserHeartRate sample is missing")
                        return
                }
                completion(mostRecentSample)
            }
        }
        HKHealthStore().execute(sampleQuery)
    }

    //MARK: - Save Workout
    func saveWorkout() {
        
//        print("saveWorkout()")
        
        // workoutDistance and workoutCaloriesBurned must be function variables to accept double value inputs from initialization within the class.  Self is not available until functions are called.
        
        // workoutDistance must be of type HKQuantity
        let workoutDistance = HKQuantity(unit: HKUnit.mile(), doubleValue: distance)
//        print("workoutDistance: \(workoutDistance)")
        
        // workoutCaloriesBurned = workoutCaloriesPerHour * timedSeconds / 3600
        let calculatedWorkoutCaloriesBurned : Double = workoutCaloriesPerHour * workoutDuration / 3600
//        print("calculatedWorkoutCaloriesBurned: \(calculatedWorkoutCaloriesBurned)")
        
        // workoutCaloriesBurned must be of type HKQuantity
        let workoutCaloriesBurned = HKQuantity(unit: HKUnit.kilocalorie(),
                                               doubleValue: calculatedWorkoutCaloriesBurned)
//        print("workoutCalorieBurned: \(workoutCaloriesBurned)")
        
        let workoutActivityType : HKWorkoutActivityType = activityType
//        print("workoutActivityType")
        
//        print("Assigning values to workout")
        let workout = HKWorkout(activityType: workoutActivityType,
                                start: workoutStartTime,
                                end: workoutEndTime,
                                duration: workoutDuration,
                                totalEnergyBurned: workoutCaloriesBurned,
                                totalDistance: workoutDistance,
                                device: HKDevice.local(),
                                metadata: [String("Workout Name"): HKMetadataKeyWorkoutBrandName])
        
//        print("Printing workout data: \n\(workout)")
        
//        print("Saving workout to healthKitStore")
        self.healthKitStore.save(workout, withCompletion: { (success, error) in
            
            if error == nil {
                print("Checking for error == nil")
                self.savedWorkoutAlert()
            } else {
                print("Workout failed to save")
                self.workoutDidNotSave()
            }
            
        })
        
        // Adding more detailed information about the workout
        guard let energyBurnedType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) else {
            fatalError("*** Unable to create an energy burned type ***")
        }
        
        //Here energy Burned must be a Double
        let energyBurned = HKQuantity(unit: HKUnit.kilocalorie(),
                                      doubleValue: calculatedWorkoutCaloriesBurned)
        
//        print("Adding more detail information to workout -> energyBurned \(energyBurned)")
        
        let energyBurnedSample = HKQuantitySample(type: energyBurnedType, quantity: energyBurned, start: workoutStartTime, end: workoutEndTime)
        
        self.healthKitStore.save(energyBurnedSample) { (success, error) in
            
//            print("Adding Active Energy Burned to Health Kit: \(energyBurnedSample)")
            
        }
        
        saveHeartRateIntoHealthStore(height: 68)
        
    }
    
    //MARK: - Save Heart Rate to HealthKit
    func saveHeartRateIntoHealthStore(height:Double) -> Void
       {
           // Save the user's heart rate into HealthKit.
        let heartRateUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
           let heartRateQuantity: HKQuantity = HKQuantity(unit: heartRateUnit, doubleValue: height)

        let heartRate : HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
           let nowDate: NSDate = NSDate()

           let heartRateSample: HKQuantitySample = HKQuantitySample(type: heartRate
            , quantity: heartRateQuantity, start: nowDate as Date, end: nowDate as Date)

        let completion: ((Bool, Error?) -> Void) = {
               (success, error) -> Void in

               if !success {
                print("An error occured saving the Heart Rate sample \(heartRateSample). In your app, try to handle this gracefully. The error was: \(String(describing: error)).")

                   abort()
               }

           }

        print("Saving Heart Rate to Health Kit Store -> \(heartRate)")
        
        self.healthKitStore.save(heartRateSample, withCompletion: completion)

       }// end saveHeartRateIntoHealthStore
    //MARK: - Saved Workout Alert
    func savedWorkoutAlert() {
        
//        print("Workout saved successfully")
        savedWorkout = true
        
    }
    
    //MARK: - Workout Did Not Save
    func workoutDidNotSave() {
        
//        print("Workout did not save")
        savedWorkout = false

    }
}



//  DC Fitness App
//
//  Version 1.0
//
//  Created by Kevin Cattran Sr
//

import UIKit
import HealthKit
import AVFoundation
import CoreLocation
import WatchConnectivity

class WorkoutViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, AVAudioPlayerDelegate  {

    //MARK: - Class Instances
    let healthKit = HealthKit()
    let user = User()
    
    //MARK: - Variables and Constants
    var time = 0
    var interval = 0
    var timer = Timer()
    var timerState = TimerState.inactive
    var timerInterval = 0.0
    var timerStartDate = Date()
    var workoutTime = 0
    var workoutTimer = Timer()
    var session = WorkoutSession()
    var status : String = ""
    var workoutStart = Date()
    var workoutEnd = Date()
    var totalCaloriesBurned : String = ""
    var selectedActivity = HKWorkoutActivityType.cycling
    var distance : Int = 0
    var duration : String = ""
    var currentArrayRow : Int = 0
    var audioPlayer : AVAudioPlayer!
    var cps : Double = 0.0
    var runningCPS : Double = 0.0
    var currentWeightInKG : Double = 0.0
    let heartRateWarning = "Gear Warning"
    
    //MARK: - Arrays
    var activityArray: [(String, Int, Double, HKWorkoutActivityType, String)] =
        [("-----", 0, 0.0, .other, "Source"),
         ("Bicycling - Leisurely", 1, 3.5, .cycling, "MET"),
         ("Calisthenics", 0, 7.0, .functionalStrengthTraining, "Calculated"),
         ("Elliptical", 0, 7.0, .elliptical, "Historical Trend"),
         ("Hiking (Easy)", 1, 3.5, .hiking, "MET"),
         ("Hiking", 1, 7.0, .hiking, "Estimate"),
         ("Mixed Cardio", 0, 7.0, .mixedCardio, "Calculated"),
         ("Resistance Bands", 0, 7.0, .functionalStrengthTraining, "Calculated"),
         ("Rowing", 0, 7.0, .rowing, "Estimate"),
         ("Strength Training", 0, 7.0, .traditionalStrengthTraining, "Historical Trend"),
         ("Walking (3.5 mph)", 1, 4.3, .walking, "MET"),
         ("Yoga", 0, 2.3, .yoga, "MET")]

    //MARK: - IBOutlets
    @IBOutlet weak var exercisePicker: UIPickerView!
    @IBOutlet weak var cphLabel: UILabel!
    @IBOutlet weak var activeLabel: UILabel!
    @IBOutlet weak var ltzLabel: UILabel!
    @IBOutlet weak var utzLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var targetZonesProgressBarWidth: NSLayoutConstraint!
    @IBOutlet weak var targetHR: UILabel!
    @IBOutlet weak var warmupHR: UILabel!
    @IBOutlet weak var fatHR: UILabel!
    @IBOutlet weak var cardioHR: UILabel!
    @IBOutlet weak var peakHR: UILabel!
    @IBOutlet weak var zonesProgressBarWidth: NSLayoutConstraint!
    @IBOutlet weak var zonesHR: UILabel!
    @IBOutlet weak var timerStateLabel: UILabel!
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var pause: UIButton!
    
    //MARK: - IBActions
    @IBAction func startButton(_ sender: UIButton) {
        
        startButtonPressed()
        
    }
    
    @IBAction func pauseButton(_ sender: Any) {
        
        pauseButtonPressed()
        
    }
    
    //MARK: - Update Labels from Picker Selection
    func updateLabelsFromPickerSelection() {
        
        ltzLabel.text = String(Int(user.calculateLowerTargetZone()))
        utzLabel.text = String(Int(user.calculateUpperTargetZone()))
        cphLabel.text = ("Up to \(calculateActiveCalories()) calories / hour")
        maxLabel.text = String(user.calculateMaxHeartRate())
        warmupHR.text = String("<  \(Int(Double(user.maxHeartRate) * 0.6))")
        fatHR.text = String("\(Int(Double(user.maxHeartRate) * 0.6)) < \(Int(Double(user.maxHeartRate) * 0.75))")
        cardioHR.text = String("\(Int(Double(user.maxHeartRate) * 0.75)) < \(Int(Double(user.maxHeartRate) * 0.85))")
        peakHR.text = String(">  \(Int(Double(user.maxHeartRate) * 0.85))")
        timerStateLabel.text = "Workout Selected"
        
    }
    
    //MARK: - Timer State
    enum TimerState {
        case inactive
        case active
        case paused
    }

    //MARK: - Update Timer Label
    func updateTimerLabel() {
        
        interval = -Int(timerStartDate.timeIntervalSinceNow)
        
        time = interval

        let hours = interval / 3600
        let minutes = interval / 60 % 60
        let seconds = interval % 60
        
        print("Current interval = \(interval)")
        
        timerLabel.text = String(format:"%02i:%02i:%02i", hours, minutes, seconds)
        
        if activityArray[currentArrayRow].2 <= 4.5 {
            
            cps = activityArray[currentArrayRow].2 * Double(user.userWeightInKilo) / 3600
            
            runningCPS = runningCPS + cps
                
//            print("MET \(activityArray[currentArrayRow].2) <= 4.5 * KG (\(Double(user.userWeightInKilo))) * HR (\(Double(user.userHeartRate))) / MaxHR (\(Double(user.maxHeartRate))  * interval \(Double(interval)) / 3600. Gives a cps 0f \(cps) and a runningCPS of \(runningCPS) ")

        } else {
        
        cps = activityArray[currentArrayRow].2 * Double(user.userWeightInKilo) * Double(user.userHeartRate) / Double(user.maxHeartRate) / 3600
 
        runningCPS = runningCPS + cps
            
//        print("MET \(activityArray[currentArrayRow].2) > 4.5 * KG (\(Double(user.userWeightInKilo))) * HR (\(Double(user.userHeartRate))) / MaxHR (\(Double(user.maxHeartRate))  * interval \(Double(interval)) / 3600. Gives a cps 0f \(cps) and a runningCPS of \(runningCPS) ")


        }
        
        activeLabel.text = String(format: "%0.1f", runningCPS) + " Calories Burned"
    
    }
    
    //MARK: - Foreground Timer
    func _foregroundTimer(repeated: Bool) -> Void {
        
//        print("_foregroundTimer(_:) invoked -> \(time)")
        
        //Define a Timer
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true);
//        print("Starting timer")
        
    }
    
    //MARK: - Timer Action
    @objc func timerAction(_ timer: Timer) {
        
        
//        print("MET selected is \(activityArray[currentArrayRow].2) with a weight of \(user.userWeightInKilo) and a HR of \(user.userHeartRate)")
//        print("Current cps = \(cps) and runningCPS = \(runningCPS)")

        self.updateTimerLabel()
    }
    
    //MARK: - Observer Method
    @objc func observerMethod(notification: NSNotification) {
        
        if notification.name == UIApplication.didEnterBackgroundNotification {
            
            // stop UI update
            timer.invalidate()
            
        } else if notification.name == UIApplication.didBecomeActiveNotification {
            
            if timerState == .active {
                updateTimerLabel()
                _foregroundTimer(repeated: true)
            }
        }
    }

    //MARK: - Start Workout Timer
    @objc func startWorkoutTimer() {
        
        workoutTime += 1
        
//        print("Getting user's current heart rate")
        healthKit.getUsersHeartRate(completion: user.getHeartRate)
        
//        print("Current User's Heart Rate -> \(Int(user.userHeartRate)) at count \(time)")
        targetHR.text = String(Int(user.userHeartRate))
        
//        print("Checking to see if userHeartRate \(user.userHeartRate) is > maxHeartRate \(user.maxHeartRate)")
        
        
        healthKit.saveHeartRateIntoHealthStore(height: 68)
        
        if Int(user.userHeartRate) != 0 && Int(user.userHeartRate) > user.maxHeartRate {

        print("Current workoutTime -> \(workoutTime)")

        }
        
        if (view.frame.size.width) * CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) == 0 {
            
//            print("Zones Status Bar width is 0")
            
        } else {
            
            //Status bar size assignment
            
            if CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) < 0.6 {
                
//                print("HR falls within Zone 1")
                
                let zoneWidth = view.frame.size.width * 0.25 - 5
                
                let hrPercentage = CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) / 0.6
                
                let results = zoneWidth * hrPercentage
                
                zonesProgressBarWidth.constant = results
                zonesHR.text = String(Int(user.userHeartRate))

                zonesHR.backgroundColor = UIColor.gray

            }
            
            if CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) >= 0.6 && CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) < 0.75 {
                
//                print("HR falls within Zone 2")
                
                let zoneWidth = view.frame.size.width * 0.50 - 5
                
                let hrPercentage = CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) / 0.75
                
                let results = zoneWidth * hrPercentage
                
                zonesProgressBarWidth.constant = results
                zonesHR.text = String(Int(user.userHeartRate))

                zonesHR.backgroundColor = UIColor.gray

            }
            
            if CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) >= 0.75 && CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) < 0.85 {
                
//                print("HR falls within Zone 3")
                
                let zoneWidth = view.frame.size.width * 0.75 - 10
                
                let hrPercentage = CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) / 0.85
                
                let results = zoneWidth * hrPercentage
                
                zonesProgressBarWidth.constant = results
                zonesHR.text = String(Int(user.userHeartRate))

                zonesHR.backgroundColor = UIColor.gray

            }
            
            if CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) >= 0.85 && CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) <= 1.0 {
                
//                print("HR falls within Zone 4")
                
                let zoneWidth = view.frame.size.width * 1.0 - 10
                
                let hrPercentage = CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) / 1.0
                
                let results = zoneWidth * hrPercentage
                
                zonesProgressBarWidth.constant = results
                zonesHR.text = String(Int(user.userHeartRate))

                zonesHR.backgroundColor = UIColor.gray

            }
            
            //Current HR > maximum
            if CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) > 1.0 {
                
                zonesProgressBarWidth.constant = view.frame.size.width * 1.0 - 10
                zonesHR.text = String(Int(user.userHeartRate))
                
                zonesHR.backgroundColor = UIColor.red
                
//                print("playSound(soundFileName) \(heartRateWarning)")
                playSound(soundFileName: heartRateWarning)
                
            }
            
        }
        
        if (view.frame.size.width) * CGFloat(user.userHeartRate)/CGFloat(user.maxHeartRate) == 0 {
            
//            print("Target Zone Status Bar width is 0")
            
        } else {
            
            if CGFloat(user.userHeartRate) < CGFloat(user.calculateLowerTargetZone()) {
                
//                print("Target HR falls within Zone 1")
                
                let zoneWidth = view.frame.size.width * 0.25 - 5
                
                let hrPercentage = CGFloat(user.userHeartRate)/CGFloat(user.targetZoneLower)
                
                let results = zoneWidth * hrPercentage
                
                targetZonesProgressBarWidth.constant = results
                targetHR.text = String(Int(user.userHeartRate))

                targetHR.backgroundColor = UIColor.gray

            }
            
            if CGFloat(user.userHeartRate) >= CGFloat(user.calculateLowerTargetZone()) && CGFloat(user.userHeartRate) < (CGFloat(user.calculateLowerTargetZone()) + CGFloat(user.calculateUpperTargetZone()))/2 {
                
//                print("Target HR falls within Zone 2")
                
                let zoneWidth = view.frame.size.width * 0.50 - 5
                
                let hrPercentage = CGFloat(user.userHeartRate) / ((CGFloat(user.calculateLowerTargetZone()) + CGFloat(user.calculateUpperTargetZone()))/2)
                
                let results = zoneWidth * hrPercentage
                
                targetZonesProgressBarWidth.constant = results
                targetHR.text = String(Int(user.userHeartRate))

                targetHR.backgroundColor = UIColor.gray

            }
            
            if CGFloat(user.userHeartRate) >= (CGFloat(user.calculateLowerTargetZone()) + CGFloat(user.calculateUpperTargetZone()))/2 && CGFloat(user.userHeartRate) < CGFloat(user.calculateUpperTargetZone()) {
                
//                print("Target HR falls within Zone 3")
                
                let zoneWidth = view.frame.size.width * 0.75 - 10
                
                let hrPercentage = CGFloat(user.userHeartRate) / CGFloat(user.calculateUpperTargetZone())
                
                let results = zoneWidth * hrPercentage
                
                targetZonesProgressBarWidth.constant = results
                targetHR.text = String(Int(user.userHeartRate))

                targetHR.backgroundColor = UIColor.gray

            }
            
            if CGFloat(user.userHeartRate) >= CGFloat(user.calculateUpperTargetZone()) && CGFloat(user.userHeartRate) <= CGFloat(user.maxHeartRate) {
                
//                print("Target HR falls within Zone 4")
                
                let zoneWidth = view.frame.size.width * 1.0 - 10
                
                let hrPercentage = CGFloat(user.userHeartRate) / CGFloat(user.maxHeartRate)
                
                let results = zoneWidth * hrPercentage
                
                targetZonesProgressBarWidth.constant = results
                targetHR.text = String(Int(user.userHeartRate))
                
                targetHR.backgroundColor = UIColor.gray


            }
            
            //Current HR > maximum
            if CGFloat(user.userHeartRate) > CGFloat(user.maxHeartRate) {
                
                targetZonesProgressBarWidth.constant = view.frame.size.width * 1.0 - 10
                targetHR.text = String(Int(user.userHeartRate))
                
                targetHR.backgroundColor = UIColor.red
            }
        }
    }
    
    // MARK: - Determine Workout Status
    func determineWorkoutStatus() -> String {
        
//        print("determineWorkoutStatus() -> duration: \(duration)")
        duration = String(time)
        
        if duration != "" {
            
            if Int(duration)! >= 3600 {
                status = "GREAT WORKOUT!!!"
            }
            else if Int(duration)! >= 1800 && Int(duration)! < 3600 {
                status = "GOOD WORKOUT!"
            }
            else if Int(duration)! > 1500 && Int(duration)! < 1800 {
                status = "EH!!! SO SO"
            }
            else {
                status = "COME ON!!!\n\n YOU CAN DO BETTER THAN THIS!"
            }
            
            return status
        }
        
        status = "YOU DID NOT DO A WORKOUT???"
//        print("Returning status -> \(status)")
        
        return status
        
    }

    //MARK: - Start Button Pressed
    func startButtonPressed() {
    
        if timerState == .inactive {
            
            timerStartDate = Date()
            
        } else if timerState == .paused {
            
            timerStartDate = Date().addingTimeInterval(-timerInterval)
            
        }

        timerState = .active
        
        timerStateLabel.text = "Workout Started"
//        print("startButtonPressed() at time \(time) and interval \(interval) seconds")

        start.isHidden = true
        pause.isHidden = false
        
        updateTimerLabel()
        _foregroundTimer(repeated: true)
//        print("Calling _foregroundTimer(_:)")
        
        //MARK: workoutTime set to 15 seconds for query of HK heart rate to display on progress bar.
        workoutTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(WorkoutViewController.startWorkoutTimer), userInfo: nil, repeats: true)
        
//        print("Workout timer - \(workoutTimer)")
        
        workoutStart = Date()
//        print("workoutStart = \(workoutStart)")
        
        healthKit.workoutStartTime = workoutStart
//        print("Sending workoutStart to healthKit.workoutStartTime")
        
        session.start()
//        print("session.start()")
        
        healthKit.workoutCaloriesPerHour = Double(calculateActiveCalories())!
//        print("Sending Double(calculateActiveCalories()) \(calculateActiveCalories()) to healthKit.workoutCaloriesPerHour")
        
        exercisePicker.isUserInteractionEnabled = false
        
    }
    
    //MARK: - Pause Button Pressed
    func pauseButtonPressed() {
        
        // record workout duration
        timerInterval = floor(-timerStartDate.timeIntervalSinceNow)
//        print("pauseButtonPressed()")
        
        timerStateLabel.text = "Workout Paused"
        
        timerState = .paused
        timer.invalidate()
        workoutTimer.invalidate()
        
        displayPauseAlert()
        
    }
    
    func pauseWorkout() {
        
        pause.isHidden = true
        start.isHidden = false
        
    }
    
    //MARK:  - Display Pause Alert
    private func displayPauseAlert() {
        
//        print("displayPauseAlert()")
        let alert = UIAlertController(title: "FitTrax",
                                      message: "Would you like to pause the workout?",
                                      preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes",
                                      style: .default) { (action) in
//                                        print("Calling pausedWorkout()")
                                        self.pauseWorkout()
        }
        
        let noAction = UIAlertAction(title: "No",
                                     style: .cancel) { (action) in
//                                        print("Calling displaySaveAlert()")
                                        self.displaySaveAlert()
        }
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: true, completion: nil)
    }

    //MARK: - Display Save Alert
    private func displaySaveAlert() {
        
//        print("displaySaveAlert()")
        let alert = UIAlertController(title: "FitTrax",
                                      message: "Do you want to save the workout?",
                                      preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes",
                                      style: .default) { (action) in
                                        print("Calling saveWorkout()")
                                        self.saveWorkout()
        }
        
        let noAction = UIAlertAction(title: "No",
                                     style: .cancel) { (action) in
//                                        print("Calling workoutCancelledAlert()")
                                        self.workoutCancelledAlert()
        }
   
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: true, completion: nil)
    }

    //MARK: - Save Workout Alert
    func saveWorkoutAlert() {
        
//        print("savedWorkoutAlert()")
        
        if activityArray[currentArrayRow].1 == 1 {
            
//            print("Workout with distance requirement")
            let alert = UIAlertController(title: "FitTrax",
                                      message: "Workout saved to Apple's Health app. \n\n Workout summary.\n\nYou burned \(totalCaloriesBurned) calories \nin \(duration).\n\n Total distance: \(distance) miles\n\n\(determineWorkoutStatus())",
                                      preferredStyle: .alert)
        
            let okayAction = UIAlertAction(title: "OK",
                                       style: .default) { (action) in
                                        print("Calling workoutSessionReset()")
                                        self.workoutSessionReset()
                                        
            }
        
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
            
        } else {
            
//            print("Workout without distance requirement")
            let alert = UIAlertController(title: "FitTrax",
                                          message: "Workout saved to Apple's Health app. \n\n Workout summary.\n\nYou burned \(totalCaloriesBurned) calories \nin \(duration).\n\n\(determineWorkoutStatus())",
                preferredStyle: .alert)
            
            let okayAction = UIAlertAction(title: "OK",
                                           style: .default) { (action) in
                                            print("Calling workoutSessionReset()")
                                            self.workoutSessionReset()
                                            
            }
            
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
            
        }
    }
    
    //MARK: - Workout Cancelled Alert
    private func workoutCancelledAlert() {
        
//        print("workoutCancelledAlert()")
        let alert = UIAlertController(title: "FitTrax",
                                      message: "Workout was not saved to Apple's Health app",
                                      preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "OK",
                                       style: .default) { (action) in
                                        self.workoutSessionReset()
                                        
        }
        
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Workout Did Not Save Alert
    func workoutDidNotSaveAlert() {
        
//        print("workoutDidNotSaveAlert()")
        let alert = UIAlertController(title: "FitTrax",
                                      message: "******* ERROR ERROR ERROR ******* \nThere was a problem saving your workout to Apple's Health App.  Please manually record this information to the Health App by opening the app, go to Activities and selecting Workouts.  You will then press the "+" to add it.\n Report this issue to the developer immediate for an immediate fix. \n\nWorkout summary.\n\nYou burned \(totalCaloriesBurned) calories \nin \(duration).\n\n Total distance: \(distance) miles\n\n\(determineWorkoutStatus())",
            preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "OK",
                                       style: .default) { (action) in
                                        print("Calling viewDidLoad()")
                                        self.workoutSessionReset()
                                        
        }
        
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    
    //MARK: - Save Workout
    func saveWorkout() {
        
//        print("saveWorkout()")
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        totalCaloriesBurned = String(format: "%0.1f", (activityArray[currentArrayRow].2 * Double(user.userWeightInKilo) * Double(time) / 3600))
//        print("totalCaloriesBurned: \(totalCaloriesBurned)")
        
        let currentTime = time
//        print("currentTime: \(currentTime)")
        
        duration = String(format:"%02ih:%02im:%02is", hours, minutes, seconds)
        
        healthKit.activityType = activityArray[currentArrayRow].3
//        print("Sending converted HKWorkoutActivityType to healthKit.activityType")
        
        workoutEnd = Date()
        
        healthKit.HKMetadataKeyWorkoutBrandName = activityArray[currentArrayRow].0
        
        healthKit.workoutEndTime = workoutEnd
//        print("Sending workoutEnd to healthKit.workoutEndTime -> \(workoutEnd)")
        
        healthKit.workoutDuration = Double(currentTime)
//        print("Sending Double(currentTime) to healthKit.workoutDuration -> \(currentTime)")
        
//        print("Start Date/Time: \(workoutStart)\nEnd Date/Time: \(workoutEnd)")
        
//        print("Calling healthKit.saveWorkout() from ViewController.savedWorkout()")
        healthKit.saveWorkout()
        
        if healthKit.savedWorkout == true {
            
            saveWorkoutAlert()
//            print("Calling savedWorkoutAlert()")
            
        } else {
            
            workoutDidNotSaveAlert()
//            print("Calling workoutDidNotSaveAlert()")
            
        }
    }

    //MARK: - Workout Session Reset
    func workoutSessionReset() {
        
//        print("workoutSessionReset()")
        
        session.end()
//        print("session.end()")
        
        session.clear()
//        print("session.clear()")
        
//        print("Stopping Timers")
        timer.invalidate()
        
//        print("Set timerState to .inactive")
        timerState = .inactive
        
//        print("workoutTimer.invalidate()")
        workoutTimer.invalidate()

///        print("Calling resetApp()")
        resetApp()

    }
    
    //MARK: - Calculate Active Calories
    func calculateActiveCalories() -> String {
        
        let activeCalories : Int = Int(activityArray[currentArrayRow].2 * user.userWeightInKilo)
        
        return String(activeCalories)
    }
    
    //MARK: - Audio Function
    func playSound(soundFileName : String) {
        
        let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "wav")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL!)
        }
        catch{
            print(error)
        }
        
        audioPlayer.play()
        
    }
    
    //MARK: - UIPicker Functions
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return activityArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return activityArray[row].0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if row == 0 {

            timerStateLabel.text = "Invalid Selection"
            cphLabel.text = "0 calories / hour"
            start.isHidden = true

        } else {

        start.isHidden = false
            
        currentArrayRow = row
            
        user.userWeightInKilo = healthKit.userWeightInKilo
            
        user.checkWeightStatus()
            
        updateLabelsFromPickerSelection()
            
        }
    }
    
    //MARK: - Reset App
    func resetApp() {
        
//        print("resetApp()")
        
//        print("Resetting time variables")
        time = 0
        interval = 0
        workoutTime = 0

//        print("timer.invalidate()")
        timer.invalidate()
        
//        print("Resetting Buttons")
        start.isHidden = true
        pause.isHidden = true
        
//        print("Enabling Picker")
        exercisePicker.isUserInteractionEnabled = true
        
//        print("Resetting Picker to position 0")
        exercisePicker.selectRow(0, inComponent:0, animated:true)
        
//        print("Resetting Status Bars")
        zonesProgressBarWidth.constant = 15
        targetZonesProgressBarWidth.constant = 15
        
//        print("Resetting UILabels")
        cphLabel.text = "0 calories / hour"
        activeLabel.text = "0 calories burned"
        maxLabel.text = "0"
        targetHR.text = "0"
        zonesHR.text = "0"
        zonesHR.backgroundColor = UIColor.gray
        targetHR.backgroundColor = UIColor.gray
        ltzLabel.text = "0"
        utzLabel.text = "0"
        timerStateLabel.text = "Select workout"
        timerLabel.text = ""
        
    }


    //MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()

//        print("viewDidLoad()")
//        print("Calling healthKit.getHealthKitPermission()")
        healthKit.getHealthKitPermission()
        
//        print("Getting users age")
        user.loadGetAge()
        
        currentWeightInKG = healthKit.userWeightInKilo
//        print("User weight in KG at VDL = \(currentWeightInKG)")
        
        exercisePicker.dataSource = self
        exercisePicker.delegate = self
        exercisePicker.setValue(UIColor.black, forKey: "textColor")
        
//        print("Calling resetApp()")
        resetApp()
        
        //For Timer to track when the applications enters and exits the background
        NotificationCenter.default.addObserver(self, selector: #selector(observerMethod), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(observerMethod), name: UIApplication.didBecomeActiveNotification, object: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


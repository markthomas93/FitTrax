//
//  InterfaceController.swift
//  FitTrax Watch Extension
//
//  Created by Kevin D. Cattran Sr. on 4/5/20.
//  Copyright © 2020 Kevin D Cattran Sr. All rights reserved.
//

import WatchKit
import UIKit
import HealthKit
import CoreLocation


class InterfaceController: WKInterfaceController {
    

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
    
    var currentArrayRow : Int = 0
    
    var selectedActivity = HKWorkoutActivityType.traditionalStrengthTraining


    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        var items = [WKPickerItem]()

        for activity in activityArray {
            let item = WKPickerItem()
            item.title = activity.0
            items.append(item)
        }

        exercisePicker.setItems(items)

    }
    
    @IBOutlet weak var exercisePicker: WKInterfacePicker!
    
    //MARK: - UIPicker Functions
    func numberOfComponents(in pickerView: WKInterfacePicker) -> Int {
            return 1
    }
    
    func pickerView(_ pickerView: WKInterfacePicker, numberOfRowsInComponent component: Int) -> Int {
        return activityArray.count
    }
    
    func pickerView(_ pickerView: WKInterfacePicker, titleForRow row: Int, forComponent component: Int) -> String? {
        return activityArray[row].0
    }
    
    func pickerView(_ pickerView: WKInterfacePicker, didSelectRow row: Int, inComponent component: Int) {
        
        if row == 0 {

//            timerStateLabel.text = "Invalid Selection"
//            cphLabel.text = "0 calories / hour"
//            start.isHidden = true

        } else {

//        start.isHidden = false
            
        currentArrayRow = row
            
//        user.userWeightInKilo = healthKit.userWeightInKilo
            
//        user.checkWeightStatus()
            
//        updateLabelsFromPickerSelection()
            
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
//        exercisePicker.dataSource = self
//        exercisePicker.delegate = self
        exercisePicker.setValue(UIColor.white, forKey: "textColor")
//      print("Enabling Picker")
        exercisePicker.setEnabled(true)
                
//      print("Resetting Picker to position 0")
//        exercisePicker.setItems(exercisePicker)


    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

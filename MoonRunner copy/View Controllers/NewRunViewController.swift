/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import CoreLocation

class NewRunViewController: UIViewController {
  
  @IBOutlet weak var launchPromptStackView: UIStackView!
  @IBOutlet weak var dataStackView: UIStackView!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!
  
  internal var run: Run?
  
  private let locationManager = LocationManager.shared //is the object you’ll use to start and stop location services.
  private var seconds = 0 //tracks the duration of the run, in seconds
  private var timer: Timer? //will fire each second and update the UI accordingly.
  internal var distance = Measurement(value: 0, unit: UnitLength.meters) //holds the cumulative distance of the run.
  internal var locationList: [CLLocation] = [] //is an array to hold all the CLLocation objects collected during runs
  
  override func viewDidLoad() {
    super.viewDidLoad()
    dataStackView.isHidden = true
  }
  //to save battery when user goes to homescreen
  override func viewWillDisappear(_ animated: Bool){
    super.viewWillDisappear(animated)
    timer?.invalidate()
    locationManager.stopUpdatingLocation()
  }
  
  // distanceFilter is for reading errors from GPS, too high of a filter will pixelate the reading though!
  private func startLocationUpdates(){
    locationManager.delegate = self
    locationManager.activityType = .fitness
    locationManager.distanceFilter = 10
    locationManager.startUpdatingLocation()
  }
  
  //will be called once per second by a Timer() set below
  func eachSecond(){
  seconds += 1
  updateDisplay()
  }
  
  //uses the  formatting capabilities  built in FormatDisplay.swift to update the UI with the details of the current run.
  private func updateDisplay(){
    let formattedDistance = FormatDisplay.distance(distance)
    let formattedTime = FormatDisplay.time(seconds)
    let formattedPace = FormatDisplay.pace(distance: distance, seconds: seconds, outputUnit: UnitSpeed.minutesPerMile)
    
    distanceLabel.text = "Distance: \(formattedDistance)"
    timeLabel.text = "Time: \(formattedTime)"
    paceLabel.text = "Pace: \(formattedPace)"
  }
  
  
  //create a new Run object and initialize its values as with any other Swift object.
  private func saveRun(){
    //create a Location object for each CLLocation you recorded, saving only the relevant data.
    let newRun = Run(context: CoreDataStack.context)
    newRun.distance = distance.value
    newRun.duration = Int16(seconds)
    newRun.timeStamp = Date() as NSDate
    
    for location in locationList{
      let locationObject = Location(context: CoreDataStack.context)
      locationObject.timestamp = location.timestamp as NSDate
      locationObject.latitude = location.coordinate.latitude
      locationObject.longitude = location.coordinate.longitude

      newRun.addToLocations(locationObject)
    }
    //add each of these new Locations to the Run using the automatically generated addToLocations.
    
    CoreDataStack.saveContext()
    
    run = newRun
  }
  
  func startRun(){
    launchPromptStackView.isHidden = true
    dataStackView.isHidden = false
    startButton.isHidden = true
    stopButton.isHidden = false
    
    //to reset all values for a fresh run
    seconds = 0
    distance = Measurement(value: 0, unit: UnitLength.meters)
    locationList.removeAll()
    updateDisplay()
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true){ _ in self.eachSecond()}
    startLocationUpdates()
  }
  
  func stopRun(){
    launchPromptStackView.isHidden = false
    dataStackView.isHidden = true
    startButton.isHidden = false
    stopButton.isHidden = true
    
    //to stop the tracking
    locationManager.stopUpdatingLocation()
  }
  
  @IBAction func startTapped() {
  startRun()
  }
  
  @IBAction func stopTapped() {
  stopRun()
    let alertController = UIAlertController(title: "End run?",
                                            message: "Do you wish to end your run?",
                                            preferredStyle: .actionSheet)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alertController.addAction(UIAlertAction(title: "Save", style: .default) { _ in
      self.stopRun()
      self.saveRun()
      self.performSegue(withIdentifier: .details, sender: nil)
    })
    alertController.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
      self.stopRun()
      _ = self.navigationController?.popToRootViewController(animated: true)
    })
    
    present(alertController, animated: true)
  
    
  }
  
}

extension NewRunViewController: SegueHandlerType{
  enum SegueIdentifier: String {
    case details = "RunDetailsViewController"
  }
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?){
    switch segueIdentifier(for: segue){
    case .details:
      let destination = segue.destination as! RunDetailsViewController
      destination.run = run
    }
  }
}

//This delegate method will be called each time Core Location updates the user's location, providing an array of CLLocation objects. Usually this array contains only one object but, if there are more, they are ordered by time with the most recent location last.

extension NewRunViewController: CLLocationManagerDelegate{
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
    for newLocation in locations{
      let howRecent = newLocation.timestamp.timeIntervalSinceNow
      
      //to get rid of early, GPS inaccuracies
      guard newLocation.horizontalAccuracy < 20 && abs(howRecent) < 10 else {
      continue
      }
      
      if let lastLocation = locationList.last{
        let delta = newLocation.distance(from: lastLocation)
        distance = distance + Measurement(value: delta, unit: UnitLength.meters)
      }
      
      locationList.append(newLocation)
    }
  }
}



























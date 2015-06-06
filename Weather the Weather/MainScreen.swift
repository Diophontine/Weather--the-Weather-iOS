//
//  MainScreen.swift
//  Weather the Weather
//
//  Created by DD Bobs on 2015-06-02.
//  Copyright (c) 2015 Diophontine. All rights reserved.
//

import UIKit
import MapKit
//quickly access which api string to use
enum ApiCallType: String{
    //searching for station/town
    case Query = "http://autocomplete.wunderground.com/aq?query="
    //using lat Long search
    case locationCall = "http://api.wunderground.com/api/f304314b26f1d73e/geolookup/q/"
    
    case forecastCall = "http://api.wunderground.com/api/f304314b26f1d73e/forecast/q/"
    case conditionsCall = "http://api.wunderground.com/api/f304314b26f1d73e/conditions/q/"
    case tenDayForecastCall = "http://api.wunderground.com/api/f304314b26f1d73e/forecast10day/q/"
 
    
}
//access which weather identifier to use
enum weatherSystem:String{
case fahrenheit = "fahrenheit"
    case celsius = "celsius"
    case inches = "in"
    case millimeters = "mm"
}
// check if a search based weather is occuring
var searched = false

let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

class MainScreen: UIViewController, CLLocationManagerDelegate, returnSearchLocationDelegate{
    //button that shows if location based or search based weather is being shown
    @IBOutlet weak var locationSwitch: UIButton!
    // shows when weather was fetched the last time
    @IBOutlet weak var lastUpdatedLabel: UILabel!
     var locationManager = CLLocationManager()
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    
    var dateFormat:NSDateFormatter = NSDateFormatter()
    // when clicking location swtich button change the search boolean and the display of the button
    @IBAction func locationSource(sender: AnyObject) {
        
        searched = !searched
        if(searched){
            locationSwitch.setTitle("Searched Based Weather", forState: UIControlState.Normal)

        }
        else{
            locationSwitch.setTitle("Location Based Weather", forState: UIControlState.Normal)

        
        }
    }
    // check if the app needs to have the location authorized or if it can just use the location
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
        } else {
            locationManager.requestWhenInUseAuthorization()
            
        }
        
        self.getLocation()
    }
    //refresh the weather
    @IBAction func refresh(sender: UIButton) {
        if(!searched){
       checkLocationAuthorizationStatus()
        }
        self.fetchData(ApiCallType.forecastCall)
        self.fetchData(ApiCallType.conditionsCall)
    }

    //where I  am getting weather data from
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var todayLow: UILabel!
   
    @IBOutlet weak var todayHigh: UILabel!
    // is it cloudy with a chance of meatballs?
    @IBOutlet weak var currentConditions: UILabel!
    //current weather visually for those who are too lazy to read
    @IBOutlet weak var iconImage: UIImageView!
    // do I need a parka or shorts?
    @IBOutlet weak var currentTemp: UILabel!
    // what am I looking for
    var queryString:String = ""
    var location:CLLocationCoordinate2D?
    var manager = AFHTTPRequestOperationManager()
  
    //get the data based on the api call
    func fetchData(callType:ApiCallType ) {
        
        manager.requestSerializer.setValue("text/html", forHTTPHeaderField: "Content-Type")
        manager.responseSerializer = AFHTTPResponseSerializer()
        
        var fullString:String = callType.rawValue
        switch(callType){
            
        case .Query:
            fullString += self.queryString
            // if its not a query get the location
        case .locationCall:
            
            fallthrough
        case .forecastCall :
            fallthrough
        case .conditionsCall:
            fallthrough
        case .tenDayForecastCall:
            
            if let lat = self.location?.latitude{
             var latitudeText:String = "\(lat)"
                fullString += latitudeText
            }
           fullString += ","
            if let long = self.location?.longitude{
                var latitudeText:String = "\(long)"
                fullString += latitudeText
            }

            
            
        default:
            break;
        }
        fullString += ".json"
      
        
        var error: NSError?
        // get the api data
        manager.GET(fullString, parameters: nil, success: { (operation, response) -> Void in
            var jsonData:NSData = response as! NSData
            // store the retireved data as a dictionary
            var jsonDict =   NSJSONSerialization.JSONObjectWithData(jsonData, options: nil, error: &error) as! NSDictionary
            
            //parsing the data so its useful
            self.processData(callType, jsonDict:jsonDict)
        
            
            
            })
            { (operation, error) -> Void in
                println(error)
                UIAlertView(title: "Failed to retrieve the weather info due to network error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
        }
        
        
    }
    // lets make this data useful
    func processData(callType:ApiCallType, jsonDict:NSDictionary){
        switch(callType){
            
        case .Query:
            break;
        case .locationCall:
          break;
        case .forecastCall :
            
            if let forecast = jsonDict.objectForKey("forecast") as? NSDictionary {
                
            var forecastDic:NSDictionary = forecast.objectForKey("simpleforecast") as! NSDictionary
            var forecastDayDic:NSArray = forecastDic.objectForKey("forecastday") as! NSArray
                //show weather data for the current day
            var day:NSDictionary = forecastDayDic[0] as! NSDictionary
                
                //download the info
            var iconUrl:String = day.objectForKey("icon_url") as! String
            self.iconImage.contentMode = UIViewContentMode.ScaleAspectFit
            if let checkedUrl = NSURL(string: iconUrl) {
                
                downloadImage(checkedUrl);
            }
            
                var conditions:String = day.objectForKey("conditions") as! String
            
            var currentHighDictionary:NSDictionary = day.objectForKey("high") as! NSDictionary
            var currentHigh:String = "High: "
           currentHigh += currentHighDictionary.objectForKey(weatherSystem.celsius.rawValue) as! String
            var currentLowDictionary:NSDictionary = day.objectForKey("low") as! NSDictionary
            var currentLow:String = "Low: "
            currentLow += currentLowDictionary.objectForKey(weatherSystem.celsius.rawValue) as! String
                 // var rainToday:Int = (day.objectForKey("qpf_day") as! NSDictionary).objectForKey(weatherSystem.millimeters.rawValue) as! Int
                
                
                // add a degrees sign
            currentHigh +=  "\u{00B0}"
               currentLow +=  "\u{00B0}"
                self.todayHigh.text = currentHigh
               self.todayHigh.hidden = false
            self.todayLow.text = currentLow
               self.todayLow.hidden = false
               // self.currentConditions.text = conditions
              
                    var updateString = "Last updated: "
                updateString += dateFormat.stringFromDate(NSDate())
               self.lastUpdatedLabel.text = updateString
            }else{
                UIAlertView(title: "Failed to retrieve the forecast info due to network error",message: "Try refreshing", delegate: nil, cancelButtonTitle: "OK").show()

            
            }
            
            
        case .tenDayForecastCall:
            
             break;
            
            
        case .conditionsCall:
            
            
            if let  forecast = jsonDict.objectForKey("current_observation") as? NSDictionary{
             var currentTemperature = 0.0;
             var displayedLocation:NSDictionary = forecast.objectForKey("display_location") as! NSDictionary
             locationLabel.text = displayedLocation.objectForKey("full") as! String
             var currentConditionsLocal = forecast.objectForKey("weather") as! String
             self.currentConditions.text = currentConditionsLocal
         
            currentTemperature = forecast.objectForKey("temp_c") as! Double
          
            self.currentTemp.text = "\(currentTemperature)\u{00B0}"
            }else{
                    UIAlertView(title: "Failed to retrieve the conditions info due to network error",message: "Try refreshing", delegate: nil, cancelButtonTitle: "OK").show()
                
            }
            //finally show the user the info
            self.currentConditions.hidden = false
            self.currentTemp.hidden = false
            self.locationLabel.hidden = false
            self.locationSwitch.hidden = false
            self.lastUpdatedLabel.hidden = false
            self.searchButton.hidden = false
            self.refreshButton.hidden = false
            
        default:
            break;
            
        
        }

    
    
    }
    // use this to get the image asynchronously
    func getDataFromUrl(urL:NSURL, completion: ((data: NSData?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(urL) { (data, response, error) in
            completion(data: NSData(data: data))
            }.resume()
    }
    // start downloading the image
    func downloadImage(url:NSURL){
        println("Started downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
        getDataFromUrl(url) { data in
            dispatch_async(dispatch_get_main_queue()) {
                println("Finished downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
                self.iconImage.image = UIImage(data: data!)
            }
        }
    }
    


    
    
    
    func getLocation() {
         locationManager.startUpdatingLocation()
            if self.locationManager.location != nil {
        location = self.locationManager.location.coordinate
                
       
    } else {
                location = CLLocationCoordinate2DMake(43.44, -120.67)
    
    }
    }

     override func viewDidLoad() {
        super.viewDidLoad()
       self.dateFormat.dateFormat = "hh:mm a"
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
       
       
     checkLocationAuthorizationStatus()
        
        fetchData(ApiCallType.conditionsCall)
        fetchData(ApiCallType.forecastCall)
        // Do view setup here.
        
        
    }
    func getSearchResult(location: NSDictionary) {
        
        searched = true
        if let lat = location.objectForKey("lat") {
            self.location?.latitude =   lat.doubleValue
        }
        if let long = location.objectForKey("lon"){
            self.location?.longitude = long.doubleValue
        }
        if(searched){
            locationSwitch.setTitle("Searched Based Weather", forState: UIControlState.Normal)
        }
        else{
            locationSwitch.setTitle("Location Based Weather", forState: UIControlState.Normal)
            
        }
        fetchData(ApiCallType.conditionsCall)
        fetchData(ApiCallType.forecastCall)
        // this is my value from my second View Controller
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "search") {
            // pass data to next view
            var destination:SearchViewController  = segue.destinationViewController as! SearchViewController
            destination.delegate = self
        }
    }
    
    
    
    }

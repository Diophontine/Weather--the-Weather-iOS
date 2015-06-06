//
//  SearchViewController.swift
//  Weather the Weather
//
//  Created by DD Bobs on 2015-06-04.
//  Copyright (c) 2015 Diophontine. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    // delegate to get the search result back
    var delegate: returnSearchLocationDelegate?
    // string with api address
    var queryString:String = "http://autocomplete.wunderground.com/aq?query="
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.delegate = self;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
       
        // Do any additional setup after loading the view.
    }
    
    //array with  the search results
    var filterArray = []
    //dictionary with the results we need to parse
    var jsonDict:NSDictionary?
    var manager = AFHTTPRequestOperationManager()
    
    func fetchData(searchText:String ) {
        
        manager.requestSerializer.setValue("text/html", forHTTPHeaderField: "Content-Type")
        manager.responseSerializer = AFHTTPResponseSerializer()
        //replace spaces with query friendly symbol
       let processedSearchText = searchText.stringByReplacingOccurrencesOfString(" ", withString: "+")
        // address of what we are searching
        var searchId:String = queryString + processedSearchText
           var error: NSError?
        manager.GET(searchId, parameters: nil, success: { (operation, response) -> Void in
            var jsonData:NSData = response as! NSData
           self.jsonDict =   NSJSONSerialization.JSONObjectWithData(jsonData, options: nil, error: &error) as? NSDictionary
            
            
            self.processData()
           
            
            
            })
            { (operation, error) -> Void in
                println(error)
                UIAlertView(title: "Failed to retrieve the weather info due to network error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
        }

    
    
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // when the search bar is used fetch the appropriate data
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
    
     self.fetchData(searchText)
        
    }
  
    func processData(){
        //set the filtered array to corresponding values
        if let results = self.jsonDict?.objectForKey("RESULTS") as? NSArray{
       self.filterArray = results
            self.tableView.reloadData()
        
        }
    
    
    }
 func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
 func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
// check if there are results otherwise show prompt
    var count = self.filterArray.count
    if(count == 0 ){
    return 1
    }else{
        return self.filterArray.count
    }
    }
    
    let basicCellIdentifier = "CellIdentifier"
    
 func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    var cell:UITableViewCell? = self.tableView.dequeueReusableCellWithIdentifier(basicCellIdentifier, forIndexPath: indexPath) as? UITableViewCell
    if cell == nil {
        
        cell = UITableViewCell(style: UITableViewCellStyle.Default,
            reuseIdentifier: basicCellIdentifier)
    
    }
    if filterArray.count == 0 {
            // Configure the cell...
        //prompt the user iif empty
          cell!.textLabel?.text = "Search for a location to get weather info"
    }
    else{
        var dic = filterArray.objectAtIndex(indexPath.row) as! NSDictionary
        // show the location of the search
        cell!.textLabel?.text = dic.objectForKey("name") as! String

    
    }
        return cell!
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // if there are actual search results pop the controller
        if(self.filterArray.count > 0){
            //pop the search controller and get the data back
        delegate?.getSearchResult(self.filterArray.objectAtIndex(indexPath.row) as! NSDictionary)
        self.dismissViewControllerAnimated(true, completion: {});
            
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

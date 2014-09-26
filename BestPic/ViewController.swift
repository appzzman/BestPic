//
//  ViewController.swift
//  SwiftBook
//
//  Created by Brian Coleman on 2014-07-07.
//  Copyright (c) 2014 Brian Coleman. All rights reserved.
//


import UIKit

class Photo
{
    var id:Int = -1
    var image_url:String = ""
    var likes_count:String = ""
    
}
    

class ViewController: UIViewController, FBLoginViewDelegate {
    
    
    
    @IBOutlet var fbLoginView : FBLoginView!
    var lock:NSConditionLock = NSConditionLock();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
         self.fbLoginView.delegate = self
        self.fbLoginView.readPermissions = ["public_profile", "email", "user_friends","user_photos"]
        
       
       // self.getPermissions()
        var array:Array<AnyObject> =  Array();
        //fields=id,name,picture"
       self.getPictures(array,url: "/me/photos?fields=id,likes&limit=100")
        
        //self.getAlbums();
        
        
        
//        
//        self.getPictures(array, finished:(photoArray) in
//            println("Done:!!!!")
//            println(photoArray)
//        })
    
    }
    
    func getRealURL(url:String)->String{
        var array:Array<String>  = url.componentsSeparatedByString("/")
        
        var finalurl:String = "/"
        
        for (var i=4; i<array.count; i++){
            var s = array[i];
            finalurl += s;
            if (i != array.count - 1 ) {finalurl += "/" }
        }
        return finalurl
    }

    
    
    
    // Facebook Delegate Methods
    
    func loginViewShowingLoggedInUser(loginView : FBLoginView!) {
        println("User Logged In")
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
//        println("User: \(user)")
//        println("User ID: \(user.objectID)")
//        println("User Name: \(user.name)")
//        var userEmail = user.objectForKey("email") as String
//        println("User Email: \(userEmail)")
    }
    
    func loginViewShowingLoggedOutUser(loginView : FBLoginView!) {
        println("User Logged Out")
    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError) {
        println("Error: \(handleError.localizedDescription)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
    func getPermissions(){
        FBRequestConnection.startWithGraphPath("/me/permissions", parameters: nil, HTTPMethod: "GET", completionHandler: { (connection:FBRequestConnection!,  result:AnyObject!, error:AnyObject!) -> Void in
            println(error);
            println(result);
            
        })
    }
    
    
    func done(photoArray:Array<AnyObject>){
       
        println("Done");
        println(photoArray.count);

        //get albums
        
        
        
    }
    
    func getAlbums()->Void{
        FBRequestConnection.startWithGraphPath("/me/albums", parameters: nil, HTTPMethod: "GET", completionHandler: { (connection:FBRequestConnection!,  result:AnyObject!, error:AnyObject!) -> Void in
            
            // println(result);
            
                if(error == nil){
                    var albumsDict:Dictionary = result as Dictionary<String, AnyObject>
                    println(result);
                    
            }
         }
        )
    }
    
    func getPictures(photoArray:Array<AnyObject>, url:String){
        var photos:Array <AnyObject> = Array();
        photos = photos + photoArray;
        
        
        FBRequestConnection.startWithGraphPath(url, parameters: nil, HTTPMethod: "GET", completionHandler: { (connection:FBRequestConnection!,  result:AnyObject!, error:AnyObject!) -> Void in
            
           // println(result);
            
            if(error == nil){
              
                var photosDict:Dictionary = result as Dictionary<String, AnyObject>
               
               // var ph:AnyObject = photos["data"]!;
                if let ph = photosDict["data"] as AnyObject? as? Array <AnyObject>
                {
                    photos =  photos + ph;
                    println(photos.count);
                    
                  //  let likes: ph["likes"] as AnyObject? as Dictionary<String, AnyObject>
                    
                    
                    
                }
                
                println("START____________________________________________________________________________");
                
                println(url)
                println(photosDict)
                
                
                println("E____________________________________________________________________________");
                if let paging = photosDict["paging"] as AnyObject? as? Dictionary <String, AnyObject>{
                    //drill down to get a link
                    if let next = paging["next"] as AnyObject? as? String
                    {
                        
                        println("Next Element Is: ")
                        var url = self.getRealURL(next);
                        println(url)
                        
                        
                        self.getPictures(photos, url: url)
                    }
                    else{
                        self.done(photos)
                    }
                }
                else{
                        self.done(photos)
                }
            }
            else{
                println("Error")
                println(error);

                self.done(photos);
            }

        
        })
        
        /*
        /* make the API call */
        [FBRequestConnection startWithGraphPath:@"/me"
        parameters:nil
        HTTPMethod:@"GET"
        completionHandler:^(
        FBRequestConnection *connection,
        id result,
        NSError *error
        ) {
            /* handle the result */
        }];
    */
}
    
}


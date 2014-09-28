//
//  ViewController.swift
//  SwiftBook
//
//  Created by Brian Coleman on 2014-07-07.
//  Copyright (c) 2014 Brian Coleman. All rights reserved.
//


import UIKit

class Photo : Printable
{
    var id:Int = 0
    var image_url:String = ""
    var thumb_url:String = ""
    var likes_count:Int = 0
    var description: String { get { return "Photo: id = \(id) image_url = \(image_url) likes = \(likes_count)" } }
    
}


class UserStats : Printable {
    
    var userPhotos:Array<Photo> = Array()
    var likeCount:Int = 0
    var photoCount:Int  = 0
    
    var description: String { get { return "User Stats: like count = \(likeCount)  photoCount = \(photoCount)" } }
    
    
}

    

class ViewController: UIViewController, FBLoginViewDelegate {
    
    var albumsToProcess:Dictionary<String,AnyObject> = Dictionary()
    var globalRawPhotoDictionary:Dictionary<String, AnyObject> = Dictionary()
    var globalRawPhotoArray:Array<AnyObject> = Array()
    var globalsortedPhotoArray:Array<Photo> = Array()
    var userStats = UserStats()

    //var operationqueue: NSOperationQueue = NSOperationQueue()
    
    @IBOutlet var fbLoginView : FBLoginView!
   // var lock:NSConditionLock = NSConditionLock();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.fbLoginView.delegate = self
        self.fbLoginView.readPermissions = ["public_profile", "email", "user_friends","user_photos"]
        
        var date:NSDate = NSDate()
        println(date)
        self.getAlbums(globalRawPhotoArray);
    }
    
    
    ///Converts absolute url to iOS friendly url
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
            if(error != nil){
                println(error);
            }
            else{
                println(result);
            }
            
        })
    }
    
    
    func done(photoArray:Array<AnyObject>){
       
        self.globalRawPhotoArray += photoArray
        
        if self.albumsToProcess.count == 0 {
            self.getLikes(self.globalRawPhotoArray);
        }
        else{
           // println(self.albumsToProcess);
        }
    }
    
    func getLikes(photoArray:Array<AnyObject>)
    {

        //Preparea global dictionary to process
        for (var i = 0; i < photoArray.count; i++){
            let photo: AnyObject = photoArray[i]
            if let pid: String = photo["id"] as? String
            {
                self.globalRawPhotoDictionary[pid] = pid
            }
 
        }
        
        for (var i = 0; i < photoArray.count; i++){
            let photo: AnyObject = photoArray[i]
            self.getLikesForPhoto(photo)
        
        }
    }
    
    
    func getMoreLikes(photo:Photo, url:String){
 
            FBRequestConnection.startWithGraphPath(url, parameters: nil, HTTPMethod: "GET", completionHandler: { (connection:FBRequestConnection!,  result:AnyObject!, error:AnyObject!) -> Void in
                
                if(error == nil){
                    
                    var photosDict:Dictionary = result as Dictionary<String, AnyObject>
                    
                    // var ph:AnyObject = photos["data"]!;
                    if let ph = photosDict["data"] as AnyObject? as? Array <AnyObject>
                    {
                        photo.likes_count += ph.count;
                        
                    }
                    
                    
                    if let paging = photosDict["paging"] as AnyObject? as? Dictionary <String, AnyObject>{
                        //drill down to get a link
                        if let next = paging["next"] as AnyObject? as? String
                        {
                            
                            self.getMoreLikes(photo, url: self.getRealURL(next))
                        }
                        else{
                            self.insertSort(photo)
                        }
                    }
                    else{
                        self.insertSort(photo)

                    }
                }
                else{
                     self.insertSort(photo)
                    println("error \(error)")
                    
                    }
                }
                
            )
        
    }
    
    
    func getLikesForPhoto(rawPhoto:AnyObject){
       // println("Raw Photo_______________________________________________")
     //   println(rawPhoto);
        var photo:Photo = Photo()
        
        if let pid: String? = rawPhoto["id"] as? String
        {
            photo.id = pid!.toInt()!
      
        }
        if let imgurl: String = rawPhoto["picture"] as? String
        {
            photo.image_url = imgurl
        }

        
        if let likesDictionary : Dictionary<String, AnyObject> = rawPhoto["likes"] as? Dictionary<String, AnyObject>{
            let dataArray:Array<AnyObject> = likesDictionary["data"] as AnyObject? as Array<AnyObject>
                photo.likes_count = dataArray.count

            if let paging:Dictionary<String, AnyObject> = likesDictionary["paging"] as AnyObject! as? Dictionary <String, AnyObject>
            {
                if let next = paging["next"] as AnyObject? as? String
                {
                    var url = self.getRealURL(next);
                    self.getMoreLikes(photo, url: url)
                }
                else{//it doesn't have next which means that we need to just update
                    self.insertSort(photo)
                }
            }
            else{
                self.insertSort(photo)
            }
        }
        else{
              self.insertSort(photo)
        }
    }
    
    ///Inserts photo element and sorts the array
    func insertSort(photo:Photo){
        
        self.globalsortedPhotoArray.append(photo)
        self.globalRawPhotoDictionary.removeValueForKey(String(photo.id))
        self.userStats.likeCount += photo.likes_count
        
        println(self.globalRawPhotoDictionary.count)
        
        if self.globalRawPhotoDictionary.count == 0 {
            //wow we are done.
            println("done with inserting photos")
            self.globalsortedPhotoArray.sort({$0.likes_count>$1.likes_count})
            self.userStats.userPhotos = self.globalsortedPhotoArray
            
            println(self.userStats)
            var date:NSDate = NSDate()
            println(date)
            
        }
    }
    
    
    
    func getAlbums(photoArray:Array<AnyObject>)->Void{

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in

            println("Background Operation")
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //done with one operation
                self.view.backgroundColor = UIColor.blackColor()
                
            })
        })
        
            FBRequestConnection.startWithGraphPath("/me/albums?fields=id,photos.fields(id,picture,thumb,likes),name", parameters: nil, HTTPMethod: "GET", completionHandler: { (connection:FBRequestConnection!,  result:AnyObject!, error:AnyObject!) -> Void in
                
                print(error);
                
                if(error == nil){
                    var albumsDict:Dictionary = result as Dictionary<String, AnyObject>
                    
                    if let photoData = albumsDict["data"] as AnyObject? as? Array<AnyObject> {
                        for (index, element) in enumerate(photoData) {
                            let name =  element["name"] as String;
                            //now each album photos
                            if let photosData = element["photos"] as AnyObject? as? Dictionary <String, AnyObject>{
                                if let photosArray = photosData["data"] as AnyObject? as? Array<AnyObject>{
                                    if let paging = photosData["paging"] as AnyObject? as? Dictionary <String, AnyObject>{
                                        if let next = paging["next"] as AnyObject? as? String
                                        {
                                            self.albumsToProcess[name] = name
                                            //found more elements to download
                                            var url = self.getRealURL(next);
                                            self.getPictures(photosArray, url: url, name:name)
                                        }
                                        else{
                                        }
                                    }
                                    else{
                                    }
                                    
                                    self.done(photosArray);
                                    
                                }
                            }
                        }
                    }
                }
            })
      }
    
    func getPictures(photoArray:Array<AnyObject>, url:String, name:String ){
        var photos:Array <AnyObject> = Array();
        photos += photoArray;
        
        FBRequestConnection.startWithGraphPath(url, parameters: nil, HTTPMethod: "GET", completionHandler: { (connection:FBRequestConnection!,  result:AnyObject!, error:AnyObject!) -> Void in
            
            if(error == nil){
                
                var photosDict:Dictionary = result as Dictionary<String, AnyObject>
               
               // var ph:AnyObject = photos["data"]!;
                if let ph = photosDict["data"] as AnyObject? as? Array <AnyObject>
                {
                    photos =  photos + ph;
             
                    
                }
                
       
                if let paging = photosDict["paging"] as AnyObject? as? Dictionary <String, AnyObject>{
                    //drill down to get a link
                    if let next = paging["next"] as AnyObject? as? String
                    {
                        
                    //    println("Next Element Is: ")
                        var url = self.getRealURL(next);
                    //    println(url)
                        
                        
                        self.getPictures(photos, url: url, name:name)
                    }
                    else{
                        self.albumsToProcess.removeValueForKey(name);
                        self.done(photos)
                    }
                }
                else{
                    self.albumsToProcess.removeValueForKey(name);
                    self.done(photos)
                }
            }
            else{
                println("Error")
                println(error);
                self.albumsToProcess.removeValueForKey(name);
                self.done(photos);
            }
        }
      )
    }
}


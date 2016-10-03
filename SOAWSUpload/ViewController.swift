//
//  ViewController.swift
//  SOAWSUpload
//
//  Created by Hitesh on 10/1/16.
//  Copyright © 2016 myCompany. All rights reserved.
//

import UIKit

let bucketName = "<bucket name>"
let accessKey = "ATRIVEDIKEYEXAMPLE"
let SecretKey = "jWaltXUntFEMI/SPACEO/ahITeshEXAMPLEKEY"

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var strURL : String = ""
    @IBOutlet weak var imgGallary: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imgGallary.layer.cornerRadius = imgGallary.frame.size.height/2
        imgGallary.layer.masksToBounds = true
        
        
        //Configure AWS by following snippets
        // Set Region too.
        let credentialsProvider: AWSStaticCredentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: SecretKey)
        let configuration: AWSServiceConfiguration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
    }

    
    //MARK: Fetch image from Gallery
    @IBAction func getImageFromGallary(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true;
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.delegate = self
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        strURL = self.saveImageInDocumentDirectory(image)
        imgGallary.image = image
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    
    //MARK: Save image to document directory
    func saveImageInDocumentDirectory(img : UIImage) -> String {
        let fileManager = NSFileManager.defaultManager()
        let path = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString).stringByAppendingPathComponent("demo.jpg") as String
        let imageData = UIImageJPEGRepresentation(img, 0.5)
        fileManager.createFileAtPath(path, contents: imageData, attributes: nil)
        return path
    }

    
    @IBAction func uploadOnAWSS3(sender: AnyObject) {
        // Set up the S3 upload request manager
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        // set the bucket
        uploadRequest.bucket = bucketName
        // Make Image public to view so set it as Public Read
        uploadRequest.ACL = .PublicRead
        // Set the image's name
        uploadRequest.key = "demoimage.jpg"
        // Set the content type
        uploadRequest.contentType = "image/jpeg"
        // Set local file path
        uploadRequest.body = NSURL(fileURLWithPath: strURL)

        //Get Progress of uploading date by Block
        uploadRequest?.uploadProgress = {(bytesSent:Int64, totalBytesSent:Int64, totalBytesExpectedToSend:Int64) in
            
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                print(totalBytesSent)
                print(totalBytesExpectedToSend)
            })
        }
        
        // Setup request for Upload
        let transferManager:AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        transferManager.upload(uploadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock:{
            task -> AnyObject in
            // Will get response status here.
            if(task.error != nil){
                // If got error then the get description from here.
                print("%@", task.error!.localizedDescription);
            }else{
                // Else we successfully uploaded image.
                // Url of S3 uploaded image should be like below
                print("https://s3.amazonaws.com/s3-demo-swift/\(bucketName)/demoimage.jpg");
            }
            return ""
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


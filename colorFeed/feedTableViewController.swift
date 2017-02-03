//
//  feedTableViewController.swift
//
//  Created by Ian Thomas
//

import UIKit
import SwiftyJSON

import AVKit
import AVFoundation

class feedTableViewController: UITableViewController {

    var arrayForTableView: [NSMutableDictionary] = []
    
    
    // MARK: Setup and UI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI
        setupNavigationBar (withImage: UIImage(named: "logo.png")!)
        setupTableViewBackgroundImage(withImage: UIImage(named: "background")!)
        
        // Setup data retrieval
        NotificationCenter.default.addObserver(self, selector: #selector(feedTableViewController.JSONDataReady), name: NSNotification.Name(rawValue: "dataReady"), object: nil)
        
        NotificationCenter.default.post(name: NSNotification.Name("pleaseSendData"), object: nil)
    }
    
    func setupNavigationBar (withImage theImage: UIImage) {
    
        let navigationBar = self.navigationController?.navigationBar
        navigationBar?.barStyle = UIBarStyle.default
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "logo.png")
        navigationItem.titleView = imageView
    }
    
    func setupTableViewBackgroundImage (withImage theImage: UIImage) {
    
        let backgroundImageView = UIImageView(image: theImage)
        self.tableView.backgroundView = backgroundImageView
    }
    
    
    // MARK: Convert JSON data to Array
    
    func JSONDataReady (_ theNotification: NSNotification) {
        
        if let theJSONArray = theNotification.object as? [JSON] {

            for aJsonDictionary in theJSONArray {
                
                let testType = aJsonDictionary["Type"].string
                
                if testType == "text" {
                    
                    // Get the confession color
                    let colorHue = self.videoStringToHue(withString: aJsonDictionary["VideoURL"].string!)
                    
                    
                    // First, add the confession cell
                    let textCellDictionary: NSMutableDictionary = [
                        "type" : testType! as String,
                        "colorHue" : colorHue,
                        "contents" : aJsonDictionary
                    ]
                    arrayForTableView.append(textCellDictionary)
                    
                    // If there is a video URL, then add a video cell
                    if let theVideoString = aJsonDictionary["VideoURL"].string {
                        
                        let videoCellDictionary: NSMutableDictionary = [
                            "type" : "video",
                            "videoString" : theVideoString
                        ]
                        arrayForTableView.append(videoCellDictionary)
                    }
                    
                    // If there are comments, add them
                    let comments = aJsonDictionary["Comments"] as JSON
                    
                    if comments.count > 0 {
                        for aComment in comments {
                            let theCommentJSONDictionary = aComment.1
                            
                            if let text = theCommentJSONDictionary["Text"].string, let userImage = theCommentJSONDictionary["UserImage"].string {
                                
                                let commentCellDictionary: NSMutableDictionary = [
                                    "type" : "comment",
                                    "text" : text,
                                    "userImage": userImage,
                                    "colorHue" : colorHue
                                ]
                                arrayForTableView.append(commentCellDictionary)
                            }
                        }
                    }
                    
                    // Finally, add a like cell for each confession
                    if let likeCount = aJsonDictionary["LikeCount"].string {
                        
                        var userLikeAction: String
                        
                        if let hasTheUserLikedTheConfession = aJsonDictionary["UserLikeAction"].string {
                            userLikeAction = hasTheUserLikedTheConfession
                        } else {
                            userLikeAction = "notLiked"
                        }
                        
                        let colorHue = self.videoStringToHue(withString: aJsonDictionary["VideoURL"].string!)
                        
                        let likeCellDictionary: NSMutableDictionary = [
                            "type" : "like",
                            "UserLikeAction" : userLikeAction,
                            "LikeCount" : likeCount,
                            "colorHue": colorHue
                        ]
                        arrayForTableView.append(likeCellDictionary)
                    }
                }
            }
        }
    }
    
    // Extract the last three digits of the video string to get the color hue data
    func videoStringToHue(withString theVideoString: String) -> Float {
        
        let start = theVideoString.index(theVideoString.endIndex, offsetBy: -7)
        let end = theVideoString.index(theVideoString.endIndex, offsetBy: -4)
        let range = start..<end
        let theHueString = theVideoString.substring(with: range)
        
        if let hueNumber = Float(theHueString) as Float! {
            return hueNumber
        } else {
            return 40
        }
    }
    
    
    // MARK: TableView Delegate
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let theModelForCellDictionary = arrayForTableView [indexPath.row]
        
        if let theCellType = theModelForCellDictionary["type"] as? String {
            
            if theCellType == "text" {
                
                return maketextCell(for: tableView, with: theModelForCellDictionary, at: indexPath)
                
            } else if theCellType == "video" {
                
                return makeVideoCell(for: tableView, with: theModelForCellDictionary, at: indexPath)
                
            } else if theCellType == "comment" {
                
                return makeCommentCell(for: tableView, with: theModelForCellDictionary, at: indexPath)
                
            } else if theCellType == "like" {
                
                return makeLikeCell(for: tableView, with: theModelForCellDictionary, at: indexPath)
            }
        }
        return UITableViewCell(style: .default, reuseIdentifier: "missingCellType")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return arrayForTableView.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let theModelForCellDictionary = arrayForTableView [indexPath.row]
        if let theCellType = theModelForCellDictionary["type"] as? String {
            
            if theCellType == "text" {
                return 200
                
            } else if theCellType == "comment" {
                return 90
                
            } else if theCellType == "video" {
                return 190
                
            } else if theCellType == "like" {
                return 75
            }
        }
        return 0
    }
    
    
    // MARK: Make the different cell types
    
    // Make a Confession Cell
    func maketextCell (for tableView: UITableView, with cellModelDictionary: NSMutableDictionary, at indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as! textCell
        
        if let theModelData = cellModelDictionary["contents"] as? JSON {
            
            let colorHue = cellModelDictionary["colorHue"] as! Float
            let text = theModelData["Text"].string!
            addTextAndColorizeQuotationMarks(withCell: cell, withColor: colorHue, withText: text)
            
            
            cell.colorButton.backgroundColor = colorizeFullSaturation(hue: colorHue)
            addShadowToObjectLayer(cell.colorButton.layer)

            
            if let postedBy = theModelData["PosterName"].string {
                cell.postedBy.text =  "posted by \(postedBy)"
            } else {
                cell.postedBy.text = "posted by anonymous"
            }
            cell.postedBy.textColor = colorizeHalfSaturation(hue: colorHue)
            
            setupDoubleTapToLikeConfession(withCell: cell, atIndexPath: indexPath)
        }
        return cell
    }
    
    // Make a Video Cell
    func makeVideoCell (for tableView: UITableView, with cellModelDictionary: NSMutableDictionary, at indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as! videoCell
        
        if let theVideoPath = cellModelDictionary["videoString"] as? String {
            
            // This properly sizes the width of video cells
            cell.layoutIfNeeded()
            
            // Remove any previous video
            if cell.theVideoPlayerLayer != nil {
                cell.theVideoPlayerLayer.removeFromSuperlayer()
            }
            
            let videoURL = NSURL(string: theVideoPath)
            
            cell.theVideoPlayer = AVPlayer(url: videoURL! as URL)
            cell.theVideoPlayerLayer = AVPlayerLayer(player: cell.theVideoPlayer)
            cell.theVideoPlayerLayer.frame = cell.theVideoPlayerContainer.frame
            cell.layer.addSublayer(cell.theVideoPlayerLayer)
            
            cell.theVideoPlayer.play()
            
            self.loopVideo(videoPlayer: cell.theVideoPlayer)
        }
        return cell
    }
    
    // Make a Comment Cell
    func makeCommentCell (for tableView: UITableView, with cellModelDictionary: NSMutableDictionary, at indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! commentCell
        
        if let userImageString = cellModelDictionary["userImage"] as? String, let url = NSURL(string: userImageString), let data = NSData(contentsOf: url as URL) {
            
            cell.userImageView.image = UIImage(data: data as Data)
            cell.userImageView.layer.cornerRadius =  cell.userImageView.frame.size.width / 2;
            cell.userImageView.layer.masksToBounds = true
        }
        
        if let theCommentText = cellModelDictionary["text"] as? String {
            
            let colorHue = cellModelDictionary["colorHue"] as! Float
            addTextAndColorizeQuotationMarks(withCell: cell, withColor: colorHue, withText: theCommentText)
        }
        addShadowToObjectLayer(cell.commentBubble.layer)
        
        return cell
    }

    // Make a Like Cell
    func makeLikeCell (for tableView: UITableView, with cellModelDictionary: NSMutableDictionary, at indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "likeCell", for: indexPath) as! likeCell
        
        if let colorHue = cellModelDictionary["colorHue"] as? Float {
            
            cell.likeButtonTextLabel.textColor = colorizeFullSaturation(hue: colorHue)
            cell.likeButton.tintColor = colorizeFullSaturation(hue: colorHue)
        }
        
        if let liking = cellModelDictionary["UserLikeAction"] as? String {
            
            let likeImage = self.updateLikeButtonPicture(for: liking)
            cell.likeButton.setImage(likeImage, for: .normal)
        }
        
        if let cellLikeCountString = cellModelDictionary["LikeCount"] as? String {
            
            if let cellLikeCount = Int(cellLikeCountString) {
                
                if cellLikeCount > 0 {
                    cell.likeButtonTextLabel.text = "\(cellLikeCount)"
                } else {
                    cell.likeButtonTextLabel.text = "Like"
                }
            }
        }
        
        cell.heartLikingBig.tag = indexPath.row
        cell.heartLikingBig.alpha = 0.0
        
        cell.likeButton.addTarget(self, action: #selector(feedTableViewController.likeButtonPressed(sender:)), for: .touchUpInside)
        
        cell.likeButton.tag = indexPath.row
        
        return cell
    }
    
    
    // MARK: Cell-Making Helper Methods
    
    // Add drop-shadows under specific cell layers
    func addShadowToObjectLayer (_ theLayer: CALayer) {
        
        theLayer.shadowColor = UIColor.black.cgColor
        theLayer.shadowOffset = CGSize(width: 0, height: 3)
        theLayer.shadowOpacity = 0.5
        theLayer.shadowRadius = 3.0
    }

    func loopVideo(videoPlayer: AVPlayer) {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            videoPlayer.seek(to: kCMTimeZero)
            videoPlayer.play()
        }
    }
    
    func updateLikeButtonPicture(for likeStatus: String) -> UIImage {
        
        if likeStatus == "liked" {
            return UIImage(named: "heartClosed.png")!
        } else {
            return UIImage(named: "heartOpen.png")!
        }
    }
    
    // MARK: Cell-Making Text and Quotation Marks Helper Methods
    
    func addTextAndColorizeQuotationMarks (withCell theCell: UITableViewCell, withColor colorHue: Float, withText theStringToDisplay: String) {
        
        let openQuoteImage: UIImage = UIImage(named: "openQuote")!.withRenderingMode(.alwaysTemplate)
        
        if let thetextCell = theCell as? textCell {
            
            thetextCell.openQuoteImageView.image = openQuoteImage
            thetextCell.openQuoteImageView.tintColor = colorizeHalfSaturation(hue: colorHue)
            
            thetextCell.postedText.textColor = UIColor.white
            
            thetextCell.postedText.attributedText = addRearQuotationMark(withText: theStringToDisplay, withHue: colorHue);
            
            
        } else if let theCommentCell = theCell as? commentCell {
            
            theCommentCell.openQuoteImageView.image = openQuoteImage
            theCommentCell.openQuoteImageView.tintColor = colorizeHalfSaturation(hue: colorHue)
            
            theCommentCell.commentTextLabel.textColor = UIColor.white
            
            theCommentCell.commentTextLabel.attributedText = addRearQuotationMark(withText: theStringToDisplay, withHue: colorHue);
        }
    }
    
    func addRearQuotationMark (withText theStringToDisplay: String, withHue colorHue: Float) -> NSAttributedString {
        
        let closeQuoteImageAttachment: NSTextAttachment = NSTextAttachment()
        
        closeQuoteImageAttachment.image = UIImage(named: "closeQuote")!.withRenderingMode(.alwaysTemplate)
        
        closeQuoteImageAttachment.bounds = CGRect(x: 0, y: 0, width: 20, height: 17)
        
        
        let attributedStringWithImage: NSAttributedString = NSAttributedString(attachment: closeQuoteImageAttachment);
        
        let attributedString: NSMutableAttributedString =
            NSMutableAttributedString(string: "\(theStringToDisplay) ")
        
        attributedString.append(attributedStringWithImage)
        
        attributedString.addAttribute(
            NSForegroundColorAttributeName,
            value: colorizeHalfSaturation(hue: colorHue),
            range: NSMakeRange(
                theStringToDisplay.characters.distance(from: theStringToDisplay.startIndex, to: theStringToDisplay.endIndex), attributedStringWithImage.length))
        
        return attributedString
    }
    
    
    // MARK: Liking Interfaces
    
    // Double tap to like a confession ... or
    func doubleTapConfession (sender: UITapGestureRecognizer) {
        
        let cellIndexRow = (sender.view?.tag)! as Int
        
        let numCellBetweenConfessionTextAndComment = 2
        
        let indexOfTargetLikeCell = cellIndexRow + numCellBetweenConfessionTextAndComment + offsetNumberOfConfessionComments(forCell: cellIndexRow)
        
        performLikeOrUnlikeAction(withLikeCellIndex: indexOfTargetLikeCell)
    }
    
    //  ... or Tap the heart to like a confession
    @IBAction func likeButtonPressed(sender: UIButton) {
        
        let cellIndexRow = sender.tag
        performLikeOrUnlikeAction (withLikeCellIndex: cellIndexRow)
    }
    
    
    // MARK: Liking Interface Helper Methods
    
    func setupDoubleTapToLikeConfession (withCell cell: textCell, atIndexPath indexPath: IndexPath) {
        
        cell.tag = indexPath.row
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(feedTableViewController.doubleTapConfession(sender:)))
        doubleTap.numberOfTapsRequired = 2
        cell.addGestureRecognizer(doubleTap)
    }
    
    func offsetNumberOfConfessionComments(forCell cellIndexRow: Int) -> Int {
        
        let confessionContentData = arrayForTableView [cellIndexRow]["contents"] as! JSON
        let comments = confessionContentData["Comments"] as JSON
        
        return comments.count
    }
    
    
    // MARK: Liking Methods
    
    func performLikeOrUnlikeAction(withLikeCellIndex cellIndexRow: Int) {
        
        if arrayForTableView[cellIndexRow].value(forKey: "UserLikeAction") as! String == "liked" {
            unlikeConfession(withIndexRow: cellIndexRow)
            
        } else {
            likeConfession(withIndexRow: cellIndexRow)
        }
    }
    
    func likeConfession (withIndexRow cellIndexRow: Int) {
        
        self.tableView.isScrollEnabled = false
        
        // Update data model
        arrayForTableView[cellIndexRow].setValue("liked", forKey: "UserLikeAction")
        updateConfessionLikeCounter(withIndexRow: cellIndexRow, byValue: 1)
        
        // Perform UI actions and updates
        performLikingUIActions(withLikeCellIndexRow: cellIndexRow)
    }
    
    func unlikeConfession (withIndexRow likeCellIndexRow: Int) {
        
        // Update data model
        arrayForTableView[likeCellIndexRow].setValue("unLiked", forKey: "UserLikeAction")
        updateConfessionLikeCounter(withIndexRow: likeCellIndexRow, byValue: -1)
        
        // Update the UI
        self.tableView.reloadRows(at: [IndexPath(row: likeCellIndexRow, section: 0)], with: .none)
    }
    
    func updateConfessionLikeCounter(withIndexRow likeCellIndexRow: Int, byValue theInt: Int) {
    
        if let cellLikeCountString = arrayForTableView[likeCellIndexRow].value(forKey: "LikeCount") as? String, var cellLikeCount = Int(cellLikeCountString) {
            
            cellLikeCount = cellLikeCount + theInt
            arrayForTableView[likeCellIndexRow].setValue("\(cellLikeCount)", forKey: "LikeCount")
        }
    }
    
    
    // MARK: UI Actions for Liking
    
    func performLikingUIActions(withLikeCellIndexRow cellIndexRow: Int) {
        
        let theCell = self.tableView.cellForRow(at: IndexPath(row: cellIndexRow, section: 0)) as! likeCell
        
        // Set the large resizing heart button and remember its position for down-scaling later
        let heartButtonOriginalCenter = setOriginalPositionOfHeart(theCell.heartLikingBig)
        
        let likingViewDimension:CGFloat = 100
        
        let likingView = setupLikingView(withOriginalCenter: heartButtonOriginalCenter, withDimension: likingViewDimension)
        let bigHeartImageView = setupALikingImage(withMainView: likingView, withImage: UIImage(named: "heartLiking")!, withDimension: likingViewDimension)
        let stripesImageView = setupALikingImage(withMainView: likingView, withImage: UIImage(named: "stripes")!, withDimension: likingViewDimension)
        
        
        // Start the heart small
        bigHeartImageView.bounds.size = CGSize(width: 30, height: 30)
        bigHeartImageView.transform.scaledBy(x: 0.1, y: 0.1)
        

        UIView.animate(withDuration: 0.8, animations: {
            
            // Scale up the heart
            bigHeartImageView.bounds.size = CGSize(width: 200, height: 200)
            bigHeartImageView.alpha = 1.0
            
            self.centerTheView(likingView, withWidth: likingViewDimension, withHeight: likingViewDimension)
            
        }, completion: { _ in
            
            // Scale the stripes image
            stripesImageView.frame = bigHeartImageView.frame
            stripesImageView.bounds.size = CGSize(width: 115, height: 115)
            
            UIView.animate(withDuration: 0.5, animations: {
                
                stripesImageView.alpha = 1.0
                
            }, completion: { _ in
                
                let exclamationImageView = self.addExclamationText(withView: likingView, withBackground: bigHeartImageView)
                
                UIView.animate(withDuration: 0.5, delay: 0.2, animations: {
                    exclamationImageView.alpha = 1.0
                    
                }, completion: { _ in
                    
                    UIView.animate(withDuration: 0.20, delay: 0.0, options: [.autoreverse, .repeat], animations: {
                        
                        // Animate the text in the heart
                        UIView.setAnimationRepeatCount(3)
                        exclamationImageView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                        
                    }, completion: { _ in
                        
                        UIView.animate(withDuration: 0.9, animations: {
                            
                            self.returnHeartToNormalSize(withView: likingView, withCenter: heartButtonOriginalCenter)
                            
                        }, completion: {_ in
                            
                            self.finishLikeActionUI(cellIndexRow)
                        })
                    })
                })
            })
        })
    }
    
    
    // MARK Liking Animation Helper Methods
    
    // MARK: Setup Liking Animation Variables
    
    func setOriginalPositionOfHeart (_ heartButton: UIButton) -> CGPoint {
        
        let heartButtonGlobalOriginalRect: CGRect = (heartButton.superview?.convert(heartButton.frame, to: self.tableView.window))!;
        let heartButtonOriginalCenter: CGPoint = CGPoint(x: (heartButtonGlobalOriginalRect.origin.x + heartButtonGlobalOriginalRect.size.width), y: heartButtonGlobalOriginalRect.origin.y + heartButtonGlobalOriginalRect.size.height / 4)
        
        return heartButtonOriginalCenter
    }
    
    func setupLikingView(withOriginalCenter originalCenter: CGPoint, withDimension theDimension: CGFloat) -> UIView {
        
        let likingView: UIView = UIView(frame: CGRect(x: originalCenter.x, y: originalCenter.y, width: theDimension, height: theDimension))
        
        self.navigationController?.view.addSubview(likingView)
        self.navigationController?.view.bringSubview(toFront: likingView)
        
        return likingView
    }
    
    func setupALikingImage (withMainView theView: UIView, withImage theImage: UIImage, withDimension dimension: CGFloat) -> UIImageView {
        
        let theImageView: UIImageView = UIImageView(image: theImage)
        
        theImageView.bounds = theView.bounds
        theView.addSubview(theImageView)
        theImageView.alpha = 0.0
        
        return theImageView
    }
    
    func centerTheView (_ theView: UIView, withWidth viewWidth: CGFloat, withHeight viewHeight: CGFloat) {
    
        let screenWidth = UIScreen.main.bounds.width / 2 - viewWidth / 2
        let screenHeight = UIScreen.main.bounds.height / 2 - viewHeight / 2
        theView.center = CGPoint(x: screenWidth, y: screenHeight)
    }
    
    func addExclamationText (withView likingView: UIView, withBackground bigHeartImageView: UIImageView) -> UIImageView {
        
        var exclamationImage: UIImage
        
        // Chose one of two possible text exclamations
        let randomText = Int(arc4random_uniform(2))
        switch randomText {
            
        case 1:
            exclamationImage = UIImage(named: "wow")!
        default:
            exclamationImage = UIImage(named: "cool")!
        }
        
        let exclamationImageView = UIImageView(image: exclamationImage)
        
        exclamationImageView.frame = bigHeartImageView.frame
        exclamationImageView.bounds.size = CGSize(width: 90, height: 90)
        
        likingView.addSubview(exclamationImageView)
        
        exclamationImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        exclamationImageView.center = bigHeartImageView.center
        
        return exclamationImageView
    }
    
    func returnHeartToNormalSize(withView likingView: UIView, withCenter heartButtonOriginalCenter: CGPoint) {
        
        likingView.center = heartButtonOriginalCenter
        likingView.alpha = 0.0
        likingView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
    }
    
    func finishLikeActionUI(_ cellIndexRow: Int) {
        
        self.tableView.reloadRows(at: [IndexPath(row: cellIndexRow, section: 0)], with: .none)
        self.tableView.isScrollEnabled = true
    }
    
    
    // MARK: Coloring Methods
    
    func colorizeFullSaturation(hue: Float) -> UIColor {
        return UIColor(hue: CGFloat(hue)/360, saturation: CGFloat(1.0), brightness: 1.0, alpha: 1.0)
    }
    
    func colorizeHalfSaturation(hue: Float) -> UIColor {
        return UIColor(hue: CGFloat(hue)/360, saturation: CGFloat(0.5), brightness: 1.0, alpha: 1.0)
    }
    
    
    // MARK: Misc Methods
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

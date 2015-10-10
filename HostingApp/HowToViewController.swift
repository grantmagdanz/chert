//
//  HowToViewController.swift
//  SnapBoard -- Multi-line Text for Snapchat
//
//  Created by Grant Magdanz on 10/10/15.
//  Copyright © 2015 Apple. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class HowToViewController: UIViewController {
    @IBOutlet weak var screen: UIView!
    private var player: AVPlayer? = nil
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // load in video file
        let videoURL: NSURL = NSBundle.mainBundle().URLForResource("tutorial", withExtension: "mp4")!
        player = AVPlayer(URL: videoURL)
        
        // set up player to loop
        player!.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "videoIsOver:",
            name: AVPlayerItemDidPlayToEndTimeNotification,
            object: player!.currentItem)  
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        var playerLayer: AVPlayerLayer?
        playerLayer = AVPlayerLayer(player: player)
        
        let bounds = screen.layer.bounds
        playerLayer!.videoGravity = AVLayerVideoGravityResize
        playerLayer!.bounds = bounds
        playerLayer!.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        screen.layer.addSublayer(playerLayer!)
        
        player!.play()
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // pause player if user switches views
        player!.pause()
    }
    
    // rewinds video to beginning
    func videoIsOver(notification: NSNotification) {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seekToTime(kCMTimeZero)
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

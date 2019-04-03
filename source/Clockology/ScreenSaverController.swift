//
//  ViewController.swift
//  Clockology
//
//  Created by Michael Hill on 3/11/19.
//  Copyright © 2019 Michael Hill. All rights reserved.
//

import UIKit
import SpriteKit

enum NavigationDestination: String {
    case EditList, None
}

class ScreenSaverController: UIBrightnessViewController, UIGestureRecognizerDelegate {

    var currentClockIndex = 0
    var currentNavDesination: NavigationDestination = .None

    weak var previewViewController:PreviewViewController?
    @IBOutlet var panGesture:UIPanGestureRecognizer?
    @IBOutlet var swipeGestureLeft:UISwipeGestureRecognizer?
    @IBOutlet var swipeGestureRight:UISwipeGestureRecognizer?
    
    @IBOutlet var buttonContainerView: UIView!
    
    @IBAction func callEditList() {
        //generate thumbs and exit if needed
        if shouldRegenerateThumbNailsAndExit() {
            currentNavDesination = .EditList
            return
        }
        
        self.performSegue(withIdentifier: "callEditListID", sender: nil)
    }
    
    @IBAction func showButtons() {
        if self.buttonContainerView.alpha < 1.0 {
            //showing button interface
            self.clockBrightness = UIScreen.main.brightness
            restoreBrightness(level: usersBrightness)
            UIView.animate(withDuration: 0.5) {
                self.buttonContainerView.alpha = 1.0
            }
        } else {
            //hiding button interface
            restoreBrightness(level: clockBrightness)
            UIView.animate(withDuration: 0.5) {
                self.buttonContainerView.alpha = 0.0
            }
        }
    }
    
    @IBAction func nextClock() {
        currentClockIndex = currentClockIndex + 1
        if (UserClockSetting.sharedClockSettings.count <= currentClockIndex) {
            currentClockIndex = 0
        }
        
        SettingsViewController.currentClockSetting = UserClockSetting.sharedClockSettings[currentClockIndex].clone()!
        redrawPreviewClock(transition: true, direction: .left)
    }
    
    @IBAction func prevClock() {
        currentClockIndex = currentClockIndex - 1
        if (currentClockIndex<0) {
            currentClockIndex = UserClockSetting.sharedClockSettings.count - 1
        }
        
        SettingsViewController.currentClockSetting = UserClockSetting.sharedClockSettings[currentClockIndex].clone()!
        redrawPreviewClock(transition: true, direction: .right)
    }
    
    func shouldRegenerateThumbNailsAndExit() -> Bool {
        //generate thumbs and exit if needed
        let missingThumbs = UserClockSetting.settingsWithoutThumbNails()
        if (missingThumbs.count > 0) {
            //first run, reload everything
//            if missingThumbs.count == UserClockSetting.sharedClockSettings.count {
//                faceListReloadType = .full
//            }
            self.performSegue(withIdentifier: "callMissingThumbsGeneratorID", sender: nil)
            return true
        }
        return false
    }
    
    func redrawPreviewClock(transition: Bool, direction: SKTransitionDirection) {
        //tell preview to reload
        if previewViewController != nil {
            previewViewController?.redraw(transition: transition, direction: direction)
            //self.showMessage( message: SettingsViewController.currentClockSetting.title)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        storeBrightness()
        
        if currentNavDesination == .EditList {
            currentNavDesination = .None
            callEditList()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        restoreBrightness(level: usersBrightness)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        storeBrightness()
        buttonContainerView?.alpha = 0.0
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ScreenSaverController.showButtons)))
        
        SettingsViewController.currentClockSetting = UserClockSetting.sharedClockSettings[currentClockIndex].clone()!
        redrawPreviewClock(transition: false, direction: .up)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is PreviewViewController {
            let vc = segue.destination as? PreviewViewController
            previewViewController = vc
        }
        if segue.destination is SettingsViewController {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    //hide the home indicator
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    
    //allow for both gestures at the same time
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.panGesture &&
            (otherGestureRecognizer == self.swipeGestureLeft || otherGestureRecognizer == self.swipeGestureRight) {
            return true
        }
        return false
    }
    
    //get brightness offset from PAN
    @IBAction func respondToPanGesture(gesture: UIPanGestureRecognizer) {
        
        //dont adjust levels when buttons are up
        guard buttonContainerView.alpha == 0 else { return }
        
        let mult:CGFloat = self.view.frame.size.height / 0.3 //larger number makes swipes change brightness faster
        let current = UIScreen.main.brightness
        let translationPoint = gesture.translation(in: self.view)
        let desiredBrightness = current - (translationPoint.y / mult)
        
        if gesture.state == .began {
            setBrightness(bright: desiredBrightness)
        }
        if gesture.state == .changed {
            //debugPrint("tr y:" + translationPoint.y.description + "m:" + (translationPoint.y / mult).description )
            //debugPrint("now:" + (DispatchTime.now().uptimeNanoseconds - timeSinceLastBrightNessUpdate).description)
            if DispatchTime.now().uptimeNanoseconds - timeSinceLastBrightNessUpdate > 20000000 {
                timeSinceLastBrightNessUpdate = DispatchTime.now().uptimeNanoseconds
                setBrightness(bright: desiredBrightness)
            }
        }
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            setBrightness(bright: desiredBrightness)
        }
    }

}

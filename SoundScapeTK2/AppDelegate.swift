//
//  AppDelegate.swift
//  SoundScapeTK2
//
//  Created by kfl on 5/27/19.
//  Copyright © 2019 kfl. All rights reserved.
//

import UIKit
import libpd


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PdReceiverDelegate {

    var window: UIWindow?
    var audioController: PdAudioController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // create soundscape data here
        let soundscapeData = SoundScapeData()
        
        let audioManager = AudioManager(patch:"sampler4bank.pd")
        audioManager.openPDPatch(patchString: audioManager.patchString)
        
        let dispatcher = PdDispatcher()
        audioManager.dispatcher = dispatcher
        
        PdBase.setDelegate(dispatcher)

        // get references to the 2 vcs that need ssdata and pass it
        guard let tabBarController = window?.rootViewController as? UITabBarController,
            let viewControllers = tabBarController.viewControllers else { return true }
        
        for (_, vc) in viewControllers.enumerated() {
            if let navigationController = vc as? UINavigationController,
                let regionsTableVC = navigationController.viewControllers.first as? RegionsTableViewController {
                regionsTableVC.soundscapeData = soundscapeData
            } else
            if let hudVC = vc as? HUDViewController {
                hudVC.soundscapeData = soundscapeData
                hudVC.appDelegate = self
                hudVC.audiomanager = audioManager
            }
        }
        // call get-data to populate both ssdata vars linked above
        soundscapeData.getJSONTestData()
        
        self.audioController = PdAudioController()
        // Pd setup
        self.audioController?.configurePlayback(withSampleRate: 48000,
                                                numberChannels: 2,
                                                inputEnabled: false,
                                                mixingEnabled: false)
        self.audioController?.print()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    
    

    func activateAudio(onFlag: Bool) {
        self.audioController?.isActive = onFlag
        if (self.audioController?.isActive ?? false) {
            print("Audio is ON.")
        } else {
            print("Audio is OFF.")
        }
    }
    
}


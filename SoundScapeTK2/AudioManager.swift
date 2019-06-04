//
//  AudioManager.swift
//  SoundScapeTK2
//
//  Created by kfl on 5/31/19.
//  Copyright © 2019 kfl. All rights reserved.
//

import Foundation
import libpd

class AudioManager: NSObject, PdReceiverDelegate, PdListener {
    
    var patchString:    String
    var slots:          Int
    var activeSlots:    [Int:Region]
    var activeTimers:   [Int:Timer]
    var dispatcher:     PdDispatcher?
    
    init(patch: String) {
        self.patchString = patch
        self.slots = 4
        self.activeSlots = [Int:Region]()
        self.activeTimers = [Int:Timer]()
    }
    
    // Pd callbacks
//    func receivePrint(message: String!) {
//        NSLog("PD print:       %s\n", message)
//    }
    func receive(_ received: Float, fromSource source: String!) {
        NSLog("PD print: [%s]   %f\n", source, received)
    }
    func receiveSymbol(_ symbol: String!, fromSource source: String!) {
        NSLog("PD print: [%s] %s\n", source, symbol)
    }
    func receiveBang(fromSource source: String!) {
        NSLog("PD print: [%s] _BANG_\n", source)
    }
    func receiveList(_ list: [Any]!, fromSource source: String!) {
        NSLog("PD print: [%s] ", source)
        for item in list {
            NSLog("- %s", item as! String)
        }
        NSLog("\n")
    }
    func receiveMessage(_ message: String!, withArguments arguments: [Any]!, fromSource source: String!) {
        NSLog("PD print: [%s] %s", source, message)
        for item in arguments {
            NSLog("- %s", item as! String)
        }
        NSLog("\n")
    }

    func reset() {
        self.activeSlots = [Int:Region]()
        for (_,timer) in self.activeTimers {
                timer.invalidate()
        }
        self.activeTimers.removeAll()
    }
    
    func openPDPatch(patchString: String) {
        print("Opening: ", self.patchString, "\nfrom: ", Bundle.main.bundlePath)
        self.adjustMasterGain(gain: 1.0)
        PdBase.openFile(self.patchString, path: Bundle.main.bundlePath)
    }
    
    func openSoundFile(soundFilePath: String, inSlot: Int) {
        let openSlot = String(inSlot) + "_open"
        PdBase.sendMessage(soundFilePath, withArguments: [], toReceiver: openSlot)
    }
    
    func assignSlotForRegion(region: Region) -> Int {
        if (self.activeSlots.count == self.slots) {
            return -1
        } else if (self.activeSlots.count == 0) {
            return 0

        } else {
            for i in (0..<slots) {
                if (self.activeSlots[i] == nil) {
                    return i
                }
            }
        }
        return -1 // something went wrong
    }
    
    func openSoundFilePath(path: String, atSlot: Int) {
        PdBase.sendMessage(path, withArguments: [0], toReceiver: (String(atSlot) + "_open"))
    }
    
    func adjustAttackForSlot(attack: Double, atSlot: Int) {
        PdBase.sendMessage("attack", withArguments: [attack], toReceiver: (String(atSlot) + "_in"))
    }

    func adjustReleaseForSlot(release: Double, atSlot: Int) {
        PdBase.sendMessage("release", withArguments: [release], toReceiver: (String(atSlot) + "_in"))
    }

    func adjustGainForSlot(gain: Double, atSlot: Int) {
        PdBase.sendMessage("level", withArguments: [gain], toReceiver: (String(atSlot) + "_in"))
    }
    
    func adjustMasterGain(gain: Double) {
        PdBase.send(Float(gain), toReceiver: "_master_volume")
    }
    
    func adjustPanForSlot(pan: Double, atSlot: Int) {
        PdBase.sendMessage("pan", withArguments: [pan], toReceiver: (String(atSlot) + "_in"))
    }
    
    func triggerPlay(atSlot: Int) {
        PdBase.sendMessage("play", withArguments: [], toReceiver: (String(atSlot) + "_in"))
    }
    
    func triggerStop(atSlot: Int) {
        PdBase.sendMessage("stop", withArguments: [], toReceiver: (String(atSlot) + "_in"))
    }
    
    func playLinkedSoundFile(region: Region) {
        assert(region.state == .ready)
        let assignedSlot = self.assignSlotForRegion(region:region)
        if ((assignedSlot > -1) && (region.linkedSoundFile != nil)) {
            print("assignedSlot: " + String(assignedSlot))
            let fakeDuration = 5.0
            // automatically schedule stop after normal duration
            region.state = .playing
            region.assignedSlot = assignedSlot
//            let assignedSlotNS: NSNumber = NSNumber(assignedSlot)
            let stoptimer = Timer.scheduledTimer(timeInterval: fakeDuration,
                                                 target: self,
                                                 selector: #selector(AudioManager.stopLinkedSoundFile(timer:)),
                                                 userInfo: ["slot": NSNumber.init(value: assignedSlot)],
                                                 repeats: false)
            
            self.activeTimers[assignedSlot] = stoptimer
            self.activeSlots[assignedSlot] = region
            
            DispatchQueue.global(qos: .userInitiated).async() { [weak self] in
                guard let self = self else {
                    return
                }
                var backgroundTaskID:UIBackgroundTaskIdentifier? = nil
                backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "trigger playback for a region") {
                    // End the task if time expires.
                    UIApplication.shared.endBackgroundTask(backgroundTaskID!)
                    backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                }
                // open the sound file in the patcher
                print("playing: ", (region.linkedSoundFile ?? "NO FILE"))
                self.openSoundFilePath(path: region.linkedSoundFile!, atSlot: assignedSlot)
                // TODO: PASS in gain!!!
                self.adjustGainForSlot(gain: 1.0, atSlot: assignedSlot)
                self.adjustAttackForSlot(attack: region.attack, atSlot: assignedSlot)
                self.adjustReleaseForSlot(release: region.release, atSlot: assignedSlot)
                self.triggerPlay(atSlot: assignedSlot)
                self.adjustMasterGain(gain: 1.0)

                RunLoop.current.add(stoptimer, forMode: RunLoop.Mode.common)

                UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            }
            
//            self.activeTimers[region.assignedSlot!] = stoptimer
        }
    }
    

    func stopLinkedSoundFile(slot:Int) {
        
        let stopSlot = slot
        let region = self.activeSlots[stopSlot] ?? nil
        
        assert(region?.state! == .playing)
        if (region?.assignedSlot != nil) {
            PdBase.sendMessage("stop", withArguments: [], toReceiver: (String(region!.assignedSlot!) + "_in"))
            region?.state = .stopping
        }
        self.activeTimers[stopSlot]!.invalidate()
        self.activeTimers[stopSlot] = nil
        region!.state = .fading
    }
//    func stopLinkedSoundFile(region: Region) {
    @objc func stopLinkedSoundFile(timer:Timer) {
        
        guard let context = timer.userInfo as? [String:NSNumber] else { return }
        let stopSlot: Int = context["slot", default: NSNumber(value: -1)].intValue
        let region = self.activeSlots[stopSlot] ?? nil
        
        assert(region?.state == .playing)
        if (region?.assignedSlot != nil) {
            PdBase.sendMessage("stop", withArguments: [], toReceiver: (String(region!.assignedSlot!) + "_in"))
            region!.state = .fading
        }
        self.activeTimers[stopSlot]!.invalidate()
        //
        let timer = Timer.scheduledTimer(timeInterval: (region!.release * 0.001),
                                         target: self,
                                         selector: #selector(resetLinkedSoundFile(timer:)),
                                         userInfo: context,
                                         repeats: false)
        self.activeTimers[stopSlot] = timer
    }
    
    // assuming fade is COMPLETE!
    @objc func resetLinkedSoundFile(timer:Timer) {
        
        guard let context = timer.userInfo as? [String:NSNumber] else { return }
        let resetSlot: Int = context["slot", default: NSNumber(value: -1)].intValue
        let region = self.activeSlots[resetSlot]
        assert(region?.state == .fading)
        let assignedSlotToRemove = region?.assignedSlot ?? -1
        if (assignedSlotToRemove > -1) {
            self.activeSlots.removeValue(forKey: assignedSlotToRemove)
        }
        region!.state = .ready
        self.activeTimers[resetSlot]!.invalidate()
    }
}

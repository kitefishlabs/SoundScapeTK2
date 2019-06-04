//
//  HUDViewController.swift
//  SoundScapeTK2
//
//  Created by kfl on 5/28/19.
//  Copyright © 2019 kfl. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import libpd

class HUDViewController: UIViewController {

    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var gpsStatusLabel: UILabel!
    @IBOutlet weak var numActiveRegionsLabel: UILabel!

    @IBOutlet var mapView:MKMapView!
//    private var locations: [MKPointAnnotation] = []
    
    var appDelegate: AppDelegate?
//    var audioManager: AudioManager?
    var soundscapeData: SoundScapeData?
    var regionPins: [RegionPin] = []

    var audiomanager: AudioManager?
    
    func loadPins() {
        self.regionPins = (soundscapeData?.regions.map{ RegionPin(title: $0.label,
                                                                  coordinate: CLLocationCoordinate2D(latitude: $0.lat,
                                                                                                     longitude: $0.lon))}) ?? []
        NSLog(":: %d %d", (self.soundscapeData?.regions.count ?? 0), self.regionPins.count)
    }

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.allowsBackgroundLocationUpdates = true
        return manager
    } ()
    
    @IBAction func enableChanged(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.startUpdatingLocation()
            self.appDelegate?.activateAudio(onFlag: true)
            gpsStatusLabel.text = "Tracking"
        } else {
            locationManager.stopUpdatingLocation()
            self.appDelegate?.activateAudio(onFlag: false)
            gpsStatusLabel.text = "Paused"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let initialLocation = CLLocation(latitude: 41.48785, longitude: -81.74062)
        self.centerMapOnLocation(location: initialLocation)
        
        self.loadPins()
        mapView.addAnnotations(self.regionPins)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    var regionRadius: CLLocationDistance = 1000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion.init(center:location.coordinate,
                                                       latitudinalMeters:regionRadius,
                                                       longitudinalMeters:regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }

}

extension HUDViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else {
            return
        }
        
        latitudeLabel.text = String(mostRecentLocation.coordinate.latitude)
        longitudeLabel.text = String(mostRecentLocation.coordinate.longitude)
        accuracyLabel.text = String(mostRecentLocation.horizontalAccuracy)
        numActiveRegionsLabel.text = String(soundscapeData?.regions.count ?? 0)
        
//        let annotation = MKPointAnnotation()
//        annotation.coordinate = mostRecentLocation.coordinate
    
//        self.locations = [annotation]
        
//        while self.locations.count > 1 {
//            let toRemove = self.locations.first!
//            self.locations.remove(at: 0)
//            mapView.removeAnnotation(toRemove)
//        }
        print("most recent loc. update: " + String(mostRecentLocation.coordinate.latitude) + " " + String(mostRecentLocation.coordinate.longitude))
        
        let recentHits = self.soundscapeData?.testAllRegions(lat: mostRecentLocation.coordinate.latitude, lon: mostRecentLocation.coordinate.longitude) ?? []
        
        self.processEnterAndExitEvents(regionList: recentHits)
        
        if UIApplication.shared.applicationState != .active {
//            mapView.showAnnotations(self.locations, animated: true)
//        } else {
            print("App is backgrounded... New location is %@.", mostRecentLocation)
        }
    }
}

extension HUDViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? RegionPin else { return nil }
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x:-5, y:5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
}


extension HUDViewController {
    
    func processEnterAndExitEvents(regionList: [Region]) {
        
        if (((regionList.count == 1) && (regionList[0].id == -1)) || (regionList.count == 0)){
            //stop all
            for reg in regionList {
                assert(reg.state! == .playing)
                reg.state = .stopping
                self.audiomanager?.stopLinkedSoundFile(slot: (reg.assignedSlot ?? -1))
                self.audiomanager?.adjustMasterGain(gain: 0.0)
            }
        } else {
    
            for reg in regionList {
                
                if ((reg.shape == "CIRCLE") && (reg.active ?? false) && (reg.lives > 0)) {
                    if reg.state! == .ready {
                        let foundSlot = self.audiomanager?.assignSlotForRegion(region: reg)
                        if (foundSlot! > -1) {
                            self.audiomanager?.playLinkedSoundFile(region: reg)
                            self.audiomanager?.adjustMasterGain(gain: 1.0)
                        }
                    } else if reg.state! == .playing {
                        assert((reg.assignedSlot ?? -1) > -1)
                        self.audiomanager?.adjustGainForSlot(gain: max(1.0 - (reg.internalDistance ?? 0.0), 0.0), atSlot: reg.assignedSlot!)
                    } else {
                        print("process enter and exit NOT ready or PLAYING in processEnterAndExit")
                    }
                }
            }
        }
        
        let allTriggeredRegions: Set = Set(regionList)
        let allActiveRegions: [Region] = self.audiomanager?.activeSlots.values.filter { $0.active ?? false } ?? []

//        let retriggeredRegions = allActiveRegions.filter { allTriggeredRegions.contains($0) }
        let justleftRegions = allActiveRegions.filter { !allTriggeredRegions.contains($0) }
        
        for reg in justleftRegions {
            assert(reg.state == .playing)
            self.audiomanager?.stopLinkedSoundFile(slot: (reg.assignedSlot ?? -1)) // if slot is -1, something went wrong
        }
        
    }
}

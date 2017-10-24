//
//  PickupVC.swift
//  htchhkr
//
//  Created by Andrew Greenough on 29/09/2017.
//  Copyright © 2017 Andrew Greenough. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class PickupVC: UIViewController {
    
    // Outlets
    @IBOutlet weak var pickupMapView: RoundMapView!
    
    // Variables
    let regionRadius: CLLocationDistance = 2000
    var pin: MKPlacemark? = nil
    var pickupCoordinate: CLLocationCoordinate2D!
    var currentUserId = Auth.auth().currentUser?.uid
    var passengerKey: String!
    var locationPlacemark: MKPlacemark!

    override func viewDidLoad() {
        super.viewDidLoad()
        pickupMapView.delegate = self
        
        locationPlacemark = MKPlacemark(coordinate: pickupCoordinate)
        dropPinFor(placemark: locationPlacemark)
        centerMapOnLocation(location: locationPlacemark.location!)
        
        DataService.instance.REF_TRIPS.child(passengerKey).observe(.value, with: { (tripSnapshot) in
            if tripSnapshot.exists() {
                if tripSnapshot.childSnapshot(forPath: TRIP_IS_ACCEPTED).value as? Bool == true {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String) {
        self.pickupCoordinate = coordinate
        self.passengerKey = passengerKey
    }

    @IBAction func acceptTripBtnWasPressed(_ sender: Any) {
        UpdateService.instance.acceptTrip(withPassengerKey: passengerKey, forDriverKey: currentUserId!)
        presentingViewController?.shouldPresentLoadingView(true)
    }
    
    @IBAction func cancelBtnWasPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
extension PickupVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = ANNO_DESTINATION_IDENTIFIER
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: ANNO_DESTINATION)
        return annotationView
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        pickupMapView.setRegion(coordinateRegion, animated: true)
    }
    
    func dropPinFor(placemark: MKPlacemark) {
        pin = placemark
        pickupMapView.removeAnnotations(pickupMapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        pickupMapView.addAnnotation(annotation)
    }
}

//
//  UpdateService.swift
//  htchhkr
//
//  Created by Andrew Greenough on 26/09/2017.
//  Copyright © 2017 Andrew Greenough. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class UpdateService {
    
    static let instance = UpdateService()
    
    func updateUserLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == Auth.auth().currentUser?.uid {
                        DataService.instance.REF_USERS.child(user.key).updateChildValues([COORDINATE : [coordinate.latitude, coordinate.longitude]])
                    }
                }
            }
        })
    }
    
    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.key == Auth.auth().currentUser?.uid {
                        if driver.childSnapshot(forPath: ACCOUNT_PICKUP_MODE_ENABLED).value as? Bool == true {
                            DataService.instance.REF_DRIVERS.child(driver.key).updateChildValues([COORDINATE : [coordinate.latitude, coordinate.longitude]])
                        }
                    }
                }
            }
        })
    }
    
    func observeTrips(handler: @escaping(_ coordinateDict: [String : Any]?) -> Void) {
        DataService.instance.REF_TRIPS.observe(.value, with: { (snapshot) in
            if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for trip in tripSnapshot {
                    if trip.hasChild(USER_PASSENGER_KEY) && trip.hasChild(TRIP_IS_ACCEPTED) {
                        if let tripDict = trip.value as? [String : Any] {
                            handler(tripDict)
                        }
                    }
                }
            }
        })
    }
    
    func updateTripsWithCoordinatesUponRequest() {
        let currentUserId = Auth.auth().currentUser?.uid
        DataService.instance.REF_USERS.child(currentUserId!).observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.hasChild(USER_IS_DRIVER) {
                if let userDict = snapshot.value as? [String : Any] {
                    let pickupArray = userDict[COORDINATE] as! NSArray
                    let destinationArray = userDict[TRIP_COORDINATE] as! NSArray
                    
                    DataService.instance.REF_TRIPS.child(currentUserId!).updateChildValues([USER_PICKUP_COORDINATE : [pickupArray.firstObject, pickupArray.lastObject], USER_DESTINATION_COORDINATE : [destinationArray.firstObject, destinationArray.lastObject], USER_PASSENGER_KEY : currentUserId!, TRIP_IS_ACCEPTED : false])
                }
            }
        })
    }
    
    func acceptTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String) {
        DataService.instance.REF_TRIPS.child(passengerKey).updateChildValues([DRIVER_KEY : driverKey, TRIP_IS_ACCEPTED : true])
        DataService.instance.REF_DRIVERS.child(driverKey).updateChildValues([DRIVER_IS_ON_TRIP : true])
    }
    
    func cancelTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String?) {
        DataService.instance.REF_TRIPS.child(passengerKey).removeValue()
        DataService.instance.REF_USERS.child(passengerKey).child(TRIP_COORDINATE).removeValue()
        if driverKey != nil {
            DataService.instance.REF_DRIVERS.child(driverKey!).updateChildValues([DRIVER_IS_ON_TRIP : false])
        }
    }
}

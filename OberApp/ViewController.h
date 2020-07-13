//
//  ViewController.h
//  OberApp
//
//  Created by Felipe Amorim Bastos on 20/06/20.
//  Copyright © 2020 Felipe Amorim Bastos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet MKMapView* mapView;
@property (nonatomic, weak) IBOutlet UITextField* txtAddress;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* constraintBottomTxt;

@end


//
//  ViewController.m
//  OberApp
//
//  Created by Felipe Amorim Bastos on 20/06/20.
//  Copyright © 2020 Felipe Amorim Bastos. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    
    CLLocationManager* locationManager;
    CLLocationCoordinate2D currentCoordinate;
    
    int* stepCounter;
    MKRouteStep* steps;
    MKRoute* mainRoute;
}
@end

@implementation ViewController 

//---------------------------------------------------------------------------------------------
//  UIViewController Delegate
//---------------------------------------------------------------------------------------------

#pragma mark - UIViewController Delegate

- (void)viewDidLoad{
    [super viewDidLoad];
    
    locationManager = [[CLLocationManager alloc] init];
    
    [self configureLocationServices];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.txtAddress.keyboardAppearance = UIKeyboardAppearanceDark;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
}

//---------------------------------------------------------------------------------------------
//  MapKit Delegate
//---------------------------------------------------------------------------------------------

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    CLLocation *latestLocation = [locations firstObject];
    
//    if (currentCoordinate == nil) {
//        [self zoomToLatestLocation:latestLocation.coordinate];
//    }
    
    currentCoordinate = [latestLocation coordinate];
    
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [self beginLocationUpdates:manager];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    renderer.strokeColor = [UIColor redColor];
    
    return renderer;
}


//---------------------------------------------------------------------------------------------
//  Custom Methods
//---------------------------------------------------------------------------------------------

- (IBAction)sendCoordinates:(id)sender {
    
    [self getCoordinate:self.txtAddress.text :^(CLLocationCoordinate2D location, NSError *error) {
        
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
        }else{
            
            //Add Pin to Screen
            
            CLLocationCoordinate2D finalLocation = CLLocationCoordinate2DMake(location.latitude, location.longitude);
            
            MKPointAnnotation *annotation;
            annotation.coordinate = finalLocation;
            annotation.title = self.txtAddress.text;
            
            [self.mapView addAnnotation:annotation];
            [self.view endEditing:true];
            
            MKCoordinateRegion zoomRegion;
            zoomRegion = MKCoordinateRegionMake(finalLocation, MKCoordinateSpanMake(100, 100));
            [self.mapView setRegion:zoomRegion];
            
            // Remove Previous Route
            
            [self.mapView removeOverlays:[self.mapView overlays]];
            
            //Trace Route
            
            CLLocationCoordinate2D sourceLocation = [[self->locationManager location] coordinate];
            
            MKPlacemark *sourcePlacemark = [[MKPlacemark alloc] initWithCoordinate:sourceLocation];
            MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:finalLocation];
            
            MKMapItem *sourceItem = [[MKMapItem alloc] initWithPlacemark:sourcePlacemark];
            MKMapItem *destinationItem = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];
            
            MKDirectionsRequest *routeRequest;
            routeRequest = [[MKDirectionsRequest alloc] init];
            routeRequest.source = sourceItem;
            routeRequest.destination = destinationItem;
            routeRequest.transportType = MKDirectionsTransportTypeAutomobile;

            MKDirections *directions = [[MKDirections alloc] initWithRequest:routeRequest];

            [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {

                if (error != nil) {
                    return;
                }

                if (response != nil) {

                    MKRoute *route = [[response routes] firstObject];

                    self->mainRoute = route;
                    [self.mapView addOverlay:route.polyline];
                    [self.mapView setVisibleMapRect:route.polyline.boundingMapRect edgePadding:UIEdgeInsetsMake(16, 16, 16, 16) animated:true];
                }

            }];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) getCoordinate:(NSString*)addressString : (nullable void (^)(CLLocationCoordinate2D location, NSError *error))completionHandler {

    CLGeocoder *geocoder;
    geocoder = [[CLGeocoder alloc] init];

    [geocoder geocodeAddressString:addressString completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {

        if (error == nil) {

            if ([placemarks firstObject] != nil) {

                CLLocation *location;

                location = [[placemarks firstObject] location];

                completionHandler(location.coordinate, nil);
            }else{
                completionHandler(kCLLocationCoordinate2DInvalid, error);
            }
        }
    }];
}

- (void) configureLocationServices {
    
    locationManager.delegate = self;
    
    if ([CLLocationManager locationServicesEnabled]) {
        [self beginLocationUpdates:locationManager];
    }else{
        [locationManager requestAlwaysAuthorization];
    }
}

- (void)zoomToLatestLocation:(CLLocationCoordinate2D)coordinate {
     
    MKCoordinateRegion zoomRegion = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
    [self.mapView setRegion:zoomRegion];
}

- (void) beginLocationUpdates:(CLLocationManager*)locationManager {
    
    [self.mapView showsUserLocation];
    
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    [locationManager startUpdatingLocation];
}


//---------------------------------------------------------------------------------------------
//  Config Keyboard
//---------------------------------------------------------------------------------------------

- (void)keyboardWillChange:(NSNotification *)notification {
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil]; //this is it!
    float keyboardHeight = keyboardRect.size.height;
    
    self.constraintBottomTxt.constant = keyboardHeight;
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void)keyboardWillHide: (NSNotification *)notification {
    
    self.constraintBottomTxt.constant = 0;
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}

@end

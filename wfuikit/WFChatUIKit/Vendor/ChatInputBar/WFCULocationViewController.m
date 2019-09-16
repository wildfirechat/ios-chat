//
//  LocationViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//


#import "WFCULocationViewController.h"
#import "UIView+Toast.h"
#import "WFCULocationPoint.h"
#import <AddressBookUI/AddressBookUI.h>
#import <CoreLocation/CoreLocation.h>
#import "UIView+Screenshot.h"

@interface WFCULocationViewController () <CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UIBarButtonItem *sendButton;
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) WFCULocationPoint *locationPoint;
@property(nonatomic, strong) CLGeocoder * geoCoder;
@property(nonatomic, strong) CALayer *annotationLayer;
@property(nonatomic, assign) BOOL updateUserLocation;


@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) UITableView *locationTableView;
@property(nonatomic, strong) NSMutableArray<CLPlacemark *> *marks;
@property(nonatomic, weak) id<LocationViewControllerDelegate> delegate;
@end

@implementation WFCULocationViewController
- (instancetype)initWithDelegate:(id<LocationViewControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _geoCoder = [[CLGeocoder alloc] init];
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithLocationPoint:(WFCULocationPoint *)locationPoint{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _locationPoint = locationPoint;
        _geoCoder = [[CLGeocoder alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"位置";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    
    
    if (_locationManager) {
        CGRect frame = self.view.bounds;
        frame.size.height /= 2;
        self.mapView = [[MKMapView alloc] initWithFrame:frame];
        frame.origin.y += frame.size.height;
        
        self.locationTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        [self.view addSubview:self.locationTableView];
        self.locationTableView.delegate = self;
        self.locationTableView.dataSource = self;
        
        self.mapView.showsUserLocation = YES;
        self.annotationLayer = [CALayer layer];
        UIImage *image = [UIImage imageNamed:@"PinGreen"];
        self.annotationLayer.contents = (id)image.CGImage;
        self.annotationLayer.frame = CGRectMake(0, 0, 35, 35);
        self.annotationLayer.anchorPoint = CGPointMake(0.25f, 0.f);
        self.annotationLayer.position = CGPointMake(CGRectGetMidX(self.mapView.bounds), CGRectGetMidY(self.mapView.bounds));
        
        [self setUpRightNavButton];
        self.locationPoint   = [[WFCULocationPoint alloc] init];
        self.locationManager = [CLLocationManager new];
        [self.locationManager requestWhenInUseAuthorization];
        self.locationManager.delegate = self;
        if ([CLLocationManager locationServicesEnabled]) {
            [_locationManager requestLocation];
            CLAuthorizationStatus status = CLLocationManager.authorizationStatus;
            if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
                [self.view makeToast:@"请在设置-隐私里允许程序使用地理位置服务"
                            duration:2
                            position:CSToastPositionCenter];
            }else{
                self.mapView.showsUserLocation = YES;
            }
        }else{
            [self.view makeToast:@"请打开地理位置服务"
                        duration:2
                        position:CSToastPositionCenter];
        }
    } else /*if (self.locationPoint)*/ {
        self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
        MKCoordinateRegion theRegion;
        theRegion.center = self.locationPoint.coordinate;
        theRegion.span.longitudeDelta    = 0.01f;
        theRegion.span.latitudeDelta    = 0.01f;
        [self.mapView addAnnotation:self.locationPoint];
        [self.mapView setRegion:theRegion animated:YES];
    }
    
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    if (locations.count) {
        [self reverseGeoLocation:locations[0].coordinate];
    }
}

- (void)setUpRightNavButton{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"选定" style:UIBarButtonItemStyleDone target:self action:@selector(onSend:)];
    self.navigationItem.rightBarButtonItem = item;
    self.sendButton = item;
    self.sendButton.enabled = NO;
}

- (void)onSend:(id)sender{
    if ([self.delegate respondsToSelector:@selector(onSendLocation:)]) {
        
        UIView * view = [self.mapView viewForAnnotation:self.mapView.userLocation];
        view.hidden = YES;
        
        CGRect frame = self.mapView.frame;
        UIImage *thumbnail = [self.mapView screenshotWithRect:CGRectMake(0, (frame.size.height - frame.size.width * 2 / 3.f)/2, frame.size.width, frame.size.width * 2 / 3.f)];
        self.locationPoint.thumbnail = thumbnail;
        [self.delegate onSendLocation:self.locationPoint];
        
    }
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (!_updateUserLocation) {
        return;
    }
    CLLocationCoordinate2D centerCoordinate = mapView.region.center;
    [self reverseGeoLocation:centerCoordinate];
    [self.annotationLayer removeFromSuperlayer];
}



- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    if (!_updateUserLocation) {
        return;
    }
    [_mapView removeAnnotations:_mapView.annotations];
    [self.mapView.layer addSublayer:self.annotationLayer];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    if (annotation == self.mapView.userLocation) {
        return nil;
    }
    
    if (_locationManager) {
        static NSString *reusePin = @"reusePin";
        MKPinAnnotationView * pin = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:reusePin];
        if (!pin) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reusePin];
        }
        
        pin.draggable = YES;
        pin.canShowCallout  = YES;
        return pin;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    _updateUserLocation = YES;
    MKCoordinateRegion theRegion;
    theRegion.center = userLocation.coordinate;
    theRegion.span.longitudeDelta    = 0.01f;
    theRegion.span.latitudeDelta    = 0.01f;
    [_mapView setRegion:theRegion animated:NO];
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views{
    [_mapView selectAnnotation:self.locationPoint animated:YES];
}


- (void)reverseGeoLocation:(CLLocationCoordinate2D)locationCoordinate2D{
    if (self.geoCoder.isGeocoding) {
        [self.geoCoder cancelGeocode];
    }
    
    CLLocation *location = [[CLLocation alloc]initWithLatitude:locationCoordinate2D.latitude
                                                     longitude:locationCoordinate2D.longitude];
    
    __weak typeof(self) ws = self;
    self.sendButton.enabled = NO;
    [self.geoCoder reverseGeocodeLocation:location
                        completionHandler:^(NSArray *placemarks, NSError *error) {
         if (!error) {
             CLPlacemark *mark = [placemarks firstObject];
             ws.marks = [placemarks mutableCopy];
             NSArray *lines = mark.addressDictionary[@"FormattedAddressLines"];
             NSString *title = [lines componentsJoinedByString:@"\n"];
            
             WFCULocationPoint *ponit = [[WFCULocationPoint alloc] initWithCoordinate:locationCoordinate2D andTitle:nil];
             [ws.mapView addAnnotation:ponit];
             ws.locationPoint = [[WFCULocationPoint alloc] initWithCoordinate:locationCoordinate2D andTitle:title];;
             ws.sendButton.enabled = YES;
             ws.title = title;
             [ws.locationTableView reloadData];
         } else {
             ws.locationPoint = nil;
             ws.sendButton.enabled = NO;
             ws.title = @"位置";
         }
     }];
}

- (void)dismiss:(id)sender {
    if (self.navigationController.presentingViewController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.marks.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    NSArray *lines = self.marks[indexPath.row].addressDictionary[@"FormattedAddressLines"];
    NSString *title = [lines componentsJoinedByString:@"\n"];
    cell.textLabel.text = title;
    if (cell.selected) {
        cell.imageView.image = [UIImage imageNamed:@"multi_selected"];
    } else {
        cell.imageView.image = nil;
    }
    return cell;
}

-(void)dealloc {
    [self.locationManager stopUpdatingLocation];
    [self.geoCoder cancelGeocode];
}


@end


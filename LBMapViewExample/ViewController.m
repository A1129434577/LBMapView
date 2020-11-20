//
//  ViewController.m
//  LBMapViewExample
//
//  Created by 刘彬 on 2020/11/20.
//

#import "ViewController.h"
#import "LBMapView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    LBAnnotation *annotation = [[LBAnnotation alloc] init];
    annotation.canShowCallout = YES;
    annotation.title = @"成都";
    annotation.coordinate = CLLocationCoordinate2DMake(30.67, 104.06);
    annotation.selected = YES;
    
    LBMapView *mapView = [[LBMapView alloc] initWithFrame:self.view.bounds];
    mapView.annotationImage = [UIImage imageNamed:@"location_green"];
    mapView.annotation = annotation;
    mapView.statusChanged = ^(LBMapViewStatus state, LBAnnotation * _Nonnull annotation) {
        
    };
    [self.view addSubview:mapView];
}


@end

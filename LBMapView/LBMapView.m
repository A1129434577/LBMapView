//
//  LBMapView.m
//
//  Created by 刘彬 on 2018/12/7.
//  Copyright © 2018 刘彬. All rights reserved.
//

#import "LBMapView.h"
@interface LBMapView()<MKMapViewDelegate>
@property (nonatomic, weak)id<MKMapViewDelegate> realProxy;//真实代理（LBMapView本身作为消息转发虚拟代理）
@property (nonatomic, strong) MKAnnotationView *fixedAnnotationView;
@end

@implementation LBMapView
- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsUserLocation = YES;
        self.delegate = self;
        
        self.canShowCallout = YES;
        self.selectUserLocation = YES;
        self.state = LBMapViewLocatingUser;
        self.style = LBMapStyleMarkPointMoveFollowMap;
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    if (self.fixedAnnotationView) {
        self.fixedAnnotationView.center = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/2);
    }
}

#pragma mark setter
-(void)setDelegate:(id<UITextFieldDelegate>)delegate{
    self.realProxy = delegate;
    [super setDelegate:self];
}
-(void)setState:(LBMapViewStatus)state{
    _state = state;
    
    __weak typeof(self) weakSelf = self;
    self.statusChanged?
    self.statusChanged(state,weakSelf.annotation):NULL;
}


- (void)setAnnotation:(LBAnnotation *)annotation{
    _annotation = annotation;
    if (annotation) {
        self.state = LBMapViewDidUpdateUserLocation;
        
        if (annotation.image == nil) {
            annotation.image = self.annotationImage;
        }
        //设置地图区域
        if (CLLocationCoordinate2DIsValid(annotation.coordinate)) {
            MKCoordinateSpan span = MKCoordinateSpanMake(0.021251, 0.016093);
            [self setRegion:MKCoordinateRegionMake(annotation.coordinate, span) animated:YES];
        }
        
        switch (self.style) {
            case LBMapStyleMarkPointFixedCenter:
                if (self.fixedAnnotationView == nil) {
                    MKAnnotationView *fixedAnnotationView = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:nil];
                    fixedAnnotationView.center = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/2);
                    fixedAnnotationView.canShowCallout = annotation.canShowCallout;//显示气泡视图
                    fixedAnnotationView.image = annotation.image;
                    
                    [self addSubview:fixedAnnotationView];
                    self.fixedAnnotationView = fixedAnnotationView;
                }
                else{
                    self.fixedAnnotationView.annotation = annotation;
                }
                break;
            case LBMapStyleMarkPointMoveFollowMap:
            case LBMapStyleMultipoint:
            {
                if (self.style != LBMapStyleMultipoint) {
                    [self removeAnnotations:self.annotations];
                }
                [self showAnnotations:@[annotation] animated:YES];
                
                
                if (annotation.title && annotation.subtitle) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self selectAnnotation:self.annotation animated:YES];
                    });
                }else{
                    CLLocation *location = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
                    [self reverseGeocodeLocation:location];
                }
            }
                break;
            default:
                break;
        }
    }else{
        self.state = LBMapViewDidFailToLocateUser;
        
        if (self.style != LBMapStyleMultipoint) {
            [self removeAnnotations:self.annotations];
        }
    }
    
    
}


#pragma mark MKMapViewDelegate
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{    
    if (self.annotation == nil) {//定位到了用户地址，如果当前地图未标记点，使用用户位置作为当前点
        LBAnnotation *annotation = [[LBAnnotation alloc] init];
        annotation.coordinate = userLocation.location.coordinate;
        annotation.canShowCallout = self.canShowCallout;
        annotation.selected = self.selectUserLocation;
        self.annotation = annotation;
    }
    
    if ([self.realProxy respondsToSelector:@selector(mapView:didUpdateUserLocation:)]) {
        [self.realProxy mapView:mapView didUpdateUserLocation:userLocation];
    }
}
- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error{
    self.state = LBMapViewDidFailToLocateUser;
    
    if ([self.realProxy respondsToSelector:@selector(mapView:didFailToLocateUserWithError:)]) {
        [self.realProxy mapView:mapView didFailToLocateUserWithError:error];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (self.style == LBMapStyleMarkPointFixedCenter) {
        CLLocationCoordinate2D centerCoordinate = [self convertPoint:CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/2) toCoordinateFromView:self];
        CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
        [self reverseGeocodeLocation:centerLocation];
        
    }
    
    if ([self.realProxy respondsToSelector:@selector(mapView:regionDidChangeAnimated:)]) {
        [self.realProxy mapView:mapView regionDidChangeAnimated:animated];
    }
}
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(LBAnnotation *)annotation
{
    if ([self.realProxy respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        return [self.realProxy mapView:mapView viewForAnnotation:annotation];
    }
    
    NSString *identifier = NSStringFromClass(self.class);
    MKAnnotationView *newAnnotation = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!newAnnotation && [annotation isKindOfClass:LBAnnotation.class]) {
        newAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        
        newAnnotation.canShowCallout = annotation.canShowCallout;//显示气泡视图
        newAnnotation.image = annotation.image;
    }
    return newAnnotation;
}

#pragma mark 检索位置
-(void)reverseGeocodeLocation:(CLLocation *)location{
    //开始检索定位到的地址
    self.state = LBMapViewGeocoding;
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks,NSError *error){
        if (error) {
            self.annotation.coordinate = location.coordinate;
        }else{
            CLPlacemark *placemark = placemarks.firstObject;
            self.annotation.coordinate = placemark.location.coordinate;
            self.annotation.placemark = placemark;
            if (self.annotation.title == nil) {
                self.annotation.title = placemark.name;
            }
            if (self.annotation.subtitle == nil){
                self.annotation.subtitle = [NSString stringWithFormat:@"%@%@%@%@%@",placemark.administrativeArea?placemark.administrativeArea:@"",placemark.locality?placemark.locality:@"",placemark.subLocality?placemark.subLocality:@"",placemark.thoroughfare?placemark.thoroughfare:@"",placemark.subThoroughfare?placemark.subThoroughfare:@""];
            }
            
            if (self.annotation.selected) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self.fixedAnnotationView) {
                        [self.fixedAnnotationView setSelected:YES animated:YES];
                    }else{
                        [self selectAnnotation:self.annotation animated:YES];
                    }
                });
            }
        }
        self.state = LBMapViewGeocoded;
    }];
}
#pragma mark 导航方法
+(NSArray<NSDictionary *> *)getInstalledMapApps{
    NSMutableArray *maps = [NSMutableArray array];
    
    //苹果地图
    NSMutableDictionary *iosMapDic = [NSMutableDictionary dictionary];
    iosMapDic[@"title"] = @"Apple地图";
    [maps addObject:iosMapDic];
    
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
        baiduMapDic[@"title"] = @"百度地图";
        baiduMapDic[@"url"] = @"baidumap://";
        [maps addObject:baiduMapDic];
    }
    
    //高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        NSMutableDictionary *gaodeMapDic = [NSMutableDictionary dictionary];
        gaodeMapDic[@"title"] = @"高德地图";
        gaodeMapDic[@"url"] = @"iosamap://";
        [maps addObject:gaodeMapDic];
    }
    
    //谷歌地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        NSMutableDictionary *googleMapDic = [NSMutableDictionary dictionary];
        googleMapDic[@"title"] = @"谷歌地图";
        googleMapDic[@"url"] = @"comgooglemaps://";
        [maps addObject:googleMapDic];
    }
    
    //腾讯地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"qqmap://"]]) {
        NSMutableDictionary *qqMapDic = [NSMutableDictionary dictionary];
        qqMapDic[@"title"] = @"腾讯地图";
        qqMapDic[@"url"] = @"qqmap://";
        [maps addObject:qqMapDic];
    }
    
    return maps;
}
#pragma mark 搜索位置
+ (void)searchLocationWithText:(NSString *)text
                      inRegion:(MKCoordinateRegion)region
                       success:(void (^)(NSArray<LBAnnotation *> * _Nonnull))success
                       failure:(void (^)(NSError * _Nonnull))failure{
    MKLocalSearchRequest *localSearchRequest = [[MKLocalSearchRequest alloc] init] ;
    if (CLLocationCoordinate2DIsValid(region.center)) {
        //设置搜索范围
        localSearchRequest.region = region;
    }
    
    localSearchRequest.naturalLanguageQuery = text;//搜索关键词
    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:localSearchRequest];
    
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        if (error)
        {
            failure?
            failure(error):NULL;
        }
        else
        {
            NSMutableArray<LBAnnotation *> *annotations = [[NSMutableArray alloc] init];
            [response.mapItems enumerateObjectsUsingBlock:^(MKMapItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                MKPlacemark *placemark = obj.placemark;
                LBAnnotation *annotation = [[LBAnnotation alloc] init];
                annotation.canShowCallout = YES;
                annotation.selected = YES;
                annotation.placemark = placemark;
                annotation.coordinate = placemark.coordinate;
                annotation.title = placemark.name;
                annotation.subtitle = [NSString stringWithFormat:@"%@%@%@%@%@",placemark.administrativeArea?placemark.administrativeArea:@"",placemark.locality?placemark.locality:@"",placemark.subLocality?placemark.subLocality:@"",placemark.thoroughfare?placemark.thoroughfare:@"",placemark.subThoroughfare?placemark.subThoroughfare:@""];
                [annotations addObject:annotation];
            }];
            success?success(annotations):NULL;
            
        }
    }];
}

#pragma mark 如果本类没实现的代理方法由realProxy实现
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (![self respondsToSelector:aSelector] && [self.realProxy respondsToSelector:aSelector]) {
        return self.realProxy;
    }
    return [super forwardingTargetForSelector: aSelector];
}
@end
@implementation LBAnnotation
@end


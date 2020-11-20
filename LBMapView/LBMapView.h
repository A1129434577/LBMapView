//
//  LBMapView.h
//
//  Created by 刘彬 on 2018/12/7.
//  Copyright © 2018 刘彬. All rights reserved.
//

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LBAnnotation : NSObject <MKAnnotation>
@property (nonatomic, assign) BOOL canShowCallout;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *subtitle;
@property (nonatomic,strong)CLPlacemark *placemark;
@end

typedef NS_ENUM(NSUInteger, LBMapViewStyle) {
    LBMapStyleMarkPointFixedCenter  = 0,//标记点固定在中心位置，不随地图移动
    LBMapStyleMarkPointMoveFollowMap,//标记点在中心位置跟随地图移动
    LBMapStyleMultipoint,//多点标记
};

typedef NS_ENUM(NSUInteger, LBMapViewStatus) {
    LBMapViewLocatingUser = 0,//正在定位
    LBMapViewDidUpdateUserLocation,//定位完成
    LBMapViewDidFailToLocateUser,//定位失败
    LBMapViewGeocoding,//正在检索
    LBMapViewGeocoded,//检索完成
};

@interface LBMapView : MKMapView
@property (nonatomic, assign) LBMapViewStyle style;
@property (nonatomic, strong) UIImage *annotationImage;
@property (nonatomic, assign) BOOL canShowCallout;
@property (nonatomic, assign) BOOL selectUserLocation;
@property (nonatomic, strong, nullable) LBAnnotation *annotation;//当前标记的点
@property (nonatomic, assign, readonly)LBMapViewStatus state;
@property (nonatomic, strong) void(^statusChanged)(LBMapViewStatus state,LBAnnotation *annotation);

/// 获取手机安装的地图APP
+(NSArray<NSDictionary *> *)getInstalledMapApps;

/// 根据文字检索地址信息
/// @param text 地理名
/// @param region 检索区域
/// @param success 成功
/// @param failure 失败
+(void)searchLocationWithText:(NSString *)text
                     inRegion:(MKCoordinateRegion)region
                      success:(void (^ _Nullable)(NSArray<LBAnnotation *> * _Nonnull annotations))success
                      failure:(void (^ _Nullable)(NSError * _Nonnull error))failure;//检索地址
@end





NS_ASSUME_NONNULL_END

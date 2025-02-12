//
//  AMapLocation.h
//  amap_map
//
//  Created by lly on 2020/11/12.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AMapLocationKit/AMapLocationKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMapLocation : NSObject

@property (nonatomic, assign) CLLocationCoordinate2D latLng;
@property (nonatomic, assign) double accuracy;
@property (nonatomic, assign) double altitude;
@property (nonatomic, assign) double bearing;
@property (nonatomic, assign) double speed;
@property (nonatomic, assign) NSTimeInterval time;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *citycode;
@property (nonatomic, copy) NSString *adcode;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *province;
@property (nonatomic, copy) NSString *district;
@property (nonatomic, copy) NSString *road;
@property (nonatomic, copy) NSString *street;
@property (nonatomic, copy) NSString *number;
@property (nonatomic, copy) NSString *poiname;
@property (nonatomic, assign) int errorCode;
@property (nonatomic, copy) NSString *errorInfo;
@property (nonatomic, assign) int locationType;
@property (nonatomic, copy) NSString *locationDetail;
@property (nonatomic, copy) NSString *aoiname;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *poiid;
@property (nonatomic, copy) NSString *floor;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *provider; // 添加 provider 属性

- (void)updateWithUserLocation:(CLLocation *)location;
- (void)updateWithReGeocode:(AMapLocationReGeocode *)regeocode;

@end

NS_ASSUME_NONNULL_END
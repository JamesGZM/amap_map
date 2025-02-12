#import "AMapLocation.h"

@implementation AMapLocation

- (instancetype)init {
    self = [super init];
    if (self) {
        self.provider = @"iOS";
    }
    return self;
}

- (void)updateWithUserLocation:(CLLocation *)location {
    if (location == nil) {
        return;
    }
    self.latLng = location.coordinate;
    self.accuracy = location.horizontalAccuracy;
    self.altitude = location.altitude;
    self.bearing = location.course;
    self.speed = location.speed;
    self.time = [location.timestamp timeIntervalSince1970]*1000;
}

- (void)updateWithReGeocode:(AMapLocationReGeocode *)regeocode {
    if (regeocode == nil) {
        return;
    }
    self.city = regeocode.city;
    self.citycode = regeocode.citycode;
    self.adcode = regeocode.adcode;
    self.country = regeocode.country;
    self.province = regeocode.province;
    self.district = regeocode.district;
    self.road = regeocode.street;
    self.street = regeocode.street;
    self.number = regeocode.number;
    self.poiname = regeocode.POIName;
    self.aoiname = regeocode.AOIName;
    self.address = regeocode.formattedAddress;
    self.desc = regeocode.description;
}

@end

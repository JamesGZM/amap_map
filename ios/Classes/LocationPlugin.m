#import "LocationPlugin.h"
#import "AMapLocation.h"
#import "AMapJsonUtils.h"
#import "AMapConvertUtil.h"

@interface LocationPlugin ()
@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, assign) BOOL isRequestingReGeocode;
@end

@implementation LocationPlugin {
    NSObject<FlutterPluginRegistrar>* _registrar;
    NSMutableDictionary* _mapControllers;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    NSLog(@"Registering LocationPlugin with registrar: %@", registrar);
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"amap_location_plugin"
                                     binaryMessenger:[registrar messenger]];
    LocationPlugin* instance = [[LocationPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化时不创建 locationManager
        self.locationManager = nil;
        self.isRequestingReGeocode = NO;
    }
    return self;
}

- (void)initializeLocationManagerIfNeeded {
    if (!self.locationManager) {
        self.locationManager = [[AMapLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
        [self.locationManager setLocationTimeout:10];
        [self.locationManager setReGeocodeTimeout:5];
        NSLog(@"AMapLocationManager initialized.");
    }
}

- (void)init:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *apiKey = call.arguments;
    NSString *iosKey = apiKey[@"iosKey"];
    if (iosKey && iosKey.length > 0) {
        [AMapServices sharedServices].apiKey = iosKey;
        NSLog(@"AMap API Key initialized: %@", iosKey);
        result(nil);
    } else {
        result([FlutterError errorWithCode:@"API_KEY_ERROR"
                                   message:@"API Key is missing or invalid"
                                   details:nil]);
    }
}

- (void)updatePrivacyAgree:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *privacyStatement = call.arguments;
    if (privacyStatement[@"hasContains"] != nil && privacyStatement[@"hasShow"] != nil) {
        [MAMapView updatePrivacyShow:[privacyStatement[@"hasShow"] integerValue] privacyInfo:[privacyStatement[@"hasContains"] integerValue]];
    }
    if (privacyStatement[@"hasAgree"] != nil) {
        [MAMapView updatePrivacyAgree:[privacyStatement[@"hasAgree"] integerValue]];
    }
    NSLog(@"Privacy agreement updated: %@", privacyStatement);
    result(nil);
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    [self initializeLocationManagerIfNeeded];
    
    if ([@"init" isEqualToString:call.method]) {
        [self init:call result:result];
    } else if ([@"updatePrivacyAgree" isEqualToString:call.method]) {
        [self updatePrivacyAgree:call result:result];
    } else if ([@"startListening" isEqualToString:call.method]) {
        // 先停止定位
        [self.locationManager stopUpdatingLocation];
        
        // 然后开始定位
        [self.locationManager startUpdatingLocation];
        result(nil);
    } else if ([@"stopListening" isEqualToString:call.method]) {
        [self.locationManager stopUpdatingLocation];
        result(nil);
    } else if ([@"getSingleLocation" isEqualToString:call.method]) {
        // 先停止定位
        [self.locationManager stopUpdatingLocation];
        
        // 然后请求单次定位并获取逆地理编码信息
        [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
            if (error) {
                result([FlutterError errorWithCode:@"LOCATION_ERROR"
                                           message:error.localizedDescription
                                           details:nil]);
            } else {
                AMapLocation *amapLocation = [[AMapLocation alloc] init];
                [amapLocation updateWithUserLocation:location];
                [amapLocation updateWithReGeocode:regeocode];
                NSDictionary *jsonObjc = [AMapJsonUtils jsonObjectFromModel:amapLocation];
                NSArray *latlng = [AMapConvertUtil jsonArrayFromCoordinate:amapLocation.latLng];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:jsonObjc];
                [dict setValue:latlng forKey:@"latLng"];
               
                // 添加打印日志
                NSLog(@"Location: %@", dict);

                result(@{@"location": dict});
            }
        }];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - AMapLocationManagerDelegate

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location {
    if (self.isRequestingReGeocode) {
        return;
    }
    
    self.isRequestingReGeocode = YES;
    
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        self.isRequestingReGeocode = NO;
        
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
            return;
        }
        
        AMapLocation *amapLocation = [[AMapLocation alloc] init];
        [amapLocation updateWithUserLocation:location];
        [amapLocation updateWithReGeocode:regeocode];
        NSDictionary *jsonObjc = [AMapJsonUtils jsonObjectFromModel:amapLocation];
        NSArray *latlng = [AMapConvertUtil jsonArrayFromCoordinate:amapLocation.latLng];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:jsonObjc];
        [dict setValue:latlng forKey:@"latLng"];
        [self.channel invokeMethod:@"onLocationChanged" arguments:@{@"location": dict}];
    }];
}

@end
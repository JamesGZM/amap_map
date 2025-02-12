part of '../amap_map.dart';

class LocationPlugin {
  static const MethodChannel _channel = MethodChannel('amap_location_plugin');
  static final StreamController<AMapLocation> _locationStreamController =
      StreamController.broadcast();

  static void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLocationChanged':
        _locationStreamController
            .add(AMapLocation.fromMap(call.arguments['location'])!);
        break;
      default:
        throw MissingPluginException('notImplemented');
    }
  }

  static Stream<AMapLocation> get locationStream =>
      _locationStreamController.stream;

  static Future<void> startListening() async {
    await _channel.invokeMethod('startListening');
  }

  static Future<void> stopListening() async {
    await _channel.invokeMethod('stopListening');
  }

  static Future<void> init(BuildContext context,
      {required AMapApiKey apiKey}) async {
    AMapInitializer.init(context, apiKey: apiKey);
    await _channel.invokeMethod('init', apiKey.toMap());
  }

  static Future<void> updatePrivacyAgree(AMapPrivacyStatement privacyStatement) async {
    AMapInitializer.updatePrivacyAgree(privacyStatement);
    await _channel.invokeMethod('updatePrivacyAgree', privacyStatement.toMap());
  }

  static Future<AMapLocation> getSingleLocation() async {
    final dynamic location = await _channel.invokeMethod('getSingleLocation');
    //print('getSingleLocation: $location');
    return AMapLocation.fromMap(location['location'])!;
  }
}

package com.amap.flutter.map;

import android.content.Context;

import androidx.annotation.NonNull;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;
import com.amap.flutter.map.utils.ConvertUtil;
import com.amap.flutter.map.utils.LogUtil;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import java.util.HashMap;
import java.util.Map;

public class LocationPlugin implements MethodChannel.MethodCallHandler, AMapLocationListener {

    private static final String CLASS_NAME = "LocationPlugin";

    private final Context context;
    private final MethodChannel methodChannel;
    private AMapLocationClient locationClient;
    // 是否开始定位
    private boolean isStartedLocation = false;
    // 是否单次定位
    private boolean isOnceLocation;
    private MethodChannel.Result getLocationResult;


    public LocationPlugin(Context context, MethodChannel methodChannel) {
        this.context = context;
        this.methodChannel = methodChannel;
        this.methodChannel.setMethodCallHandler(this);
    }

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "amap_location_plugin");
        channel.setMethodCallHandler(new LocationPlugin(registrar.context(), channel));

        LogUtil.i(CLASS_NAME, "registerWith=====>");
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "init":
                ConvertUtil.checkApiKey(call.arguments);
                result.success(null);
                break;
            case "updatePrivacyAgree":
                ConvertUtil.setPrivacyStatement(context, call.arguments);
                result.success(null);
                break;
            case "startListening":
                startListening();
                result.success(null);
                break;
            case "stopListening":
                stopLocation();
                result.success(null);
                break;
            case "getSingleLocation":
                getLocationResult = result;
                getSingleLocation();
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void startListening() {
        stopLocation();
        initLocationClient(false);
        if (locationClient != null) {
            locationClient.startLocation();
        }
        isStartedLocation = true;
    }

    private void initLocationClient(boolean isOnceLocation) {
        this.isOnceLocation = isOnceLocation;
        if (locationClient == null) {
            try {
                locationClient = new AMapLocationClient(context);
                locationClient.setLocationListener(this);
                AMapLocationClientOption locationOption = new AMapLocationClientOption();
                locationOption.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
                locationOption.setOnceLocation(isOnceLocation); // 设置为单次定位
                locationClient.setLocationOption(locationOption);
            } catch (Exception e) {
                LogUtil.e(CLASS_NAME, "initLocationClient===>", e);
            }
        }
    }

    private void stopLocation() {
        if (locationClient != null) {
            locationClient.stopLocation();
            locationClient.onDestroy();
            locationClient = null;
        }
        isStartedLocation = false;
    }

    private void getSingleLocation() {
        stopLocation();
        initLocationClient(true);

        if (locationClient != null) {
            locationClient.startLocation();
        }
        isStartedLocation = true;
    }

    @Override
    public void onLocationChanged(AMapLocation location) {
        if (location != null && location.getErrorCode() == 0) {
            final Map<String, Object> arguments = new HashMap<>(2);
            arguments.put("location", ConvertUtil.location2Map(location));
            if (isStartedLocation) {
                if (isOnceLocation) {
                    if (getLocationResult != null) {
                        getLocationResult.success(arguments);
                        getLocationResult = null;
                    }
                    stopLocation();
                } else {
                    methodChannel.invokeMethod("onLocationChanged", arguments);
                }
                LogUtil.i(CLASS_NAME, "onLocationChanged===>" + arguments);
            }
        } else {
            if (isOnceLocation) {
                if (location != null) {
                    if (getLocationResult != null) {
                        getLocationResult.error(String.valueOf(location.getErrorCode()), location.getErrorInfo(), null);
                        getLocationResult = null;
                    }
                } else {
                    if (getLocationResult != null) {
                        getLocationResult.error("0", "定位失败", null);
                        getLocationResult = null;
                    }
                }
                stopLocation();
            }
            LogUtil.i(CLASS_NAME, "onLocationChanged===>" + "定位失败");
        }
    }
}
import 'package:boats_mobile_app/api/get_weather.dart';
import 'package:boats_mobile_app/models/weather_data.dart';
import 'package:boats_mobile_app/utils/get_current_address.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class GlobalController extends GetxController {
  // reactive variables
  final RxBool _isLoading = true.obs;
  final RxDouble _latitude = 0.0.obs;
  final RxDouble _longitude = 0.0.obs;
  final RxString _currentLocation = ''.obs;

  final RxList<CameraDescription> cameras = RxList<CameraDescription>();

  final weatherData = WeatherData().obs;

  // instance for them to be called
  RxBool checkLoading() => _isLoading;
  RxDouble getLatitude() => _latitude;
  RxDouble getLongitude() => _longitude;
  RxString getCurrentLocation() => _currentLocation;
  RxList getCameraList() => cameras;

  WeatherData getWeatherData() {
    return weatherData.value;
  }

  @override
  void onInit() {
    if (_isLoading.isTrue) {
      getLocation();
    }
    getCamera();
    super.onInit();
  }

  getCamera() async {
    cameras.value = await availableCameras();
    print(cameras.toString());
  }

  getLocation() async {
    bool isServiceEnabled;
    LocationPermission locationPermission;

    isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return Future.error('Location Service is not enabled');
    }

    // status of permission
    locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.deniedForever) {
      return Future.error('Location Service is not allowed');
    } else if (locationPermission == LocationPermission.denied) {
      // request permission
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied) {
        return Future.error('Location permission is denied');
      }
    }

    // get current location
    await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation)
        .then(
      (value) {
        // update the current location
        _latitude.value = value.latitude;
        _longitude.value = value.longitude;

        getAddress(_latitude.value, _longitude.value).then((placemark) {
          if (placemark.subThoroughfare?.isEmpty &&
              placemark.thoroughfare?.isEmpty) {
            _currentLocation.value =
                '${placemark.locality}, ${placemark.administrativeArea}';
          } else if (placemark.thoroughfare?.isEmpty) {
            _currentLocation.value =
                '${placemark.locality}, ${placemark.administrativeArea}';
          } else {
            _currentLocation.value =
                '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.locality}, ${placemark.administrativeArea}';
          }
        });

        return GetWeatherApi()
            .processData(value.latitude, value.longitude)
            .then((value) {
          weatherData.value = value;
          _isLoading.value = false;
        });
      },
    );
  }
}

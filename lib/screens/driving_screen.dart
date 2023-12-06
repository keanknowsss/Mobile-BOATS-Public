import 'dart:async';

import 'package:boats_mobile_app/api/map_information.dart';
import 'package:boats_mobile_app/components/app_bar.dart';
import 'package:boats_mobile_app/components/side_bar.dart';
import 'package:boats_mobile_app/constants/api_key.dart';
import 'package:boats_mobile_app/controllers/global_controller.dart';
import 'package:boats_mobile_app/screens/detection_screen.dart';
import 'package:boats_mobile_app/screens/map_screen.dart';
import 'package:boats_mobile_app/utils/get_current_address.dart';
import 'package:camera/camera.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:boats_mobile_app/utils/remove_symbol.dart';

class DrivingScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;

  const DrivingScreen(
      {Key? key, required this.origin, required this.destination})
      : super(key: key);

  @override
  State<DrivingScreen> createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen> {
  final GlobalController globalController = Get.put(
    GlobalController(),
    permanent: true,
  );

  late LatLng currentLocation = LatLng(0, 0);
  late LatLng destinationLocation = LatLng(0, 0);
  late GoogleMapController? mapController;
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  double bearing = 0.0;
  Set<Marker> markers = {};
  bool isMoving = false;
  StreamSubscription<Position>? positionStreamSubscription;

  bool _showInformation = false;
  late String currentStreet = '';
  late CameraController controller;
  FlutterVision vision = FlutterVision();
  bool isDetecting = false;
  String objectLabel = '';
  Timer? detectionTimer;
  int _hazardCounter = 0;
  int _recordedHazard = 0;

  int _crackCounter = 0;
  int _recordedCrack = 0;

  int _potholeCounter = 0;
  int _recordedPothole = 0;

  int _manholeCounter = 0;
  int _recordedManhole = 0;

  int _metalPlateCounter = 0;
  int _recorededMetalPlate = 0;

  final database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    setPolylines();
    getUserLocation();
    loadModel().then((void v) {});
    initCamera();
    getData();
    setState(() {
      currentLocation = widget.origin;
      destinationLocation = widget.destination;
    });
  }

  Future<void> loadModel() async {
    await vision.loadYoloModel(
      modelPath: 'assets/ml/model_float32.tflite',
      labels: 'assets/ml/classes.txt',
      modelVersion: 'yolov8',
      numThreads: 1,
      useGpu: false,
    );
  }

  void initCamera() {
    controller = CameraController(
        globalController.getCameraList()[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});

      controller.startImageStream((CameraImage image) {
        if (!isDetecting) {
          isDetecting = true;
          _objectDetection(image);
          isDetecting = false;
        }
      });
    });
  }

  void _objectDetection(CameraImage cameraImage) async {
    final result = await vision.yoloOnFrame(
      bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      iouThreshold: 0.6,
      confThreshold: 0.6,
      classThreshold: 0.6,
    );

    if (result.isNotEmpty) {
      setState(() {
        objectLabel = result[0]['tag'];
      });
      print(result.toString());

      switch (result[0]['tag']) {
        case 'Dry Crack':
          _crackCounter++;
          break;
        case 'Dry Pothole':
        case 'Wet Pothole':
          _potholeCounter++;
          break;
        case 'Dry Manhole':
          _manholeCounter++;
          break;
        case 'Metal Plate':
          _metalPlateCounter++;
          break;
        default:
          break;
      }

      setState(() {
        _hazardCounter++;
      });
      writeData();

      // Reset the objectLabel after 5 seconds of no detection
      detectionTimer?.cancel();
      detectionTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          objectLabel = '';
        });
      });
    }
  }

  writeData() {
    getData();
    int totalHazards = _recordedCrack +
        _recordedManhole +
        _recordedPothole +
        _recorededMetalPlate +
        1;

    if (totalHazards > _recordedHazard) {
      database
          .child(removeSymbolsFromString(currentStreet))
          .child('hazardCount')
          .set(totalHazards);
    }

    if (_crackCounter > _recordedCrack) {
      database
          .child(removeSymbolsFromString(currentStreet))
          .child('crack')
          .set(_crackCounter);
    }
    if (_manholeCounter > _recordedManhole) {
      database
          .child(removeSymbolsFromString(currentStreet))
          .child('manhole')
          .set(_manholeCounter);
    }
    if (_potholeCounter > _recordedPothole) {
      database
          .child(removeSymbolsFromString(currentStreet))
          .child('pothole')
          .set(_potholeCounter);
    }
    if (_metalPlateCounter > _recorededMetalPlate) {
      database
          .child(removeSymbolsFromString(currentStreet))
          .child('metal_plate')
          .set(_metalPlateCounter);
    }
    getData();
  }

  void getData() {
    if (currentStreet.isNotEmpty) {
      database
          .child(removeSymbolsFromString(currentStreet))
          .once()
          .then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic,
              dynamic>?; // Explicitly cast to Map<dynamic, dynamic>?
          if (data != null && data.containsKey('hazardCount')) {
            int hazardCount =
                data['hazardCount'] as int; // Explicitly cast to int
            print('Hazard Count: $hazardCount');

            setState(() {
              _recordedHazard = hazardCount;
            });
          }
          if (data != null && data.containsKey('crack')) {
            int crack = data['crack'] as int; // Explicitly cast to int
            print('Crack Count: $crack');

            setState(() {
              _recordedCrack = crack;
            });
          }
          if (data != null && data.containsKey('pothole')) {
            int pothole = data['pothole'] as int; // Explicitly cast to int
            print('Pothole Count: $pothole');

            setState(() {
              _recordedPothole = pothole;
            });
          }
          if (data != null && data.containsKey('manhole')) {
            int manhole = data['manhole'] as int; // Explicitly cast to int
            print('Manhole Count: $manhole');

            setState(() {
              _recordedManhole = manhole;
            });
          }
          if (data != null && data.containsKey('metal_plate')) {
            int metalPlate =
                data['metal_plate'] as int; // Explicitly cast to int
            print('Manhole Count: $metalPlate');

            setState(() {
              _recorededMetalPlate = metalPlate;
            });
          }
        } else {
          database
              .child(removeSymbolsFromString(currentStreet))
              .child('hazardCount')
              .set(0);
          database
              .child(removeSymbolsFromString(currentStreet))
              .child('crack')
              .set(0);
          database
              .child(removeSymbolsFromString(currentStreet))
              .child('pothole')
              .set(0);
          database
              .child(removeSymbolsFromString(currentStreet))
              .child('manhole')
              .set(0);
          database
              .child(removeSymbolsFromString(currentStreet))
              .child('metal_plate')
              .set(0);
        }
      }).catchError((error) {
        print('Error: $error');
      });
    } else {
      return;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    detectionTimer?.cancel();
    positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideBar(),
      appBar: const BoatsAppBar(),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) =>
                mapController = controller,
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: 18,
              bearing: bearing,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(5, 25),
            markers: markers,
            polylines: Set<Polyline>.of(polylines.values),
            onCameraMove: (CameraPosition position) {
              mapController?.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: currentLocation,
                    zoom: position.zoom,
                    bearing: bearing,
                  ),
                ),
              );
            },
          ),
          // EXIT
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Get.to(() =>
                    const MapScreen()); // Navigate back to the previous screen
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // INFORMATION ROAD HAZARDS
          Positioned(
            right: 16,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showInformation = !_showInformation;
                });
              },
              icon: const Icon(
                Icons.info,
                color: Colors.blue,
                size: 50,
              ),
            ),
          ),
          // INFORMATION CONTAINER
          Visibility(
            visible: _showInformation,
            child: Positioned(
              top: 48,
              right: 24,
              child: Container(
                color: Colors.black.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 20,
                ),
                width: 220,
                child: Column(children: [
                  Text(
                    'Current Street:',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    currentStreet,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hazards in Current Street:',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _recordedHazard.toString(),
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'DETAILS',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Crack: ${_recordedCrack.toString()}',
                    style: GoogleFonts.montserrat(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Pothole: ${_recordedPothole.toString()}',
                    style: GoogleFonts.montserrat(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Manhole: ${_recordedManhole.toString()}',
                    style: GoogleFonts.montserrat(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Metal Plate: ${_recorededMetalPlate.toString()}',
                    style: GoogleFonts.montserrat(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ),
          ),
          // HAZARD NAME INFORMATION
          Positioned(
            bottom: 100,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      objectLabel,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Get.to(
                () => DetectionScreen(
                  origin: currentLocation,
                  destination: destinationLocation,
                ),
                transition: Transition.noTransition,
              ),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.pedal_bike,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void setPolylines() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(
        currentLocation.latitude,
        currentLocation.longitude,
      ),
      PointLatLng(
        destinationLocation.latitude,
        destinationLocation.longitude,
      ),
      travelMode: TravelMode.driving,
    );

    if (result.status == 'OK') {
      polylineCoordinates.clear(); // Clear the previous coordinates
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    PolylineId id = const PolylineId('main_route');

    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue.withOpacity(0.5),
      points: polylineCoordinates,
    );

    setState(() {
      polylines.clear(); // Clear the previous polylines
      polylines[id] = polyline; // Add the new polyline
    });
  }

  void getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      Placemark positionPlace =
          await getAddress(position.latitude, position.longitude);

      if (currentStreet != positionPlace.thoroughfare!) {
        setState(() {
          currentStreet = positionPlace.thoroughfare!;
          _hazardCounter = 0;
          _crackCounter = 0;
          _potholeCounter = 0;
          _manholeCounter = 0;
          _metalPlateCounter = 0;
        });
      }

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        bearing = getBearing(currentLocation, destinationLocation);
        updateMarkers();
        moveCamera();
      });

      if (!isMoving) {
        isMoving = true;
        positionStreamSubscription = Geolocator.getPositionStream(
            locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        )).listen((Position position) {
          setState(() {
            currentLocation = LatLng(position.latitude, position.longitude);
            bearing = position.heading;
            updateMarkers();
            moveCamera();
            updatePolyline();
            getData();
          });
        });
      }
    }
  }

  void updateMarkers() {
    Marker marker = Marker(
      markerId: const MarkerId('destination'),
      position: destinationLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {
      markers = {marker};
    });
  }

  void moveCamera() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLocation,
          zoom: 18,
          bearing: bearing,
        ),
      ),
    );
  }

  void updatePolyline() async {
    if (!mounted) return; // Check if the State object is still mounted

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(
        currentLocation.latitude,
        currentLocation.longitude,
      ),
      PointLatLng(
        destinationLocation.latitude,
        destinationLocation.longitude,
      ),
    );

    if (!mounted) return; // Check again after the asynchronous operation

    Placemark positionPlace =
        await getAddress(currentLocation.latitude, currentLocation.longitude);
    setState(() {
      currentStreet = positionPlace.thoroughfare!;
    });

    if (result.status == 'OK') {
      polylineCoordinates.clear();
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    double distance = await MapInformationApi().getDistance(
      currentLocation,
      destinationLocation,
    );
    if (distance < 0.05) {
      if (mounted) {
        Get.to(
          () => const MapScreen(),
        );
      }
    }

    PolylineId id = const PolylineId('main_route');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue.withOpacity(0.5),
      points: polylineCoordinates,
    );

    if (mounted) {
      setState(() {
        polylines = {id: polyline};
      });
    }
  }

  double getBearing(LatLng start, LatLng end) {
    double startLat = degreesToRadians(start.latitude);
    double startLng = degreesToRadians(start.longitude);
    double endLat = degreesToRadians(end.latitude);
    double endLng = degreesToRadians(end.longitude);

    double dLng = endLng - startLng;

    double y = math.sin(dLng) * math.cos(endLat);
    double x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    double bearing = math.atan2(y, x);

    return radiansToDegrees(bearing);
  }

  double degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  double radiansToDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }
}

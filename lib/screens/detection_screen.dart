import 'dart:async';

import 'package:boats_mobile_app/components/app_bar.dart';
import 'package:boats_mobile_app/components/side_bar.dart';
import 'package:boats_mobile_app/controllers/global_controller.dart';
import 'package:boats_mobile_app/screens/driving_screen.dart';
import 'package:boats_mobile_app/screens/map_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class DetectionScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  const DetectionScreen(
      {super.key, required this.origin, required this.destination});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  late LatLng currentLocation;
  late LatLng destinationLocation;
  bool frontHazard = false;
  bool rearHazard = false;
  bool leftHazard = false;
  bool rightHazard = false;

  bool isDetecting = false;
  late CameraController controller;
  FlutterVision vision = FlutterVision();
  String objectLabel = '';
  bool showCamera = false;

  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;

  Timer? detectionTimer;
  Timer? hazardIndicatorTimer;

  late BluetoothConnection connection;
  List<String> messages = [];

  final GlobalController globalController = Get.put(
    GlobalController(),
    permanent: true,
  );

  @override
  void initState() {
    currentLocation = widget.origin;
    destinationLocation = widget.destination;
    super.initState();
    loadModel().then((void v) {});
    initCamera();
    _startConnection();
  }

  Future<void> _startConnection() async {
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      BluetoothDevice? device; // Change type to BluetoothDevice?
      for (BluetoothDevice d in devices) {
        if (d.name == 'BOATS Device') {
          device = d;
          break;
        }
      }
      if (device != null) {
        connection = await BluetoothConnection.toAddress(device.address);
        connection.input!.listen((data) {
          String message = String.fromCharCodes(data).trim();
          print(message);
          setState(() {
            messages.add(message);
          });
          assignDirections(message);
        });
      } else {
        print('Device not found');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void assignDirections(String message) {
    switch (message) {
      case 'DETECTION (Sensor Front)':
        setState(() {
          frontHazard = true;
          rearHazard = false;
          leftHazard = false;
          rightHazard = false;
        });
        break; // Added break statement
      case 'Sensor Left':
        setState(() {
          frontHazard = false;
          rearHazard = false;
          leftHazard = true;
          rightHazard = false;
        });
        break; // Added break statement
      case 'Sensor Right':
        setState(() {
          frontHazard = false;
          rearHazard = false;
          leftHazard = false;
          rightHazard = true;
        });
        break; // Added break statement
      case 'Sensor Back':
        setState(() {
          frontHazard = false;
          rearHazard = true;
          leftHazard = false;
          rightHazard = false;
        });
        break; // Added break statement
      default:
        hazardIndicatorTimer?.cancel();
        hazardIndicatorTimer = Timer(const Duration(seconds: 3), () {
          setState(() {
            frontHazard = false;
            rearHazard = false;
            leftHazard = false;
            rightHazard = false;
          });
        });
    }
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

      // Reset the objectLabel after 5 seconds of no detection
      detectionTimer?.cancel();
      detectionTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          objectLabel = '';
        });
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    connection.dispose();
    detectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: prefer_const_constructors
    return Scaffold(
      drawer: const SideBar(),
      appBar: const BoatsAppBar(),
      body: Stack(
        children: [
          Container(),
          Center(
            child: Image.asset(
              'assets/bike.png',
              cacheHeight: 167,
              cacheWidth: 71,
            ),
          ),
          Visibility(
            visible: rearHazard,
            child: Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 260,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.red, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter)),
              ),
            ),
          ),
          Visibility(
            visible: frontHazard,
            child: Positioned(
              top: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 260,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.red, Colors.transparent],
                      end: Alignment.bottomCenter,
                      begin: Alignment.topCenter),
                ),
              ),
            ),
          ),
          Visibility(
            visible: leftHazard,
            child: Positioned(
              left: 0,
              child: Container(
                width: 180,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.red, Colors.transparent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight)),
              ),
            ),
          ),
          Visibility(
            visible: rightHazard,
            child: Positioned(
              right: 0,
              child: Container(
                width: 180,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.red, Colors.transparent],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft)),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Get.to(
                  () => const MapScreen(),
                  transition: Transition.noTransition,
                ); // Navigate back to the previous screen
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
                () => DrivingScreen(
                  origin: currentLocation,
                  destination: destinationLocation,
                ),
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
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  showCamera = !showCamera;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.video_camera_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Visibility(
            visible: showCamera,
            child: Positioned(
              top: 10,
              right: 10,
              child: Container(
                height: 300,
                width: 200,
                child: Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: Uri.parse('http://192.168.43.38'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

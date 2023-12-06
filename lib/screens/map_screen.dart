import 'dart:async';

import 'package:boats_mobile_app/api/map_information.dart';
import 'package:boats_mobile_app/components/custom_bottom_navigation.dart';
import 'package:boats_mobile_app/constants/colors.dart';
import 'package:boats_mobile_app/controllers/global_controller.dart';
import 'package:boats_mobile_app/screens/driving_screen.dart';
import 'package:boats_mobile_app/utils/background_gradient.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../components/app_bar.dart';
import '../components/side_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _isRoutesShown = false;
  String currentLocation = 'Origin';

  final GlobalController globalController = Get.put(
    GlobalController(),
    permanent: true,
  );

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Set<Marker> _markers = Set<Marker>();
  Set<Polyline> _polylines = Set<Polyline>();
  late LatLng origin;
  late LatLng destination;

  @override
  void initState() {
    getCurrentLocation();
    super.initState();
  }

  Future<void> getCurrentLocation() async {
    await globalController.getLocation();
    setState(() {
      currentLocation = globalController.getCurrentLocation().value;
      _originController.text = currentLocation;
    });
  }

  _getDirection() async {
    var directions = await MapInformationApi().getDirections(
        globalController.getCurrentLocation().value,
        _destinationController.text);
    _goToPlace(
      directions['start_location']['lat'],
      directions['start_location']['lng'],
      directions['bounds_ne'],
      directions['bounds_sw'],
      directions['end_location']['lat'],
      directions['end_location']['lng'],
    );

    setState(() {
      origin = LatLng(
        directions['start_location']['lat'],
        directions['start_location']['lng'],
      );

      destination = LatLng(
        directions['end_location']['lat'],
        directions['end_location']['lng'],
      );
    });

    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId('main_route'),
        width: 6,
        color: Colors.red,
        points: directions['polyline_decoded'].map<LatLng>((point) {
          return LatLng(point.latitude as double, point.longitude as double);
        }).toList(),
      ));
    });
  }

  _goToPlace(
      double latitude,
      double longitude,
      Map<String, dynamic> boundsNe,
      Map<String, dynamic> boundsSw,
      double latDestination,
      double lngDestination) async {
    final GoogleMapController controller = await _controller.future;

    // moves to the destination location
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(latitude, longitude), zoom: 12),
      ),
    );

    // zooms out to the direction from origin to destination
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
              southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
              northeast: LatLng(boundsNe['lat'], boundsNe['lng'])),
          20),
    );

    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('origin'),
        position: LatLng(latitude, longitude),
        icon: BitmapDescriptor.defaultMarker,
      ));
    });

    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('destination'),
        position: LatLng(latDestination, lngDestination),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideBar(),
      appBar: const BoatsAppBar(),
      body: SafeArea(
        child: Container(
          decoration: appBackgroundGradient(),
          child: Column(
            children: [
              SingleChildScrollView(child: _inputAddressWidget()),
              Expanded(
                child: _googleMapsWidget(),
              ),
              const CustomBottomNavigation(
                pageIndex: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputAddressWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.trip_origin,
                    color: Colors.white,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ),
                  const Icon(
                    Icons.edit_location_alt_outlined,
                    color: Colors.white,
                    size: 27,
                  ),
                ],
              ),
              Container(
                width: MediaQuery.of(context).size.width - 50,
                child: Column(
                  children: [
                    SizedBox(
                      height: 45,
                      child: TextFormField(
                        controller: _originController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                            enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.only(left: 10),
                            hintText: 'Origin',
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                            suffixIcon: _originController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _originController.clear();
                                    },
                                    icon: const Icon(Icons.clear),
                                    color: Colors.white,
                                  )
                                : null),
                      ),
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      height: 45,
                      child: TextFormField(
                        onFieldSubmitted: (value) => _getDirection(),
                        controller: _destinationController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                            enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.only(left: 10),
                            hintText: 'Destination',
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                            suffixIcon: _destinationController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _destinationController.clear();
                                    },
                                    icon: const Icon(Icons.clear),
                                    color: Colors.white,
                                  )
                                : null),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: MediaQuery.of(context).size.width,
            height: 40,
            child: !_isRoutesShown
                ? ElevatedButton(
                    style: ButtonStyle(
                      side: MaterialStateProperty.all(
                        const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      alignment: Alignment.center,
                      backgroundColor: MaterialStateColor.resolveWith((states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Colors.grey
                              .withOpacity(0.5); // Fill color when clicked
                        }
                        return Colors.transparent; // No fill color
                      }),
                      shadowColor:
                          const MaterialStatePropertyAll(Colors.transparent),
                    ),
                    onPressed: () {
                      _getDirection();
                      setState(() {
                        _isRoutesShown = true;
                      });
                    },
                    child: Text(
                      'SHOW ROUTE',
                      style: GoogleFonts.montserrat(),
                    ),
                  )
                : ElevatedButton(
                    style: ButtonStyle(
                      side: MaterialStateProperty.all(
                        const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      alignment: Alignment.center,
                      backgroundColor: MaterialStateColor.resolveWith((states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Colors.grey
                              .withOpacity(0.5); // Fill color when clicked
                        }
                        return Colors.transparent; // No fill color
                      }),
                      shadowColor:
                          const MaterialStatePropertyAll(Colors.transparent),
                    ),
                    onPressed: () => Get.to(() => DrivingScreen(
                        origin: origin, destination: destination)),
                    child: Text(
                      'START RIDE',
                      style: GoogleFonts.montserrat(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _googleMapsWidget() {
    final CameraPosition _currentAvailableLocation = CameraPosition(
      target: LatLng(globalController.getLatitude().value,
          globalController.getLongitude().value),
      zoom: 20,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              spreadRadius: 1,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: GoogleMap(
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            indoorViewEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
            compassEnabled: true,
            tiltGesturesEnabled: true,
            initialCameraPosition: _currentAvailableLocation,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
        ),
      ),
    );
  }
}

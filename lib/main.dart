import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:maps/Community/Main.dart';
import 'package:maps/locationontap.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyCOoGxWlgYEFg9LQUVieOITKZi27LQCGMg",
        appId: "1:166629524832:android:d2bccd985c1d58fb85ca05",
        messagingSenderId: "166629524832",
        projectId: "mapdatabase-f3797",
        storageBucket: "mapdatabase-f3797.appspot.com"),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MapSample(),
        title: 'RMUTT Map',
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
          // กำหนดสีหลักเป็นสีขาวที่นี่
          // คุณยังสามารถปรับแต่งธีมอื่นๆ ของแอปพลิเคชันได้ตามต้องการ
        ),
      ),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  String? userSelected;
  GoogleMapController? _controllers;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  List<Marker> markers = [];
  String _searchText = '';
  Marker? _userMarker;
  final LatLng _startLocation =
      const LatLng(14.039614599717076, 100.72766444381722);
  late PanelController _panelController;
  bool _showPanel = false;
  double travelDuration = 0.0;
  bool _showCancelButton = false;
  BitmapDescriptor userLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _toilet = BitmapDescriptor.defaultMarker;
  Location locationController = Location();
  BitmapDescriptor toiletIcon = BitmapDescriptor.defaultMarker;
  late GoogleMapController mapController;
  @override
  void initState() {
    super.initState();
    _requestPermission();
    _panelController = PanelController();
    _setMarkerIcon();
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData? data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> _setMarkerIcon() async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/Userlocation.png', 100);
    _markerIcon = BitmapDescriptor.fromBytes(markerIcon);
    final Uint8List toiletIcon =
        await getBytesFromAsset('assets/toilet1.png', 100);
    _toilet = BitmapDescriptor.fromBytes(toiletIcon);
  }

  Future<void> _requestPermission() async {
    PermissionStatus permissionStatus = await Location().requestPermission();
    if (permissionStatus == PermissionStatus.granted) {
      _startLocationUpdates();
    } else {
      print('Location permission denied');
    }
  }

  void _startLocationUpdates() {
    _locationSubscription = Location().onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        _currentPosition =
            LatLng(locationData.latitude!, locationData.longitude!);
        _updateUserMarker();
      }
    });
  }

  void _updateUserMarker() {
    if (_currentPosition != null) {
      setState(() {
        _userMarker = Marker(
          markerId: MarkerId('user_marker'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarker,
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationSubscription?.cancel();

    super.dispose();
  }

  static const CameraPosition university = CameraPosition(
    target: LatLng(14.03658958923885, 100.72790357867967),
    zoom: 16,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchController.clear(); // ล้างค่าในช่องค้นหา
                _searchText = ''; // เคลียร์ข้อความที่ใช้ในการค้นหา
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.gps_fixed),
            onPressed: showUserLocation,
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: _showMenu, // แก้ไขการเรียกฟังก์ชันนี้
            ),
            IconButton(
              icon: Icon(Icons.comment),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomeScreen()),
                );
              },
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,

            markers: Set.from(_markers)
              ..addAll([
                if (_currentPosition != null)
                  Marker(
                    markerId: MarkerId('currentLocation'),
                    position: _currentPosition!,
                    icon: _markerIcon,
                  ),
              ]),
            indoorViewEnabled: true,
            initialCameraPosition: university,
            polylines: _polylines,
            trafficEnabled: true,
            mapToolbarEnabled: false, // ซ่อนปุ่มทั้งหมด
            zoomControlsEnabled: false,

            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          if (_showPanel)
            SlidingUpPanel(
              controller: _panelController,
              maxHeight: 100.0,
              color: Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19.0)),
              panel: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'เวลาในการเดินทางโดยประมาณ : ${_travelDuration.toStringAsFixed(2)} นาที',
                        style: TextStyle(
                          fontSize: 19,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_showCancelButton)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _polylines.clear();
                              _showCancelButton = false;
                              _markers.clear();
                              _showPanel = false; // ซ่อน SlidingUpPanel
                            });
                          },
                          child: Text('ยกเลิกการแสดงเส้นทาง'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (_markers.length > 1 ||
              (_markers.length == 1 &&
                  _markers.first.markerId != const MarkerId('currentLocation')))
            Positioned(
              top: 5,
              right: 16.0,
              child: SizedBox(
                width: 100.0,
                height: 35,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _markers.removeWhere((marker) =>
                          marker.markerId != const MarkerId('currentLocation'));
                    });
                  },
                  child: const Text('ปิดจุดมาร์ค'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
            ),
          if (_searchText.isEmpty)
            Container()
          else
            Positioned(
              top: 0,
              left: 16.0,
              right: 16.0,
              bottom: 0.0,
              child: SizedBox.expand(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('rmuttlocations')
                      .where('namelocation',
                          isGreaterThanOrEqualTo: _searchText)
                      .where('namelocation',
                          isLessThanOrEqualTo: _searchText + '\uf8ff')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }
                    return ListView.builder(
                      itemCount: snapshot.data?.docs.length ?? 0,
                      itemBuilder: (context, index) {
                        if (snapshot.hasData &&
                            snapshot.data!.docs.isNotEmpty) {
                          return GestureDetector(
                            onTap: () {
                              var selectedLocation =
                                  snapshot.data!.docs[index]['namelocation'];
                              var latitude =
                                  snapshot.data!.docs[index]['latitude'];
                              var longitude =
                                  snapshot.data!.docs[index]['longitude'];
                              var detail = snapshot.data!.docs[index]['detail'];

                              LatLng destinationLatLng =
                                  LatLng(latitude, longitude);

                              // Add marker to map
                              setState(() {
                                _markers.add(
                                  Marker(
                                    markerId: MarkerId('destination_$index'),
                                    position: destinationLatLng,
                                    infoWindow: InfoWindow(
                                      title: selectedLocation,
                                      snippet: detail,
                                      onTap: () => _onMarkerTap(
                                          destinationLatLng, selectedLocation),
                                    ),
                                  ),
                                );
                              });

                              // Update the TextField and clear the search text
                              textFieldOnTap(_searchController,
                                  selectedLocation, setState, _searchText);
                              _searchController.clear();
                              _searchText = '';
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color.fromARGB(253, 255, 253, 253),
                              ),
                              child: ListTile(
                                title: Text(
                                    snapshot.data!.docs[index]['namelocation']),
                                subtitle:
                                    Text(snapshot.data!.docs[index]['detail']),
                              ),
                            ),
                          );
                        } else {
                          return ListTile(
                            title: Text('No data available'),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _updateCurrentLocationMarker(LocationData currentLocation) {
    if (_controller != null) {
      setState(() {
        _currentLocationMarker = Marker(
          markerId: const MarkerId('currentLocation'),
          position:
              LatLng(currentLocation.latitude!, currentLocation.longitude!),
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
        _markers.removeWhere(
            (marker) => marker.markerId.value == 'currentLocation');
        _markers.add(_currentLocationMarker!);
      });

      _controllers?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
          zoom: 17.5,
        ),
      ));
    }
  }

  Future<void> _fetchAndCalculateRoutes(
      LatLng endLocation, String destination) async {
    final String url =
        'https://355c12d0-f697-4646-9c07-0715c29de092-00-b95cq7qjvlj7.pike.replit.dev/Route';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK' &&
          json['routes'] != null &&
          json['routes'].isNotEmpty) {
        final route = json['routes'][0];

        // Debug output
        print("Received route data: ${route['data']}");

        final matchingData = route['data'].firstWhere(
          (data) =>
              data['end_address'] != null &&
              data['end_address']
                  .toString()
                  .toLowerCase()
                  .contains(destination.toLowerCase()),
          orElse: () => null,
        );

        // Debug output
        print("Matching data: $matchingData");

        if (matchingData != null) {
          final steps = matchingData['steps'];
          final List<LatLng> polylineCoordinates = _extractCoordinates(steps);

          setState(() {
            _steps = List<Map<String, dynamic>>.from(steps);
            _polylines.clear(); // Clear all existing polylines
            _addPolyline(polylineCoordinates);
          });
        } else {
          print('No matching data found for destination: $destination');
          // Find nearest point
          _findNearestRouteAndDisplay(endLocation, route['data']);
        }
      } else {
        print('No routes found in the response or status is not OK.');
      }
    } else {
      print(
          'Failed to fetch initial route. Status code: ${response.statusCode}');
    }
  }

  void _findNearestRouteAndDisplay(
      LatLng endLocation, List<dynamic> routeData) {
    double minDistance = double.infinity;
    Map<String, dynamic>? nearestRoute;

    for (var data in routeData) {
      LatLng routeStartLocation =
          LatLng(data['start_location']['lat'], data['start_location']['lng']);
      double distance = _calculateDistance(_startLocation, routeStartLocation);

      if (distance < minDistance) {
        minDistance = distance;
        nearestRoute = data;
      }
    }

    if (nearestRoute != null) {
      final steps = nearestRoute['steps'];
      final List<LatLng> polylineCoordinates = _extractCoordinates(steps);

      setState(() {
        _steps = List<Map<String, dynamic>>.from(steps);
        _polylines.clear(); // Clear all existing polylines
        _addPolyline(polylineCoordinates);
      });

      print('Displaying route to the nearest point.');
    } else {
      print('No suitable route found.');
    }
  }

  void _onMarkerTap(LatLng endLocation, String destination) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Show Route'),
          content: Text('Do you want to display the route to this point?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchAndCalculateRoutes(endLocation, destination);
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _addPolyline(List<LatLng> polylineCoordinates) {
    final String polylineIdVal =
        'polyline_id_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 5,
        color: Colors.blue,
        points: polylineCoordinates,
      ));
    });
  }

  Set<Polyline> _polylines = {};
  List<Marker> _markers = [];
  Location _location = Location();
  List<Map<String, dynamic>> _steps = [];
  bool _isCompleted = false;
  Marker? _currentLocationMarker;
  late StreamSubscription<LocationData> _locationSubscription;

  List<LatLng> _extractCoordinates(List<dynamic> steps) {
    List<LatLng> polylineCoordinates = [];
    for (var step in steps) {
      LatLng startLocation =
          LatLng(step['start_location']['lat'], step['start_location']['lng']);
      LatLng endLocation =
          LatLng(step['end_location']['lat'], step['end_location']['lng']);

      polylineCoordinates.add(startLocation);
      polylineCoordinates.add(endLocation);
    }
    return polylineCoordinates;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  void _redrawPolyline(List<LatLng> newPoints) {
    if (_polylines.isNotEmpty) {
      Polyline matchingPolyline = _polylines.first;
      _polylines.clear();
      _polylines.add(Polyline(
        polylineId: matchingPolyline.polylineId,
        width: matchingPolyline.width,
        color: matchingPolyline.color,
        points: newPoints,
      ));
    }
  }

  void showCurrentLocation() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();

    final currentLocation =
        LatLng(_locationData.latitude ?? 0.0, _locationData.longitude ?? 0.0);

    _updateCurrentLocationMarker(_locationData);

    _controllers?.animateCamera(CameraUpdate.newLatLng(currentLocation));
    location.onLocationChanged.listen((LocationData currentLocation) {
      print(currentLocation);
      final _currentLocation = LatLng(
          currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);
      _updateCurrentLocationMarker(currentLocation);
      _updateRoute(currentLocation.latitude!, currentLocation.longitude!);
      _controllers?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
    });
  }

  void _updateRoute(double currentLatitude, double currentLongitude) {
    LatLng currentLocation = LatLng(currentLatitude, currentLongitude);

    // Create a new list of remaining steps
    List<Map<String, dynamic>> remainingSteps = [];
    bool exitedBounds = false;

    for (var step in _steps) {
      LatLng startLocation =
          LatLng(step['start_location']['lat'], step['start_location']['lng']);
      LatLng endLocation =
          LatLng(step['end_location']['lat'], step['end_location']['lng']);
      double distanceToStart =
          _calculateDistance(currentLocation, startLocation);
      double distanceToEnd = _calculateDistance(currentLocation, endLocation);

      // Debug output to check the calculated distances
      print('Distance to step start location: $distanceToStart');
      print('Distance to step end location: $distanceToEnd');

      // Check if currentLocation is outside the polyline bounds
      if (distanceToEnd > 0.015) {
        exitedBounds = true;
      }

      if (distanceToStart <= 0.015 && distanceToEnd > 0.0) {
        // Gradually reduce the last polyline step
        double fraction =
            distanceToStart / _calculateDistance(startLocation, endLocation);
        double newLat = startLocation.latitude +
            fraction * (endLocation.latitude - startLocation.latitude);
        double newLng = startLocation.longitude +
            fraction * (endLocation.longitude - startLocation.longitude);

        _redrawPolyline([
          LatLng(newLat, newLng),
          endLocation,
        ]);

        // Debug output to confirm polyline update
        print('Updated polyline with remaining steps');

        // Exit the loop after updating the polyline
        return;
      }

      // Add the step to remainingSteps if needed
      if (distanceToEnd > 0.0) {
        remainingSteps.add(step);
      }
    }

    // If no steps matched the condition, clear all polylines
    if (remainingSteps.isEmpty) {
      _polylines.clear();
      _isCompleted = true;

      // Debug output to confirm route completion
      print('Route completed');
    }
  }

  Future<double> calculateTravelDuration(
      List<LatLng> polylineCoordinates, LatLng destinationLatLng) async {
    double totalDistance = 0.0;
    double walkingSpeed = 5.0; // อัตราเร็วในการเดิน (กม./ชม.)

    // คำนวณระยะทางรวมของเส้นทาง
    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      double distance = await Geolocator.distanceBetween(
        polylineCoordinates[i].latitude,
        polylineCoordinates[i].longitude,
        polylineCoordinates[i + 1].latitude,
        polylineCoordinates[i + 1].longitude,
      );
      totalDistance += distance;
    }

    // คำนวณระยะทางจากจุดสุดท้ายของเส้นทางไปยังจุดหมายปลายทาง
    double distanceToDestination = await Geolocator.distanceBetween(
      polylineCoordinates.last.latitude,
      polylineCoordinates.last.longitude,
      destinationLatLng.latitude,
      destinationLatLng.longitude,
    );
    totalDistance += distanceToDestination;

    // คำนวณระยะเวลาในการเดินทาง (นาที)
    double travelDuration = (totalDistance / 1000.0) / (walkingSpeed / 60.0);

    return travelDuration;
  }

  double _travelDuration = 0.0;

  Future<void> getShortestRoute(LatLng destinationLatLng, detail) async {
    setState(() {
      _polylines.clear();
      _showCancelButton = true;
      _showPanel = false;
    });

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCKrCcDsIhfgQW9DuhOAJzNyCK06ieo0ks',
      PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      PointLatLng(destinationLatLng.latitude, destinationLatLng.longitude),
      travelMode: TravelMode.walking,
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('เส้นทางการเดิน'),
            points: polylineCoordinates,
            width: 4,
            color: Color.fromRGBO(10, 239, 255, 1),
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      });

      // คำนวณระยะเวลาในการเดินทาง
      _travelDuration =
          await calculateTravelDuration(polylineCoordinates, destinationLatLng);

      setState(() {
        _showPanel = true;
      });
      _panelController.open();

      // Check if last point of polyline is near destination
      LatLng lastPoint = polylineCoordinates.last;
      double distanceToDestination = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        destinationLatLng.latitude,
        destinationLatLng.longitude,
      );

      if (distanceToDestination < 10) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white, // เปลี่ยนสีพื้นหลังเป็นสีขาว
              title: Text('Destination Reached'),
              content: Text(detail),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      // ไม่แสดง SlidingUpPanel หากไม่มีการแสดงเส้นทาง
      _panelController.close();
    }
  }

  bool _cameraMoved = false;
  LatLng? _currentPosition;
  Future<void> showUserLocation() async {
    LocationData? currentLocationData = await Location().getLocation();
    if (currentLocationData != null) {
      _currentPosition =
          LatLng(currentLocationData.latitude!, currentLocationData.longitude!);
      _updateUserMarker();
      GoogleMapController controller = await _controller.future;
      controller
          .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 16));

      // Start location service to get continuous location updates
      Location().onLocationChanged.listen((LocationData locationData) {
        _currentPosition =
            LatLng(locationData.latitude!, locationData.longitude!);
        _updateUserMarker();
        if (!_cameraMoved) {
          // ตรวจสอบว่ามุมกล้องได้ถูกขยับหรือไม่
          controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
          _cameraMoved = true; // กำหนดให้มุมกล้องได้ถูกขยับ
        }
      });
    } else {
      print('Error: Cannot get current location');
    }
  }

  void _addMarkerAndShowDirections(LatLng latLng, String markerId, detail,
      {bool showDialogOnMarkerTap = true}) {
    _controller.future.then((controller) {
      if (_currentPosition != null) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 16),
        );
      }
    });

    Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: latLng,
      infoWindow: InfoWindow(title: markerId),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      onTap: () {
        if (showDialogOnMarkerTap) {
          showDialogForDirections(markerId, latLng, detail);
        }
      },
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void showDialogForDirections(
      String destinationName, LatLng destinationLatLng, detail) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(' $destinationName'),
          content: Text('ต้องการแสดงเส้นทางไปที่ $destinationName หรือไม่'),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
                getShortestRoute(destinationLatLng, detail);
              },
              child: Text('ใช่'),
            ),
            TextButton(
              onPressed: () {
                // Get and display directions

                Navigator.of(context).pop();
              },
              child: Text('ไม่'),
            ),
          ],
        );
      },
    );
  }

  void _categoryLocation(String destinationName, LatLng destinationLatLng) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(' $destinationName'),
          content: Text('ต้องการแสดงเส้นทางไปที่ $destinationName หรือไม่'),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
                _showCategoryDirection(destinationLatLng);
              },
              child: Text('ใช่'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ไม่'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCategoryDirection(LatLng destinationLatLng) async {
    setState(() {
      _polylines.clear();
      _showCancelButton = true; // แสดงปุ่มยกเลิก
      _showPanel = false; // ซ่อน SlidingUpPanel ก่อน
    });

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCKrCcDsIhfgQW9DuhOAJzNyCK06ieo0ks',
      PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      PointLatLng(destinationLatLng.latitude, destinationLatLng.longitude),
      travelMode: TravelMode.walking,
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('เส้นทางการเดิน'),
            points: polylineCoordinates,
            width: 4,
            color: Color.fromRGBO(10, 239, 255, 1),
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      });

      _travelDuration =
          await calculateTravelDuration(polylineCoordinates, destinationLatLng);

      setState(() {
        _showPanel = true;
      });
      _panelController.open();

      // Check if last point of polyline is near destination
      LatLng lastPoint = polylineCoordinates.last;
      double distanceToDestination = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        destinationLatLng.latitude,
        destinationLatLng.longitude,
      );

      if (distanceToDestination < 10) {}
    } else {
      // ไม่แสดง SlidingUpPanel หากไม่มีการแสดงเส้นทาง
      _panelController.close();
    }
  }

  void _showMenu() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Image.asset(
                  'assets/svg/Toilet.png',
                  width: 24,
                  height: 24,
                ),
                title: Text(
                  'ห้องน้ำ',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _markers.add(
                      Marker(
                        markerId: MarkerId('ห้องน้ำ1'),
                        position:
                            LatLng(14.035978558473701, 100.72472173847785),
                        infoWindow: InfoWindow(title: 'ห้องน้ำ 1'),
                        icon: _toilet,
                        onTap: () {
                          _categoryLocation(
                            'ห้องน้ำ 1',
                            LatLng(14.035978558473701, 100.72472173847785),
                          );
                        },
                      ),
                    );
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.food_bank),
                title: Text(
                  'จุดขายอาหารและเครื่องดื่ม',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Color.fromARGB(255, 37, 247, 138),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _markers.add(
                      Marker(
                        markerId: MarkerId('ตู้เต่าบิน1'),
                        position: LatLng(14.0341588, 100.7298778),
                        infoWindow: InfoWindow(title: 'ตู้เต่าบิน1'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                        onTap: () {
                          _categoryLocation(
                            'ตู้เต่าบิน1',
                            LatLng(14.0341588, 100.7298778),
                          );
                        },
                      ),
                    );
                    _markers.add(
                      Marker(
                        markerId: MarkerId('ตู้เต่าบิน2'),
                        position: LatLng(14.0355962, 100.7247165),
                        infoWindow: InfoWindow(title: 'ตู้เต่าบิน2'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                        onTap: () {
                          _categoryLocation(
                            'ตู้เต่าบิน2',
                            LatLng(14.0355962, 100.7247165),
                          );
                        },
                      ),
                    );
                    _markers.add(
                      Marker(
                        markerId: MarkerId('ตู้เต่าบิน3'),
                        position: LatLng(14.0364159, 100.7298667),
                        infoWindow: InfoWindow(title: 'ตู้เต่าบิน3'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                        onTap: () {
                          _categoryLocation(
                            'ตู้เต่าบิน3',
                            LatLng(14.0364159, 100.7298667),
                          );
                        },
                      ),
                    );
                    _markers.add(
                      Marker(
                        markerId: MarkerId('ตู้เต่าบิน4'),
                        position: LatLng(14.0362949, 100.7260241),
                        infoWindow: InfoWindow(title: 'ตู้เต่าบิน4'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                        onTap: () {
                          _categoryLocation(
                            'ตู้เต่าบิน4',
                            LatLng(14.0362949, 100.7260241),
                          );
                        },
                      ),
                    );
                    _markers.add(
                      Marker(
                        markerId: MarkerId('ศูนย์อาหารช่อพวงชมพู'),
                        position:
                            LatLng(14.039641633441367, 100.72955146567259),
                        infoWindow: InfoWindow(title: 'ศูนย์อาหารช่อพวงชมพู'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                        onTap: () {
                          _categoryLocation(
                            'ศูนย์อาหารช่อพวงชมพู',
                            LatLng(14.039641633441367, 100.72955146567259),
                          );
                        },
                      ),
                    );
                    _markers.add(
                      Marker(
                        markerId: MarkerId('โรงอาหารหอใน'),
                        position: LatLng(14.03236454776452, 100.7224935789183),
                        infoWindow: InfoWindow(title: 'โรงอาหารหอใน'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                        onTap: () {
                          _categoryLocation(
                            'โรงอาหารหอใน',
                            LatLng(14.03236454776452, 100.7224935789183),
                          );
                        },
                      ),
                    );
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.directions_car),
                title: Text('ลานจอดรถ'),
                onTap: () async {
                  setState(() {
                    _markers.add(
                      Marker(
                        markerId: MarkerId('ลานจอดรถ1'),
                        position: LatLng(14.03328625545491, 100.72943063441335),
                        infoWindow: InfoWindow(title: 'ลานจอดรถ1'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                        onTap: () {
                          _categoryLocation(
                            'ลานจอดรถ1',
                            LatLng(14.03328625545491, 100.72943063441335),
                          );
                        },
                      ),
                    );
                    // เพิ่ม Marker อื่น ๆ ที่ต้องการที่นี่
                  });

                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.atm),
                title: Text('ตู้ ATM'),
                onTap: () async {
                  setState(() {
                    _markers.add(
                      Marker(
                        markerId: MarkerId('ตู้ATMธนาคารกรุงไทย'),
                        position: LatLng(14.0355962, 100.7247165),
                        infoWindow: InfoWindow(title: 'ตู้ATMธนาคารกรุงไทย'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                        onTap: () {
                          _categoryLocation(
                            'ตู้ATMธนาคารกรุงไทย',
                            LatLng(14.0355962, 100.7247165),
                          );
                        },
                      ),
                    );
                    // เพิ่ม Marker อื่น ๆ ที่ต้องการที่นี่
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    ).then((value) {});
  }
}

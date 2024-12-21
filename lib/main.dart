import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:maps/MarkerController.dart';
import 'package:maps/OpenChat/WelcomeScreen.dart';
import 'package:maps/RoutesController.dart';
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
  final MarkerController _markerController = MarkerController();
  List<LatLng> _routeCoordinates = [];
  LatLng? _destinationLatLng;
  String _destination = '';
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
          infoWindow: InfoWindow(title: 'Your Location'),
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
              onPressed: _showMenu,
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
            markers: Set<Marker>.from(_markerController.markers)
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
            mapToolbarEnabled: false,
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

                              // Update the class variables
                              setState(() {
                                _destinationLatLng = destinationLatLng;
                                _destination = selectedLocation;

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

                              // Call the route fetching function with all required parameters
                              Location().getLocation().then((locationData) {
                                if (locationData != null) {
                                  LatLng currentPosition = LatLng(
                                      locationData.latitude!,
                                      locationData.longitude!);
                                  _fetchRouteFromApi(
                                      currentPosition,
                                      destinationLatLng,
                                      selectedLocation // Add the destination name
                                      );
                                }
                              });
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

  void _onMarkerTap(LatLng endLocation, String destination) {
    final routeController = RouteController(
      onRouteFetched: (polylineCoordinates, steps) {
        setState(() {
          _steps = List<Map<String, dynamic>>.from(steps);
          _polylines.clear();
          _addPolyline(polylineCoordinates);
        });
      },
    );

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
                routeController.fetchAndCalculateRoutes(
                  _currentPosition!,
                  endLocation,
                  destination, // Add the destination parameter
                );
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
    setState(() {
      _routeCoordinates.addAll(polylineCoordinates); // แก้ไขที่นี่
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: _routeCoordinates,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

  Set<Polyline> _polylines = {};
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _steps = [];
  Marker? _currentLocationMarker;
  late StreamSubscription<LocationData> _locationSubscription;

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
      setState(() {
        _currentPosition = LatLng(
          currentLocationData.latitude!,
          currentLocationData.longitude!,
        );
      });

      GoogleMapController controller =
          await _controller.future; // Added .future
      controller
          .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 16));

      Location().onLocationChanged.listen((LocationData locationData) {
        setState(() {
          _currentPosition =
              LatLng(locationData.latitude!, locationData.longitude!);
        });

        if (!_cameraMoved) {
          controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
          _cameraMoved = true;
        }

        // You'll need to provide a destination for this call
        if (_destinationLatLng != null) {
          // Add this check
          _fetchRouteFromApi(
              _currentPosition!, _destinationLatLng!, _destination);
        }
      });
    } else {
      print('Error: Cannot get current location');
    }
  }

  void _fetchRouteFromApi(
      LatLng currentPosition, LatLng destinationLatLng, String destination) {
    final routeController = RouteController(
      onRouteFetched: (polylineCoordinates, steps) {
        setState(() {
          _steps = List<Map<String, dynamic>>.from(steps);
          _polylines.clear();
          _addPolyline(polylineCoordinates);
        });
      },
    );

    routeController.fetchAndCalculateRoutes(
      currentPosition,
      destinationLatLng,
      destination,
    );
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

  Future<double> calculateTravelDuration(
      List<LatLng> polylineCoordinates, LatLng destinationLatLng) async {
    double totalDistance = 0.0;
    double walkingSpeed = 5.0;

    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      double distance = await Geolocator.distanceBetween(
        polylineCoordinates[i].latitude,
        polylineCoordinates[i].longitude,
        polylineCoordinates[i + 1].latitude,
        polylineCoordinates[i + 1].longitude,
      );
      totalDistance += distance;
    }

    double distanceToDestination = await Geolocator.distanceBetween(
      polylineCoordinates.last.latitude,
      polylineCoordinates.last.longitude,
      destinationLatLng.latitude,
      destinationLatLng.longitude,
    );
    totalDistance += distanceToDestination;

    double travelDuration = (totalDistance / 1000.0) / (walkingSpeed / 60.0);

    return travelDuration;
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

      LatLng lastPoint = polylineCoordinates.last;
      double distanceToDestination = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        destinationLatLng.latitude,
        destinationLatLng.longitude,
      );

      if (distanceToDestination < 10) {}
    } else {
      _panelController.close();
    }
  }

  void _showMenu() {
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
                title: Text('ห้องน้ำ'),
                onTap: () {
                  setState(() {
                    _markerController.addToiletMarkers(
                      (LatLng position) {
                        _categoryLocation('ห้องน้ำ 1', position);
                      },
                      BitmapDescriptor.defaultMarker,
                    );
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.food_bank),
                title: Text('จุดขายอาหารและเครื่องดื่ม'),
                onTap: () {
                  setState(() {
                    _markerController.addFoodMarkers((LatLng position) {
                      _categoryLocation('Food Location', position);
                    });
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

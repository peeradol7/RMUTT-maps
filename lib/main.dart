import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/MarkerController.dart';
import 'package:maps/OpenChat/Main.dart';
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
  List<LatLng> _polylineCoordinates = [];
  bool _hasShownArrivalDialog = false;
  late PanelController _panelController;
  bool _showPanel = false;
  double travelDuration = 0.0;
  bool _showCancelButton = false;
  LatLng? _currentPosition;
  LatLng? _destinationLatLng;
  Set<Polyline> _polylines = {};

  List<LatLng> _routeCoordinates = [];
  bool _cameraMoved = false;
  BitmapDescriptor userLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _toilet = BitmapDescriptor.defaultMarker;
  BitmapDescriptor toiletIcon = BitmapDescriptor.defaultMarker;
  late GoogleMapController mapController;
  final MarkerController _markerController = MarkerController();
  String _destination = '';
  StreamSubscription<Position>? _locationSubscription;
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
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _startLocationUpdates();
    } else {
      print('Location permission denied');
    }
  }

  void _startLocationUpdates() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Updates every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _updateUserMarker();
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
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    // กรองข้อมูลที่มี field namelocation และ match กับคำค้นหา
                    var filteredDocs = snapshot.data!.docs.where((doc) {
                      try {
                        // ตรวจสอบว่ามี field namelocation หรือไม่
                        if (!doc.data().containsKey('namelocation')) {
                          return false;
                        }

                        String locationName =
                            doc['namelocation'].toString().toLowerCase();
                        String searchQuery = _searchText.toLowerCase().trim();

                        // ถ้าไม่มีคำค้นหา ให้แสดงทั้งหมด
                        if (searchQuery.isEmpty) {
                          return true;
                        }

                        // ค้นหาแบบ contains
                        return locationName.contains(searchQuery);
                      } catch (e) {
                        // ถ้าเกิด error ในการเข้าถึงข้อมูล ให้ข้ามรายการนั้น
                        return false;
                      }
                    }).toList();

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        try {
                          // ตรวจสอบว่ามีข้อมูลครบหรือไม่
                          final doc = filteredDocs[index].data();
                          final hasRequiredFields =
                              doc.containsKey('namelocation') &&
                                  doc.containsKey('latitude') &&
                                  doc.containsKey('longitude') &&
                                  doc.containsKey('detail');

                          if (!hasRequiredFields) {
                            return ListTile(
                              title: Text('ข้อมูลไม่ครบถ้วน'),
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              var selectedLocation = doc['namelocation'];
                              var latitude = doc['latitude'];
                              var longitude = doc['longitude'];
                              var detail = doc['detail'];

                              LatLng destinationLatLng =
                                  LatLng(latitude, longitude);
                              setState(() {
                                _destinationLatLng = destinationLatLng;
                                _destination = selectedLocation;

                                _markerController.addMarker(
                                  id: 'destination_$index',
                                  position: destinationLatLng,
                                  title: selectedLocation,
                                  icon: BitmapDescriptor.defaultMarker,
                                  onTap: (LatLng tappedPosition) {
                                    _onMarkerTap(
                                        tappedPosition, selectedLocation);
                                  },
                                );
                              });

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
                                title: Text(doc['namelocation']),
                                subtitle: Text(doc['detail']),
                              ),
                            ),
                          );
                        } catch (e) {
                          return ListTile(
                            title: Text('เกิดข้อผิดพลาดในการแสดงข้อมูล'),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            )
        ],
      ),
    );
  }

  List<Marker> _markers = [];
  List<Map<String, dynamic>> _steps = [];

  double _travelDuration = 0.0;

  Future<void> showUserLocation() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );
      });

      GoogleMapController controller = await _controller.future;
      controller
          .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 15));

      StreamSubscription<Position> positionStream =
          Geolocator.getPositionStream(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
            timeLimit: Duration(seconds: 1)),
      ).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        if (!_cameraMoved) {
          controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
          _cameraMoved = true;
        }

        // Update route and check for arrival
        if (_destinationLatLng != null) {
          _updateRouteProgress(_currentPosition!, _destinationLatLng!);
        }
      });
    } catch (e) {
      print('Error: Cannot get current location - $e');
    }
  }

  int _findNextUnreachedStep(LatLng currentPosition) {
    final double stepThreshold =
        5.0; // meters - distance to consider a step reached

    for (int i = 0; i < _steps.length; i++) {
      final stepPoint = _steps[i]['point'] as LatLng;

      double distanceToStep = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        stepPoint.latitude,
        stepPoint.longitude,
      );

      if (distanceToStep > stepThreshold) {
        return i;
      }
    }

    return _steps.length - 1;
  }

  void _updateRouteProgress(LatLng currentPosition, LatLng destination) {
    if (_steps.isEmpty || _polylineCoordinates.isEmpty) return;

    int nextStepIndex = _findNextUnreachedStep(currentPosition);
    setState(() {
      if (nextStepIndex > 0 && nextStepIndex < _polylineCoordinates.length) {
        _polylineCoordinates = _polylineCoordinates.sublist(nextStepIndex);
        _updatePolyline();
      }
    });

    double distanceToDestination = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      destination.latitude,
      destination.longitude,
    );

    if (distanceToDestination <= 50 && !_hasShownArrivalDialog) {
      _showArrivalDialog();
      _hasShownArrivalDialog = true;
    }
  }

  void _updatePolyline() {
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: _polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    );
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ถึงจุดหมายแล้ว'),
          content: Text('คุณได้เดินทางมาถึงจุดหมายเรียบร้อยแล้ว'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear the route after arrival
                setState(() {
                  _polylines.clear();
                  _polylineCoordinates.clear();
                  _steps.clear();
                });
              },
              child: Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  bool _hasRequestedRoute = false;

  void _fetchRouteFromApiOnce(
      LatLng currentPosition, LatLng destinationLatLng, String destination) {
    if (_hasRequestedRoute) return;

    final routeController = RouteController(
      onRouteFetched: (polylineCoordinates, steps) {
        setState(() {
          _steps = List<Map<String, dynamic>>.from(steps);
          _polylines.clear(); // เคลียร์เส้นทางก่อน
          _addPolyline(polylineCoordinates); // เพิ่มเส้นทางใหม่
        });
      },
    );

    _hasRequestedRoute = true;

    routeController.fetchAndCalculateRoutes(currentPosition, destinationLatLng);
  }

  void _onMarkerTap(LatLng endLocation, String destination) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('แสดงเส้นทาง'),
          content: Text('ต้องการให้แสดงเส้นทางไปยัง $destination หรือไม่'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                if (_currentPosition != null) {
                  // Only fetch route when user confirms
                  _fetchRouteFromApiOnce(
                      _currentPosition!, endLocation, destination);
                }
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

  void _addPolyline(List<LatLng> polylineCoordinates) {
    _polylineCoordinates = polylineCoordinates; // Fixed variable name
    _updatePolyline();
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

    // Add to route coordinates
    setState(() {
      _routeCoordinates.addAll(polylineCoordinates);
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: _routeCoordinates,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

  _showMenu() {
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
                  // setState(() {
                  //   _markerController.addToiletMarkers(
                  //     (LatLng position) {
                  //       _categoryLocation('ห้องน้ำ 1', position);
                  //     },
                  //     BitmapDescriptor.defaultMarker,
                  //   );
                  // });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.food_bank),
                title: Text('จุดขายอาหารและเครื่องดื่ม'),
                onTap: () {
                  // setState(() {
                  //   _markerController.addFoodMarkers((LatLng position) {
                  //     _categoryLocation('Food Location', position);
                  //   });
                  // });
                  // Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:maps/DirectionController.dart';
import 'package:maps/MarkerController.dart';
import 'package:maps/OpenChat/Main.dart';
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

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  List<Marker> markers = [];
  String _searchText = '';
  String? _searchType = '';
  Marker? _userMarker;
  List<LatLng> _fullRoutePoints = [];
  double _remainingDistance = 0.0;
  bool _isNavigating = false;
  List<LatLng> _polylineCoordinates = [];
  bool _hasShownArrivalDialog = false;
  bool _walkMode = true;
  Stream<Position>? _locationStream;
  bool _carMode = false;
  late PanelController _panelController;
  bool _showPanel = false;
  double travelDuration = 0.0;
  bool _showCancelButton = false;
  LatLng? _currentPosition;
  LatLng? _destinationLatLng;
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;
  List<LatLng> _routeCoordinates = [];
  bool _cameraMoved = false;
  BitmapDescriptor userLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _toilet = BitmapDescriptor.defaultMarker;
  BitmapDescriptor toiletIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _parkingIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _faculty = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _foodIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _classroomIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _serviceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _libraryIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _atmIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _canteenIcon = BitmapDescriptor.defaultMarker;
  Timer? _routeUpdateTimer;
  StreamSubscription<Position>? _navigationLocationSubscription;
  bool _isRouteActive = false;
  Timer? _locationUpdateTimer;
  LatLng? _savedDestination;
  String? _routeDistance;
  String? _routeDuration;
  String? _savedDestinationName;

  BitmapDescriptor _sportIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _seven = BitmapDescriptor.defaultMarker;
  late GoogleMapController mapController;
  final MarkerController _markerController = MarkerController();
  String _destination = '';
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _steps = [];

  double _travelDuration = 0.0;
  StreamSubscription<Position>? _locationSubscription;
  List<LatLng> _currentPolylinePoints = [];
  @override
  void initState() {
    super.initState();
    _panelController = PanelController();
    _setMarkerIcon();
    _initializeIcons();
    _requestLocationPermission();
  }

  Future<void> _initializeIcons() async {
    _seven = await getResizedMarker('assets/iconCategory/seven.png', 125, 125);
    _atmIcon = await getResizedMarker('assets/iconCategory/atm.png', 125, 125);
    // _libraryIcon = await getResizedMarker('assets/iconCategory/Libra.png', width, height)
    _faculty =
        await getResizedMarker('assets/iconCategory/faculty.png', 125, 125);
  }

  Future<BitmapDescriptor> getResizedMarker(
      String assetPath, int width, int height) async {
    ByteData data = await rootBundle.load(assetPath);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    ByteData? resizedImage =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(resizedImage!.buffer.asUint8List());
  }

  void _showCategoryLocations(String locationType) async {
    setState(() {
      _markerController.clearMarkers(exceptId: 'currentLocation');
    });

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('rmuttlocations')
          .where('type', isEqualTo: locationType)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่พบข้อมูลสถานที่ประเภท $locationType')));
        return;
      }

      for (var i = 0; i < snapshot.docs.length; i++) {
        var doc = snapshot.docs[i];
        var data = doc.data();

        if (data.containsKey('latitude') &&
            data.containsKey('longitude') &&
            data.containsKey('namelocation')) {
          LatLng position = LatLng(data['latitude'], data['longitude']);

          BitmapDescriptor markerIcon;
          switch (locationType) {
            case 'ห้องน้ำ':
              markerIcon = _toilet;
              break;
            case 'จุดขายอาหารและเครื่องดื่ม':
              markerIcon = _foodIcon;
              break;
            case 'ห้องเรียน':
              markerIcon = _classroomIcon;
              break;
            case 'จุดบริการของมหาลัย':
              markerIcon = _serviceIcon;
              break;
            case 'ห้องสมุด':
              markerIcon = _libraryIcon;
              break;
            case 'ATM':
              markerIcon = _atmIcon;
              break;
            case 'โรงอาหาร':
              markerIcon = _canteenIcon;
              break;
            case 'สนามกีฬา':
              markerIcon = _sportIcon;
              break;
            case 'ลานจอดรถ':
              markerIcon = _parkingIcon;
              break;
            case 'เซเว่น':
              markerIcon = _seven;
              break;
            case 'ตึกคณะ/ภาควิชา':
              markerIcon = _faculty;
              break;
            default:
              markerIcon = BitmapDescriptor.defaultMarker;
          }

          setState(() {
            _markerController.addMarker(
              id: '${locationType}_${doc.id}',
              position: position,
              title: data['namelocation'],
              icon: markerIcon,
              onTap: (LatLng tappedPosition) {
                _onMarkerTap(tappedPosition, data['namelocation']);
              },
            );
          });
        }
        print('Seven Icon initialized: ${_seven != null}');
        print('ATM Icon initialized: ${_atmIcon != null}');
      }

      var firstDoc = snapshot.docs.first.data();
      var firstPosition = LatLng(firstDoc['latitude'], firstDoc['longitude']);

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(firstPosition, 16));
    } catch (e) {
      print('Error loading $locationType locations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถโหลดข้อมูล $locationType ได้')));
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    try {
      ByteData? data = await rootBundle.load(path);
      print('Successfully loaded asset: $path');
      ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
          targetWidth: width);
      ui.FrameInfo fi = await codec.getNextFrame();
      return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
    } catch (e) {
      print('Error loading asset $path: $e');
      throw e;
    }
  }

  Future<void> _setMarkerIcon() async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/Userlocation.png', 125);
    _markerIcon = BitmapDescriptor.fromBytes(markerIcon);

    final Uint8List toiletIcon =
        await getBytesFromAsset('assets/iconCategory/toilet1.png', 125);
    _toilet = BitmapDescriptor.fromBytes(toiletIcon);

    final Uint8List parkingIcon =
        await getBytesFromAsset('assets/iconCategory/parking.png', 110);
    _parkingIcon = BitmapDescriptor.fromBytes(parkingIcon);

    final Uint8List foodIcon =
        await getBytesFromAsset('assets/iconCategory/foodDrink.png', 125);
    _foodIcon = BitmapDescriptor.fromBytes(foodIcon);

    final Uint8List classroomIcon =
        await getBytesFromAsset('assets/iconCategory/classroom.png', 100);
    _classroomIcon = BitmapDescriptor.fromBytes(classroomIcon);

    final Uint8List serviceIcon =
        await getBytesFromAsset('assets/iconCategory/Service.png', 150);
    _serviceIcon = BitmapDescriptor.fromBytes(serviceIcon);

    final Uint8List libraryIcon =
        await getBytesFromAsset('assets/iconCategory/Libra.png', 125);
    _libraryIcon = BitmapDescriptor.fromBytes(libraryIcon);
    final Uint8List canteenIcon =
        await getBytesFromAsset('assets/iconCategory/canteen.png', 125);
    _canteenIcon = BitmapDescriptor.fromBytes(canteenIcon);

    final Uint8List sportIcon =
        await getBytesFromAsset('assets/iconCategory/sport.png', 125);
    _sportIcon = BitmapDescriptor.fromBytes(sportIcon);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationSubscription?.cancel();
    _routeUpdateTimer?.cancel();
    super.dispose();
  }

  static const CameraPosition university = CameraPosition(
    target: LatLng(14.03658958923885, 100.72790357867967),
    zoom: 16,
  );

  void searchTypeLocation(String query) {
    switch (query.toLowerCase()) {
      case 'ห้องเรียน':
        _searchType = 'ห้องเรียน';
        break;
      case 'ห้องน้ำ':
      case 'สุขา':
      case 'toilet':
        _searchType = 'ห้องน้ำ';
        break;
      case 'ซุ้ม':
        _searchType = 'จุดขายอาหาร';
      default:
        _searchType = null;
    }
  }

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
                searchTypeLocation(value);
              });
            },
            decoration: InputDecoration(
              hintText: 'ค้นหา',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchText = '';
                });
              },
            ),
          IconButton(
            icon: Icon(Icons.gps_fixed),
            onPressed: () {
              _requestLocationPermission();
            },
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
            mapType: MapType.satellite,
            markers: Set<Marker>.from(_markerController.markers)
              ..addAll([
                if (_currentPosition != null)
                  Marker(
                      markerId: MarkerId('currentLocation'),
                      position: _currentPosition!,
                      icon: _markerIcon),
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
          Positioned(
            left: 4.0,
            bottom: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Car mode switch
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _carMode = true;
                        _walkMode = false;
                        if (_currentPosition != null &&
                            _destinationLatLng != null) {
                          _polylines.clear();
                          directionApiFromgoogleApi(_currentPosition!,
                              _destinationLatLng!, _destination!);
                        }
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _carMode ? Colors.blue : Colors.white,
                        borderRadius:
                            BorderRadius.horizontal(left: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: _carMode ? Colors.white : Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'รถ',
                            style: TextStyle(
                              color: _carMode ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Walking mode switch
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _walkMode = true;
                        _carMode = false;
                        // If there's an active route, recalculate it
                        if (_currentPosition != null &&
                            _destinationLatLng != null) {
                          _polylines.clear();
                          _fetchRouteFromApiOnce(_currentPosition!,
                              _destinationLatLng!, _destination!);
                          _startPeriodicRouteUpdates();
                        }
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _walkMode ? Colors.blue : Colors.white,
                        borderRadius:
                            BorderRadius.horizontal(right: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            color: _walkMode ? Colors.white : Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'เดิน',
                            style: TextStyle(
                              color: _walkMode ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_polylines.isNotEmpty)
            SlidingUpPanel(
              controller: _panelController,
              minHeight: 60.0,
              maxHeight: 60.0,
              isDraggable: false, // ปิดการลาก
              color: Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
              panel: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _polylines.clear();
                            _showCancelButton = false;
                            _markers.clear();
                            _showPanel = false;
                            _cancelRoute();
                            // ยกเลิกการอัพเดตเส้นทางแบบ periodic
                            _routeUpdateTimer?.cancel();
                            _routeUpdateTimer = null;

                            // รีเซ็ตสถานะอื่น ๆ ที่เกี่ยวข้องกับเส้นทางถ้าจำเป็น
                            _isLoadingRoute = false;
                            _steps.clear();
                          });
                        },
                        child: Center(
                          child: Text('ยกเลิกการแสดงเส้นทาง'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_markerController.markers.isNotEmpty &&
              !(_markerController.markers.length == 1 &&
                  _markerController.markers.first.markerId.value ==
                      'currentLocation') &&
              _polylines.isEmpty)
            Positioned(
              top: 5,
              right: 16.0,
              child: SizedBox(
                width: 100.0,
                height: 35,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _markerController.clearMarkers(
                          exceptId: 'currentLocation');
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
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('rmuttlocations')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  try {
                    if (!doc.data().containsKey('namelocation') ||
                        !doc.data().containsKey('type')) {
                      return false;
                    }

                    String locationName =
                        doc['namelocation'].toString().toLowerCase();
                    String locationType = doc['type'].toString().toLowerCase();
                    String searchQuery = _searchText.toLowerCase().trim();

                    if (_searchType != null) {
                      return locationType == _searchType;
                    } else {
                      return locationName.contains(searchQuery);
                    }
                  } catch (e) {
                    return false;
                  }
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Container();
                }

                return Positioned(
                  top: 0,
                  left: 16.0,
                  right: 16.0,
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        try {
                          final doc = filteredDocs[index].data();
                          final hasRequiredFields =
                              doc.containsKey('namelocation') &&
                                  doc.containsKey('latitude') &&
                                  doc.containsKey('longitude') &&
                                  doc.containsKey('detail');

                          if (!hasRequiredFields) {
                            return ListTile(
                              title: Text('ข้อมูลไม่ครบถ้วน'),
                              tileColor: Colors.grey[100],
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
                              margin: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  doc['namelocation'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  doc['detail'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          return ListTile(
                            title: Text('เกิดข้อผิดพลาดในการแสดงข้อมูล'),
                            tileColor: Colors.red[50],
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    startTrackingLocation();
  }

  void _updateRouteProgress(LatLng currentPosition, LatLng destination) {
    if (_steps.isEmpty || _polylineCoordinates.isEmpty) {
      print('DEBUG: Steps or polyline coordinates are empty');
      return;
    }

    final double passThreshold = 30.0;
    final double arrivalThreshold = 10.0;

    int closestPolylineIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < _polylineCoordinates.length; i++) {
      double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _polylineCoordinates[i].latitude,
        _polylineCoordinates[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestPolylineIndex = i;
      }
    }

    if (minDistance <= passThreshold) {
      setState(() {
        // Update passed steps
        for (var step in _steps) {
          if (step['start_index'] <= closestPolylineIndex) {
            step['passed'] = true;
          }
        }

        if (closestPolylineIndex < _polylineCoordinates.length - 1) {
          _polylineCoordinates =
              _polylineCoordinates.sublist(closestPolylineIndex);
          final int offset = closestPolylineIndex;
          for (var step in _steps) {
            if (!step['passed']) {
              int newStartIndex = (step['start_index'] as int) - offset;
              step['start_index'] = newStartIndex < 0 ? 0 : newStartIndex;

              int newEndIndex = (step['end_index'] as int) - offset;
              step['end_index'] = newEndIndex < 0 ? 0 : newEndIndex;
              step['coordinates'] =
                  (step['coordinates'] as List<LatLng>).where((coord) {
                int coordIndex = _polylineCoordinates.indexOf(coord);
                return coordIndex != -1;
              }).toList();
            }
          }
        }
      });
    }

    // Check for arrival
    double distanceToDestination = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      destination.latitude,
      destination.longitude,
    );

    if (distanceToDestination <= arrivalThreshold && !_hasShownArrivalDialog) {
      _showArrivalDialog();
      _hasShownArrivalDialog = true;
      stopTrackingLocation();
    }
  }

  void resetRouteRequest() {
    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = null;
    _savedDestination = null;
    _savedDestinationName = null;

    setState(() {
      _hasRequestedRoute = false;
      _polylines.clear();
      _steps.clear();
    });
  }

  bool _hasRequestedRoute = false;

  void _fetchRouteFromApiOnce(LatLng currentPosition, LatLng destinationLatLng,
      String destination) async {
    if (_isLoadingRoute || !_isRouteActive) return;

    setState(() {
      _isLoadingRoute = true;
    });

    if (_isRouteActive) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition, 20),
      );
    }

    final directionController = DirectionController(
      onRouteFetched: (polylineCoordinates, steps) {
        if (_shouldUpdatePolyline(polylineCoordinates) && _isRouteActive) {
          setState(() {
            // Cast the steps to the correct type
            _steps =
                steps.map((step) => Map<String, dynamic>.from(step)).toList();
            _updatePolylineSmoothly(polylineCoordinates);
            _currentPolylinePoints = polylineCoordinates;
            _isLoadingRoute = false;
          });
        } else {
          setState(() {
            _isLoadingRoute = false;
          });
        }
      },
      onArrivalDetected: () {
        _handleArrival();
      },
    );

    try {
      if (_isRouteActive) {
        await directionController.fetchAndCalculateRoutes(
          currentPosition,
          destinationLatLng,
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
      });
      print('Error in _fetchRouteFromApiOnce: $e');
    }
  }

  bool _shouldUpdatePolyline(List<LatLng> newPolylinePoints) {
    if (_currentPolylinePoints.isEmpty) return true;

    // เปรียบเทียบจุดเริ่มต้นและจุดสิ้นสุดของเส้นทาง
    double startPointDiff = Geolocator.distanceBetween(
      _currentPolylinePoints.first.latitude,
      _currentPolylinePoints.first.longitude,
      newPolylinePoints.first.latitude,
      newPolylinePoints.first.longitude,
    );

    double endPointDiff = Geolocator.distanceBetween(
      _currentPolylinePoints.last.latitude,
      _currentPolylinePoints.last.longitude,
      newPolylinePoints.last.latitude,
      newPolylinePoints.last.longitude,
    );

    // อัปเดตเฉพาะเมื่อมีความแตกต่างที่มากพอ
    return startPointDiff > 5 || endPointDiff > 5;
  }

  void startRouteTracking(LatLng currentPosition, LatLng destinationLatLng) {
    startTrackingLocation(); // เริ่มติดตามตำแหน่งปัจจุบัน
    startPeriodicRouteUpdates(
        currentPosition, destinationLatLng); // เริ่มอัปเดตเส้นทาง
  }

  void startPeriodicRouteUpdates(
      LatLng currentPosition, LatLng destinationLatLng) {
    _routeUpdateTimer?.cancel(); // ยกเลิก Timer เดิมถ้ามี
    _routeUpdateTimer = Timer.periodic(Duration(seconds: 2), (_) {
      _fetchRouteFromApiOnce(currentPosition, destinationLatLng, 'Destination');
    });
  }

  void stopRouteTracking() {
    stopTrackingLocation(); // หยุดติดตามตำแหน่งปัจจุบัน
    _routeUpdateTimer?.cancel(); // หยุดการอัปเดตเส้นทาง
  }

  void startTrackingLocation() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      if (!_cameraMoved) {
        _moveCameraToPosition(_currentPosition!);
        _cameraMoved = true;
      }

      if (_destinationLatLng != null) {
        _updateRouteProgress(_currentPosition!, _destinationLatLng!);
      }
    });
  }

  void stopTrackingLocation() {
    _locationSubscription?.cancel();
  }

  void _updatePolylineSmoothly(List<LatLng> newPolylinePoints) {
    final Polyline newPolyline = Polyline(
      polylineId: PolylineId('route'),
      points: newPolylinePoints,
      color: Colors.blue,
      width: 5,
    );

    setState(() {
      _polylines.clear();
      _polylines.add(newPolyline);
    });
  }

  void _moveCameraToPosition(LatLng position) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 18));
  }

  void _startPeriodicRouteUpdates() {
    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_currentPosition != null && _savedDestination != null) {
        _fetchRouteFromApiOnce(
            _currentPosition!, _savedDestination!, _savedDestinationName ?? '');
      }
    });
  }

  void _cancelRoute() {
    setState(() {
      _polylines.clear();
      _showCancelButton = false;
      _markers.clear();
      _showPanel = false;
      _steps.clear();

      _isRouteActive = false;
      _isLoadingRoute = false;
      _isNavigating = false;

      _routeUpdateTimer?.cancel();
      _routeUpdateTimer = null;
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = null;
      _locationSubscription?.cancel();

      _currentPolylinePoints = [];
      _fullRoutePoints = [];
      _savedDestination = null;
      _savedDestinationName = null;
    });
  }

  void _onMarkerTap(LatLng endLocation, String destination) {
    if (_isLoadingRoute) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('แสดงเส้นทาง'),
          content: Text('ต้องการให้แสดงเส้นทางไปยัง $destination หรือไม่'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (_currentPosition != null) {
                  _savedDestination = endLocation;
                  _savedDestinationName = destination;
                  _isRouteActive = true;

                  // Lock camera to current location with zoom level 20
                  final GoogleMapController controller =
                      await _controller.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 20),
                  );

                  if (_walkMode) {
                    _fetchRouteFromApiOnce(
                        _currentPosition!, endLocation, destination);
                    _startPeriodicRouteUpdates();
                  } else {
                    directionApiFromgoogleApi(
                        _currentPosition!, endLocation, destination);
                  }
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

  List<List<double>> decodePolyline(String encoded) {
    List<List<double>> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add([lat / 1E5, lng / 1E5]);
    }

    return poly;
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

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
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
                    Navigator.pop(context);
                    _showCategoryLocations('ห้องน้ำ');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.food_bank),
                  title: Text('จุดขายอาหารและเครื่องดื่ม'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('จุดขายอาหารและเครื่องดื่ม');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.class_),
                  title: Text('ห้องเรียน'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('ห้องเรียน');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.room_service),
                  title: Text('จุดบริการของมหาลัย'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('จุดบริการของมหาลัย');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.library_books),
                  title: Text('ห้องสมุด'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('ห้องสมุด');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.atm),
                  title: Text('ตู้ ATM'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('ATM');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.restaurant),
                  title: Text('โรงอาหาร'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('โรงอาหาร');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.sports_soccer),
                  title: Text('สนามกีฬา'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('สนามกีฬา');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_parking),
                  title: Text('ลานจอดรถ'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('ลานจอดรถ');
                  },
                ),
                ListTile(
                  leading: Image.asset(
                    'assets/7-11.png',
                    width: 24,
                    height: 24,
                  ),
                  title: Text('7-11'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('เซเว่น');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.school),
                  title: Text('ตึกคณะ/ภาควิชา'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryLocations('ตึกคณะ/ภาควิชา');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> directionApiFromgoogleApi(
      LatLng origin, LatLng destination, String destinationName) async {
    if (!_isRouteActive) return;

    setState(() {
      _isLoadingRoute = true;
      _showPanel = true;
      _isNavigating = true;
    });

    try {
      final String apiKey = 'AIzaSyBiBXvhX4YenKelpFUA30_R5p_OVkbHy8o';
      final String baseUrl =
          'https://maps.googleapis.com/maps/api/directions/json';
      final response = await http.get(
        Uri.parse('$baseUrl?'
            'origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&mode=driving'
            '&language=th'
            '&key=$apiKey'),
      );

      if (response.statusCode == 200 && _isRouteActive) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['status'] == 'OK') {
          setState(() {
            _polylines.clear();
            _steps.clear();
          });

          final route = decodedResponse['routes'][0];
          final leg = route['legs'][0];
          String encodedPoints = route['overview_polyline']['points'];
          _fullRoutePoints = decodePolyline(encodedPoints)
              .map((point) => LatLng(point[0], point[1]))
              .toList();

          updateRoutePolyline(_fullRoutePoints);
          startTrackingLocation2();

          final GoogleMapController controller = await _controller.future;
          // Update zoom level to 20
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 20),
          );

          setState(() {
            _routeDistance = leg['distance']['text'];
            _routeDuration = leg['duration']['text'];
            _isLoadingRoute = false;
          });
        }
      }
    } catch (e) {
      handleDirectionError(e);
    }
  }

// Add this new method to keep the camera centered on current location
  void _keepCameraCentered() async {
    if (_isRouteActive && _currentPosition != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 20),
      );
    }
  }

  int findClosestPointOnRoute(LatLng currentPosition) {
    int closestIndex = 0;
    double closestDistance = double.infinity;

    for (int i = 0; i < _fullRoutePoints.length; i++) {
      double distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        _fullRoutePoints[i].latitude,
        _fullRoutePoints[i].longitude,
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  double calculateRemainingDistance(List<LatLng> points) {
    double distance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      distance += calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return distance;
  }

// Update polyline on map
  void updateRoutePolyline(List<LatLng> points) {
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue,
          width: 5,
        ),
      );
    });
  }

  void handleDirectionError(dynamic error) {
    setState(() {
      _isLoadingRoute = false;
      _isNavigating = false;
    });

    print('Error fetching directions: $error');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ข้อผิดพลาด'),
        content: Text('ไม่สามารถดึงข้อมูลเส้นทางได้ กรุณาลองใหม่อีกครั้ง'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _handleArrival() {
    if (!_isRouteActive) return;

    _cancelRoute();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ถึงจุดหมายแล้ว'),
        content: Text('คุณได้เดินทางมาถึงจุดหมายแล้ว'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  void startTrackingLocation2() {
    _navigationLocationSubscription?.cancel();
    _navigationLocationSubscription =
        _locationStream?.listen((Position position) async {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      if (_isRouteActive) {
        _keepCameraCentered();
      }
    });
  }

  void updateNavigationProgress2() async {
    if (_currentPosition == null || _fullRoutePoints.isEmpty) return;

    int closestPointIndex = findClosestPointOnRoute(_currentPosition!);

    List<LatLng> remainingPoints = _fullRoutePoints.sublist(closestPointIndex);

    updateRoutePolyline(remainingPoints);

    _remainingDistance = calculateRemainingDistance(remainingPoints);

    if (_remainingDistance < 20) {
      _handleArrival();
    }
    if (!_cameraMoved) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    }
  }
}

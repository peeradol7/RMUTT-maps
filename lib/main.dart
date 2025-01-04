import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  List<Marker> markers = [];
  String _searchText = '';
  String? _searchType = '';
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
  bool _isLoadingRoute = false;
  List<LatLng> _routeCoordinates = [];
  bool _cameraMoved = false;
  BitmapDescriptor userLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _toilet = BitmapDescriptor.defaultMarker;
  BitmapDescriptor toiletIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _parkingIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _foodIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _classroomIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _serviceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _libraryIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _atmIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _canteenIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _sportIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _seven = BitmapDescriptor.defaultMarker;
  late GoogleMapController mapController;
  final MarkerController _markerController = MarkerController();
  String _destination = '';
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _steps = [];
  double _travelDuration = 0.0;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _panelController = PanelController();
    _setMarkerIcon();
    _initializeIcons();
  }

  Future<void> _initializeIcons() async {
    _seven = await getResizedMarker('assets/iconCategory/seven.png', 125, 125);
    _atmIcon = await getResizedMarker('assets/iconCategory/atm.png', 125, 125);
    // _libraryIcon = await getResizedMarker('assets/iconCategory/Libra.png', width, height)
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
          // IconButton(
          //   icon: Icon(Icons.gps_fixed),
          //   onPressed: showUserLocation,
          // ),
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
            markers: Set<Marker>.from(
                _markerController.markers), // คงการใช้งาน markers อื่นๆ หากมี
            indoorViewEnabled: true,
            myLocationButtonEnabled: true, // แสดงปุ่มตำแหน่งปัจจุบัน
            myLocationEnabled: true, // แสดงตำแหน่งปัจจุบันบนแผนที่
            initialCameraPosition: university,
            polylines: _polylines,
            trafficEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          if (_polylines.isNotEmpty)
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
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _polylines.clear();
                            _showCancelButton = false;
                            _markers.clear();
                            _showPanel = false;
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

  Future<void> showUserLocation() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );
      });

      GoogleMapController controller = await _controller.future;
      controller
          .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 18));

      StreamSubscription<Position> positionStream =
          Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
          timeLimit: Duration(seconds: 1),
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        if (!_cameraMoved) {
          controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
          _cameraMoved = true;
        }

        if (_destinationLatLng != null) {
          _updateRouteProgress(_currentPosition!, _destinationLatLng!);
        }
      });
    } catch (e) {
      print('Error: Cannot get current location - $e');
    }
  }

  int _findNextUnreachedStep(LatLng currentPosition) {
    final double stepThreshold = 5.0;

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

  void _fetchRouteFromApiOnce(LatLng currentPosition, LatLng destinationLatLng,
      String destination) async {
    if (_isLoadingRoute) return;
    setState(() {
      _isLoadingRoute = true;
      _polylines.clear();
      _steps.clear();
    });
    final directionController = DirectionController(
      onRouteFetched: (polylineCoordinates, steps) {
        setState(() {
          _steps = List<Map<String, dynamic>>.from(steps);
          _addPolyline(polylineCoordinates);
          _isLoadingRoute = false;
        });
      },
    );
    await directionController.fetchAndCalculateRoutes(
        currentPosition, destinationLatLng);
  }

  void resetRouteRequest() {
    setState(() {
      _hasRequestedRoute = false;
      _polylines.clear();
      _steps.clear();
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_currentPosition != null) {
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
              ],
            ),
          ),
        );
      },
    );
  }
}

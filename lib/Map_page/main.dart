import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/DirectionController.dart';
import 'package:maps/DirectionService.dart';
import 'package:maps/MarkerController.dart';
import 'package:maps/OpenChat/Main.dart';
import 'package:maps/Survey.dart';
import 'package:maps/locationontap.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../MapboxDirectionService.dart';
import '../OpenChat/ChatScreen.dart';
import '../OpenChat/sharepreferenceservice.dart';

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MapSample(),
        title: 'RMUTT Nav',
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
  bool _hasArrived = false;
  List<LatLng> _fullRoutePoints = [];
  double _remainingDistance = 0.0;
  bool _isNavigating = false;
  List<LatLng> _polylineCoordinates = [];
  bool _hasShownArrivalDialog = false;
  Timer? _timer;
  Stream<Position>? _locationStream;
  late PanelController _panelController;
  bool _showPanel = false;
  double travelDuration = 0.0;
  bool _showCancelButton = false;
  LatLng? _currentPosition;
  LatLng? _destinationLatLng;
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;
  RouteTrackingService? _routeTrackingService;
  List<LatLng> _currentRoute = [];
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
  bool _isRouteActive = false;
  bool _hasRequestedRoute = false;
  Timer? _locationUpdateTimer;
  LatLng? _savedDestination;
  String? _savedDestinationName;

  LatLng? _endLocation;
  final QuestionnaireDialogHelper questionnaire = QuestionnaireDialogHelper();
  BitmapDescriptor _sportIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _seven = BitmapDescriptor.defaultMarker;
  late GoogleMapController mapController;
  MapboxDirectionService _service = MapboxDirectionService();
  final MarkerController _markerController = MarkerController();
  String _destination = '';
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _steps = [];
  late LatLng newPosition;
  StreamSubscription<Position>? _locationSubscription;
  List<LatLng> _currentPolylinePoints = [];
  late SharedPreferencesService _pref;
  @override
  void initState() {
    super.initState();
    _panelController = PanelController();
    _setMarkerIcon();
    _initializeIcons();
    _initPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission(context);
    });
  }

// เรียก Instance ของ  SharedPreferences
  Future<void> _initPreferences() async {
    _pref = await SharedPreferencesService.getInstance();
  }

//โหลดไอคอนของหมวดหมู่ บางตัวที่ฟังชัน _showCategoryLocations ไม่สามารถแสดงออกมาได้
  Future<void> _initializeIcons() async {
    _seven = await getResizedMarker('assets/iconCategory/seven.png', 125, 125);
    _atmIcon = await getResizedMarker('assets/iconCategory/atm.png', 125, 125);
    _faculty =
        await getResizedMarker('assets/iconCategory/faculty.png', 125, 125);
  }

  //โหลดข้อมูลรูป
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

  //ฟังชันสำหรับ ZOOM เข้า
  Future<void> zoom(LatLng destinationLatLng) async {
    final GoogleMapController? mapController = await _controller.future;
    if (mapController == null) {
      debugPrint('MapController is not initialized yet.');
      return;
    }
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(destinationLatLng, 18.0),
    );
  }

//ฟังชันสำหรับแสดงหมวดหมู่สถานที่
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

  // โหลดรูปภาพ (เวอร์ชันเก่า)
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    try {
      ByteData? data = await rootBundle.load(path);

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

//เซ็ท Icon ของ Marker id ต่า่งๆ
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
  //ฟังชันสำหรับแสดง type Location ทั้งหมด เมื่อค้นหาบน TextField
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

//ฟังชันสำหรับ เข้าระบบ Community ถ้าข้อมูลไม่อยู่ใน Key ของ getStoredUserData ก็จะไปหน้าของ WelcomeScreen
  Future<void> handleChat(BuildContext context) async {
    try {
      final storedUid = await _pref.getStoredUid();

      if (storedUid != null && storedUid.isNotEmpty) {
        final userData = await _pref.getStoredUserData();

        if (!context.mounted) {
          print('Context not mounted');
          return;
        }

        if (userData != null && userData.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(),
            ),
          );
          return;
        } else {
          print('User data is empty');
        }
      } else {
        print('No valid UID found');
      }

      if (!context.mounted) {
        print('Context not mounted');
        return;
      }

      print('Navigating to LoginScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(),
        ),
      );
    } catch (e) {
      print('Error in login process: $e');
      print('Stack trace: ${StackTrace.current}');
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
              zoom(_currentPosition!);
              _requestLocationPermission(context);
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
                handleChat(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.assessment),
              onPressed: () {
                QuestionnaireDialogHelper.show(context);
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
            ),
          ),
          if (_polylines.isNotEmpty)
            Positioned(
              bottom: 3.0,
              left: 175,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _polylines.clear();
                      _showCancelButton = false;
                      _markers.clear();
                      _showPanel = false;
                      _cancelRoute();
                      _routeUpdateTimer?.cancel();
                      _routeUpdateTimer = null;
                      _timer?.cancel();
                      _isLoadingRoute = false;
                      _steps.clear();
                    });
                  },
                  child: Text(
                    'ยกเลิกการแสดงเส้นทาง',
                    style: TextStyle(fontSize: 13.5),
                  ),
                ),
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
          //ค้นหาชื่อสถานที่โดยเอา Container มาวางในจุด ของ Positioned
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
                            onTap: () async {
                              var selectedLocation = doc['namelocation'];
                              var latitude = doc['latitude'];
                              var longitude = doc['longitude'];
                              var detail = doc['detail'];
                              LatLng destinationLatLng =
                                  LatLng(latitude, longitude);
                              zoom(destinationLatLng);
                              setState(() {
                                _destinationLatLng = destinationLatLng;
                                _destination = selectedLocation;

                                _markerController.addMarker(
                                  id: 'destination_$index',
                                  position: destinationLatLng,
                                  title: selectedLocation,
                                  icon: BitmapDescriptor.defaultMarker,
                                  onTap: (LatLng tappedPosition) {
                                    _markers.clear();
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

//ขอสิทธิ์เข้าถึง GPS
  Future<void> _requestLocationPermission(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // แจ้งให้ผู้ใช้เปิด GPS
        _showGPSDialog(context);
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // เริ่มติดตามตำแหน่ง
      startTrackingLocation();
    } catch (e) {
      print("เกิดข้อผิดพลาด: $e");
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

  void _showGPSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('กรุณาเปิด GPS'),
          content: Text('กรุณาเปิด GPS บนอุปกรณ์ของคุณ'),
          actions: <Widget>[
            TextButton(
              child: Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Dialog
              },
            ),
          ],
        );
      },
    );
  }

//แสดง Error ของโหมดเดินว่า ไม่ได้อยู่ในมหาลัย
  void showErrorWalkError() {
    if (!mounted) return; // ตรวจสอบว่าหน้ายังอยู่
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('ไม่สามารถแสดงเส้นทางได้'),
          content: Text('ต้องอยู่ในบริเวณมหาวิทยาลัยเท่านั้น'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _cancelRoute();
                });
              },
              child: Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  // Fetch เส้นทางจาก API โหมดเดิน
  void _fetchRouteFromApiOnce(LatLng currentPosition, LatLng destinationLatLng,
      String destination) async {
    if (_isLoadingRoute || !_isRouteActive) return;
    print('_isRouteActive: $_isRouteActive');

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
    // ถ้า อยู่นอกมหาลัยจะแสดง Error Dialog
    try {
      if (_isRouteActive) {
        await directionController.fetchAndCalculateRoutes(
          currentPosition,
          destinationLatLng,
        );
      }
      showErrorWalkError();
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
      });
      print('Error in _fetchRouteFromApiOnce: $e');
    }
  }

//อัพเดท Polyline
  bool _shouldUpdatePolyline(List<LatLng> newPolylinePoints) {
    if (_currentPolylinePoints.isEmpty) return true;

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

    return startPointDiff > 5 || endPointDiff > 5;
  }

// Tracking จุด _currentPosition
  void startTrackingLocation() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        //ความแม่นยำ = best distanceFilter คือ การอัพเดทจุด GPS ทุกๆ2เมตร
        accuracy: LocationAccuracy.best,
        distanceFilter: 2,
      ),
    ).listen((Position position) async {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      if (!_cameraMoved) {
        zoom(_currentPosition!);
        _cameraMoved = true;
      }
    }, onError: (error) {
      print("เกิดข้อผิดพลาดใน Position Stream: $error");
    });
  }

  // _updatePolyline();
  Future<void> updateRoute() async {
    if (_currentPosition == null || _endLocation == null) return;

    try {
      List<LatLng> newRoute = await DirectionService.getRoute(
          _currentPosition!, _endLocation!, 'Destination');

      if (newRoute.isNotEmpty) {
        if (_polylines.isEmpty || _polylines.first.points != newRoute) {
          setState(() {
            _polylines = {
              Polyline(
                polylineId: PolylineId('route'),
                points: newRoute,
                color: Colors.blue,
                width: 5,
                geodesic:
                    true, // เพิ่มบรรทัดนี้หากต้องการให้เส้นทางมีลักษณะโค้ง
              )
            };
          });
        }
      }
    } catch (e) {
      print('Error updating route: $e');
    }
  }

// อัพเดท Polyline แต่ไม่มั่นใจว่าฟังชันนี้ต้องใช้มั้ย (ยังไม่ลบออกและเทส)
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

//ฟังชันสำหรับ Call API ทุกๆ 2 วินาที
  void _startPeriodicRouteUpdates() {
    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_currentPosition != null && _savedDestination != null) {
        _fetchRouteFromApiOnce(
            _currentPosition!, _savedDestination!, _savedDestinationName ?? '');
      }
    });
  }

//ฟังชันบสำหรับเคลียร์ทุกอย่างที่เกี่ยวกับแผนที่
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

//วาดเส้น polyline
  void _drawRoutePolyline(List<List<double>> coordinates) {
    if (coordinates.isEmpty) {
      print('No coordinates to draw.');
      return;
    }

    final List<LatLng> points =
        coordinates.map((coord) => LatLng(coord[0], coord[1])).toList();

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: points,
          color: Colors.blue,
          width: 5,
        ),
      );
    });

    print('Polyline added: ${_polylines.length}');
  }

  //ฟังชันสำหรับแสดง Dialog เมื่อกดจุดมาร์ค
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

                  final GoogleMapController controller =
                      await _controller.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 20),
                  );

                  startUpdatingRoute(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    endLocation.latitude,
                    endLocation.longitude,
                    (routeCoordinates) {
                      if (routeCoordinates.isEmpty) {
                        _showArrivalDialog();
                        stopUpdatingRoute();
                      } else {
                        setState(() {
                          _drawRoutePolyline(routeCoordinates);
                        });
                      }
                    },
                  );
                }
              },
              child: Text('เดินทางด้วยรถ'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (_currentPosition != null) {
                  _savedDestination = endLocation;
                  _savedDestinationName = destination;
                  _isRouteActive = true;
                  final GoogleMapController controller =
                      await _controller.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 20),
                  );
                  _fetchRouteFromApiOnce(
                      _currentPosition!, endLocation, destination);
                  _startPeriodicRouteUpdates();
                }
              },
              child: Text('เดินทางด้วยการเดิน'),
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

  // Update เส้นทางหมวดรถที่Call Api มาจาก MapBox Direction Api เรียกทุกๆ2วินาทีและอัพเดทเมื่อ currentPosition เปลี่ยนพิกัด
  Future<void> startUpdatingRoute(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      Function(List<List<double>>) onUpdate) async {
    LatLng? _lastPosition;
    _isRouteActive = true;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 20),
      );
      try {
        if (_currentPosition == null) return;

        bool hasLocationChanged = _lastPosition == null ||
            (calculateDistance(
                    _lastPosition!.latitude,
                    _lastPosition!.longitude,
                    _currentPosition!.latitude,
                    _currentPosition!.longitude) >
                5);

        if (hasLocationChanged) {
          final routeCoordinates = await _service.getDirections(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            endLat,
            endLng,
          );

          _lastPosition = _currentPosition;

          onUpdate(routeCoordinates);
        }
      } catch (e) {
        print('Error updating route: $e');
      }
    });
  }

  void stopUpdatingRoute() {
    _timer?.cancel();
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

// Widget สำหรับแสดง หมวดหมู่สถานที่
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
    const R = 6371e3;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }
}

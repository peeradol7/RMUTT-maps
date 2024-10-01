import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MenuPage extends StatelessWidget {
  final Function(BuildContext, String, LatLng, double) onTap;
  final Completer<GoogleMapController> controller;

  MenuPage({required this.onTap, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เมนู'),
      ),
      body: ListView(
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
            onTap: () => _onMenuItemTap(
              context,
              'ห้องน้ำ',
              LatLng(14.035978558473701, 100.72472173847785),
              BitmapDescriptor.hueAzure,
            ),
          ),
          ListTile(
            leading: Icon(Icons.food_bank),
            title: Text(
              'จุดขายอาหารและเครื่องดื่ม',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Color.fromARGB(255, 251, 255, 7),
              ),
            ),
            onTap: () => _onMenuItemTap(
              context,
              'โรงอาหารกลาง',
              LatLng(14.03529495057221, 100.72439570609433),
              BitmapDescriptor.hueYellow,
            ),
          ),
          ListTile(
            leading: Icon(Icons.directions_car),
            title: Text('ลานจอดรถ'),
            onTap: () async {
              final GoogleMapController mapController = await controller.future;
              mapController.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(14.03658958923885, 100.72790357867967),
                  zoom: 16,
                ),
              ));
              onTap(
                context,
                "ลานจอดรถ",
                LatLng(14.03658958923885, 100.72790357867967),
                BitmapDescriptor.hueAzure,
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _onMenuItemTap(
      BuildContext context, String title, LatLng position, double hue) {
    onTap(context, title, position, hue);
  }
}

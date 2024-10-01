import 'package:flutter/material.dart';

void textFieldOnTap(TextEditingController searchController,
    String selectedLocation, Function setState, String searchText) {
  searchController.text = selectedLocation;
  setState(() {
    searchText = selectedLocation;
  });
}

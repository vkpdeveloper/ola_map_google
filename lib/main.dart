import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_ola/location_details.dart';
import 'package:maps_ola/location_result.dart';
import 'package:maps_ola/uuid.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Maps OLA",
      theme: ThemeData.light(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController _googleMapController;
  PanelController _controller;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLocalSelected = true;
  bool isOutSideSelected = false;
  LatLng initLatLng;
  TextEditingController _pickUpController;
  TextEditingController _destinationController;
  bool isPanelOpenComplete = false;
  FocusNode _pickFocusNode = FocusNode();
  FocusNode _mainFocusNode = FocusNode();
  String mainAddress;
  Timer _debounce;
  bool hasSearchTerm = false;
  bool isSearchingCurrently = false;
  String searchVal = "";
  String googleMapsAPIKeys = "AIzaSyCHySMHG-mV2kq1pYGqgw2B6OAK-9xbOxk";
  LocationResult locationResult;
  String sessionToken = Uuid().generateV4();
  List<LocationDetails> allLocations = [];
  Set<Polyline> _polyLines = {};

  getCurrentLocation() async {
    bool status = Geolocator().forceAndroidLocationManager;
    print(status);
    Geolocator()
        .checkGeolocationPermissionStatus()
        .then((GeolocationStatus status) {
      print(status);
    });
    Geolocator().getCurrentPosition().then((value) async {
      List<Address> allAddresses = await Geocoder.local
          .findAddressesFromCoordinates(
              Coordinates(value.latitude, value.longitude));
      setState(() {
        initLatLng = LatLng(value.latitude, value.longitude);
        mainAddress = allAddresses[0].addressLine;
        print(mainAddress);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = PanelController();
    _pickUpController = TextEditingController();
    _destinationController = TextEditingController();
    _pickUpController.addListener(_onSearchChangedPickUp);
    _destinationController.addListener(_onSearchChangedDrop);
    getCurrentLocation();
  }

  _onSearchChangedPickUp() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlace(_pickUpController.text);
    });
  }

  _onSearchChangedDrop() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlace(_destinationController.text);
    });
  }

  void searchPlace(String place) {
    if (_scaffoldKey.currentContext == null) return;

    setState(() => hasSearchTerm = place.length > 0);

    if (place.length < 1) return;

    setState(() {
      isSearchingCurrently = true;
      searchVal = "Searching locations...";
    });

    autoCompleteSearch(place);
  }

  void autoCompleteSearch(String place) {
    place = place.replaceAll(" ", "+");
    var endpoint =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?" +
            "key=${googleMapsAPIKeys}&" +
            "input={$place}&sessiontoken=$sessionToken";

    if (locationResult != null) {
      endpoint += "&location=${locationResult.latLng.latitude}," +
          "${locationResult.latLng.longitude}";
    }
    http.get(endpoint).then((response) {
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> predictions = data['predictions'];
        allLocations.clear();
        if (predictions.isEmpty) {
          setState(() => searchVal = "No resutl found");
        } else {
          for (dynamic single in predictions) {
            LocationDetails detail = LocationDetails(
                locationAddress: single['description'],
                locationID: single['place_id']);
            allLocations.add(detail);
          }
          setState(() => isSearchingCurrently = false);
        }
      }
    });
  }

  void decodeAndSelectPlace(String placeId) {
    String endpoint =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&key=$googleMapsAPIKeys";

    http.get(endpoint).then((response) {
      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        Map<String, dynamic> location =
            jsonDecode(response.body)['result']['geometry']['location'];
        LatLng latLng = LatLng(location['lat'], location['lng']);
        print(latLng);
      }
    }).catchError((error) {
      print(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(),
        key: _scaffoldKey,
        body: SlidingUpPanel(
          color: Colors.white,
          controller: _controller,
          parallaxEnabled: true,
          isDraggable: true,
          collapsed: Stack(
            alignment: Alignment.center,
            overflow: Overflow.visible,
            children: [
              Container(
                height: MediaQuery.of(context).size.height / 4,
                width: MediaQuery.of(context).size.width,
              ),
              Positioned(
                top: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLocalSelected = true;
                          isOutSideSelected = false;
                        });
                      },
                      child: Container(
                        height: 120,
                        padding: const EdgeInsets.all(8.0),
                        width: (MediaQuery.of(context).size.width / 2) - 40,
                        margin: const EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                            border: isLocalSelected
                                ? Border.all(color: Colors.black, width: 4.0)
                                : null,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.shade100, blurRadius: 10)
                            ]),
                        child: Column(
                          children: <Widget>[
                            Image.asset(
                              "asset/marker.png",
                              height: 60,
                              width: 60,
                            ),
                            Text(
                              "Local",
                              style: TextStyle(fontSize: 15.0),
                            )
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLocalSelected = false;
                          isOutSideSelected = true;
                        });
                      },
                      child: Container(
                        height: 120,
                        width: (MediaQuery.of(context).size.width / 2) - 40,
                        margin: const EdgeInsets.all(15.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                            border: isOutSideSelected
                                ? Border.all(color: Colors.black, width: 4.0)
                                : null,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.shade100, blurRadius: 10)
                            ]),
                        child: Column(
                          children: <Widget>[
                            Image.asset(
                              "asset/marker.png",
                              height: 60,
                              width: 60,
                            ),
                            Text(
                              "Outside Station",
                              style: TextStyle(fontSize: 14.0),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          onPanelClosed: () {
            _pickFocusNode.unfocus();
            setState(() {
              isPanelOpenComplete = false;
            });
          },
          onPanelOpened: () {
            setState(() {
              isPanelOpenComplete = true;
              _pickUpController.text = mainAddress;
            });
          },
          defaultPanelState: PanelState.CLOSED,
          boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.grey.shade100)],
          maxHeight: MediaQuery.of(context).size.height,
          minHeight: (MediaQuery.of(context).size.height / 4),
          panel: !isPanelOpenComplete
              ? Container()
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _pickUpController,
                        focusNode: _pickFocusNode,
                        style: TextStyle(color: Colors.black, fontSize: 16.0),
                        autofocus: true,
                        decoration: InputDecoration(
                            prefixIcon: IconButton(
                              icon: Icon(Icons.my_location),
                              onPressed: () =>
                                  _scaffoldKey.currentState.openDrawer(),
                              color: Colors.black,
                            ),
                            hintText: "Your Pickup Location",
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.circular(10),
                            )),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      TextField(
                        controller: _destinationController,
                        style: TextStyle(color: Colors.black, fontSize: 16.0),
                        decoration: InputDecoration(
                            prefixIcon: IconButton(
                              icon: Icon(Icons.my_location),
                              onPressed: () =>
                                  _scaffoldKey.currentState.openDrawer(),
                              color: Colors.black,
                            ),
                            hintText: "Your Drop Location",
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.circular(10),
                            )),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Divider(
                        color: Colors.black,
                        height: 8.0,
                      ),
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          children: <Widget>[
                            if (isSearchingCurrently)
                              _isSearchingOrNotFound(searchVal),
                            if (!isSearchingCurrently)
                              for (LocationDetails detail in allLocations) ...[
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.shade100,
                                            blurRadius: 14.0)
                                      ]),
                                  child: ListTile(
                                    title: Text(detail.locationAddress),
                                  ),
                                ),
                                Divider()
                              ]
                          ],
                        ),
                      )
                    ],
                  ),
                ),
          body: initLatLng == null
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Stack(
                  children: <Widget>[
                    GoogleMap(
                      polylines: _polyLines,
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                          zoom: 18, target: LatLng(26.7937061, 82.4627244)),
                      onMapCreated: (controller) {
                        _googleMapController = controller;
                      },
                    ),
                    _buildSearch(context),
                    _buildMyLocation(),
                    pin(),
                  ],
                ),
        ));
  }

  Widget _buildMyLocation() {
    return Positioned(
      bottom: (MediaQuery.of(context).size.height / 4 + 10),
      right: 10.0,
      child: FloatingActionButton(
        onPressed: () => _googleMapController.animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(
                target: initLatLng, zoom: 18, bearing: 180, tilt: 60))),
        child: Icon(Icons.my_location),
        backgroundColor: Colors.black38,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      height: 60,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 60.0,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.grey.shade100, blurRadius: 14.0)
            ]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState.openDrawer(),
              color: Colors.black,
            ),
            Expanded(
              child: TextField(
                focusNode: _mainFocusNode,
                onTap: () {
                  _mainFocusNode.unfocus();
                  _pickFocusNode.requestFocus();
                  _controller.open();
                },
                style: TextStyle(color: Colors.black, fontSize: 16.0),
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Your Current Location",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget pin() {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'asset/marker.png',
              height: 45,
              width: 45,
            ),
            Container(
              decoration: ShapeDecoration(
                shadows: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black38,
                  ),
                ],
                shape: CircleBorder(
                  side: BorderSide(
                    width: 4,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            SizedBox(height: 56),
          ],
        ),
      ),
    );
  }

  Widget _isSearchingOrNotFound(String result) {
    return ListTile(
      title: Text(result),
    );
  }
}

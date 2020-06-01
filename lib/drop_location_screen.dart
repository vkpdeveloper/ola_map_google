import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DropLocationMap extends StatelessWidget {
  GoogleMapController _googleMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: GoogleMap(
          initialCameraPosition:
              CameraPosition(zoom: 18, target: LatLng(26.7937061, 82.4627244)),
          onMapCreated: (controller) {
            _googleMapController = controller;
          },
          mapType: MapType.normal,
        ),
      ),
      Positioned(
        top: 30,
        left: 10.0,
        child: FloatingActionButton(
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.black38,
            foregroundColor: Colors.white,
            child: Icon(Icons.arrow_back_ios)),
      ),
      Positioned(
          bottom: 20,
          left: 30.0,
          right: 30.0,
          child: MaterialButton(
            onPressed: () {},
            height: 40.0,
            color: Colors.black,
            textColor: Colors.white,
            child: Text("Confirm"),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
          )),
      pin()
    ]));
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
}

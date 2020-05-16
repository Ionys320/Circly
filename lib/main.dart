import 'dart:html';

import 'package:flutter/material.dart';
import 'package:google_maps/google_maps.dart' as map;
import 'package:just_debounce_it/just_debounce_it.dart';
import 'package:mapbox_search/mapbox_search.dart' as mapboxsearch;

void main() {
  //Map variables
  runApp(Circly());
}

class Circly extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Circly',
        theme: ThemeData(
          primaryColor: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          inputDecorationTheme: InputDecorationTheme(
              labelStyle: TextStyle(color: Colors.white),
              hoverColor: Colors.white,
              fillColor: Colors.white,
              focusColor: Colors.white,
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white))),
        ),
        home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Available colors list
  List<String> colorsList = [
    '#FA00FF',
    '#FF0000',
    '#00C2FF',
    '#33FF00',
    '#FFB000',
    '#0029FF',
    '#FF4500'
  ];

  List<Address> addressesList = List<Address>();

  //Text field variables
  String inputSearch = '';
  TextEditingController searchFieldController = TextEditingController();

  //Mapbox search variables
  var placesSearch = mapboxsearch.PlacesSearch(
      apiKey:
          'pk.eyJ1Ijoic3BvdGVycyIsImEiOiJja2E4N3Jwa3UwNzFoMnRsNXhvcnp3eG1rIn0.VLlIEIzuQ6jKR839elYQjg',
      limit: 5,
      country: 'fr',
      language: 'fr');
  List<mapboxsearch.MapBoxPlace> foundedAddressesList =
      List<mapboxsearch.MapBoxPlace>();

  //Map
  static map.MapOptions mapOptions = map.MapOptions()
    ..streetViewControl = false
    ..center = map.LatLng(46.603354, 1.8883335)
    ..zoom = 6;
  map.GMap createdMap = map.GMap(document.getElementById("map"), mapOptions);
  List<map.Circle> circlesList = List<map.Circle>();

  @override
  Widget build(BuildContext context) {
    //Change the size of the map (56px is the AppBar height)
    document.getElementById('map').style.height =
        (MediaQuery.of(context).size.height - 56).toString() + 'px';

    return Scaffold(
        appBar: AppBar(title: SizedBox(width: 53, child: Text('Circly'))),
        body: Row(children: <Widget>[
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
              child: Stack(children: [
                Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                        color: Theme.of(context).primaryColor,
                        height: 100,
                        child: Center(
                            child: Padding(
                                padding: EdgeInsets.all(16),
                                child: TextField(
                                    enabled: addressesList.length < 6,
                                    controller: searchFieldController,
                                    style: TextStyle(color: Colors.white),
                                    onChanged: ((input) {
                                      inputSearch = input;
                                      Debounce.clear(searchAddress);
                                      Debounce.milliseconds(200, searchAddress);
                                    }),
                                    decoration: InputDecoration(
                                        labelText: 'Nouvelle adresse')))))),
                Positioned.fill(
                    top: 100,
                    child: SizedBox(
                        height: MediaQuery.of(context).size.height - 156,
                        child: ListView.separated(
                            separatorBuilder: (BuildContext context, int i) =>
                                Divider(),
                            itemCount: addressesList.length,
                            itemBuilder: (BuildContext context, int i) =>
                                ListTile(
                                  title: Text(addressesList[i].address),
                                  leading: IconButton(
                                      icon: Icon(Icons.remove_circle_outline),
                                      onPressed: () => removeAddress(i)),
                                  onTap: () => focusPin(i),
                                )))),
                if (foundedAddressesList != null &&
                    foundedAddressesList.length > 0)
                  Positioned.fill(
                      top: 78,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                              height: 125,
                              color: Colors.white,
                              child: ListView.builder(
                                  itemCount: foundedAddressesList.length,
                                  itemBuilder: (BuildContext context, int i) =>
                                      ListTile(
                                          title: Text(foundedAddressesList[i]
                                              .placeName),
                                          onTap: () => addAddress(i))))))
              ])),
        ]));
  }

  void searchAddress() {
    if (inputSearch != null && inputSearch != '')
      placesSearch
          .getPlaces(inputSearch)
          .then((List<mapboxsearch.MapBoxPlace> results) {
        setState(() => foundedAddressesList = results);
      }).catchError((e) {});
  }

  void addAddress(int i) {
    mapboxsearch.MapBoxPlace mapBoxPlace = foundedAddressesList[i];

    Address address = Address(
        mapBoxPlace.placeName,
        mapBoxPlace.geometry.coordinates[1],
        mapBoxPlace.geometry.coordinates[0],
        colorsList.first);
    map.CircleOptions circleOptions = map.CircleOptions()
      ..map = createdMap
      ..center = map.LatLng(address.lat, address.lng)
      ..fillColor = address.color
      ..strokeOpacity = 100
      ..strokeColor = address.color
      ..strokeWeight = 3
      ..radius = 100000;
    circlesList.add(map.Circle(circleOptions));

    //Add the address to the list
    addressesList.add(address);
    //Remove the used color of the available colors list
    colorsList.removeAt(0);

    //Reset the search variables
    foundedAddressesList.clear();
    searchFieldController.clear();

    focusPin(addressesList.length - 1);

    setState(() {});
  }

  void focusPin(int i) {
    createdMap.center = map.LatLng(addressesList[i].lat, addressesList[i].lng);
    createdMap.zoom = 8;
  }

  void removeAddress(int i) {
    //Add the color of the circle at the available colors list
    colorsList.add(addressesList[i].color);

    addressesList.removeAt(i);

    //Remove the circle from the map
    circlesList[i].map = null;
    circlesList.removeAt(i);

    setState(() {});
  }
}

class Address {
  String address;
  double lat;
  double lng;
  String color;

  Address(this.address, this.lat, this.lng, this.color);
}

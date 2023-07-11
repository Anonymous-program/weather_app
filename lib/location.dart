

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  LocationData? _locationData;
  String? _errorMessage;
  bool _isLoading = true;
  late WeatherData _weatherData;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled.';
        });
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are denied.';
        });
        return;
      }
    }

    LocationData? locationData = await location.getLocation();
    setState(() {
      _locationData = locationData;
    });

    await _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    final apiKey = "YOUR_API_KEY";
    final apiUrl = "https://api.openweathermap.org/data/2.5/weather?lat=23.7644025&lon=90.389015&appid=181f6992099f874380b9d7fdcba5d676";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final weatherData = WeatherData.fromJson(jsonBody);
        setState(() {
          _weatherData = weatherData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error retrieving weather data.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error retrieving weather data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        actions: [
          Row(children: [
            IconButton(onPressed: (){}, icon: Icon(Icons.search)),
            IconButton(onPressed: (){}, icon: Icon(Icons.settings)),
          ],)
        ],
        title: Text('Weather App'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _errorMessage != null
            ? Text(
          _errorMessage!,
          style: TextStyle(fontSize: 18),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Location:',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            Text(
              'Latitude: ${_locationData?.latitude}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Longitude: ${_locationData?.longitude}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),
            Text(
              'Current Weather:',
              style: TextStyle(fontSize: 24),
            ),
            Image.network(
              'http://openweathermap.org/img/w/${_weatherData.icon}.png',
              scale: 1.5,
            ),
            SizedBox(height: 10),
            Text(
              '${_weatherData.temperature}\u00B0',
              style: TextStyle(fontSize: 36, fontFamily: 'CustomFont'),
            ),
            Text(
              _weatherData.description,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherData {
  final double temperature;
  final String description;
  final String icon;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    return WeatherData(
      temperature: main['temp'],
      description: weather['description'],
      icon: weather['icon'],
    );
  }
}

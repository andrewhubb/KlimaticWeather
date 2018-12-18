import 'package:flutter/material.dart';
import 'package:klimatic/util/utils.dart' as util;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Klimatic extends StatefulWidget {
  @override
  _KlimaticState createState() => _KlimaticState();
}

class _KlimaticState extends State<Klimatic> {
  String _cityEntered;
  String defaultCity;

  @override
  void initState() {
    super.initState();

    loadSavedPrefs();
  }

  loadSavedPrefs() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    setState(() {
      if (preferences.getString('default_city')!=null && preferences.getString('default_city').isNotEmpty ) {
        defaultCity = preferences.getString('default_city');
      } else {
        defaultCity = "Bangkok, TH";
      }
    });
  }

  void showWeather() async {
    Map data = await getWeather(util.appId, defaultCity);
  }

  Future _gotoNextScreen(BuildContext context) async {
    Map results = await Navigator.of(context)
        .push(MaterialPageRoute<Map>(builder: (BuildContext context) {
      return ChangeCity();
    }));
    if (results != null && results.containsKey('city')) {
      _cityEntered = results['city'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
            title: Text('Klimatic'),
            centerTitle: true,
            backgroundColor: Colors.red,
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {
                    _gotoNextScreen(context);
                  })
            ]),
        body: Stack(children: <Widget>[
          Center(
            child: Image.asset('images/umbrella.png',
                width: 500, height: 1200, fit: BoxFit.fill),
          ),
          new Container(
              alignment: Alignment.topRight,
              margin: const EdgeInsets.fromLTRB(0.0, 10.9, 20.9, 0.0),
              child: Text(
                  '${_cityEntered == null ? defaultCity : _cityEntered}',
                  style: cityStyle())),
          new Container(
            alignment: Alignment.center,
            child: Image.asset('images/light_rain.png'),
          ),
          updateTempWidget(_cityEntered == null
              ? defaultCity
              : _cityEntered.replaceAll(' ', '+').trim()),
        ]));
  }

  Future<Map> getWeather(String appId, String city) async {
    String apiUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=${util.appId}&units=metric';
    http.Response response = await http.get(apiUrl);
    return json.decode(response.body);
  }

  Widget updateTempWidget(String city) {
    return FutureBuilder(
        future: getWeather(util.appId, city == null ? defaultCity : city),
        builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
          if (snapshot.hasData) {
            Map content = snapshot.data;
            if(content['cod']=='404') {
              return Container(
                  margin: EdgeInsets.fromLTRB(55.0, 270.0, 0.0, 0.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            content['message'],
                            style: tempStyle(),
                          ),
                        )
                      ]));
            } else {
              return new Container(
                margin: EdgeInsets.fromLTRB(55.0, 270.0, 0.0, 0.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ListTile(
                        title: Text(
                          content['main']['temp'].toString() + " \u00B0C",
                          style: tempStyle(),
                        ),
                        subtitle: ListTile(
                            title: Text(
                                'Humidity: ${content['main']['humidity']
                                    .toString()}%\n'
                                    'Min: ${content['main']['temp_min']
                                    .toString()} \u00B0C\n'
                                    'Max: ${content['main']['temp_max']
                                    .toString()} \u00B0C',
                                style: extraDataStyle())))
                  ],
                ),
              );
            }
          } else {
            return Container();
          }
        });
  }
}

class ChangeCity extends StatefulWidget {
  @override
  _ChangeCityState createState() => _ChangeCityState();
}

class _ChangeCityState extends State<ChangeCity> {
  var _cityFieldController = TextEditingController();
  bool citySelected=false;
  savePrefs(String city) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString('default_city', city);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text('Change City'),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Center(
              child: Image.asset('images/white_snow.png',
                  width: 500.0, height: 1200.0, fit: BoxFit.fill)),
          ListView(
            children: <Widget>[
              ListTile(
                  title: TextField(
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Enter City',
                    ),
                    controller: _cityFieldController,
                    keyboardType: TextInputType.text,
                  )),
              CheckboxListTile(
                  title: Text('Make Default City'),
                  value: citySelected,
                  onChanged: (bool value) {
                    setState(() {
                      citySelected = value;
                      if (citySelected) {
                        savePrefs(_cityFieldController.text);
                      } else {
                        savePrefs("Bangkok,TH");
                      }
                    });
                  }),
              ListTile(
                title: FlatButton(
                    onPressed: () {
                      Navigator.pop(
                          context, {'city': _cityFieldController.text});
                    },
                    textColor: Colors.white70,
                    color: Colors.redAccent,
                    child: Text('Get Weather')),
              )
            ],
          )
        ],
      ),
    );
  }
}

TextStyle cityStyle() {
  return TextStyle(
      color: Colors.white, fontSize: 22.9, fontStyle: FontStyle.italic);
}

TextStyle tempStyle() {
  return TextStyle(
    color: Colors.white,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    fontSize: 49.9,
  );
}

TextStyle extraDataStyle() {
  return TextStyle(
    color: Colors.white70,
    fontStyle: FontStyle.normal,
    fontSize: 24.9,
  );
}



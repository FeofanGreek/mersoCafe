
import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:mersocafe/menuScreen.dart';
import 'package:mersocafe/basketScreen.dart';
import 'package:mersocafe/profileScreen.dart';

import 'package:http/http.dart' as http;

import 'package:mersocafe/historyScreen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'editOrders.dart';

String IdRestaurant = "2"; //идентификатор ресторана в системе (на сервере)
String textMainScreen = '   Επιβεβαιώστε τον αριθμό του κινητού σας τηλεφώνου και ολοκληρώστε το προφίλ σας.\n    Για να λάβετε πληροφορίες σχετικά με παραγγελίες, επιβεβαιώστε την αποστολή ειδοποιήσεων.';


//переменная в которой храним наш JSON с сервера
var parsedJson, parsedJsonHistory;

// готовим массив для списка картинок и списка названий групп блюд
final List<String> imgList = [];
double eatTotalPriceList = 0.00;
bool ProfileComplite = false;
bool menuListComplite = false;


void main(){
  //runApp(SplashScreen());
  runApp(GreekCafe());// что запускаем в первую очередь
  readProfile();
}

class GreekCafe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(title: ''),
    );
  }

}

class MainScreen extends StatefulWidget {
  MainScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MainScreenState createState() => _MainScreenState();

}


class _MainScreenState extends State<MainScreen> {

  @override
  void initState(){
    _sendRequestPost();
    readProfile();
    readProfileL();
    super.initState();
  }

  callClient(url) async {

    if (await canLaunch('tel://$url')) {
      await launch('tel://$url');
    } else {
      throw 'Невозможно набрать номер $url';
    }
  }

  @override
  readProfileL() async {
    FirebaseMessaging _fcm = FirebaseMessaging();
    token = await _fcm.getToken();

    //делаем запрос к серверу на предмет проверки прав доступа
    try {
      var responseRules = await http.post('https://koldashev.ru/GreekCafeAPI.php',
          headers: {"Accept": "application/json"},
          body: jsonEncode(<String, dynamic>{
            "login": "$IdRestaurant",
            "token" : "$token",
            "subject" : "checkpartnercode"
          })
      );
      var jsonUserRules = responseRules.body;
      var parsedUserRules = json.decode(jsonUserRules);
      if(parsedUserRules[0]["isAdmin"] == 1){isAdmin = true; ordersListComplite = true;}
      if(parsedUserRules[0]["isCooker"] == 1){isCooker = true; ordersListComplite = true;}
      if(parsedUserRules[0]["isDeliver"] == 1){isDeliver = true; ordersListComplite = true;}
      if(parsedUserRules[0]["isManager"] == 1){isManager = true; ordersListComplite = true;}
    } catch (error) {}
    setState(() {});
  }


  _sendRequestPost() async {
      if(imgList.length < 1) {
        try {
          var response = await http.post('https://koldashev.ru/GreekCafeAPI.php',
              headers: {"Accept": "application/json"},
              body: jsonEncode(<String, dynamic>{
                "login": "$IdRestaurant",
                "subject" : "menu"
              })
          );

          var jsonData = response.body;
          parsedJson = json.decode(jsonData);
          var imgCount = parsedJson[0]['menuClient'].length;
          for (int i = 0; i < imgCount; i++) {
            imgList.add(parsedJson[0]['menuClient'][i]['pictureUrl']);
            menuListComplite = true;
          }
        } catch (error) {}
        setState(() {}); //reBuildWidget
      }
  }//_sendRequestPost

  @override
  Widget build(BuildContext context){
    final List<Widget> imageSliders = imgList.map((item) => GestureDetector(
        onTap: () {
          Navigator.push(context,
              CupertinoPageRoute(builder: (context) => ScreenMenu(eatSlide: imgList.indexOf(item))));
        },
        child: Container(
          child: Container(
            margin: EdgeInsets.all(5.0),
            child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                child: Stack(
                  children: <Widget>[
                    Image.network(item, fit: BoxFit.cover, width: 1000.0),
                    Positioned(
                      bottom: 0.0,
                      left: 0.0,
                      right: 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(200, 0, 0, 0),
                              Color.fromARGB(0, 0, 0, 0)
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                        child: Text(
                          '${parsedJson[0]['menuClient'][imgList.indexOf(item)]['nameGroupBlude']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
            ),
          ),
        ))).toList();

    return Scaffold(
      backgroundColor: Color(0xFFffffff),
             appBar:AppBar(
                elevation: 0.0,
                title: Image.asset('images/our-menu-header.png',  height: 50, fit:BoxFit.fill),
                centerTitle: true,
                backgroundColor: Color(0xFFffffff),
              brightness: Brightness.light,
                leading: ordersListComplite?Container(
                    child: Material(
                      color: Colors.white, // button color
                        child: InkWell(
                          splashColor: Colors.green, // splash color
                          onTap: () {
                            orderListComplite = false;
                            Navigator.push(context,
                              CupertinoPageRoute(builder: (context) => editOrders()));}, // button pressed
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.playlist_add_check, size: 18.0, color: Colors.black), // icon
                          Text("Orders", style: TextStyle(color: Colors.black87)), // text
                      ],
                    ),
                  ),
                ),
                ):Container(), //кнопка перехода в управление заказами если партнерский код комплит
                actions: <Widget>[
                  Container(
                    margin: EdgeInsets.fromLTRB(0,0,10,0),
                    child: Material(
                      color: Colors.white, // button color
                      child: InkWell(
                        splashColor: Colors.green, // splash color
                        onTap: () {
                          Navigator.push(context,
                              CupertinoPageRoute(builder: (context) => profileView()));}, // button pressed
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.account_box, size: 18.0, color: Colors.black), // icon
                            Text("Profile", style: TextStyle(color: Colors.black87)), // text
                          ],
                        ),
                      ),
                    ),
                  ),
                  ProfileComplite?Container(
                    margin: EdgeInsets.fromLTRB(0,0,10,0),
                      child: Material(
                      color: Colors.white, // button color
                        child: InkWell(
                        splashColor: Colors.green, // splash color
                        onTap: () { Navigator.push(context,
                            CupertinoPageRoute(builder: (context) => HistoryView()));}, // button pressed HistoryView
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                            Icon(Icons.history, size: 18.0, color: Colors.black), // icon
                            Text("History", style: TextStyle(color: Colors.black87)), // text
                          ],
                        ),
                      ),
                    ),
                ):Container(),
                ],
              ),
      body:SingleChildScrollView(
          physics: ScrollPhysics(),

      child:Center(
        child: Column(
          children: <Widget>[
            SizedBox(height: 20.0),

                    Container(
                      child:Image.asset('images/mainLogo2.png',  height: 150, fit:BoxFit.fill,),
                      alignment: Alignment(0.00, 0.0),
                      padding: EdgeInsets.fromLTRB(0,0,0,5),
                    ),
            Container(
              margin: EdgeInsets.fromLTRB(10,10,10,10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7.0),
                color: Color.fromRGBO(84, 94, 172, 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Text('$textMainScreen',
                    style: TextStyle(fontSize: 15.0, color: Colors.black),textAlign: TextAlign.justify,),
                  padding: EdgeInsets.fromLTRB(10,10,10,10),
                  alignment: Alignment(0.0, 0.0),
                ),
            SizedBox(height: 20.0),
            Text('Τι θα θέλατε?',style: TextStyle(fontSize: 20.0, color: Colors.black),textAlign: TextAlign.center,),
            menuListComplite?CarouselSlider(
              options: CarouselOptions(
                autoPlay: true,
                aspectRatio: 2.0,
                enlargeCenterPage: true,
              ),
              items: imageSliders,
            ):Container(
                width: 50.0,
                height: 50.0,
                margin: EdgeInsets.fromLTRB(10,50,0,0),
                child:CircularProgressIndicator(strokeWidth: 4.0,
                  valueColor : AlwaysStoppedAnimation(Colors.green),)),
            Transform.rotate(
                angle: 3.1458,
                child:Container(
                  child:Image.asset('images/spaceImage.png',   fit:BoxFit.fill,),
                  alignment: Alignment(0.00, 0.0),
                  padding: EdgeInsets.fromLTRB(0,0,0,5),
                )),
            SizedBox(height: 10.0),
            Text('Περιμένουμε την επίσκεψή σας',style: TextStyle(fontSize: 20.0, color: Colors.black),textAlign: TextAlign.center,),
            SizedBox(height: 10.0),
          Column(
              children: <Widget>[
                SizedBox(height: 10.0),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.access_time),
                      Text('  13.00 το μεσιμερί έως 1.00 το βράδυ')
                    ]
                ),
                SizedBox(height: 10.0),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                     children: <Widget>[
                      Icon(Icons.local_post_office),
                      Text('  Μυσίας 2 & Φορμίωνος ΒΥΡΩΝΑΣ')
                    ]
                  ),
             GestureDetector(
                    onTap: () {
                      callClient('+302111824565');
                    },
                    child:
                Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.phone),
                        Text('  211 1824565', style: TextStyle(fontSize: 15.0,color: Colors.blue,fontWeight: FontWeight.bold,))
                      ]
                  )),
                GestureDetector(
                    onTap: () {
                      callClient('+302111824566');
                    },
                    child:
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.phone),
                          Text('  211 1824566', style: TextStyle(fontSize: 15.0,color: Colors.blue,fontWeight: FontWeight.bold,))
                        ]
                    )),
          ]),
            SizedBox(height: 20.0),
            Container(
              child:Image.asset('images/bonApetit.png',  height: 120, fit:BoxFit.fill,),
              alignment: Alignment(0.00, 0.0),
              padding: EdgeInsets.fromLTRB(0,0,0,5),
            ),

      ]))),
      floatingActionButton: !ProfileComplite?FloatingActionButton.extended(
        onPressed:() {Navigator.push(context,
            CupertinoPageRoute(builder: (context) => profileView()));},
        tooltip: 'Increment',
        label: Text('Add profile', style: TextStyle(fontSize: 14.0, color: Colors.black),textAlign: TextAlign.justify,),
        icon: Icon(Icons.account_box),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ):
      eatTotalPriceList>0?FloatingActionButton.extended(
        onPressed:() {
          sendBascket = true;
          if(eatTotalPriceList >0.00){PrintBasket (); Navigator.push(context,
            CupertinoPageRoute(builder: (context) => CartView()));}},
        tooltip: 'Increment',
        label: Text('${double.parse((eatTotalPriceList.toStringAsFixed(2)))}€', style: TextStyle(fontSize: 14.0, color: Colors.black),textAlign: TextAlign.justify,),
        icon: Icon(Icons.shopping_basket),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ):Container(),
    );
  }
}

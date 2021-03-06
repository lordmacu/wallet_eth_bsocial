import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_wallet/controllers/Transaction.dart';
import 'package:get/get.dart';
import 'package:social_wallet/home.dart';
import 'package:social_wallet/login.dart';
import 'package:social_wallet/uiHelpers/animationBackground.dart';
import 'package:loading_animations/loading_animations.dart';

import 'package:social_wallet/finishScreen.dart';

class LoadingPage extends StatefulWidget {
  LoadingPage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _LoadingPageState createState() => _LoadingPageState();
}



class _LoadingPageState extends State<LoadingPage>{

  checkSession() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var token =prefs.getString("token");

    var userToken= prefs.getString("password");



      if(token==null){
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Login()),
              (Route<dynamic> route) => false,
        );
      }else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => FinishScreen()),
              (Route<dynamic> route) => false,
        );
      }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();


    checkSession();

  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Color(0xff424f5c),


      body: Stack(
        children: [
          AnimationBackground(),
         Center(
           child: Container(
             width: 100,
             child: Image.asset("assets/icon.png",),
           ),
         )

        ],
      ),
    );
  }

}
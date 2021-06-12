import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart'; //You can also import the browser version
import 'dart:math';
import 'package:web_socket_channel/io.dart';

class WalletController extends GetxController{

  var tags=[].obs;


  setTokenAndWallet(wallet, phrases,token) async{

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("wallet", wallet);
    prefs.setString("phrases", phrases);
    prefs.setString("token", token);

  }



}
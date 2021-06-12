import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_wallet/models/Coin.dart';
import 'package:social_wallet/models/Transaction.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart'; //You can also import the browser version
import 'dart:math';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:social_wallet/models/Transaction.dart' as tr;
import 'package:web3dart/web3dart.dart' as web;

class AddresController extends GetxController {
  var address = "".obs;


  @override
  onInit() {

    getqr();
  }


  getqr() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var wallet = await prefs.getString("wallet");
    address.value=wallet;
  }

}

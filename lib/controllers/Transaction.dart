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

class TransactionWallet extends GetxController {
  var ethBalance = "0".obs;
  var bsocialBalance = "0".obs;
  var bsocialBalanceNumber = 0.0.obs;
  var canTransfer = 0.0.obs;

  var isloading = false.obs;
  var transactions = [];
  var usdValue = "0".obs;
  var totalEarnings = "0".obs;
  var valuePasteWallet = "".obs;
 var transaction="".obs;
  @override
  onInit() {

    checkTransactionStatus();
  }



  checkTransactionStatus( ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var transaction = await prefs.getString("transaction");


    var url = Uri.parse(
        'https://api.etherscan.io/api?module=transaction&action=getstatus&txhash=${transaction}&apikey=3YF336R8GJFSC6KT34S4JSS812WM536RVU');
    var response = await http.get(url);

    var resuldt = jsonDecode(response.body);

  }


}

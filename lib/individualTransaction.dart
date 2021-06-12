import 'package:flutter/material.dart';
import 'package:social_wallet/controllers/Transaction.dart';
import 'package:get/get.dart';
import 'package:social_wallet/home.dart';
import 'package:social_wallet/uiHelpers/animationBackground.dart';
import 'package:loading_animations/loading_animations.dart';

class IndividualTransaction extends StatelessWidget{

  TransactionWallet walletController = Get.put(TransactionWallet());


  var transaction;
  var price;
  var wallet;

  IndividualTransaction(this.transaction,this.price,this.wallet);
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Color(0xff424f5c),
      bottomNavigationBar:  Container(
        padding: EdgeInsets.only(right: 20,left: 20,bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              child: RaisedButton(
                shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(10.0),
                ),
                onPressed: () async {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Home()),
                        (Route<dynamic> route) => false,
                  );
                },
                child: Text(
                  "View transactions",
                  style: TextStyle(fontSize: 20),
                ),
                color: Colors.white,
              ),
            ),

          ],
        ),
      ),

      body: Stack(
        children: [
          AnimationBackground(),
         Align(
           child:  Container(
             margin: EdgeInsets.only(top: 40, left: 15, right: 15),
             child: Text(
               "Transfer",
               style: TextStyle(
                   color: Colors.white, fontSize: 30),
             ),
           ),
           alignment: Alignment.topCenter,
         ),
         Center(
           child: Text(""),
         )

        ],
      ),
    );
  }

}
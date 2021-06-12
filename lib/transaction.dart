import 'package:flutter/material.dart';
import 'package:social_wallet/controllers/Transaction.dart';
import 'package:get/get.dart';
import 'package:social_wallet/home.dart';
import 'package:social_wallet/uiHelpers/animationBackground.dart';
import 'package:loading_animations/loading_animations.dart';

class TransactionPage extends StatelessWidget{

  TransactionWallet walletController = Get.put(TransactionWallet());


  var transaction;
  var price;
  var wallet;

  TransactionPage(this.transaction,this.price,this.wallet);
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
           child:  Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Container(
                 child: Text("Transfer to:",style: TextStyle(color: Colors.white,fontSize: 20),),
               ),
               Container(
                 margin: EdgeInsets.only(top: 10),
                 child: Text("${wallet}",style: TextStyle(color: Colors.white),),
               ),
               Container(
                 margin: EdgeInsets.only(top: 30),
                 child: Text("${price} ",style: TextStyle(color: Colors.white,fontSize: 30),),
               ),
               Container(
                 margin: EdgeInsets.only(top: 0),
                 child: Text("\$BSOCIAL",style: TextStyle(color: Colors.white,fontSize: 30),),
               ),
               Container(
                 margin: EdgeInsets.only(top: 50),
                 child: Column(
                   children: [

                     LoadingBouncingLine.circle(
                       borderColor: Color(0xff424f5c),
                       borderSize: 3.0,
                       size: 60.0,
                       backgroundColor: Colors.white,
                       duration: Duration(milliseconds: 2000),
                     ),
                     Container(
                       margin: EdgeInsets.only(top: 0),
                       child: Text("Procesing...",style: TextStyle(color: Colors.white,fontSize: 15),),
                     ),
                   ],
                 ),
               )

             ],
           ),
         )

        ],
      ),
    );
  }

}
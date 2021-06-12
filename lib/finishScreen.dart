import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:social_wallet/controllers/BalanceController.dart';
import 'package:social_wallet/controllers/WalletController.dart';
import 'package:social_wallet/home.dart';
import 'package:social_wallet/uiHelpers/animationBackground.dart';
import 'package:get/get.dart';

class FinishScreen extends StatelessWidget{
  BalanceWallet walletController = Get.put(BalanceWallet());


  @override
  Widget build(BuildContext context) {

    return Obx(()=>ModalProgressHUD(inAsyncCall: walletController.isloading.value, child: Scaffold(
      bottomNavigationBar:  Container(
        color: Colors.white,
        padding: EdgeInsets.only(top: 20, left: 20, right: 20,bottom: 20),

        width: double.infinity,
        child: RaisedButton(
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(10.0),
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Home()),
                  (Route<dynamic> route) => false,
            );
          },
          child: Text(
            "Next",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          color: Color(0xff424f5c),
        ),
      ),
      backgroundColor: Color(0xff424f5c),
      body: Column(
        children: [
          Expanded(child:Stack(
            children: [

              AnimationBackground(),
              Center(
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        child: Text("Well done!",style: TextStyle(color: Colors.white,fontSize: 45,fontWeight: FontWeight.bold),),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 15),
                        child: Text("Your wallet was added \n successfully!",style: TextStyle(color: Colors.white.withOpacity(0.5),fontSize: 25),textAlign:  TextAlign.center,),
                      )
                    ],
                  ),
                ),
              ),

            ],
          )),
          Expanded(child: Container(
            padding: EdgeInsets.only(left: 30,right: 30),
            width: double.infinity,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 30,bottom: 30),
                  child: Text("Your balance is",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w300),),
                ),

                Container(
                  margin: EdgeInsets.only(bottom: 30),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Container(
                        child: Text("\$Bsocial",style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Color(0xff424f5c)),),
                      ),
                      Container(
                        child: Obx(()=>Text("${walletController.bsocialBalance.value}",style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Color(0xff424f5c)),)),
                      )
                    ],
                  ),
                ),
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Text("Ethereum",style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Color(0xff424f5c)),),
                      ),
                      Container(
                        child: Obx(()=>Text("${walletController.ethBalance.value} ETH",style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Color(0xff424f5c)),)),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ))
        ],
      ),
    )));
  }

}
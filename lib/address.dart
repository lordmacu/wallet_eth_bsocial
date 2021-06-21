import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:social_wallet/controllers/Transaction.dart';
import 'package:get/get.dart';
import 'package:social_wallet/home.dart';
import 'package:social_wallet/uiHelpers/animationBackground.dart';
import 'package:loading_animations/loading_animations.dart';
import 'controllers/AddressController.dart';
import 'package:share/share.dart';

class AddressPage extends StatelessWidget {
  AddresController addresController = Get.put(AddresController());

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(

      backgroundColor: Color(0xff424f5c),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(right: 20, left: 20, bottom: 20),
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
                  Navigator.pop(context);

                },
                child: Text(
                  "Back to wallet",
                  style: TextStyle(fontSize: 20),
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xff424f5c),
        title: Container(
           child: Text(
            "Receive \$Bsocial",
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
        ),
      ),
      body: Stack(
        children: [
          AnimationBackground(),


          Center(
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (addresController.address.value != null)
                    QrImage(
                      data: addresController.address.value,
                      size: 200.0,
                      embeddedImage: AssetImage('assets/logo_social.png'),
                      version: QrVersions.auto,
                     ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child:Obx(()=> Text(
                      addresController.address.value ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 25),
                    )),
                  ),
                 GestureDetector(
                   onTap: (){
                     Share.share('Look my \$Bosical address! ${ addresController.address.value}', subject: 'Look my \$Bosical address!');
                   },
                   child:  Container(
                     margin: EdgeInsets.only(top: 20),
                     child: Text("Share address",style: TextStyle(fontSize: 24,color: Color(0xff424f5c),fontWeight: FontWeight.bold),),
                   ),
                 )


                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

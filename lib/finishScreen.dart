import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_wallet/controllers/BalanceController.dart';
import 'package:social_wallet/controllers/PinController.dart';
import 'package:social_wallet/home.dart';
import 'package:social_wallet/login.dart';
import 'package:social_wallet/uiHelpers/animationBackground.dart';
import 'package:get/get.dart';
import 'package:pin_code_text_field/pin_code_text_field.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class FinishScreen extends StatefulWidget {
  FinishScreen();

  @override
  _FinishScreen createState() => _FinishScreen();
}

class _FinishScreen extends State<FinishScreen> {
  PinController walletController = Get.put(PinController());

  final _formKey = GlobalKey<FormState>();
  TextEditingController controller = TextEditingController(text: "");

  Future resetPassword() {
    Alert(
        context: context,
        style: AlertStyle(
            descStyle: TextStyle(color: Color(0xff424f5c)),
            titleStyle: TextStyle(fontSize: 30, color: Color(0xff424f5c))),
        title: "Reset password",
        content: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Text(
                "Do you want to reset the password? you need to enter your phrase again.",
                style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
              ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            color: Colors.white,
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();

              Navigator.pop(context);
            },
            child: Text(
              "CANCEL",
              style: TextStyle(color: Color(0xff424f5c), fontSize: 20),
            ),
          ),
          DialogButton(
            color: Color(0xff424f5c),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();

              await prefs.clear();

              walletController.step.value = 0;
              walletController.hasError.value =
              false;
              controller.text = "";
              walletController.tempPassword.value =
              "";

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Login()),
                (Route<dynamic> route) => false,
              );
            },
            child: Text(
              "YES",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => ModalProgressHUD(
        inAsyncCall: walletController.isloading.value,
        child: Scaffold(
          bottomNavigationBar: Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
            width: double.infinity,
            child: RaisedButton(
              shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(10.0),
              ),
              onPressed: walletController.hasError.value == false
                  ? () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Home()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  : null,
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
              Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      AnimationBackground(),
                      walletController.isregister.value
                          ? Center(
                              child: Container(
                                padding: EdgeInsets.only(left: 20, right: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      child: Text(
                                        "Well done!",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 45,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 15),
                                      child: Text(
                                        "Now lets create a PIN to secure your wallet",
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            fontSize: 25),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Container(
                                padding: EdgeInsets.only(left: 20, right: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      child: Text(
                                        "Welcome!",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 45,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 15),
                                      child: Text(
                                        "Please enter your password to enter your wallet!",
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            fontSize: 25),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                    ],
                  )),
              Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.only(left: 10, right: 10, top: 30),
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PinCodeTextField(
                          autofocus: true,
                          controller: controller,
                          hideCharacter: false,
                          highlight: true,
                          highlightColor: Colors.blue,
                          defaultBorderColor: Colors.black,
                          hasTextBorderColor: Colors.green,
                          highlightPinBoxColor: Colors.grey.withOpacity(0.1),
                          pinBoxRadius: 10,
                          maxLength: 5,

                          hasError: walletController.hasError.value,
                          onTextChanged: (text) {
                            if (text.length < 6) {
                              walletController.isCorrect.value = false;
                            }
                          },

                          onDone: (text) async {
                            if (walletController.isregister.value) {
                              if (walletController.step.value == 0) {
                                walletController.tempPassword.value =
                                    controller.text;
                                controller.text = "";
                                walletController.step.value = 1;
                                print("is register");
                              } else {
                                if (walletController.tempPassword.value ==
                                    controller.text) {
                                  walletController.hasError.value = false;

                                  await walletController
                                      .setPassword(controller.text);

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Home()),
                                    (Route<dynamic> route) => false,
                                  );
                                } else {
                                  walletController.hasError.value = true;
                                }
                              }
                            } else {
                              if (walletController.password.value ==
                                  controller.text) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Home()),
                                  (Route<dynamic> route) => false,
                                );
                              } else {

                                walletController.hasError.value = true;
                              }
                            }

                          },
                          pinBoxWidth: 50,
                          pinBoxHeight: 50,
                          hasUnderline: true,
                          wrapAlignment: WrapAlignment.spaceAround,
                          pinBoxDecoration:
                              ProvidedPinBoxDecoration.defaultPinBoxDecoration,
                          pinTextStyle: TextStyle(fontSize: 22.0),
                          pinTextAnimatedSwitcherTransition:
                              ProvidedPinBoxTextAnimation.scalingTransition,
//                    pinBoxColor: Colors.green[100],
                          pinTextAnimatedSwitcherDuration:
                              Duration(milliseconds: 300),
//                    highlightAnimation: true,
                          highlightAnimationBeginColor: Colors.black,
                          highlightAnimationEndColor: Colors.white12,
                          keyboardType: TextInputType.number,
                        ),
                        walletController.hasError.value
                            ? walletController.isregister.value == true
                                ? Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 10),
                                        child: Text(
                                          "Wrong password, please enter the password again.",
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          walletController.step.value = 0;
                                          walletController.hasError.value =
                                              false;
                                          controller.text = "";
                                          walletController.tempPassword.value =
                                              "";
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          margin: EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 10,
                                              right: 10),
                                          child: Text(
                                            "Start again",
                                            style: TextStyle(
                                                color: Colors.blueAccent),
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 10),
                                        child: Text(
                                          "Wrong password, please enter the password again.",
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          resetPassword();
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          margin: EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 10,
                                              right: 10),
                                          child: Text(
                                            "Reset password",
                                            style: TextStyle(
                                                color: Colors.blueAccent),
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                            : Container(),
                        walletController.step.value == 0
                            ? walletController.hasError.value == false
                                ? Container(
                                    margin: EdgeInsets.only(top: 10),
                                    child: Text("Please enter the password."),
                                  )
                                : Container()
                            : walletController.hasError.value == false
                                ? Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 10),
                                        child: Text(
                                            "Enter the PIN again for verification."),
                                      )
                                    ],
                                  )
                                : Container()
                      ],
                    ),
                  ))
            ],
          ),
        )));
  }
}

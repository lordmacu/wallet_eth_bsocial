import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';
import 'package:hex/hex.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:social_wallet/controllers/WalletController.dart';
import 'package:social_wallet/finishScreen.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:wallet_hd_pro/wallet_hd_pro.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:convert/convert.dart';
import 'package:web3dart/web3dart.dart';
import 'package:clipboard/clipboard.dart';
import 'package:toast/toast.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tags/flutter_tags.dart';

class Login extends StatefulWidget {
  Login({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _Login createState() => new _Login();
}

class _Login extends State<Login> with TickerProviderStateMixin {
  PanelController controller = PanelController();
  WalletController walletController = Get.put(WalletController());
  int step = 0;
  bool isLoading = false;
  List<String> prhases = [];
  List<String> prhasesWriten = [];
  String prhasesString = "";
  int numbersWords = 0;

  bool isClassic = false;
  bool isError = false;

  TextEditingController controllerClassic;

  List tags = [];

  @override
  void initState() {
    // TODO: implement initState
    controllerClassic = TextEditingController();
    super.initState();
    initChart();
  }

  initChart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("chartRange", "1D");
  }

  static Future<String> generateWallet(String mnemonic) async {
    Map<String, String> mapAddr = await WalletHd.getAccountAddress(mnemonic);

    return mapAddr["ETH"];
  }

  static Future<String> generateKey(String mnemonic) async {
    var mapAddr = await WalletHd.ethMnemonicToPrivateKey(mnemonic);

    var result = hex.encode(mapAddr.privateKey);
    Credentials fromHex = EthPrivateKey.fromHex(result);

    var address = await fromHex.extractAddress();

    return address.hex;
    ;
  }


  static Future<EthPrivateKey> importKey(String mnemonic) async {
   return  await WalletHd.ethMnemonicToPrivateKey(mnemonic);
  }

  buildChips() {
    Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: prhases.map((e) => _buildChip('Gamer', Color(0xff424f5c))),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      labelPadding: EdgeInsets.all(2.0),
      avatar: null,
      label: Text(
        label,
        style: TextStyle(color: Color(0xff424f5c), fontSize: 16),
      ),
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide()),
      elevation: 6.0,
      shadowColor: Colors.grey[60],
      padding: EdgeInsets.all(8.0),
    );
  }

  Future createteWallet() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(Duration(seconds: 1));




    String mnemonic = WalletHd.createRandomMnemonic();

   // var mapAddr = await WalletHd.ethMnemonicToPrivateKey(mnemonic);

    var mapAddr = await compute(importKey, mnemonic);




    setState(() {
      prhasesString = mnemonic;
      prhases = mnemonic.split(" ");
    });

 //   final resultPrivate = await compute(generateKey, mnemonic);



    final result = await compute(generateWallet, mnemonic);
    walletController.setTokenAndWallet(
        result, prhasesString, HEX.encode(mapAddr.privateKey));
    setState(() {
      isLoading = false;
    });

    controller.open();
    setState(() {
      step = 2;
    });
  }

  Future importWallet() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(Duration(seconds: 1));

    String mnemonic = controllerClassic.text.trim();



    var mapAddr = await compute(importKey, mnemonic);

    setState(() {
      prhasesString = mnemonic;
      prhases = mnemonic.split(" ");
    });

  //  final resultPrivate = await compute(generateKey, mnemonic);
    final result = await compute(generateWallet, mnemonic);
    walletController.setTokenAndWallet(
        result, prhasesString, HEX.encode(mapAddr.privateKey));
    setState(() {
      isLoading = false;
    });

    controller.open();
    setState(() {
      step = 2;
    });
  }

  void copyPrhases(String prhases) {
    FlutterClipboard.copy(prhases).then((value) {
      Toast.show("Your phrase was copied", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    });
  }

  final GlobalKey<TagsState> _tagStateKey = GlobalKey<TagsState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff424f5c),
      body: ModalProgressHUD(
        child: SlidingUpPanel(
          controller: controller,
          backdropEnabled: true,
          renderPanelSheet: true,
          panelSnapping: true,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          minHeight: 0,
          maxHeight: step == 1 ? 400 : 350,
          panel: step == 1
              ? Container(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: Text(
                          "Write or paste your phrase, separated by single spaces",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            padding:
                                EdgeInsets.only(left: 20, right: 20, top: 30),
                            child: TextFormField(
                              onChanged: (word) {
                                var words = word.trim().split(" ");
                                setState(() {
                                  numbersWords = words.length;
                                });
                                print(word);
                              },
                              controller: controllerClassic,
                              minLines: 4,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                hintText: 'e.g. curious business thought etc',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20.0)),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                              child: Container(
                            child: Text("${numbersWords} words",style: TextStyle(color: numbersWords>12 ? Colors.redAccent: Colors.grey),),
                          ),
                            bottom: 10,
                            left: 35,
                          ),
                          Positioned(
                            child: InkWell(
                              onTap: () async {
                                FlutterClipboard.paste().then((value) {
                                  controllerClassic.text = value;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(30),
                                        bottomRight: Radius.circular(30))),
                                padding: EdgeInsets.only(
                                    left: 10, right: 5, top: 10, bottom: 5),
                                child: Row(
                                  children: [
                                    Text("Paste"),
                                  ],
                                ),
                              ),
                            ),
                            bottom: 5,
                            right: 30,
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                        width: double.infinity,
                        child: RaisedButton(
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: () {
                            //controller.open();
                            var words = controllerClassic.text.split(" ");
                            if (words.length < 12) {
                              setState(() {
                                isError = true;
                              });
                              Alert(
                                context: context,
                                type: AlertType.error,
                                title: "Review the phrases",
                                desc:
                                    "Please check that the number of phrases is 12 ",
                                buttons: [
                                  DialogButton(
                                    child: Text(
                                      "Ok",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    width: 120,
                                    color: Color(0xff424f5c),
                                  )
                                ],
                              ).show();
                            } else {
                              importWallet();
                            }
                          },
                          child: Text(
                            "Import",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          color: Color(0xff424f5c),
                        ),
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        "Copy and save your secret phrase",
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                    Container(
                      height: 200,
                      padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                      child: prhases.length > 0
                          ? SingleChildScrollView(
                              child: Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: prhasesString
                                    .split(' ') // split the text into an array
                                    .map((String text) => _buildChip(
                                        text,
                                        Color(
                                            0xff424f5c))) // put the text inside a widget
                                    .toList(),
                              ),
                            )
                          : Container(),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 20, right: 20, top: 10),
                      width: double.infinity,
                      child: OutlineButton(
                        child: Text(
                          "Copy your phrase",
                          style:
                              TextStyle(color: Color(0xff424f5c), fontSize: 18),
                        ),
                        onPressed: () {
                          copyPrhases(prhasesString);
                        },
                        borderSide:
                            BorderSide(width: 2.0, color: Color(0xff424f5c)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 0, left: 20, right: 20),
                      width: double.infinity,
                      child: RaisedButton(
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(10.0),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FinishScreen()),
                            (Route<dynamic> route) => false,
                          );

                          ///controller.open();
                        },
                        child: Text(
                          "Next",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        color: Color(0xff424f5c),
                      ),
                    )
                  ],
                ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                      child: AnimatedBackground(
                    behaviour: RandomParticleBehaviour(
                        options: ParticleOptions(
                      baseColor: Color(0xff3b4651),
                      spawnOpacity: 0.0,
                      opacityChangeRate: 0.25,
                      minOpacity: 0.1,
                      maxOpacity: 0.4,
                      spawnMinSpeed: 30.0,
                      spawnMaxSpeed: 70.0,
                      spawnMinRadius: 7.0,
                      spawnMaxRadius: 30.0,
                      particleCount: 40,
                    )),
                    vsync: this,
                    child: Text(""),
                  )),
                ],
              ),
              Center(
                child: Image.asset(
                  "assets/white-logo-dark.png",
                  scale: 2.5,
                ),
              ),
              Align(
                child: Container(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            child: RaisedButton(
                              shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(10.0),
                              ),
                              onPressed: () async {
                                walletController.tags.value = [];
                                controllerClassic.text="";

                                createteWallet();
                              },
                              child: Text(
                                "Create new wallet",
                                style: TextStyle(fontSize: 20),
                              ),
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            child: OutlinedButton(
                              child: Text(
                                "Import wallet",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              onPressed: () {
                                setState(() {
                                  step = 1;
                                });
                                walletController.tags.value = [];
                                controller.open();
                              },
                              style: ElevatedButton.styleFrom(
                                side:
                                    BorderSide(width: 2.0, color: Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                alignment: Alignment.bottomCenter,
              )
            ],
          ),
        ),
        inAsyncCall: isLoading,
      ),
    );
  }
}

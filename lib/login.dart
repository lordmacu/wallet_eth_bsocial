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
  String prhasesString = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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

     String mnemonic =WalletHd.createRandomMnemonic();


    var mapAddr = await WalletHd.ethMnemonicToPrivateKey(mnemonic);

    setState(() {
      prhasesString = mnemonic;
      prhases = mnemonic.split(" ");
    });

    final resultPrivate = await compute(generateKey, mnemonic);
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

    String mnemonic =walletController.tags.join(" ");


    var mapAddr = await WalletHd.ethMnemonicToPrivateKey(walletController.tags.join(" "));

    setState(() {
      prhasesString = mnemonic;
      prhases = mnemonic.split(" ");
    });

    final resultPrivate = await compute(generateKey, mnemonic);
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

  void copyPrhases(String prhases){
    FlutterClipboard.copy(prhases).then(( value ) {
      Toast.show("Your phrase was copied", context, duration: Toast.LENGTH_LONG, gravity:  Toast.BOTTOM);

    });
  }

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
          maxHeight: step == 1 ? 200 : 350,
          panel: step == 1
              ? Container(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        child: Text(
                          "Write your secret phrase",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: TextFieldTags(

                          tagsStyler: TagsStyler(
                              tagTextStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              tagDecoration: BoxDecoration(
                                color: Color(0xff424f5c),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              tagCancelIcon: Container(
                                child: Icon(Icons.cancel,
                                    size: 18.0, color: Colors.white),
                                padding: EdgeInsets.only(left: 5),
                              ),
                              tagPadding: const EdgeInsets.all(6.0)),
                          textFieldStyler: TextFieldStyler(
                              hintText: "Write your phrase word by word",
                              helperText: null,
                              isDense: false),
                          onTag: (tag) {
                            walletController.tags.add(tag);

                          },
                          onDelete: (tag) {
                            walletController.tags.remove(tag);
                          },
                        ),
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
                            if(walletController.tags.length<12){

                            }else{
                              print("aquii estan los tags  ${ walletController.tags}");
                              importWallet();
                            }
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
                )
              : Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        "Copy and save your secret phrase",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: prhases.length > 0
                          ? Wrap(
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: prhasesString
                                  .split(' ') // split the text into an array
                                  .map((String text) => _buildChip(
                                      text,
                                      Color(
                                          0xff424f5c))) // put the text inside a widget
                                  .toList(),
                            )
                          : Container(),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 20, right: 20,top: 20),

                      width: double.infinity,
                      child: OutlinedButton(
                        child: Text(
                          "Copy your phrase",
                          style: TextStyle(
                              color: Color(0xff424f5c), fontSize: 18),
                        ),
                        onPressed: () {
                          copyPrhases(prhasesString);
                        },
                        style: ElevatedButton.styleFrom(
                          side:
                          BorderSide(width: 2.0, color: Color(0xff424f5c)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
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
                            MaterialPageRoute(builder: (context) => FinishScreen()),
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
                                walletController.tags.value=[];

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
                                walletController.tags.value=[];
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

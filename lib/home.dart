import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:social_wallet/address.dart';
import 'package:social_wallet/controllers/BalanceController.dart';
import 'package:social_wallet/controllers/WalletController.dart';
import 'package:social_wallet/transaction.dart';
import 'package:social_wallet/uiHelpers/animationBackground.dart';
import 'package:get/get.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/services.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatelessWidget {
  BalanceWallet walletController = Get.put(BalanceWallet());
  TextEditingController walletControlerText = TextEditingController();

  PanelController controller = PanelController();
  final _formKey = GlobalKey<FormState>();

  var _url='https://app.uniswap.org/#/swap?inputCurrency=ETH&outputCurrency=0x26a79Bd709A7eF5E5F747B8d8f83326EA044d8cC&use=V2';

  void launchUrl() async =>
      await canLaunch(_url) ? await launch(_url) : throw 'Could not launch $_url';
  showPopUp(context){
    Alert(
        context: context,
        style: AlertStyle(
          descStyle: TextStyle(color: Color(0xff424f5c)),
          titleStyle: TextStyle(fontSize: 30,color: Color(0xff424f5c))
        ),
        title: "Well done!",
        content: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Text("The transaction is being processed" ,style: TextStyle(color: Color(0xff424f5c),fontSize: 18),),
            ),
            Container(
              margin: EdgeInsets.only(top: 15),
              child: Text("Please wait.The average transaction time is 120 minutes",style: TextStyle(fontWeight: FontWeight.w300,color: Color(0xff424f5c),fontSize: 16),),
            ),

          ],
        ),
        buttons: [
          DialogButton(
            color: Color(0xff424f5c),
            onPressed: () {
              walletController.LoadBalance();
              controller.close();

              Navigator.pop(context);
            },
            child: Text(
              "Back to wallet",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
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
          maxHeight: 350,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          minHeight: 0,
          body: Column(
            children: [
              Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      AnimationBackground(),
                      Align(
                        child: Container(
                          margin: EdgeInsets.only(top: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                child: Image.asset("assets/logo_social.png"),
                              ),
                              Obx(() => Container(
                                    margin: EdgeInsets.only(top: 20),
                                    child: Text(
                                      "${walletController.bsocialBalance.value}",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 35,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                              Obx(() => Container(
                                    margin: EdgeInsets.only(top: 5),
                                    child: Text(
                                      "(${walletController.usdValue.value})",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                child: OutlinedButton(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "You gained",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 25,
                                            fontWeight: FontWeight.w300),
                                        textAlign: TextAlign.center,
                                      ),
                                      Stack(
                                        children: [
                                          Text(
                                            " ${walletController.totalEarnings.value}",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    side: BorderSide(
                                        width: 2.0, color: Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 30),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    RaisedButton(
                                      onPressed: () {
                                        controller.open();

                                        ///  walletController.getpriceCoin();
                                      },
                                      child: Text(
                                        "Transfer",
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Color(0xff424f5c)),
                                      ),
                                      color: Colors.white,
                                    ),
                                    RaisedButton(
                                      onPressed: () {

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => AddressPage()),
                                        );
                                      },
                                      child: Text(
                                        "Recieve",
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Color(0xff424f5c)),
                                      ),
                                      color: Colors.white,
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                      ),
                      Align(
                        child: Container(
                          margin: EdgeInsets.only(top: 40, left: 15, right: 15),
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                child: InkWell(
                                  child: Icon(
                                    Icons.shopping_basket_outlined,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  onTap: (){
                                    launchUrl();
                                  },
                                ),
                              ),
                              Container(
                                child: Text(
                                  "Wallet",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 30),
                                ),
                              ),
                              Container(
                                child: Icon(
                                  Icons.settings_sharp,
                                  size: 30,
                                  color: Colors.transparent,
                                ),
                              )
                            ],
                            mainAxisSize: MainAxisSize.max,
                          ),
                        ),
                        alignment: Alignment.topCenter,
                      ),
                    ],
                  )),
              Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.only(left: 30, right: 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          topLeft: Radius.circular(20)),
                      color: Colors.white,
                    ),
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 30, bottom: 10),
                          child: Text(
                            "Recent Transactions",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w300),
                          ),
                        ),
                        Expanded(
                            child: GetBuilder<BalanceWallet>(
                          builder: (_dx) => ListView.builder(
                              itemCount: _dx.transactions.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: (){
                                    print( _dx.transactions[index]);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 30),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                child: _dx.transactions[index]
                                                    .type ==
                                                    "up"
                                                    ? Icon(
                                                  Icons.arrow_circle_up,
                                                  color: Colors.greenAccent,
                                                )
                                                    : Icon(
                                                  Icons.arrow_circle_down,
                                                  color: Colors.redAccent,
                                                ),
                                                margin: EdgeInsets.only(right: 5),
                                              ),
                                              Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        child: Text(
                                                          "${_dx.transactions[index].from}",
                                                          overflow:
                                                          TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                              FontWeight.bold,
                                                              color:
                                                              Color(0xff424f5c)),
                                                        ),
                                                      ),
                                                      Container(
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              "${_dx.convertTimeStampToHumanDate(int.parse(_dx.transactions[index].timeStamp))}",
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                  FontWeight.bold,
                                                                  color: Colors.grey
                                                                      .withOpacity(
                                                                      0.7)),
                                                            )
                                                          ],
                                                        ),
                                                        margin:
                                                        EdgeInsets.only(top: 5),
                                                      )
                                                    ],
                                                  ))
                                            ],
                                          ),
                                          flex: 6,
                                        ),
                                        Expanded(
                                            flex: 4,
                                            child: Container(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    "${_dx.transactions[index].price}",
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        color: Color(0xff424f5c)),
                                                  )
                                                ],
                                                mainAxisAlignment:
                                                MainAxisAlignment.end,
                                              ),
                                            ))
                                      ],
                                    ),
                                  ),
                                );

                              }),
                        ))
                      ],
                    ),
                  ))
            ],
          ),
          panel: Container(
            margin: EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Obx(()=>Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 20, bottom: 30),
                  child:Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Available",
                        style: TextStyle(fontSize: 20),
                      ),
                     Expanded(child:  Text(
                       " ${walletController.bsocialBalance.value}",
                       style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
                     ))
                    ],
                  ),
                ),
                Form(
                  key: _formKey,

                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            child:TextFormField(
                              controller: walletControlerText,
                              decoration: new InputDecoration(
                                labelText: "Enter wallet address",
                                fillColor: Colors.white,
                                border: new OutlineInputBorder(
                                  borderRadius: new BorderRadius.circular(25.0),
                                  borderSide: new BorderSide(),
                                ),
                                //fillColor: Colors.green
                              ),
                              validator: (val) {


                                if (val.length == 0) {
                                  return "Email cannot be empty";
                                } else {
                                  return null;
                                }
                              },
                              keyboardType: TextInputType.emailAddress,
                              style: new TextStyle(
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                          Positioned(
                            right: 5,
                            top: 5,
                            child: walletController.valuePasteWallet.value.length == 0
                                ? InkWell(
                              onTap: () async {
                                FlutterClipboard.paste().then((value) {
                                  walletControlerText.text = value;

                                  walletController.valuePasteWallet.value =
                                      value;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(30),
                                        bottomRight: Radius.circular(30))),
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.paste,
                                  size: 25,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                                : InkWell(
                              onTap: () async {
                                FlutterClipboard.paste().then((value) {
                                  walletControlerText.text = "";

                                  walletController.valuePasteWallet.value =
                                  "";
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(30),
                                        bottomRight: Radius.circular(30))),
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.cancel_outlined,
                                  size: 25,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: TextFormField(
                          inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                          keyboardType: TextInputType.number,
                          decoration: new InputDecoration(
                            labelText: "Enter ammount",
                            fillColor: Colors.white,
                            border: new OutlineInputBorder(
                              borderRadius: new BorderRadius.circular(25.0),
                              borderSide: new BorderSide(),
                            ),
                            //fillColor: Colors.green
                          ),
                          onChanged: (val){

                            walletController.canTransfer.value=double.parse(val);

                          },

                           style: new TextStyle(
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        child: RaisedButton(
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: walletController.canTransfer.value <= walletController.bsocialBalanceNumber.value ?  ()  async{

                          var transaction= await  walletController.transferToAnother();
                          final formatter = new NumberFormat("#,###.##");
                        var value= formatter.format(walletController.canTransfer.value);
                         /* Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TransactionPage(transaction,value,walletController.valuePasteWallet.value)),
                          );*/
                          showPopUp(context);


                          } : null ,
                          child: Text(
                            "Transfer \$Bsocial",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          color: Color(0xff424f5c),
                        ),
                      )
                    ],
                  ),
                )
              ],
            )),
          ),
        ),
        inAsyncCall: walletController.isloading.value,
      ),
    );
  }
}

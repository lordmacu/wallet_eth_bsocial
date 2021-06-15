import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:slide_popup_dialog/slide_popup_dialog.dart' as slideDialog;
import 'login.dart';
import 'package:flutter_boom_menu/flutter_boom_menu.dart';
import 'package:social_wallet/models/Transaction.dart' as tr;

import 'package:social_wallet/models/Coin.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart'; //You can also import the browser version
import 'dart:math';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  BalanceWallet walletController = Get.put(BalanceWallet());
  TextEditingController walletControlerText = TextEditingController();
  Timer timer;

  PanelController controller = PanelController();
  final _formKey = GlobalKey<FormState>();
  var transactions = [];



  LoadBalanceWihoutLoading(bool withloading) async {
    if(withloading){
      walletController.isloading.value = true;

    }

    print("cargando");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final formatter = new NumberFormat("#,###.##");

    var token = prefs.getString("token");
    var httpClient = new Client();
    var ethClient = new Web3Client(
        "https://mainnet.infura.io/v3/4a2bad1755634c5b9771f76163e9d129",
        httpClient);
    Credentials fromHex = EthPrivateKey.fromHex(token);
    var addresds = await fromHex.extractAddress();

    var balance = await ethClient.getBalance(addresds);

    walletController.ethBalance.value =
        "${balance.getValueInUnit(EtherUnit.ether)}";

    final EthereumAddress contractAddr =
        EthereumAddress.fromHex('0x26a79Bd709A7eF5E5F747B8d8f83326EA044d8cC');

    var abicode = walletController.getAbi();
    final contract = DeployedContract(
        ContractAbi.fromJson(abicode, 'Bsocial'), contractAddr);

    final balanceFunction = contract.function('balanceOf');

    final client = Web3Client(
        "https://mainnet.infura.io/v3/4a2bad1755634c5b9771f76163e9d129",
        Client(), socketConnector: () {
      return IOWebSocketChannel.connect(
              "wss://mainnet.infura.io/ws/v3/4a2bad1755634c5b9771f76163e9d129")
          .cast<String>();
    });

    final balances = await client.call(
        contract: contract, function: balanceFunction, params: [addresds]);
    var balanceBsocial = (double.parse("${balances[0]}") / pow(10, 8));
    Coin coin = await walletController.getpriceCoin();
    walletController.bsocialBalance.value =
        "${formatter.format(balanceBsocial)}";
    walletController.bsocialBalanceNumber.value = balanceBsocial;

    walletController.usdValue.value =
        "\$${formatter.format(balanceBsocial * double.parse(coin.price))}";

    await getTransactions(balanceBsocial, double.parse(coin.price));
  }

  getTransactions(balanceBsocial, priceCoin) async {
    var transactionsLocal = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var wallet = prefs.getString("wallet");
    final formatter = new NumberFormat("#,###.##");

    var url = Uri.parse(
        'https://api.etherscan.io/api?module=account&action=tokentx&address=${wallet}&startblock=0&endblock=999999999&sort=desc&apikey=3YF336R8GJFSC6KT34S4JSS812WM536RVU');
    var response = await http.get(url);

    var result = jsonDecode(response.body);

    double total = 0;
    result["result"].forEach((item) {
      if (item["tokenSymbol"] == "BSOCIAL") {
        var value = (double.parse(item["value"]) / pow(10, 8));
        var balanceTotal = item["value"];

        var type = "";
        if ("${item["to"]}".toLowerCase() == wallet.toLowerCase()) {
          total = total + double.parse(balanceTotal);
          type = "up";
        } else {
          total = total - double.parse(balanceTotal);
          type = "down";
        }

        tr.Transaction transaction = tr.Transaction(
            item["blockNumber"],
            item["timeStamp"],
            item["hash"],
            item["nonce"],
            item["blockHash"],
            item["from"],
            item["contractAddress"],
            item["to"],
            "${formatter.format(value)}",
            item["tokenName"],
            item["tokenSymbol"],
            item["tokenDecimal"],
            item["transactionIndex"],
            item["gas"],
            item["gasPrice"],
            item["gasUsed"],
            item["cumulativeGasUsed"],
            item["input"],
            item["confirmations"],
            type);
        transactionsLocal.add(transaction);
      }
    });

    setState(() {
      transactions = transactionsLocal;
    });

    var balanceBsociadl = (double.parse("${total}") / pow(10, 8));

    var totalGained = balanceBsocial - balanceBsociadl;

    walletController.totalEarnings.value =
        "\$${formatter.format(totalGained * priceCoin)}";

    walletController.isloading.value = false;
  }
  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    timer = Timer.periodic(Duration(seconds: 30), (Timer t) => LoadBalanceWihoutLoading(false));

    LoadBalanceWihoutLoading(true);
  }

  void launchUrl(_url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';

  showTransaction(tr.Transaction transaction){
    print(transaction);
    Alert(
        context: context,
        style: AlertStyle(
            descStyle: TextStyle(color: Color(0xff424f5c)),
            titleStyle: TextStyle(fontSize: 30, color: Color(0xff424f5c))),
        title: "Transaction",
        content: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Text(
                    "Date:",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
                  ),
                  Text(
                    "${walletController.convertTimeStampToHumanDate(int.parse(transaction.timeStamp))}",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
                  )
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Text(
                    "From:",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
                  ),
                 Expanded(child:  Container(child: Text(
                   "${transaction.from}",
                   style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                 ),margin: EdgeInsets.only(left: 10),))
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Text(
                    "To:",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
                  ),
                  Expanded(child:  Container(child: Text(
                    "${transaction.to}",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                  ),margin: EdgeInsets.only(left: 10),))
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Text(
                    "Price:",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
                  ),
                  Expanded(child:  Container(child: Text(
                    "${transaction.price}",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                  ),margin: EdgeInsets.only(left: 10),))
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Text(
                    "Gas:",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
                  ),
                  Expanded(child:  Container(child: Text(
                    "${transaction.gas}",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                  ),margin: EdgeInsets.only(left: 10),))
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Text(
                    "Gas price:",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
                  ),
                  Expanded(child:  Container(child: Text(
                    "${transaction.gasPrice}",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                  ),margin: EdgeInsets.only(left: 10),))
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Text(
                    "Confirmations:",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
                  ),
                  Expanded(child:  Container(child: Text(
                    "${transaction.confirmations}",
                    style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                  ),margin: EdgeInsets.only(left: 10),))
                ],
              ),
            ),

          ],
        ),
        buttons: [
          DialogButton(
            color: Color(0xff424f5c),
            onPressed: () {
              launchUrl("https://etherscan.io/tx/${transaction.hash}");

              Navigator.pop(context);
            },
            child: Text(
              "Go to transaction",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }

  showPopUp(context) {
    Alert(
        context: context,
        style: AlertStyle(
            descStyle: TextStyle(color: Color(0xff424f5c)),
            titleStyle: TextStyle(fontSize: 30, color: Color(0xff424f5c))),
        title: "Well done!",
        content: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Text(
                "The transaction is being processed",
                style: TextStyle(color: Color(0xff424f5c), fontSize: 18),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 15),
              child: Text(
                "Please wait.The average transaction time is 120 minutes",
                style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Color(0xff424f5c),
                    fontSize: 16),
              ),
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
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      floatingActionButton: BoomMenu(
        backgroundColor: Color(0xff424f5c),
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0),

        //child: Icon(Icons.add),
        onOpen: () => print('OPENING DIAL'),
        onClose: () => print('DIAL CLOSED'),
        overlayColor: Colors.black,
        overlayOpacity: 0.7,
        children: [
          MenuItem(
            child: Container(
              child: Image.asset("assets/icon.png"),
              width: 35,
            ),
            title: "Visit BankSocial ",
            titleColor: Color(0xff424f5c),
            subtitle: "Check news and more information",
            subTitleColor: Color(0xff424f5c),
            backgroundColor: Colors.white,
            onTap: () {
              launchUrl("https://banksocial.io/");
            },
          ),
          MenuItem(
            child: Container(
              child: Image.asset("assets/uniswap.png"),
              width: 35,
            ),
            title: "Buy \$BSocial ",
            titleColor: Color(0xff424f5c),
            subtitle: "Purchase token now",
            subTitleColor: Color(0xff424f5c),
            backgroundColor: Colors.white,
            onTap: () {
              launchUrl(
                  "https://www.dextools.io/app/uniswap/pair-explorer/0x6a0d8a35cda1f0d3534a346394661ed02e9a4072");
            },
          ),
          MenuItem(
            child: Container(
              child: Image.asset("assets/dextoolslogo.png"),
              width: 35,
            ),
            title: "View BSocial in Dextools",
            titleColor: Color(0xff424f5c),
            subtitle: "View chart and price in dextools",
            subTitleColor: Color(0xff424f5c),
            backgroundColor: Colors.white,
            onTap: () {
              launchUrl(
                  "https://www.dextools.io/app/uniswap/pair-explorer/0x6a0d8a35cda1f0d3534a346394661ed02e9a4072");
            },
          ),
          MenuItem(
            child: Container(
              child: Image.asset("assets/shop.png"),
              width: 35,
            ),
            title: "BSocial Shop",
            titleColor: Color(0xff424f5c),
            subtitle: "Buy Bsocial merchandise",
            subTitleColor: Color(0xff424f5c),
            backgroundColor: Colors.white,
            onTap: () {
              launchUrl("https://shop.banksocial.io/");
            },
          ),
          MenuItem(
            child: Icon(Icons.logout),
            title: "Logout from wallet",
            titleColor: Color(0xff424f5c),
            subtitle: "Secure logoout from Bsocial wallet",
            subTitleColor: Color(0xff424f5c),
            backgroundColor: Colors.white,
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();

              await prefs.clear();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Login()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      backgroundColor: Color(0xff424f5c),
      body: Obx(() => ModalProgressHUD(
            child: SlidingUpPanel(
              controller: controller,
              backdropEnabled: true,
              renderPanelSheet: true,
              panelSnapping: true,
              maxHeight: 350,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              minHeight: 0,
              body: Container(
                height: height,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
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
                                      child:
                                          Image.asset("assets/logo_social.png"),
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                                      fontWeight:
                                                          FontWeight.bold),
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
                                            borderRadius:
                                                BorderRadius.circular(10.0),
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
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AddressPage()),
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
                                margin: EdgeInsets.only(
                                    top: 40, left: 15, right: 15),
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      child: InkWell(
                                        child: Icon(
                                          Icons.menu,
                                          size: 30,
                                          color: Colors.transparent,
                                        ),
                                        onTap: () {},
                                      ),
                                    ),
                                    Container(
                                      child: Text(
                                        "Wallet",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 30),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        LoadBalanceWihoutLoading(true);
                                      },
                                      child: Container(
                                        child: Icon(
                                          Icons.refresh,
                                          size: 30,
                                          color: Colors.white,
                                        ),
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
                              GetBuilder<BalanceWallet>(
                                  builder: (_dx) => Container(
                                        margin: EdgeInsets.only(
                                            top: 30, bottom: 10),
                                        child: Text(
                                          transactions.length == 0
                                              ? "No recent ransactions"
                                              : "Recent transactions",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w300),
                                        ),
                                      )),
                              Expanded(
                                  child: ListView.builder(
                                      itemCount: transactions.length,
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            showTransaction(transactions[index]);

                                          },
                                          child: Container(
                                            color: Colors.white,
                                            padding: EdgeInsets.only(bottom: 30),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        child:
                                                            transactions[index]
                                                                        .type ==
                                                                    "up"
                                                                ? Icon(
                                                                    Icons
                                                                        .arrow_circle_up,
                                                                    color: Colors
                                                                        .greenAccent,
                                                                  )
                                                                : Icon(
                                                                    Icons
                                                                        .arrow_circle_down,
                                                                    color: Colors
                                                                        .redAccent,
                                                                  ),
                                                        margin: EdgeInsets.only(
                                                            right: 5),
                                                      ),
                                                      Expanded(
                                                          child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            child: Text(
                                                              "${transactions[index].from}",
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                      0xff424f5c)),
                                                            ),
                                                          ),
                                                          Container(
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "${walletController.convertTimeStampToHumanDate(int.parse(transactions[index].timeStamp))}",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.7)),
                                                                )
                                                              ],
                                                            ),
                                                            margin:
                                                                EdgeInsets.only(
                                                                    top: 5),
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
                                                            "${transactions[index].price}",
                                                            style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xff424f5c)),
                                                          )
                                                        ],
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                      ),
                                                    ))
                                              ],
                                            ),
                                          ),
                                        );
                                      }))
                            ],
                          ),
                        ))
                  ],
                ),
              ),
              panel: Container(
                margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                child: Obx(() => Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 20, bottom: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Available",
                                style: TextStyle(fontSize: 20),
                              ),
                              Expanded(
                                  child: Text(
                                " ${walletController.bsocialBalance.value}",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
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
                                    child: TextFormField(
                                      controller: walletControlerText,
                                      decoration: new InputDecoration(
                                        labelText: "Enter wallet address",
                                        fillColor: Colors.white,
                                        border: new OutlineInputBorder(
                                          borderRadius:
                                              new BorderRadius.circular(25.0),
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
                                    child: walletController.valuePasteWallet
                                                .value.length ==
                                            0
                                        ? InkWell(
                                            onTap: () async {
                                              FlutterClipboard.paste()
                                                  .then((value) {
                                                walletControlerText.text =
                                                    value;

                                                walletController
                                                    .valuePasteWallet
                                                    .value = value;
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topRight:
                                                              Radius.circular(
                                                                  30),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  30))),
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
                                              FlutterClipboard.paste()
                                                  .then((value) {
                                                walletControlerText.text = "";

                                                walletController
                                                    .valuePasteWallet
                                                    .value = "";
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topRight:
                                                              Radius.circular(
                                                                  30),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  30))),
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
                                  inputFormatters: [
                                    WhitelistingTextInputFormatter.digitsOnly
                                  ],
                                  keyboardType: TextInputType.number,
                                  decoration: new InputDecoration(
                                    labelText: "Enter ammount",
                                    fillColor: Colors.white,
                                    border: new OutlineInputBorder(
                                      borderRadius:
                                          new BorderRadius.circular(25.0),
                                      borderSide: new BorderSide(),
                                    ),
                                    //fillColor: Colors.green
                                  ),
                                  onChanged: (val) {
                                    walletController.canTransfer.value =
                                        double.parse(val);
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
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                  ),
                                  onPressed:
                                      walletController.canTransfer.value <=
                                              walletController
                                                  .bsocialBalanceNumber.value
                                          ? () async {
                                              var transaction =
                                                  await walletController
                                                      .transferToAnother();
                                              final formatter =
                                                  new NumberFormat("#,###.##");
                                              var value = formatter.format(
                                                  walletController
                                                      .canTransfer.value);
                                              /* Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TransactionPage(transaction,value,walletController.valuePasteWallet.value)),
                          );*/
                                              showPopUp(context);
                                            }
                                          : null,
                                  child: Text(
                                    "Transfer \$Bsocial",
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.white),
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
          )),
    );
  }
}

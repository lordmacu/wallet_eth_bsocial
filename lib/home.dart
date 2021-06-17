import 'dart:async';
import 'dart:math';

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
import 'package:forceupdate/forceupdate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

import 'package:social_wallet/models/Coin.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart'; //You can also import the browser version
import 'dart:math';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:after_layout/after_layout.dart';

import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';

class Home extends StatefulWidget {
  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> with AfterLayoutMixin<Home> {
  BalanceWallet walletController = Get.put(BalanceWallet());
  TextEditingController walletControlerText = TextEditingController();
  Timer timer;
  Timer timerGraphic;

  double max;
  double min;
  List<FlSpot> spots = [];
  List<double> rates = [];

  var lastPrice;
  bool isShowPopup = false;

  PanelController controller;
  final _formKey = GlobalKey<FormState>();
  var transactions = [];
  List<Color> gradientColors = [
    const Color(0xff88c4ff),
    const Color(0xffffffff),
  ];

  Future<void> checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      if (info.updateAvailable) {
        InAppUpdate.startFlexibleUpdate().then((_) {}).catchError((e) {});
      }
    }).catchError((e) {});
  }

  LoadBalanceWihoutLoading(bool withloading) async {
    if (withloading) {
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
    timerGraphic.cancel();

    super.dispose();
  }

  checkVersion() async {
    final checkVersion = CheckVersion(context: context);
    final appStatus = await checkVersion.getVersionStatus();
    if (appStatus.canUpdate) {
      checkVersion.showUpdateDialog("com.companyName.appName", "id0123456789");
    }
  }

  LineChartData mainData() {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueAccent,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((LineBarSpot barSpot) {
                var value = "${barSpot.y}".substring(0, 11);
                return LineTooltipItem(
                  '${value} \n ${walletController.convertTimeStampToHumanDateMinutes(barSpot.x.toInt())}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            }),
      ),
      gridData: FlGridData(
        show: false,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: false,
          reservedSize: 0,
          getTextStyles: (value) => const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 16),
          getTitles: (value) {
            switch (value.toInt()) {
              case 2:
                return 'MAR';
              case 5:
                return 'JUN';
              case 8:
                return 'SEP';
            }
            return ' ';
          },
        ),
        leftTitles: SideTitles(
          showTitles: false,
          getTextStyles: (value) => const TextStyle(
            color: Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '10k';
              case 3:
                return '30k';
              case 5:
                return '50k';
            }
            return ' ';
          },
        ),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 0)),
      lineBarsData: [
        spots.length>0 ? LineChartBarData(
          spots: spots,
          isCurved: true,
          colors: gradientColors,
          barWidth: 1,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: false,
            colors:
                gradientColors.map((color) => color.withOpacity(0.3)).toList(),
          ),
        ): null,
      ],
    );
  }

  handleAppLifecycleState() {
    AppLifecycleState _lastLifecyleState;
    SystemChannels.lifecycle.setMessageHandler((msg) {

      print('SystemChannels> $msg');

      switch (msg) {
        case "AppLifecycleState.paused":
          _lastLifecyleState = AppLifecycleState.paused;
          break;
        case "AppLifecycleState.inactive":
          _lastLifecyleState = AppLifecycleState.inactive;
          break;
        case "AppLifecycleState.resumed":
          loadJson();
          LoadBalanceWihoutLoading(true);
          _lastLifecyleState = AppLifecycleState.resumed;
          break;

          break;
        default:
      }
    });
  }

  Future loadJson() async{
    List<FlSpot> spotsTemp = [];


    print("load graphic");

    var now =DateTime.now();
    var end =now.subtract(Duration(hours: 24));
    var stringNow="${now.millisecondsSinceEpoch}".substring(0, 12);;
    var url = Uri.parse('https://api.coinmarketcap.com/data-api/v3/cryptocurrency/detail/chart?id=10102&range=1D');

    print(url);
    var response = await http.get(url);

    var jsonData = jsonDecode(response.body);
    var data = jsonData["data"]["points"];

    data.forEach((final String key, final value) {

      FlSpot spot = FlSpot(double.parse(key), value["v"][0].toDouble());
       rates.add(value["v"][0].toDouble());
      spotsTemp.add(spot);

    });

    print("esta es la cantidad ${spotsTemp.length}");
   // spotsTemp.removeRange((spotsTemp.length/3).toInt(), spotsTemp.length);
    print("esta es la cantidad ${spotsTemp.length}");


    setState(() {
      max = rates.reduce((curr, next) => curr > next ? curr : next);
      min = rates.reduce((curr, next) => curr < next ? curr : next);
      spots=spotsTemp;
      lastPrice="${rates.last}".substring(0, 12);
      print("this is the last ${lastPrice}");
    });

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    print("aquiii ${DateTime.now().microsecondsSinceEpoch}");

    controller = PanelController();


  }

  void launchUrl(_url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';

  showTransaction(tr.Transaction transaction) {
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
                  Expanded(
                      child: Container(
                    child: Text(
                      "${transaction.from}",
                      style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                    ),
                    margin: EdgeInsets.only(left: 10),
                  ))
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
                  Expanded(
                      child: Container(
                    child: Text(
                      "${transaction.to}",
                      style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                    ),
                    margin: EdgeInsets.only(left: 10),
                  ))
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
                  Expanded(
                      child: Container(
                    child: Text(
                      "${transaction.price}",
                      style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                    ),
                    margin: EdgeInsets.only(left: 10),
                  ))
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
                  Expanded(
                      child: Container(
                    child: Text(
                      "${transaction.gas}",
                      style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                    ),
                    margin: EdgeInsets.only(left: 10),
                  ))
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
                  Expanded(
                      child: Container(
                    child: Text(
                      "${transaction.gasPrice}",
                      style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                    ),
                    margin: EdgeInsets.only(left: 10),
                  ))
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
                  Expanded(
                      child: Container(
                    child: Text(
                      "${transaction.confirmations}",
                      style: TextStyle(color: Color(0xff424f5c), fontSize: 15),
                    ),
                    margin: EdgeInsets.only(left: 10),
                  ))
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

  buildMenuItem(icon, title, subitle, url) {
    var isLogout = false;
    if (icon == 'assets/logout.png') {
      isLogout = true;
    }

    return GestureDetector(
      onTap: () async {
        if (isLogout) {
          SharedPreferences prefs = await SharedPreferences.getInstance();

          await prefs.clear();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Login()),
            (Route<dynamic> route) => false,
          );
        } else {
          launchUrl(url);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Row(
          children: [
            Container(
              child: isLogout ? Icon(Icons.logout) : Image.asset(icon),
              width: 35,
            ),
            Expanded(
                child: Container(
              margin: EdgeInsets.only(left: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text(
                      title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: Color(0xff424f5c)),
                    ),
                    margin: EdgeInsets.only(bottom: 5),
                  ),
                  Text(
                    subitle,
                    style: TextStyle(fontSize: 15, color: Color(0xff424f5c)),
                  ),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final double navigationBarHeight = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Color(0xff424f5c),
      body: Obx(() => ModalProgressHUD(
            child: SlidingUpPanel(
              controller: controller,
              backdropEnabled: true,
              parallaxEnabled: true,
              maxHeight: 350,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              minHeight: isShowPopup ? 0 : (height * 27) / 100,
              body: Container(
                child: Stack(
                  children: [
                    AnimationBackground(),
                    Container(
                      margin: EdgeInsets.only(top: (height * 6) / 100),
                      child: Column(
                        children: [
                          Container(
                            child: Image.asset("assets/icon.png"),
                            width: (height * 7) / 100,
                            margin: EdgeInsets.only(top: 10),
                          ),
                          Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  Obx(() => Container(
                                        margin: EdgeInsets.only(top: 20),
                                        child: Text(
                                          "${walletController.bsocialBalance.value}",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 30,
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
                                    margin:
                                        EdgeInsets.only(top: 10, bottom: 10),
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
                                                fontSize: 17,
                                                fontWeight: FontWeight.w300),
                                            textAlign: TextAlign.center,
                                          ),
                                          Stack(
                                            children: [
                                              Text(
                                                " ${walletController.totalEarnings.value}",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
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
                                ],
                              )),
                          rates.length > 0 ? Expanded(
                              flex: 14,
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Row(

                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(left: 30),
                                        child: Text("${max}".substring(0, 12),
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                      ),
                                      Container(
                                        padding: EdgeInsets.only(left: 5,right: 5,top: 2,bottom: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(30)
                                        ),
                                        margin: EdgeInsets.only(right: 20),
                                        child: Text("Current: ${lastPrice}",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                                color: Color(0xff424f5c),
                                                fontSize: 13)),
                                      )
                                    ],
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  ),
                                  Container(
                                      margin:
                                          EdgeInsets.only(top: 5, bottom: 5),
                                      height: (height * 20) / 100,
                                      padding: EdgeInsets.only(
                                          left: 30, right: 20, top: 20),
                                      width: double.infinity,
                                      child: spots.length>0  ?LineChart(
                                      mainData(),
                    ) : Container() ),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Container(
                                        margin:
                                            EdgeInsets.only(top: 10, right: 20),
                                        child: Text(
                                          "${min}".substring(0, 12),
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ))
                                    ],
                                  ),
                                ],
                              )) : Container(),
                        ],
                      ),
                    ),
                    Positioned(
                        top: 40,
                        left: 10,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isShowPopup = true;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.menu,
                              color: Colors.white,
                            ),
                          ),
                        )),
                    AnimatedOpacity(
                      opacity: isShowPopup ? 1 :  0,
                      duration: Duration(milliseconds: 500),
                      child: isShowPopup ? Container(
                        padding: EdgeInsets.all(40),
                        color: Colors.black.withOpacity(0.5),
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            buildMenuItem(
                                "assets/icon.png",
                                "Visit BankSocial ",
                                "Check news and more information",
                                "https://banksocial.io/"),
                            buildMenuItem(
                                "assets/uniswap.png",
                                "Buy \$BSocial  ",
                                "Purchase token now",
                                "https://exchange.banksocial.io/#/swap?inputCurrency=ETH&outputCurrency=0x26a79Bd709A7eF5E5F747B8d8f83326EA044d8cC&use=V2"),
                            buildMenuItem(
                                "assets/dextoolslogo.png",
                                "View BSocial in Dextools ",
                                "Check news and more information",
                                "https://www.dextools.io/app/uniswap/pair-explorer/0x6a0d8a35cda1f0d3534a346394661ed02e9a4072"),
                            buildMenuItem(
                                "assets/shop.png",
                                "BSocial Shop ",
                                "Buy Bsocial merchandise",
                                "https://shop.banksocial.io/"),
                            buildMenuItem(
                                "assets/logout.png",
                                "Logout from wallet",
                                "Secure logoout from Bsocial wallet",
                                "https://banksocial.io/"),
                            Container(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isShowPopup = false;
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Color(0xff424f5c),
                                ),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.white,
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(15),
                                ),
                              ),
                            )
                          ],
                        ),
                      ): Container(),
                    )

                  ],
                ),
              ),
              onPanelClosed: () {
                walletController.step.value = 2;
              },
              backdropTapClosesPanel: true,
              onPanelSlide: (value) {
                if (value < 0.8) {
                  if (controller.isPanelOpen) {
                    //  walletController.step.value=2;
                  }
                }
                print(
                    "este es el valuedd  ${controller.isPanelOpen}  ${value} ${walletController.step.value}");
              },
              panel: Column(
                children: [
                  Container(
                    child: Icon(Icons.drag_handle),
                  ),
                  Expanded(
                      child: Container(
                    margin: EdgeInsets.only(top: 0, left: 20, right: 20),
                    child: Obx(() => Stack(
                          children: [
                            AnimatedOpacity(
                              opacity: walletController.step.value == 2 ? 0 : 1,
                              duration: Duration(milliseconds: 200),
                              child: Column(
                                children: [
                                  Container(
                                    margin:
                                        EdgeInsets.only(top: 20, bottom: 30),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Available",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        Expanded(
                                            child: Text(
                                          " ${walletController.bsocialBalance.value}",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
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
                                              margin:
                                                  EdgeInsets.only(bottom: 20),
                                              child: TextFormField(
                                                controller: walletControlerText,
                                                decoration: new InputDecoration(
                                                  labelText:
                                                      "Enter wallet address",
                                                  fillColor: Colors.white,
                                                  border:
                                                      new OutlineInputBorder(
                                                    borderRadius:
                                                        new BorderRadius
                                                            .circular(25.0),
                                                    borderSide:
                                                        new BorderSide(),
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
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                style: new TextStyle(
                                                  fontFamily: "Poppins",
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 5,
                                              top: 5,
                                              child: walletController
                                                          .valuePasteWallet
                                                          .value
                                                          .length ==
                                                      0
                                                  ? InkWell(
                                                      onTap: () async {
                                                        FlutterClipboard.paste()
                                                            .then((value) {
                                                          walletControlerText
                                                              .text = value;

                                                          walletController
                                                              .valuePasteWallet
                                                              .value = value;
                                                        });
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.only(
                                                                topRight: Radius
                                                                    .circular(
                                                                        30),
                                                                bottomRight: Radius
                                                                    .circular(
                                                                        30))),
                                                        padding:
                                                            EdgeInsets.all(10),
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
                                                          walletControlerText
                                                              .text = "";

                                                          walletController
                                                              .valuePasteWallet
                                                              .value = "";
                                                        });
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.only(
                                                                topRight: Radius
                                                                    .circular(
                                                                        30),
                                                                bottomRight: Radius
                                                                    .circular(
                                                                        30))),
                                                        padding:
                                                            EdgeInsets.all(10),
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
                                              WhitelistingTextInputFormatter
                                                  .digitsOnly
                                            ],
                                            keyboardType: TextInputType.number,
                                            decoration: new InputDecoration(
                                              labelText: "Enter ammount",
                                              fillColor: Colors.white,
                                              border: new OutlineInputBorder(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        25.0),
                                                borderSide: new BorderSide(),
                                              ),
                                              //fillColor: Colors.green
                                            ),
                                            onChanged: (val) {
                                              walletController.canTransfer
                                                  .value = double.parse(val);
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
                                                  new BorderRadius.circular(
                                                      10.0),
                                            ),
                                            onPressed: walletController
                                                        .canTransfer.value <=
                                                    walletController
                                                        .bsocialBalanceNumber
                                                        .value
                                                ? () async {
                                                    var transaction =
                                                        await walletController
                                                            .transferToAnother();
                                                    final formatter =
                                                        new NumberFormat(
                                                            "#,###.##");
                                                    var value = formatter
                                                        .format(walletController
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
                                                  fontSize: 20,
                                                  color: Colors.white),
                                            ),
                                            color: Color(0xff424f5c),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            AnimatedOpacity(
                                opacity:
                                    walletController.step.value == 1 ? 0 : 1,
                                duration: Duration(milliseconds: 200),
                                child: Container(
                                  padding: EdgeInsets.only(left: 0, right: 0),
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
                                        margin: EdgeInsets.only(top: 5),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            RaisedButton(
                                              shape: new RoundedRectangleBorder(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        30.0),
                                              ),
                                              onPressed: () {
                                                walletController.step.value = 1;
                                                controller.open();

                                                ///  walletController.getpriceCoin();
                                              },
                                              child: Text(
                                                "Transfer",
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    color: Colors.white),
                                              ),
                                              color: Color(0xff424f5c),
                                            ),
                                            RaisedButton(
                                              shape: new RoundedRectangleBorder(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        30.0),
                                              ),
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
                                                    fontSize: 17,
                                                    color: Colors.white),
                                              ),
                                              color: Color(0xff424f5c),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: 10, bottom: 10),
                                        child: Text(
                                          transactions.length == 0
                                              ? "No recent ransactions"
                                              : "Recent transactions",
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w300),
                                        ),
                                      ),
                                      transactions.length>0 ? Expanded(
                                          child: ListView.builder(
                                              padding: EdgeInsets.only(top: 10),
                                              itemCount: transactions.length,
                                              itemBuilder: (context, index) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    showTransaction(
                                                        transactions[index]);
                                                  },
                                                  child: Container(
                                                    color: Colors.white,
                                                    padding: EdgeInsets.only(
                                                        bottom: 20, top: 0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Expanded(
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                child: transactions[index]
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
                                                                margin: EdgeInsets
                                                                    .only(
                                                                        right:
                                                                            5),
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
                                                                          fontSize:
                                                                              15,
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          color:
                                                                              Color(0xff424f5c)),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    child: Row(
                                                                      children: [
                                                                        Text(
                                                                          "${walletController.convertTimeStampToHumanDate(int.parse(transactions[index].timeStamp))}",
                                                                          style: TextStyle(
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.grey.withOpacity(0.7)),
                                                                        )
                                                                      ],
                                                                    ),
                                                                    margin: EdgeInsets
                                                                        .only(
                                                                            top:
                                                                                0),
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
                                                                        fontSize:
                                                                            15,
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
                                              })) : Container()
                                    ],
                                  ),
                                )),
                          ],
                        )),
                  ))
                ],
              ),
            ),
            inAsyncCall: walletController.isloading.value,
          )),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    // TODO: implement afterFirstLayout

    if (GetPlatform.isAndroid) {
      checkForUpdate();
    } else {
      checkVersion();
    }

    timer = Timer.periodic(
        Duration(seconds: 30), (Timer t) => LoadBalanceWihoutLoading(false));


    handleAppLifecycleState();
    timerGraphic = Timer.periodic(
        Duration(seconds: 20), (Timer t) => loadJson());
    loadJson();
    LoadBalanceWihoutLoading(true);
  }
}

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

  double max;
  double min;
  List<FlSpot> spots = [];
  List<double> rates = [];

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

               var value="${barSpot.y}".substring(0, 11);
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
        LineChartBarData(


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
        ),
      ],
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    print("aquiii ${DateTime.now().microsecondsSinceEpoch}");

    controller = PanelController();
   var json='{"success":true,"coin":"BSOCIAL","data":[{"date":1621725300000,"rate":0.000009336482946534153,"volume":194810877,"cap":0},{"date":1621732500000,"rate":0.000008271174860086442,"volume":172752509,"cap":0},{"date":1621739700000,"rate":0.000004945118968127416,"volume":52135385,"cap":0},{"date":1621746900000,"rate":0.000005106417354445984,"volume":38796695,"cap":0},{"date":1621754100000,"rate":0.000004467884148868627,"volume":28297790,"cap":0},{"date":1621761300000,"rate":0.00000473615330055071,"volume":28374705,"cap":0},{"date":1621768500000,"rate":0.0000048651069845624,"volume":27961052,"cap":0},{"date":1621775700000,"rate":0.000004176005336694537,"volume":23307479,"cap":0},{"date":1621782900000,"rate":0.0000031704390760712266,"volume":15606520,"cap":0},{"date":1621790100000,"rate":0.000003116648531307375,"volume":12702181,"cap":0},{"date":1621797300000,"rate":0.0000029886491599768905,"volume":11625501,"cap":0},{"date":1621804500000,"rate":0.0000035898405353124087,"volume":13697356,"cap":0},{"date":1621811700000,"rate":0.0000033463298450348895,"volume":12933525,"cap":0},{"date":1621818900000,"rate":0.000003092519067672814,"volume":12137249,"cap":0},{"date":1621826100000,"rate":0.000004809111006427466,"volume":6747822,"cap":0},{"date":1621833300000,"rate":0.000005625927959920279,"volume":7694152,"cap":0},{"date":1621840500000,"rate":0.000005658090303548305,"volume":7309484,"cap":0},{"date":1621847700000,"rate":0.00000555077201792338,"volume":6753812,"cap":0},{"date":1621854900000,"rate":0.000005115365624866539,"volume":6168490,"cap":0},{"date":1621862100000,"rate":0.000004621082851271521,"volume":5535629,"cap":0},{"date":1621869300000,"rate":0.000004366000934710449,"volume":4605539,"cap":0},{"date":1621876500000,"rate":0.000004224402693504593,"volume":4075038,"cap":0},{"date":1621883700000,"rate":0.000005117905789094026,"volume":4846847,"cap":0},{"date":1621890900000,"rate":0.000004803204121663394,"volume":4344518,"cap":0},{"date":1621898100000,"rate":0.000004743771512827619,"volume":3801423,"cap":0},{"date":1621905300000,"rate":0.000004970473694073932,"volume":3568235,"cap":0},{"date":1621912500000,"rate":0.000004821777438809047,"volume":3090438,"cap":0},{"date":1621919700000,"rate":0.000004385004078343084,"volume":2072836,"cap":0},{"date":1621926900000,"rate":0.000004655362873982791,"volume":2153619,"cap":0},{"date":1621934100000,"rate":0.00000446776385111433,"volume":2014891,"cap":0},{"date":1621941300000,"rate":0.000004276895060808909,"volume":1854354,"cap":0},{"date":1621948500000,"rate":0.0000039946151688374604,"volume":1734154,"cap":0},{"date":1621955700000,"rate":0.00000407850857932116,"volume":1727143,"cap":0},{"date":1621962900000,"rate":0.00000438947896083071,"volume":1969027,"cap":0},{"date":1621970100000,"rate":0.000004208334408538827,"volume":1754426,"cap":0},{"date":1621977300000,"rate":0.000004317375152365667,"volume":1554100,"cap":0},{"date":1621984500000,"rate":0.000004454746726582065,"volume":1542610,"cap":0},{"date":1621991700000,"rate":0.000004293427815671232,"volume":1546145,"cap":0},{"date":1621998900000,"rate":0.000004508563061987526,"volume":1427510,"cap":0},{"date":1622006100000,"rate":0.000004462244691994737,"volume":1228012,"cap":0},{"date":1622013300000,"rate":0.00000450339490781722,"volume":1388540,"cap":0},{"date":1622020500000,"rate":0.000004430547294898957,"volume":1443203,"cap":0},{"date":1622027700000,"rate":0.0000042163143552429615,"volume":1406828,"cap":0},{"date":1622034900000,"rate":0.000004203673848970373,"volume":1213805,"cap":0},{"date":1622042100000,"rate":0.000004238779533643817,"volume":1151148,"cap":0},{"date":1622049300000,"rate":0.000004005349664552947,"volume":974376,"cap":0},{"date":1622056500000,"rate":0.000003829931920323789,"volume":1101483,"cap":0},{"date":1622063700000,"rate":0.0000047951026227662764,"volume":1690074,"cap":0},{"date":1622070900000,"rate":0.000004172392308412281,"volume":2021113,"cap":0},{"date":1622078100000,"rate":0.000004285867471399262,"volume":2242598,"cap":0},{"date":1622085300000,"rate":0.000004324903186780939,"volume":2417313,"cap":0},{"date":1622092500000,"rate":0.0000055932978912112335,"volume":3888628,"cap":0},{"date":1622099700000,"rate":0.000005205548836777365,"volume":3519073,"cap":0},{"date":1622106900000,"rate":0.0000054647998189244845,"volume":5538876,"cap":0},{"date":1622114100000,"rate":0.0000053825653688048826,"volume":5486460,"cap":0},{"date":1622121300000,"rate":0.000005287051834589127,"volume":5403342,"cap":0},{"date":1622128500000,"rate":0.000005345883655699542,"volume":5517168,"cap":0},{"date":1622135700000,"rate":0.000005329605436975881,"volume":5481571,"cap":0},{"date":1622142900000,"rate":0.000006427855689592523,"volume":6989763,"cap":0},{"date":1622150100000,"rate":0.000007170777091363226,"volume":7998812,"cap":0},{"date":1622157300000,"rate":0.00000848817732858927,"volume":9317479,"cap":0},{"date":1622164500000,"rate":0.000007907291938217902,"volume":8690570,"cap":0},{"date":1622171700000,"rate":0.000009401549021355785,"volume":10722797,"cap":0},{"date":1622178900000,"rate":0.000012917907175257454,"volume":15816633,"cap":0},{"date":1622186100000,"rate":0.000011386724391664343,"volume":15075627,"cap":0},{"date":1622193300000,"rate":0.000010752806005178068,"volume":10759527,"cap":0},{"date":1622200500000,"rate":0.000008796343845145173,"volume":9428898,"cap":0},{"date":1622207700000,"rate":0.000008764589617088316,"volume":9855429,"cap":0},{"date":1622214900000,"rate":0.000011274604759118008,"volume":13129009,"cap":0},{"date":1622222100000,"rate":0.000010824912889612634,"volume":13221123,"cap":0},{"date":1622229300000,"rate":0.000011927744580390765,"volume":13120588,"cap":0},{"date":1622236500000,"rate":0.000008738542343365658,"volume":11049135,"cap":0},{"date":1622243700000,"rate":0.000008954203289356629,"volume":10604281,"cap":0},{"date":1622250900000,"rate":0.000009684047357247085,"volume":11255663,"cap":0},{"date":1622258100000,"rate":0.000010147624142428493,"volume":11124542,"cap":0},{"date":1622265300000,"rate":0.000009582610605206221,"volume":8231228,"cap":0},{"date":1622272500000,"rate":0.00000962997724201734,"volume":7399042,"cap":0},{"date":1622279700000,"rate":0.00000876525902896197,"volume":6536296,"cap":0},{"date":1622286900000,"rate":0.000008778640362260474,"volume":5902446,"cap":0},{"date":1622294100000,"rate":0.000008599575912790307,"volume":5331957,"cap":0},{"date":1622301300000,"rate":0.000007525856266947919,"volume":4532124,"cap":0},{"date":1622308500000,"rate":0.000008288904001501344,"volume":4706159,"cap":0},{"date":1622315700000,"rate":0.000006788223297945124,"volume":4361410,"cap":0},{"date":1622322900000,"rate":0.000006648122921270265,"volume":2615829,"cap":0},{"date":1622330100000,"rate":0.000006597712635347864,"volume":2429749,"cap":0},{"date":1622337300000,"rate":0.000006529453774249937,"volume":2386118,"cap":0},{"date":1622344500000,"rate":0.000006690761873304196,"volume":2350361,"cap":0},{"date":1622351700000,"rate":0.000007047890972197483,"volume":2553854,"cap":0},{"date":1622358900000,"rate":0.000007604797323356736,"volume":2805156,"cap":0},{"date":1622366100000,"rate":0.00000774774488761896,"volume":2784328,"cap":0},{"date":1622373300000,"rate":0.0000074373078459283146,"volume":2626170,"cap":0},{"date":1622380500000,"rate":0.000007455633859366257,"volume":2624624,"cap":0},{"date":1622387700000,"rate":0.000006935957748335111,"volume":2217374,"cap":0},{"date":1622394900000,"rate":0.000007096353700149878,"volume":1854191,"cap":0},{"date":1622402100000,"rate":0.000006592049824105762,"volume":1236311,"cap":0},{"date":1622409300000,"rate":0.000006519810350870659,"volume":1055051,"cap":0},{"date":1622416500000,"rate":0.000006399328141619752,"volume":1090632,"cap":0},{"date":1622423700000,"rate":0.000006147025027097988,"volume":1020394,"cap":0},{"date":1622430900000,"rate":0.000005875879028708055,"volume":1004282,"cap":0},{"date":1622438100000,"rate":0.0000059349298107676355,"volume":881190,"cap":0},{"date":1622445300000,"rate":0.000006372373747939555,"volume":888414,"cap":0},{"date":1622452500000,"rate":0.0000065440846515978605,"volume":895671,"cap":0},{"date":1622459700000,"rate":0.000006816351094886379,"volume":922729,"cap":0},{"date":1622466900000,"rate":0.000006663853070781126,"volume":885633,"cap":0},{"date":1622474100000,"rate":0.000006716280581212563,"volume":805646,"cap":0},{"date":1622481300000,"rate":0.000006842132435112521,"volume":788897,"cap":0},{"date":1622488500000,"rate":0.000006767583712384092,"volume":668875,"cap":0},{"date":1622495700000,"rate":0.000006880178615939766,"volume":648012,"cap":0},{"date":1622502900000,"rate":0.000006878188512470735,"volume":593588,"cap":0},{"date":1622510100000,"rate":0.000006970739787615799,"volume":543709,"cap":0},{"date":1622517300000,"rate":0.0000067887099692231525,"volume":483933,"cap":0},{"date":1622524500000,"rate":0.000006585464072627639,"volume":489630,"cap":0},{"date":1622531700000,"rate":0.000005978401835902144,"volume":489577,"cap":0},{"date":1622538900000,"rate":0.000006271280416702964,"volume":531351,"cap":0},{"date":1622546100000,"rate":0.000006414158346294579,"volume":539174,"cap":0},{"date":1622553300000,"rate":0.000006198071417453326,"volume":585492,"cap":0},{"date":1622560500000,"rate":0.0000062039947921298,"volume":596491,"cap":0},{"date":1622567700000,"rate":0.00000574815233418276,"volume":651301,"cap":0},{"date":1622574900000,"rate":0.000005632923555628233,"volume":895415,"cap":0},{"date":1622582100000,"rate":0.000005601701816631952,"volume":926290,"cap":0},{"date":1622589300000,"rate":0.000005359069518953235,"volume":1000507,"cap":0},{"date":1622596500000,"rate":0.000005185821636263663,"volume":1024946,"cap":0},{"date":1622603700000,"rate":0.00000505591577605695,"volume":1097531,"cap":0},{"date":1622610900000,"rate":0.000005157000133471333,"volume":1114531,"cap":0},{"date":1622618100000,"rate":0.0000052813769581132445,"volume":1097953,"cap":0},{"date":1622625300000,"rate":0.0000053764544561180434,"volume":1068950,"cap":0},{"date":1622632500000,"rate":0.000005361942719907461,"volume":1080135,"cap":0},{"date":1622639700000,"rate":0.00000533865875383828,"volume":1043734,"cap":0},{"date":1622646900000,"rate":0.00000565979834433301,"volume":1128044,"cap":0},{"date":1622654100000,"rate":0.00000556799650789734,"volume":927463,"cap":0},{"date":1622661300000,"rate":0.000005359505870303557,"volume":762790,"cap":0},{"date":1622668500000,"rate":0.000005233738816653028,"volume":724736,"cap":0},{"date":1622675700000,"rate":0.00000512188823255605,"volume":585894,"cap":0},{"date":1622682900000,"rate":0.0000051431551900858184,"volume":523145,"cap":0},{"date":1622690100000,"rate":0.000004947782373727076,"volume":469814,"cap":0},{"date":1622697300000,"rate":0.00000519250365379875,"volume":480776,"cap":0},{"date":1622704500000,"rate":0.000005293428971369303,"volume":514313,"cap":0},{"date":1622711700000,"rate":0.00000526625304715993,"volume":537088,"cap":0},{"date":1622718900000,"rate":0.000005170298702436165,"volume":580591,"cap":0},{"date":1622726100000,"rate":0.000005467973509801507,"volume":590067,"cap":0},{"date":1622733300000,"rate":0.000005432170821095263,"volume":561001,"cap":0},{"date":1622740500000,"rate":0.000005357919715420349,"volume":571176,"cap":0},{"date":1622747700000,"rate":0.0000041692021580248895,"volume":777368,"cap":0},{"date":1622754900000,"rate":0.000004268679100134246,"volume":907412,"cap":0},{"date":1622762100000,"rate":0.000004424306130717825,"volume":1049128,"cap":0},{"date":1622769300000,"rate":0.000004444340990555747,"volume":1115475,"cap":0},{"date":1622776500000,"rate":0.000004624329630417042,"volume":1170400,"cap":0},{"date":1622783700000,"rate":0.000004528265778496373,"volume":1134829,"cap":0},{"date":1622790900000,"rate":0.000004431366373274422,"volume":1085672,"cap":0},{"date":1622798100000,"rate":0.000004509361286726546,"volume":1113951,"cap":0},{"date":1622805300000,"rate":0.00000454664438262643,"volume":1082041,"cap":0},{"date":1622812500000,"rate":0.000004509155497723456,"volume":1061617,"cap":0},{"date":1622819700000,"rate":0.000004514486351133839,"volume":1078357,"cap":0},{"date":1622826900000,"rate":0.000004626315022053706,"volume":1093564,"cap":0},{"date":1622834100000,"rate":0.000004703449409047182,"volume":714000,"cap":0},{"date":1622841300000,"rate":0.00000461154081889897,"volume":641277,"cap":0},{"date":1622848500000,"rate":0.000004488611817027769,"volume":518693,"cap":0},{"date":1622855700000,"rate":0.0000048842301102746885,"volume":541817,"cap":0},{"date":1622862900000,"rate":0.000005031740988052249,"volume":509801,"cap":0},{"date":1622870100000,"rate":0.00000508328616150855,"volume":550133,"cap":0},{"date":1622877300000,"rate":0.000005021214981700845,"volume":544939,"cap":null},{"date":1622884500000,"rate":0.000004950943279831489,"volume":538850,"cap":null},{"date":1622891700000,"rate":0.00000490336129178633,"volume":535229,"cap":null},{"date":1622898900000,"rate":0.000004903891529230515,"volume":487661,"cap":0},{"date":1622906100000,"rate":0.000005032420529064419,"volume":549273,"cap":0},{"date":1622913300000,"rate":0.0000048743422814540304,"volume":554031,"cap":0},{"date":1622920500000,"rate":0.000004886445242272645,"volume":528527,"cap":0},{"date":1622927700000,"rate":0.000004858885212771058,"volume":453173,"cap":0},{"date":1622934900000,"rate":0.000004454558124383869,"volume":495198,"cap":0},{"date":1622942100000,"rate":0.000004576039573824291,"volume":451969,"cap":0},{"date":1622949300000,"rate":0.000004504488652885131,"volume":444729,"cap":0},{"date":1622956500000,"rate":0.000004497121254080148,"volume":395692,"cap":0},{"date":1622963700000,"rate":0.000004457262871357049,"volume":401205,"cap":0},{"date":1622970900000,"rate":0.0000045626279695358266,"volume":404585,"cap":0},{"date":1622978100000,"rate":0.0000045395474886164805,"volume":400348,"cap":0},{"date":1622985300000,"rate":0.0000045118645635557614,"volume":386595,"cap":0},{"date":1622992500000,"rate":0.000004496724013824867,"volume":314229,"cap":0},{"date":1622999700000,"rate":0.000004461411410651481,"volume":294696,"cap":0},{"date":1623006900000,"rate":0.000004267911377010871,"volume":309155,"cap":0},{"date":1623014100000,"rate":0.000004200408053978469,"volume":324855,"cap":0},{"date":1623021300000,"rate":0.000004188579460993027,"volume":246146,"cap":0},{"date":1623028500000,"rate":0.000004300949513728821,"volume":263663,"cap":0},{"date":1623035700000,"rate":0.000004211972189290122,"volume":277767,"cap":0},{"date":1623042900000,"rate":0.0000042207032639540435,"volume":282918,"cap":0},{"date":1623050100000,"rate":0.000004159099558488879,"volume":262524,"cap":0},{"date":1623057300000,"rate":0.000004134332987802885,"volume":281514,"cap":0},{"date":1623064500000,"rate":0.000003933663230919171,"volume":357928,"cap":0},{"date":1623071700000,"rate":0.000004014089650908459,"volume":373444,"cap":0},{"date":1623078900000,"rate":0.000003540054485919241,"volume":437212,"cap":0},{"date":1623086100000,"rate":0.0000033709543114204044,"volume":516809,"cap":0},{"date":1623093300000,"rate":0.0000033699203646381782,"volume":497836,"cap":0},{"date":1623100500000,"rate":0.000003100614263481604,"volume":517966,"cap":0},{"date":1623107700000,"rate":0.0000028536180953966572,"volume":568308,"cap":0},{"date":1623114900000,"rate":0.000002937372019930459,"volume":622095,"cap":0},{"date":1623122100000,"rate":0.000002866936029918008,"volume":633789,"cap":0},{"date":1623129300000,"rate":0.0000031473118095186475,"volume":748003,"cap":0},{"date":1623136500000,"rate":0.0000031668263894963768,"volume":776498,"cap":0},{"date":1623143700000,"rate":0.000003120450776714932,"volume":784358,"cap":0},{"date":1623150900000,"rate":0.0000031106469564361275,"volume":727488,"cap":0},{"date":1623158100000,"rate":0.00000303890327779362,"volume":729226,"cap":0},{"date":1623165300000,"rate":0.0000028681995788153487,"volume":603675,"cap":0},{"date":1623172500000,"rate":0.000002915286268300504,"volume":559707,"cap":0},{"date":1623179700000,"rate":0.0000030051254634096763,"volume":594957,"cap":0},{"date":1623186900000,"rate":0.0000031202242377991755,"volume":527181,"cap":0},{"date":1623194100000,"rate":0.000003165421669433529,"volume":450067,"cap":0},{"date":1623201300000,"rate":0.0000030240901277291004,"volume":393271,"cap":0},{"date":1623208500000,"rate":0.0000029857550982077825,"volume":368219,"cap":0},{"date":1623215700000,"rate":0.0000030207637229618096,"volume":316385,"cap":0},{"date":1623222900000,"rate":0.0000030813909922893043,"volume":303452,"cap":0},{"date":1623230100000,"rate":0.000003042253181498995,"volume":268878,"cap":0},{"date":1623237300000,"rate":0.0000030637765024449086,"volume":252165,"cap":0},{"date":1623244500000,"rate":0.0000031008824704948697,"volume":235586,"cap":0},{"date":1623251700000,"rate":0.000003047105067988574,"volume":215344,"cap":0},{"date":1623258900000,"rate":0.0000031441736464416186,"volume":193678,"cap":0},{"date":1623266100000,"rate":0.0000029807831982619226,"volume":219189,"cap":0},{"date":1623273300000,"rate":0.0000029339076622086242,"volume":223173,"cap":0},{"date":1623280500000,"rate":0.000002992535141917976,"volume":207098,"cap":0},{"date":1623287700000,"rate":0.0000029618600479652796,"volume":167773,"cap":0},{"date":1623294900000,"rate":0.0000029587320314123975,"volume":167538,"cap":0},{"date":1623302100000,"rate":0.0000028885391275133554,"volume":161389,"cap":0},{"date":1623309300000,"rate":0.000002880274846506629,"volume":163503,"cap":0},{"date":1623316500000,"rate":0.0000028066985030035655,"volume":160687,"cap":0},{"date":1623323700000,"rate":0.0000028993806741522607,"volume":166164,"cap":0},{"date":1623330900000,"rate":0.000002839020254234523,"volume":169913,"cap":0},{"date":1623338100000,"rate":0.0000023815094400397355,"volume":299218,"cap":0},{"date":1623345300000,"rate":0.000002072008528093939,"volume":549966,"cap":0},{"date":1623352500000,"rate":0.000002045812208346378,"volume":589467,"cap":0},{"date":1623359700000,"rate":0.0000017720454860517848,"volume":681933,"cap":0},{"date":1623366900000,"rate":0.0000019081386153378306,"volume":792457,"cap":0},{"date":1623374100000,"rate":0.0000018384419071615217,"volume":787469,"cap":0},{"date":1623381300000,"rate":0.0000018644463683659127,"volume":807491,"cap":0},{"date":1623388500000,"rate":0.0000018940305091895611,"volume":824632,"cap":0},{"date":1623395700000,"rate":0.0000018478716094308354,"volume":805030,"cap":0},{"date":1623402900000,"rate":0.000001881182241340156,"volume":828752,"cap":0},{"date":1623410100000,"rate":0.0000018857948037607511,"volume":835209,"cap":0},{"date":1623417300000,"rate":0.0000018883081999032626,"volume":833585,"cap":0},{"date":1623424500000,"rate":0.0000018355449850652114,"volume":691507,"cap":0},{"date":1623431700000,"rate":0.000001743037497273121,"volume":470981,"cap":0},{"date":1623438900000,"rate":0.0000015014683719179204,"volume":460655,"cap":0},{"date":1623446100000,"rate":0.0000011492750054770039,"volume":463277,"cap":0},{"date":1623453300000,"rate":0.0000011691699395482826,"volume":473023,"cap":0},{"date":1623460500000,"rate":0.0000011974981952043874,"volume":491211,"cap":0},{"date":1623467700000,"rate":0.0000012253976696714312,"volume":538774,"cap":0},{"date":1623474900000,"rate":0.0000012350230803797299,"volume":539424,"cap":0},{"date":1623482100000,"rate":0.0000011110530749112635,"volume":555461,"cap":0},{"date":1623489300000,"rate":7.183462781226733e-7,"volume":570383,"cap":0},{"date":1623496500000,"rate":7.966436771180697e-7,"volume":673573,"cap":0},{"date":1623503700000,"rate":7.337166424684951e-7,"volume":717067,"cap":0},{"date":1623510900000,"rate":7.284436763551004e-7,"volume":775890,"cap":0},{"date":1623518100000,"rate":8.767259133188006e-7,"volume":1124983,"cap":0},{"date":1623525300000,"rate":0.0000012571652209017365,"volume":1752135,"cap":0},{"date":1623532500000,"rate":0.0000014774427120292203,"volume":1961140,"cap":0},{"date":1623539700000,"rate":0.000001325451563604681,"volume":1808912,"cap":0},{"date":1623546900000,"rate":0.0000013657215353546853,"volume":1870820,"cap":0},{"date":1623554100000,"rate":0.0000014130004171768103,"volume":1914218,"cap":0},{"date":1623561300000,"rate":0.0000013858114221567029,"volume":1880843,"cap":0},{"date":1623568500000,"rate":0.0000013403449481987822,"volume":1760380,"cap":0},{"date":1623575700000,"rate":0.0000013431091079296604,"volume":1370919,"cap":0},{"date":1623582900000,"rate":0.00000137091568431404,"volume":1322931,"cap":0},{"date":1623590100000,"rate":0.0000013498591658085565,"volume":1142940,"cap":0},{"date":1623597300000,"rate":0.0000013361005267683457,"volume":985560,"cap":0},{"date":1623604500000,"rate":0.0000014234551384953634,"volume":758639,"cap":0},{"date":1623611700000,"rate":0.000001631641425178194,"volume":662131,"cap":0},{"date":1623618900000,"rate":0.000002007655306103407,"volume":764173,"cap":0},{"date":1623626100000,"rate":0.0000019734235838967865,"volume":646321,"cap":0},{"date":1623633300000,"rate":0.0000018794814871271278,"volume":627240,"cap":0},{"date":1623640500000,"rate":0.0000017137873178155096,"volume":543831,"cap":0},{"date":1623647700000,"rate":0.0000017077349806090584,"volume":541465,"cap":0},{"date":1623654900000,"rate":0.0000017059769976238206,"volume":511260,"cap":0},{"date":1623662100000,"rate":0.0000017073023060920857,"volume":502416,"cap":0},{"date":1623669300000,"rate":0.0000017226809838444374,"volume":496993,"cap":0},{"date":1623676500000,"rate":0.0000017487957988933058,"volume":503759,"cap":0},{"date":1623683700000,"rate":0.0000017738591166147456,"volume":549962,"cap":0},{"date":1623690900000,"rate":0.0000017938975974864527,"volume":507667,"cap":0},{"date":1623698100000,"rate":0.0000017953353468719894,"volume":386651,"cap":0},{"date":1623705300000,"rate":0.000001803097144406986,"volume":269915,"cap":0},{"date":1623712500000,"rate":0.0000017611043305033597,"volume":259019,"cap":0},{"date":1623719700000,"rate":0.0000017704826752607652,"volume":218826,"cap":0},{"date":1623726900000,"rate":0.0000017570116891960627,"volume":225480,"cap":0},{"date":1623734100000,"rate":0.0000017691569475089293,"volume":224401,"cap":0},{"date":1623741300000,"rate":0.0000017823098708699413,"volume":224962,"cap":0},{"date":1623748500000,"rate":0.0000017448022441614276,"volume":220940,"cap":0},{"date":1623755700000,"rate":0.0000017603158066043528,"volume":218458,"cap":0},{"date":1623762900000,"rate":0.000001783311276649595,"volume":214832,"cap":0},{"date":1623770100000,"rate":0.000001749297779835801,"volume":153522,"cap":0},{"date":1623777300000,"rate":0.0000017507965389687403,"volume":133526,"cap":0},{"date":1623784500000,"rate":0.0000017110435005012907,"volume":133099,"cap":0},{"date":1623791700000,"rate":0.0000017028543124341056,"volume":126319,"cap":0},{"date":1623798900000,"rate":0.0000017211392080224153,"volume":112431,"cap":0},{"date":1623806100000,"rate":0.0000016915233806806856,"volume":115555,"cap":0},{"date":1623813300000,"rate":0.0000016098473667574993,"volume":127354,"cap":0},{"date":1623820500000,"rate":0.00000159958770339014,"volume":138147,"cap":0},{"date":1623827700000,"rate":0.0000016402042869714897,"volume":141115,"cap":0},{"date":1623834900000,"rate":0.0000016263744804972208,"volume":139105,"cap":0},{"date":1623842100000,"rate":0.0000015867802781996476,"volume":137164,"cap":0},{"date":1623849300000,"rate":0.0000015794376721645543,"volume":135677,"cap":0}]}';

    var jsonData = jsonDecode(json);
    var data = jsonData["data"];

    data.forEach((item) {
      FlSpot spot = FlSpot(item["date"].toDouble(), item["rate"].toDouble());
      rates.add(item["rate"].toDouble());
      spots.add(spot);
    });

    max = rates.reduce((curr, next) => curr > next ? curr : next);
    min = rates.reduce((curr, next) => curr < next ? curr : next);
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

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff424f5c),
        title: Container(
          child: Text(
            "Wallet",
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: BoomMenu(
        fabPaddingTop: 0,
        marginBottom: 70,
        fabAlignment: Alignment.topLeft,


        backgroundColor: Colors.white,
        foregroundColor: Color(0xff424f5c),

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

                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                        child: Stack(
                      children: [
                     AnimationBackground(),

                        Container(
                          margin: EdgeInsets.only(top: 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [

                              Container(
                                child: Image.asset("assets/icon.png"),
                                width: 30,
                              ),
                              Expanded(
                                flex: 4,
                                  child: Column(
                                children: [
                                  Obx(() => Container(
                                        margin: EdgeInsets.only(top: 10),
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
                                        EdgeInsets.only(top: 10, bottom: 30),
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
                              Expanded(
                                  flex: 5,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(left: 30),
                                            child: Text("${max}",
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12)),
                                          )
                                        ],
                                      ),
                                      Container(
                                          margin: EdgeInsets.only(
                                              top: 5, bottom: 5),
                                          height: 150,
                                          padding: EdgeInsets.only(
                                              left: 30, right: 20, top: 20),
                                          width: double.infinity,
                                          child: LineChart(
                                            mainData(),
                                          )),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: Container(
                                            margin: EdgeInsets.only(
                                                top: 10, right: 20),
                                            child: Text(
                                              "${max}",
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ))
                                        ],
                                      ),
                                    ],
                                  )),
                              Expanded(
                                  flex: 2,
                                  child: Container(

                                margin: EdgeInsets.only(bottom: 0,top: 0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: [
                                        RaisedButton.(
                                          shape: new RoundedRectangleBorder(
                                            borderRadius: new BorderRadius.circular(30.0),
                                          ),
                                          onPressed: () {
                                            controller.open();

                                            ///  walletController.getpriceCoin();
                                          },
                                          child: Text(
                                            "Transfer",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xff424f5c)),
                                          ),
                                          color: Colors.white,
                                        ),
                                        RaisedButton(
                                          shape: new RoundedRectangleBorder(
                                            borderRadius: new BorderRadius.circular(30.0),
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
                                                fontSize: 16,
                                                color: Color(0xff424f5c)),
                                          ),
                                          color: Colors.white,
                                        ),
                                        RaisedButton(
                                          shape: new RoundedRectangleBorder(
                                            borderRadius: new BorderRadius.circular(30.0),
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
                                            "Transactions",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xff424f5c)),
                                          ),
                                          color: Colors.white,
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ))


                            ],
                          ),
                        ),

                      ],
                    )),
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

    LoadBalanceWihoutLoading(true);
  }
}

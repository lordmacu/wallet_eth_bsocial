import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_wallet/models/Coin.dart';
import 'package:social_wallet/models/Transaction.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart'; //You can also import the browser version
import 'dart:math';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:social_wallet/models/Transaction.dart' as tr;
import 'package:web3dart/web3dart.dart' as web;

class BalanceWallet extends GetxController {
  var ethBalance = "0".obs;
  var bsocialBalance = "0".obs;
  var bsocialBalanceNumber = 0.0.obs;
  var canTransfer = 0.0.obs;

  var isloading = false.obs;
  var transactions = [];
  var usdValue = "0".obs;
  var totalEarnings = "0".obs;
  var valuePasteWallet = "".obs;

  @override
  onInit() {
    LoadBalance();

    Future.delayed(Duration(seconds: 30), () {
      LoadBalance();

    });
  }

  String getAbi() {
    var abicode =
        '[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"minTokensBeforeSwap","type":"uint256"}],"name":"MinTokensBeforeSwapUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"tokensSwapped","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"ethReceived","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"tokensIntoLiquidity","type":"uint256"}],"name":"SwapAndLiquify","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"enabled","type":"bool"}],"name":"SwapAndLiquifyEnabledUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[],"name":"_liquidityFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"_maxTxAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"_taxFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"tAmount","type":"uint256"}],"name":"deliver","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"excludeFromFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"excludeFromReward","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"geUnlockTime","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"includeInFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"includeInReward","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isExcludedFromFee","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isExcludedFromReward","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"time","type":"uint256"}],"name":"lock","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tAmount","type":"uint256"},{"internalType":"bool","name":"deductTransferFee","type":"bool"}],"name":"reflectionFromToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"liquidityFee","type":"uint256"}],"name":"setLiquidityFeePercent","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"maxTxPercent","type":"uint256"}],"name":"setMaxTxPercent","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_enabled","type":"bool"}],"name":"setSwapAndLiquifyEnabled","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"taxFee","type":"uint256"}],"name":"setTaxFeePercent","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"swapAndLiquifyEnabled","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"rAmount","type":"uint256"}],"name":"tokenFromReflection","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalFees","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"uniswapV2Pair","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"uniswapV2Router","outputs":[{"internalType":"contract IUniswapV2Router02","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"unlock","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]';
    return abicode;
  }

  Future<Coin> getpriceCoin() async {
    Coin coin;
    var headers = {
      'X-CMC_PRO_API_KEY': '5ec1ed2c-4090-4d84-874d-ce1b4d337224',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=bsocial'));
    request.bodyFields = {'module': 'account', 'action': 'tokentx'};
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();

      var dataJson = jsonDecode(string);

      var data = dataJson["data"]["BSOCIAL"];
      coin = Coin(
          "${data["id"]}",
          data["name"],
          data["symbol"],
          data["slug"],
          "${data["num_market_pairs"]}",
          data["date_added"],
          "${data["max_supply"]}",
          "${data["circulating_supply"]}",
          "${data["total_supply"]}",
          "${data["is_active"]}",
          "${data["cmc_rank"]}",
          "${data["is_fiat"]}",
          "${data["quote"]["USD"]["price"]}");
    }
    return coin;
  }

  getTransactions(balanceBsocial, priceCoin) async {
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
        transactions.add(transaction);
      }
    });

    var balanceBsociadl = (double.parse("${total}") / pow(10, 8));

    var totalGained = balanceBsocial - balanceBsociadl;

    totalEarnings.value = "\$${formatter.format(totalGained * priceCoin)}";

    this.isloading.value = false;
  }

  String convertTimeStampToHumanDate(int timeStamp) {
    var dateToTimeStamp = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
    return DateFormat('dd/MM/yyyy').format(dateToTimeStamp);
  }

  Future<String> transferToAnother() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final client = Web3Client(
        "https://mainnet.infura.io/v3/4a2bad1755634c5b9771f76163e9d129",
        Client(), socketConnector: () {
      return IOWebSocketChannel.connect(
              "wss://mainnet.infura.io/ws/v3/4a2bad1755634c5b9771f76163e9d129")
          .cast<String>();
    });
    var token = prefs.getString("token");

    Credentials credentials = EthPrivateKey.fromHex(token);
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex('0x26a79Bd709A7eF5E5F747B8d8f83326EA044d8cC');

    var abicode = getAbi();
    final contract = DeployedContract(
        ContractAbi.fromJson(abicode, 'Bsocial'), contractAddr);

    final transfer = contract.function('transfer');

    final EthereumAddress receiver =
        EthereumAddress.fromHex(this.valuePasteWallet.value);

    var result = await client.sendTransaction(
      credentials,
      web.Transaction.callContract(
        contract: contract,
        function: transfer,
        parameters: [receiver, BigInt.from(canTransfer.value)],
      ),
    );

    return result;


  }

  checkTransactionStatus(transaction) async {
    var url = Uri.parse(
        'https://api.etherscan.io/api?module=transaction&action=getstatus&txhash=${transaction}&apikey=3YF336R8GJFSC6KT34S4JSS812WM536RVU');
    var response = await http.get(url);

    var resuldt = jsonDecode(response.body);

  }

  LoadBalance() async {
    print("aquii cargando");
   this.isloading.value = true;
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

    ethBalance.value = "${balance.getValueInUnit(EtherUnit.ether)}";

    final EthereumAddress contractAddr =
        EthereumAddress.fromHex('0x26a79Bd709A7eF5E5F747B8d8f83326EA044d8cC');

    var abicode = getAbi();
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
    Coin coin = await getpriceCoin();
    bsocialBalance.value = "${formatter.format(balanceBsocial)}";
    bsocialBalanceNumber.value = balanceBsocial;

    usdValue.value =
        "\$${formatter.format(balanceBsocial * double.parse(coin.price))}";
   this.isloading.value = false;

    await getTransactions(balanceBsocial, double.parse(coin.price));

    update();

  }
}

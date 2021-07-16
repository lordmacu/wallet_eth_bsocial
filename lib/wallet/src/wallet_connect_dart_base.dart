// TODO: Put public facing types in this file.
import 'package:web_socket_channel/io.dart';
import 'Cryptography/Crypto.dart' as c;
import 'Models/ClientMeta.dart';
import 'WebSocketMessages/WebSocketMessages.dart';


/// Checks if you are awesome. Spoiler: you are.
class WalletConnect {
  ClientMeta _clientMeta;
  c.Crypto _cryptography;
  WebSocketMessages sendWebSocketMessages;

  WalletConnect(ClientMeta clientMeta) {
    _clientMeta = clientMeta;
    _cryptography = c.Crypto();
    sendWebSocketMessages = WebSocketMessages(_cryptography);
  }

  Future<void> sessionRequest() async {
    await _cryptography.initKey();
    //Abre o socket.
    sendWebSocketMessages.openConnection();
    //Envia o sub.
    sendWebSocketMessages.sendSub();
    //Envia o pub.
    await sendWebSocketMessages.sendPub('wc_sessionRequest',{
          'peerId': sendWebSocketMessages.topics.subscribeTopic,
          'peerMeta': _clientMeta.toJson(),
          'chainId': 1,
        });
    //Exibe o deeplink ou o qrcode
    sendWebSocketMessages.displayURI();
  }

   Future<void>  eth_signTransaction() async {
    //Envia o pub.
    await sendWebSocketMessages.sendPub('net_version',{});
   }

  //personal_sign
  //eth_sign
  //eth_signTypedData
  //eth_sendTransaction
  //eth_signTransaction
  //eth_sendRawTransaction

}

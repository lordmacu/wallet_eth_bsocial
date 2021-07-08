import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinController extends GetxController {

    var characters="".obs;
  var isCorrect=false.obs;
  var isregister=true.obs;
    var isloading=false.obs;
    var hasError=false.obs;
  var password= "".obs;
  var step=0.obs;
    var tempPassword= "".obs;


    Future setPassword(string) async{
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var userToken= prefs.setString("password",string);
    }

  Future getUserPassword() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userToken= prefs.getString("password");
    print("aquii esta la password  ${userToken}");
    password.value= userToken;

    if(userToken==null){
      isregister.value=true;
    }else{
      isregister.value=false;

    }

  }

  @override
  onInit() {
    getUserPassword();



  }

}
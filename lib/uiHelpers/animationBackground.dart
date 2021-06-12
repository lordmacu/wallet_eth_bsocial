import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';


class AnimationBackground extends StatefulWidget {
  AnimationBackground({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _AnimationBackground createState() => _AnimationBackground();
}

class _AnimationBackground extends State<AnimationBackground>  with TickerProviderStateMixin{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
   return AnimatedBackground(
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
   );
  }
}
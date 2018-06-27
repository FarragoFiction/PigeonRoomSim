import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'demo.dart';
import 'package:box2d/box2d.dart';
import 'package:LoaderLib/Loader.dart';

Future<Null>main() async {
  querySelector('#output').text = 'Your Dart app is running.';
  ImageElement birb = await Loader.getResource("images/pigeon.png");
  PigeonDemo pigeon = new PigeonDemo("HELLOWORLD", birb);



  pigeon.initialize();

  pigeon.initializeAnimation();
  pigeon.runAnimation();
}


class PigeonDemo extends Demo {
  ImageElement birb;
  PigeonDemo(String name, ImageElement this.birb) : super(name);


  void initialize() {
    assert(null != world);
    _createGround();
    _createBox();
  }

  @override
  void step(num timestamp) {
    super.step(timestamp);
    // ignore: conflicting_dart_import
    for(Body b in bodies) {
      if(b.getType() == BodyType.DYNAMIC) {
        //looks like 0,0 is in the center, and y is inverted. viewport.scale handles coordinate conversion
        num x = b.position.x * viewport.scale + canvas.width / 2 -
            birb.width / 2;
        num y = canvas.height - (b.position.y * viewport.scale) -
            canvas.height / 2 - birb.height / 2;
        canvas.context2D.drawImage(birb, x, y);
      }
    }
  }

  void _createGround() {
    // Create shape
    final PolygonShape shape = new PolygonShape();

    // Define body
    final BodyDef bodyDef = new BodyDef();
    bodyDef.position.setValues(0.0, 0.0);

    // Create body
    // ignore: conflicting_dart_import
    final Body ground = world.createBody(bodyDef);

    // Set shape 3 times and create fixture on the body for each
    //first number is length, second is width
    shape.setAsBox(50.0, 0.4,new Vector2(0.0, -25.0), 0.0);
    ground.createFixtureFromShape(shape);
    shape.setAsBox(0.4, 50.0, new Vector2(-40.0, 0.0), 0.0);
    ground.createFixtureFromShape(shape);
    shape.setAsBox(0.4, 50.0, new Vector2(40.0, 0.0), 0.0);
    ground.createFixtureFromShape(shape);

    // Add composite body to list
    bodies.add(ground);
  }

  void _createBox() {
    // Create shape
    final PolygonShape shape = new PolygonShape();
    shape.setAsBox(3.0, 2.5, new Vector2.zero(), Math.PI / 2);

    // Define fixture (links body and shape)
    final FixtureDef activeFixtureDef = new FixtureDef();
    activeFixtureDef.restitution = 0.5;
    activeFixtureDef.density = 0.05;
    activeFixtureDef.shape = shape;

    // Define body
    final BodyDef bodyDef = new BodyDef();
    bodyDef.type = BodyType.DYNAMIC;
    bodyDef.position = new Vector2(0.0, 30.0);

    // Create body and fixture from definitions
    final Body fallingBox = world.createBody(bodyDef);
    fallingBox.createFixtureFromFixtureDef(activeFixtureDef);

    // Add to list
    bodies.add(fallingBox);
  }
}
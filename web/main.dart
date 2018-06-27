import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'demo.dart';
import 'package:box2d/box2d.dart';
import 'package:LoaderLib/Loader.dart';
import "package:DollLibCorrect/DollRenderer.dart";

int type = 113;

List<CanvasElement> birbs;

Future<Null>main() async {
  if(getParameterByName("type", null) != null) {
   type = int.parse(getParameterByName("type", null));
  }
  querySelector('#output').text = 'Your Dart app is running.';
  //65 x 65
  birbs = await initBirbs();
  PigeonDemo pigeon = new PigeonDemo("HELLOWORLD", birbs);



  pigeon.initialize();

  pigeon.initializeAnimation();
  pigeon.runAnimation();

  ButtonElement box = new ButtonElement()..text = "Spawn Birb";
  querySelector("#output").append(box);
  box.onClick.listen((Event e) {
    pigeon.createBox();
  });
}

//http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
//simulatedParamsGlobalVar is the simulated global vars.
String getParameterByName(String name, [String url]) {
  Uri uri = Uri.base;
  String tmp = null;
  if (url != null) {
    uri = Uri.parse(url);
    // //print("uri is $uri");
    String tmp = (uri.queryParameters[name]); //doesn't need decoded, guess it was auto decoded with the parse?
    if(tmp != null) return tmp;
  } else {
    ////print("uri is $uri");
    String tmp = (uri.queryParameters[name]);
    if (tmp != null) tmp = Uri.decodeComponent(tmp);
    if(tmp != null) return tmp;
  }
  ////print("gonna check simulated params");


  return tmp;
}

Future<List<CanvasElement>> initBirbs() async {
  List<CanvasElement> ret = new List<CanvasElement>();
  DivElement stats = new DivElement()..text = "Loading Dolls of type $type";
  querySelector("#output").append(stats);
  //don't spend too long doing this
  DateTime startTime = new DateTime.now();
  for(int i = 0; i<13; i++) {
    Doll doll = Doll.randomDollOfType(type);
    CanvasElement canvas = new CanvasElement(width:doll.width, height:doll.height);
    await DollRenderer.drawDoll(canvas,doll);
    CanvasElement finalCanvas = new CanvasElement(width:64, height:65);
    await Renderer.cropToVisible(canvas);
    await Renderer.drawToFitCentered(finalCanvas, canvas);
    ret.add(finalCanvas);
    print("drew $doll");
    stats.text = "Loaded $i dolls of type $type";
    DateTime currentTime = new DateTime.now();
    Duration diff = currentTime.difference(startTime);
    if(diff.inMilliseconds >13000) {
      break;
    }
  }
  return ret;
}


class PigeonDemo extends Demo {
  List<CanvasElement> birbs;
  PigeonDemo(String name, List<CanvasElement> this.birbs) : super(name);


  void initialize() {
    assert(null != world);
    _createGround();
    createBox();
  }

  @override
  void step(num timestamp) {
    super.step(timestamp);
    // ignore: conflicting_dart_import
    for(Body b in bodies) {
      if(b.getType() == BodyType.DYNAMIC) {
        CanvasElement birb = getRandomBirb(bodies.indexOf(b));
        //looks like 0,0 is in the center, and y is inverted. viewport.scale handles coordinate conversion
        num x = b.position.x * viewport.scale + canvas.width / 2 -
            birb.width / 2;
        num y = canvas.height - (b.position.y * viewport.scale) -
            canvas.height / 2 - birb.height / 2;
        canvas.context2D.save();
        canvas.context2D.rotate(b.getAngle());
        canvas.context2D.restore();
        canvas.context2D.drawImage(birb, x, y);
      }
    }
  }

  CanvasElement getRandomBirb(int seed) {
    Random rand = new Random(seed);
    return rand.pickFrom(birbs);
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

  void createBox() {
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
import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'demo.dart';
import 'package:box2d/box2d.dart';
import "package:DollLibCorrect/DollRenderer.dart";

int type = 113;
int spriteSize = 100;

List<CanvasElement> birbs;

Future<Null>main() async {
  if(getParameterByName("type", null) != null) {
   type = int.parse(getParameterByName("type", null));
  }
  querySelector('#output').text = 'Your Dart app is running.';
  //65 x 65
  birbs = await initBirbs();
  ImageElement bg = await Loader.getResource("images/58.png");
  PigeonDemo pigeon = new PigeonDemo("HELLOWORLD", birbs, bg);



  pigeon.initialize();
  pigeon.DEBUG = true;

  pigeon.initializeAnimation();
  pigeon.runAnimation();

  ButtonElement box = new ButtonElement()..text = "Spawn Birb";
  querySelector("#output").append(box);
  box.onClick.listen((MouseEvent e) {
    pigeon.createBox();
  });
  pigeon.canvas.onClick.listen((MouseEvent e) => pigeon.createBox(e.client.x, e.client.y));
  pigeon.canvas.style.marginLeft = "auto";
  pigeon.canvas.style.marginRight = "auto";
  pigeon.canvas.style.paddingLeft = "300px";
  pigeon.canvas.style.paddingRight = "300px";

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
  stats.style.color = "white";
  querySelector("#output").append(stats);
  //don't spend too long doing this
  DateTime startTime = new DateTime.now();

  for(int i = 0; i<13; i++) {
    Doll doll = Doll.randomDollOfType(type);
    CanvasElement canvas = new CanvasElement(width:doll.width, height:doll.height);
    await DollRenderer.drawDoll(canvas,doll);
    CanvasElement finalCanvas = new CanvasElement(width:spriteSize, height:spriteSize);
    await Renderer.cropToVisible(canvas);
    await Renderer.drawToFitCentered(finalCanvas, canvas);
    //crop again after resizing
    await Renderer.cropToVisible(finalCanvas);

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
  ImageElement bg;
  // ignore: conflicting_dart_import
  List<Fixture> toDestroy = new List<Fixture>();

  PigeonDemo(String name, List<CanvasElement> this.birbs, ImageElement this.bg) : super(name);


  void initialize() {
    assert(null != world);
    PigeonListener cl = new PigeonListener(this);
    world.setContactListener(cl);
    _createGround();
    createBox();
  }

  @override
  void step(num timestamp) {
    processDestruction();
    super.step(timestamp);
   if(!DEBUG) canvas.context2D.drawImage(bg, 0,0);
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
        canvas.context2D.translate(x+birb.width/2,y+birb.height/2);
        canvas.context2D.rotate(b.getAngle());
        canvas.context2D.drawImage(birb, -birb.width/2, -birb.width/2);
        canvas.context2D.restore();
      }
    }
  }

  //is this enough?
  void processDestruction() {
    for(Fixture f in toDestroy) {
      Body b  = f.getBody();
      world.destroyBody(b);
      //f.destroy();
      bodies.remove(b);
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

  void createBox([double x, double y]) {
    // Create shape
    final CircleShape shape = new CircleShape();
    CanvasElement birb = getRandomBirb(bodies.length);
    double width = 3.0;
    double height = 2.5;
    if(viewport != null) {
      width = birb.width / viewport.scale;
      height = birb.height / viewport.scale;
    }
    shape.radius = width/4;
    //shape.setAsBox(width, height, new Vector2.zero(), Math.PI / 2);

    // Define fixture (links body and shape)
    final FixtureDef activeFixtureDef = new FixtureDef();
    activeFixtureDef.restitution = 0.5;
    activeFixtureDef.density = 0.05;
    activeFixtureDef.shape = shape;

    // Define body
    final BodyDef bodyDef = new BodyDef();
    bodyDef.type = BodyType.DYNAMIC;
    if(x == null) {
      x = 0.0;
      y = 30.0;
    }else {
     // print("before i scale, x is $x and y is $y");
      x = (x - canvas.width+3*birb.width/4)/ viewport.scale;
      y = (canvas.height - y-canvas.height/2+6*birb.height/4) / viewport.scale;
      //print("after i scale, x is $x and y is $y");
    }
    bodyDef.position = new Vector2(x, y);

    // Create body and fixture from definitions
    final Body fallingBox = world.createBody(bodyDef);
    fallingBox.createFixtureFromFixtureDef(activeFixtureDef);

    // Add to list
    bodies.add(fallingBox);
  }
}

class PigeonListener extends ContactListener {
  PigeonDemo demo;

  PigeonListener(PigeonDemo this.demo);

  //if two identical dolls touch, they vanish.
  @override
  void beginContact(Contact contact) {
    Body a = contact.fixtureA.getBody();
    Body b = contact.fixtureB.getBody();
    if(a.getType() == BodyType.DYNAMIC && b.getType() == BodyType.DYNAMIC) {
      CanvasElement dollA = demo.getRandomBirb(demo.bodies.indexOf(a));
      CanvasElement dollB = demo.getRandomBirb(demo.bodies.indexOf(b));
      if(dollA != null && dollA == dollB) {
        demo.toDestroy.add(contact.fixtureA);
        demo.toDestroy.add(contact.fixtureB);
      }
    }
  }

  @override
  void endContact(Contact contact) {
    // TODO: implement endContact
  }

  @override
  void postSolve(Contact contact, ContactImpulse impulse) {
    // TODO: implement postSolve
  }

  @override
  void preSolve(Contact contact, Manifold oldManifold) {
    // TODO: implement preSolve
  }
}
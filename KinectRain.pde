/* --------------------------------------------------------------------------
 * Rain simulation thing used with Kinect
 * --------------------------------------------------------------------------
 * Taro Morimoto, Christopher Jon Andersen, Pouyan Mohseninia
 * ----------------------------------------------------------------------------
 */
import java.util.Iterator;
import java.util.Map;
import SimpleOpenNI.*;
import ddf.minim.*;

Minim minim;
AudioPlayer underTheRainSound;
AudioSnippet backgroundSound;
int startPoint;
int endPoint;


SimpleOpenNI  context;
color[]       userClr = new color[]{ color(255,0,0),
                                     color(0,255,0),
                                     color(0,0,255),
                                     color(255,255,0),
                                     color(255,0,255),
                                     color(0,255,255)
                                   };
PVector com = new PVector();                                   
PVector com2d = new PVector();                                   

int[] userMap;
int[] depthMap;
PImage img;
PImage userImage = new PImage(640, 480);
PGraphics pg;
int dropHitCount = 0;
int frameCount = 0;
final int scale = 1;
final boolean PIXELS = true; // true is pixel rendering, false is vector
final boolean BW = true;    // true is black and white, false is color


long dropCounter = 0;
int numDrops = 10000;
HashMap drops = new HashMap();


void setup()
{
  size(640*scale, 480*scale);
  pg = createGraphics(width, height);
  //img = loadImage("helsinkiblackandwhite.jpg");
  
  setupAudio();
  
  context = new SimpleOpenNI(this);
  if (context.isInit() == false) {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }
  
  context.setMirror(true);
  context.enableDepth();
  context.enableUser();
 
  background(0);
  smooth();  
  
  setupRain();
}

void setupAudio() {
  minim = new Minim(this);

  startPoint = 500;
  endPoint = 1000;
  
  backgroundSound = minim.loadSnippet("STE-006_01.wav");
  backgroundSound.setLoopPoints(startPoint, endPoint);
  backgroundSound.loop(999);
  backgroundSound.setGain(10);

  underTheRainSound = minim.loadFile("STE-004_01.wav");
  backgroundSound.setLoopPoints(startPoint, endPoint);
  underTheRainSound.loop(999);
  //underTheRainSound.mute();
  underTheRainSound.setGain(-10);
}

void playWhenUserEnters() {
  //underTheRainSound.unmute();
  //backgroundSound.mute();
  underTheRainSound.setGain(10.0);
  backgroundSound.setGain(-10.0);
}

void playWhenUserExits() {
  backgroundSound.setGain(10.0);
  underTheRainSound.setGain(-10.0);
  //backgroundSound.unmute();
  //underTheRainSound.mute();
}

void updateSound() {
  if (dropHitCount > 0) {
     playWhenUserEnters();    
  } else {
     playWhenUserExits();    
  }
}

void draw() {
  // update the cam
  //image(img, 0, 0);
  context.update();
    
  userMap = context.userMap();
  depthMap = context.depthMap();
  
  updateSound();
  
  // Filter out background
  /*
  if (context.getNumberOfUsers() > 0) {
    userMap = context.userMap();
    loadPixels();
    for (int i = 0; i < userMap.length; i++) {
      if (userMap[i] != 0) {
        userImage.pixels[i] = userClr[userMap[i]];
      } else {
        userImage.pixels[i] = 0;
      } 
    }
    userImage.updatePixels();
  }
  */

  //image(userImage, 0, 0, width, height);
  
  // draw the skeleton if it's available
  /*
  int[] userList = context.getUsers();
  for (int i=0;i<userList.length;i++) {
    if (context.isTrackingSkeleton(userList[i])) {
      stroke(userClr[ (userList[i] - 1) % userClr.length ] );
      drawSkeleton(userList[i]);
    }      
      
    // draw the center of mass
    if (context.getCoM(userList[i],com)) {
      context.convertRealWorldToProjective(com,com2d);
      stroke(100,255,0);
      strokeWeight(1);
      beginShape(LINES);
        vertex(com2d.x,com2d.y - 5);
        vertex(com2d.x,com2d.y + 5);

        vertex(com2d.x - 5,com2d.y);
        vertex(com2d.x + 5,com2d.y);
      endShape();
      
      fill(0,255,100);
      text(Integer.toString(userList[i]),com2d.x,com2d.y);
    }
  }*/
  
  updateRain();
  drawRain();
  if (frameCount++ % 30 == 0)
    println(frameRate);
}

// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  // to get the 3d joint data
  /*
  PVector jointPos = new PVector();
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,jointPos);
  println(jointPos);
  */
  
  context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
}

// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(SimpleOpenNI curContext, int userId)
{
  println("onNewUser - userId: " + userId);
  //println("\tstart tracking skeleton");
  
  //curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
  //println("onVisibleUser - userId: " + userId);
}


void keyPressed()
{
  switch(key)
  {
  case ' ':
    context.setMirror(!context.mirror());
    break;
  }
}  

void setupRain() {
  for (int i = 0; i < numDrops; i++) {
    new Drop();
  }
}

void updateRain(){
  //loadPixels();
  dropHitCount = 0;
  
  Object[] arr = drops.values().toArray();
  for (int i = 0; i < arr.length; i++) {
    ((Drop)arr[i]).update();
  }
}

void drawRain(){
  pg.beginDraw();
  pg.noStroke();
  pg.background(0);
  pg.fill(0, 150);
  pg.rect(0, 0, width, height);
  
  if (PIXELS) {
    pg.endDraw();
    pg.loadPixels();
  }

  Iterator i = drops.entrySet().iterator();  // Get an iterator
  while (i.hasNext()) {
    Map.Entry e = (Map.Entry)i.next();
    ((Drop)e.getValue()).draw();
  }
  
  if (PIXELS) {
    pg.updatePixels();
  } else {
    pg.endDraw();
  }

  image(pg, 0, 0);
}

class Drop {
  long id;
  boolean isDroplet = false;
  boolean useDepth = false;
  boolean dieAfterDrawing = false;
  int lifetime = (int)random(5, 15);
  int size = 0;
  float x = random(width);
  float y = random(-height);
  float prevX = x;
  float prevY = y;
  PVector velocity = new PVector(random(1*scale, 6*scale), random(10*scale, 30*scale));
  color col;

  Drop() {
    dropCounter++;
    id = dropCounter;
    setup();
    drops.put(id, this);
  }
  Drop(float _x, float _y, boolean _isDroplet) {
    dropCounter++;
    id = dropCounter;
    setup();
    prevX = x = _x;
    prevX = y = _y;
    isDroplet = _isDroplet;
    drops.put(id, this);
  }
  
  void setup() {
    prevX = x = random(width);
    prevY = y = random(-height/2);
    size = (int)random(3*scale, 40*scale);
    setupColor();
  }
  
  void setupColor() {
    if (BW) {
      int c = (int)random(90, 255);
      col = color(c, c);
    } else {
      col = color(0, 0, map(x, 0, width, 100, 255), random(50, 200));
    }
  }
  
  void drawPixel(float fx, float fy, color c) {
    int ix = round(fx);
    int iy = round(fy);
    if (ix < 0 || ix >= width || iy < 0 || iy >= height) return;
    
    pg.pixels[ix + iy * width] = c;
  }
  
  void drawTrail(float xpos, float ypos, PVector trail, float dist, color c) {
      drawPixel(xpos - trail.x * dist, ypos - trail.y * dist, c);
  }

  void drawVector() {
    pg.fill(col);
    if (isDroplet) {
      pg.noStroke();
      pg.ellipse(x, y, size, size);
    } else {
      pg.stroke(col);
      pg.strokeWeight(1);
      pg.line(x, y, prevX, prevY);
    }
  }
  
  void drawToEdge(int xi, int yi, int intensity) {
    if (yi < 0) return;
    
    int index = xi + yi * width;
    int d = depthMap[index];
    int u = userMap[index];
    if (u > 0) {
      //drawPixel(xi, yi, color(255, intensity));
      drawToEdge(xi, yi-1, intensity + 20);
    } else {
      drawPixel(xi, yi, color(255));
    }
  }
  
  void drawPixels() {
    PVector trail = velocity.normalize(null);
    if (isDroplet) {
      if (useDepth) {
        drawToEdge((int)x, (int)y, 150);
      } else {
        drawPixel(x, y, col);
      }
    } else {
      for (int i = 1; i < size; i++) {
        drawTrail(x, y, trail, i, col);
      }
      drawPixel(x, y, col);
    }
  }
  
  void draw() {
    if (PIXELS) {
      drawPixels();
    } else {
      drawVector();
    }
    if (dieAfterDrawing) {
      die();
    }
  }
  
  void update() {
    prevX = x;
    prevY = y;
    y += velocity.y;
    x += velocity.x;
    
    if (isDroplet) {
      // Check when to die
      if (--lifetime < 0) {
        die();
        return;
      }
      // Update face gravity
      velocity.x *= 0.9;
      if (velocity.y < 10) {
        velocity.y += 0.5;
      }
    }

    if (y < 0) return;
    
    if (y >= height || x < 0 || x >= width){
      this.die();
      return;
    }
    
    // Check impact with silhouette
    //color c = userImage.pixels[(int)x + (int)y * w];
    //if (!isDroplet && (blue(c) != red(c) || red(c) != green(c))) {
    //if (!isDroplet && userMap[((int)x >> 1) + ((int)y >> 1) * 640] != 0) {
    int opacity = (int)red(col);
    if (!isDroplet && opacity > 120 && userMap[(int)x + (int)y * 640] != 0) {
      dropHitCount++;
      createDroplets();      
      dieAfterDrawing = true;
      return;
    }
  }
  
  void createDroplets() {
    createDroplet();
    createDroplet();
    createDroplet();
    createDroplet();
    createDroplet();
    //createDroplet(true);
  }
  
  void createDroplet() {
    createDroplet(false);
  }
  void createDroplet(boolean depth) {
    Drop droplet = new Drop(x, y, true);
    if (depth) {
      droplet.useDepth = true;
      droplet.size = 1;
      droplet.velocity.x = 0;
      droplet.velocity.y = 0.5;
      droplet.lifetime = 5;
    } else {
      droplet.size = (int)random(1, 3);
      droplet.velocity.x = random(-4, 4);
      droplet.velocity.y = random(-5, 5);
      droplet.lifetime = (int)random(5, 10);
    }
  }
  
  void die() {
    if (isDroplet) {
      drops.remove(id);
    } else {
      setup();
      dieAfterDrawing = false;
    }
  }
}

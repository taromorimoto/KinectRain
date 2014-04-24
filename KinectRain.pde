/* --------------------------------------------------------------------------
 * Rain simulation thing used with Kinect
 * --------------------------------------------------------------------------
 * Taro Morimoto, Christopher Jon Andersen, Pouyan Mohseninia
 * ----------------------------------------------------------------------------
 */
import java.util.Iterator;
import java.util.Map;
import SimpleOpenNI.*;


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

PImage userImage;
//PImage rainImage = new PImage(640, 480);

void setup()
{
  //size(1024, 768);
  size(640, 480);
  
  context = new SimpleOpenNI(this);
  if (context.isInit() == false) {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }
  
  context.setMirror(true);
  
  // enable depthMap generation 
  context.enableDepth();
   
  // enable skeleton generation for all joints
  context.enableUser();
 
  background(200,0,0);

  stroke(0,0,255);
  strokeWeight(3);
  smooth();  
  
  setupRain();
}



void draw()
{
  // update the cam
  context.update();
  
  // draw depthImageMap
  //image(context.depthImage(),0,0);
  userImage = context.userImage();
  userImage.loadPixels();
  
  // Filter out background
  for (int i = 0; i < userImage.pixels.length; i++) {
    color col = userImage.pixels[i];
    if ((col & 0xff) == (col >> 8 & 0xff) && (col & 0xff) == (col >> 16 & 0xff)) {
      userImage.pixels[i] = 0;
    } 
  }

  image(userImage, 0, 0, width, height);
  
  // draw the skeleton if it's available
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
  }
  
  updateRain();
  drawRain();
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
  println("\tstart tracking skeleton");
  
  curContext.startTrackingSkeleton(userId);
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


long dropCounter = 0;
int numDrops = 1000;
HashMap drops = new HashMap();

void setupRain() {
  for (int i = 0; i < numDrops; i++) {
    new Drop();
  }
}

void updateRain(){
  //loadPixels();
  
  Object[] arr = drops.values().toArray();
  for (int i = 0; i < arr.length; i++) {
    ((Drop)arr[i]).update();
  }
}

void drawRain(){
  noStroke();
  
  Iterator i = drops.entrySet().iterator();  // Get an iterator
  while (i.hasNext()) {
    Map.Entry e = (Map.Entry)i.next();
    ((Drop)e.getValue()).draw();
  }  
}

class Drop {
  long id;
  boolean isDroplet = false;
  int lifetime = 10 + (int)random(20);
  int size = 1 + (int)random(2);
  float x = random(600);
  float y = random(-height);
  PVector velocity = new PVector(random(10) / 10, 17 + (random(10) / 10));
  color col = color(100 + random(50), 200 + random(50), 255, 200 + random(50));

  Drop() {
    dropCounter++;
    id = dropCounter;
    drops.put(id, this);
  }
  Drop(float _x, float _y, boolean _isDroplet) {
    dropCounter++;
    id = dropCounter;
    
    x = _x;
    y = _y;
    isDroplet = _isDroplet;
    drops.put(id, this);
  }

  void draw() {
    fill(col);
    if (isDroplet) {
      noStroke();
      ellipse(x, y, size, size);
    } else {
      stroke(col);
      strokeWeight(size);
      line(x, y, x, y - size*1.5);
    }
  }
  
  void update() {
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
    color c = userImage.pixels[(int)x + (int)y*width];
    if (!isDroplet && (blue(c) != red(c) || red(c) != green(c))) {
      createDroplets();      
      die();
      return;
    }
  }
  
  void createDroplets() {
    Drop droplet = new Drop(x, y, true);
    droplet.size = 1;
    droplet.velocity.x = random(3);
    droplet.velocity.y = -random(3);
    
    droplet = new Drop(x, y, true);
    droplet.size = 1;
    droplet.velocity.x = -random(3);
    droplet.velocity.y = -random(3);
  }
  
  void die() {
    if (isDroplet) {
      drops.remove(id);
    } else {
      x = random(600);
      y = random(-10);
    }
  }
}

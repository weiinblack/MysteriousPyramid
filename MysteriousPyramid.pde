import gab.opencv.*;
import processing.video.*;
import java.awt.*;
import signal.library.*;

Rectangle[] faces;
Capture video;
OpenCV opencv;
SignalFilter myFilter;
SignalFilter myFilter2;
float step = 0;
int step2 = 10;
float angleY = 0;
float angleX = 0;
float zoom = 0;

float freq      = 120.0;
float minCutoff = 0.05; // decrease this to get rid of slow speed jitter
float beta      = 6.0;  // increase this to get rid of high speed lag
float dcutoff   = 1.0;
boolean isDetected = false;

void setup() {
  size(1280,720, P3D);
  //fullScreen(P3D);
  smooth();
  
  //為了處理人臉x,y 座標的濾波器
  myFilter = new SignalFilter(this, 3);
  myFilter.setFrequency(freq);
  myFilter.setMinCutoff(minCutoff);
  myFilter.setBeta(beta);
  myFilter.setDerivateCutoff(dcutoff); 
  
  //為了處理人臉width, height 的濾波器
  myFilter2 = new SignalFilter(this, 3);
  myFilter2.setFrequency(freq);
  myFilter2.setMinCutoff(minCutoff);
  myFilter2.setBeta(beta);
  myFilter2.setDerivateCutoff(dcutoff);

  String[] cameras = Capture.list();
  for (int i = 0; i < cameras.length; i++) {
    //列出電腦裡有連接的攝影機
    println(cameras[i]);
  }

  video = new Capture(this, 320, 240, cameras[0]);
  //new Capture(this, width, height, "pipeline:autovideosrc",30);
  //new Capture(this, width, height, "pipeline:avfvideosrc device-index=0 ! video/x-raw, width=640, height=480, framerate=30/1");

  opencv = new OpenCV(this, 320, 240);
  //讀取人臉辨識模組
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  video.start();
  frameRate(15);
  colorMode(HSB);
}
void draw() {
  background(0);
  beginCamera();
  camera();
  translate(0, 0, zoom);
  endCamera();

  float ratioX = width/320.0;
  float ratioY = height/240.0;

  push();
  if (video.available()) {
    video.read();
    opencv.loadImage(video);
    video.updatePixels();
    image(video, 0, 0 );
    faces = opencv.detect();
    
    //如果有偵測到一個人臉，就用rect()畫出追蹤方框序列
    if(faces.length>0) {
      isDetected= true;
      PVector vec = new PVector(faces[0].x, faces[0].y);
      PVector vec2 = new PVector(faces[0].width, faces[0].height);
      //訊號濾波
      PVector filteredVec = myFilter.filterCoord2D( vec, 320, 240 );
      PVector filteredVec2 = myFilter2.filterCoord2D( vec2, 320, 240 );

      for(int i = 0 ;i<10 ;i++){
        push();
        translate((filteredVec.x+filteredVec2.x/4)*ratioX, (filteredVec.y+filteredVec2.y/4)*ratioY,400-i*40);
        rotateZ(frameCount/5.0+i*0.1);
        rectMode(CENTER);
        stroke(255);
        noFill();
        rect(0,0 , filteredVec2.x*ratioX/(2+i), filteredVec2.x*ratioX/(2+i));
        pop();
      }
      angleY=map( (faces[0].x +  faces[0].width/2), 0, 320, -PI/3, PI/3);
      angleX=map( (faces[0].y +  faces[0].height/2), 0, 240, -PI/5, PI/5);
     
      zoom = map( filteredVec2.x, 0,320, -1500,1500);
    }else{
      isDetected = false;
    }
  }
  pop();
  
  translate(width/2, height/2);
  rotateX(2.65+angleX);
  rotateY(PI/2 - angleY );

  // 用sphere()畫出紅月
  push();
  translate(width/5, height/5);
  noStroke();
  if(isDetected){
    fill(0,255,255);
  }else{
    fill(0,0,128);
  }
  sphere(10);
  if(isDetected){
    pointLight(0, 255, 255, 0, 0, 0);
  }else{
    pointLight(0, 0, 128, 0, 0, 0);
  }
  pop();

  int p = width/8;
  for (int i = 0; i<p; i+=step2) {
    // 用circle()畫地面電波紋
    push();
    float c =map(i, 0, width/8, 0, 230);
    if(isDetected){
      stroke(255,230-c);
    }
    else{
      stroke(64);
    }
    rotateX(PI/2);
    noFill();
    circle(0, 0, p+i*6+(step%10)/10.0*(step2*6));
    pop();
    
    // 用box()畫金字塔
    push();
    float x = i + step%step2;
    if(isDetected){
      stroke(255,230-c);
    }
    else{
      stroke(64);
    }
    fill(255-c, 80);
    translate(0, width/16-x/2, 0);
    box(x, width/8-x, x);
    rotateX(PI/2);
    pop();
  }
  if(isDetected){
    step+=PI/5;
  } 
}

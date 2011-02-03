import hypermedia.video.*;

// init OpenCV
// reference: http://ubaa.net/shared/processing/opencv/
OpenCV opencv;


// SETTINGS

// camera settings
int contrast_value    = 0;  // used in HAAR
int brightness_value  = 0;  // used in HAAR
int threshold_value   = 190; // used in BLOBs

// position for calibrating
int webcam_x = 0;
int webcam_y = 0;
int overall_scale = 4;

int frames_since_last_save = 0;

// trigger
boolean cfg_mode_blobs = false;
boolean cfg_debug = false;
boolean cfg_reset = false;
boolean cfg_auto_save = true;



void setup() {
 
    size( 1290, 820 );
    background(0);

    opencv = new OpenCV( this );
    opencv.capture( 320, 240 );    // open video stream

    // LOAD THE HAAR CASCADER (load the profile only once, here in setup) 
//    opencv.cascade( OpenCV.CASCADE_FULLBODY );  // load detection description, here-> front face detection : "haarcascade_frontalface_alt.xml"
    opencv.cascade( OpenCV.CASCADE_FRONTALFACE_ALT );  // load detection description, here-> front face detection : "haarcascade_frontalface_alt.xml"

}


public void stop() {
    opencv.stop();
    super.stop();
}



void draw() {
    
    // black out, reset screen to black
    if (cfg_reset) {
      background(0);
      cfg_reset = false;
      println("--------[ black out ]--------");
    }
  
    scale(overall_scale);
    
    // grab new frame
    opencv.read();
    opencv.contrast( contrast_value );
    opencv.brightness( brightness_value );

    
    // pushmatrix for position transition (calibration)
    pushMatrix();
    translate(webcam_x, webcam_y);

    // display the webcam image (for calibration/debugging)
    if (cfg_debug) {
      image( opencv.image(), 0, 0 );
    }


    if (cfg_mode_blobs) {
    //  ######################  //
    //  MODE blobs              //
    //  ######################  //
    
    
      // absDiff is only neccessary when OpenCV.MEMORY is used
      opencv.absDiff();
      opencv.threshold(threshold_value);
      if (cfg_debug) {
        image( opencv.image(OpenCV.GRAY),0,0 );
      }
    
      // detect blobs
      //                    blobs(minArea, maxArea, maxBlobs, findHoles);
      Blob[] blobs = opencv.blobs(100,     width*height/5,   3,         false );

//      println("blobs gefunden: "+blobs.length);
      // transform them into founds as Rectangles[]
      for( int i=0; i<blobs.length; i++ ) {
        paint(blobs[i].rectangle);
      }
      
      // restore the webcam image, destroyed by blobs()
      opencv.restore();
    
    
    } else {
    //  ######################  //
    //  MODE haar               //
    //  ######################  //
            
      // grab a new frame
      // and convert to gray
      opencv.convert( GRAY );
  
      // proceed detection
      //              detect(scale, min_neighbors, flags, min_width, min_height);
      Rectangle[] founds = opencv.detect( 1.2, 2, OpenCV.HAAR_DO_CANNY_PRUNING, 40, 40 ); 
      for( int i=0; i<founds.length; i++ ) {
        paint(founds[i]);
//        rect( founds[i].x, founds[i].y, founds[i].width, founds[i].height ); 
      }
    }
    //  ######################  //
    //  end of MODE             //
    //  ######################  //

    
    // popmatrix for position transition (calibration)
    popMatrix();
    
    // check for auto-save (every 10 minutes)
    if (cfg_auto_save) {
      frames_since_last_save++;
      if (frames_since_last_save >= 1000) {
        saveFrame("data/save_"+String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", Calendar.getInstance())+"_##.png"); println("image saved");
        frames_since_last_save = 0;
      }
    }
    
}


//  ######################  //
//  DRAW the founds         //
//  ######################  //
void paint(Rectangle coord) {
  stroke(255,0,0);
  strokeWeight(1);
  noStroke();
  fill(255,0,0,20);
//  rect( coord.x, coord.y, coord.width, coord.height );
  ellipse(coord.x+coord.width/2, coord.y+coord.width/2, coord.width*.75, coord.width*.75);
  
  
}



/**
 * change settings, trigger and actions
*/
void keyPressed(){
  if(key=='q' || key=='Q') { saveFrame("data/save_"+String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", Calendar.getInstance())+"_##.png"); println("image saved"); }
  
  if(key=='w' || key=='W') { cfg_debug = !cfg_debug; cfg_reset = true; }

  if(key=='m' || key=='M') { cfg_mode_blobs = !cfg_mode_blobs; println("changed mode! mode blobs is: "+cfg_mode_blobs); }

  // reset
  if(key=='r')
    cfg_reset = true;
  if(key=='R') {
    cfg_reset = true;
    contrast_value    = 0;  // used in HAAR
    brightness_value  = 0;  // used in HAAR
    threshold_value   = 190; // used in BLOBs
  }
  
  // auto-save
  if(key=='o' || key=='O') { cfg_auto_save = !cfg_auto_save; frames_since_last_save = 0; println("AUTO SAVE IS NOW "+cfg_auto_save); }
  
  // position
  if(key=='4') { webcam_x -= 10; println("webcam_x is now "+webcam_x); }
  if(key=='6') { webcam_x += 10; println("webcam_x is now "+webcam_x); }
  if(key=='8') { webcam_y -= 10; println("webcam_y is now "+webcam_y); }
  if(key=='2') { webcam_y += 10; println("webcam_y is now "+webcam_y); }
  if(key=='5') { webcam_x = 0; webcam_y = 0; println("webcam_x & y reset to "+webcam_x+"/"+webcam_y); }
  
  // scale
  if(key=='-') overall_scale -= .125;
  if(key=='.') overall_scale = 4;
  
  // threshold (for blobs)
  if(key=='t') { threshold_value -= 10; println("changed threshold: "+threshold_value); }
  if(key=='T') { threshold_value += 10; println("changed threshold: "+threshold_value); }

  // brightness
  if(key=='b') { brightness_value -= 10; println("changed brightness: "+brightness_value); }
  if(key=='B') { brightness_value += 10; println("changed brightness: "+brightness_value); }

  // contrast
  if(key=='c') { contrast_value -= 10; println("changed contrast: "+contrast_value); }
  if(key=='C') { contrast_value += 10; println("changed contrast: "+contrast_value); }
  
  // ask
  if(key=='a' || key=='A') { println("-------ASKED FOR SETTINGS-------\nthreshold: "+threshold_value+"\nbrightness: "+brightness_value+"\ncontrast: "+contrast_value); }
}


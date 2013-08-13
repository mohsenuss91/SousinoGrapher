import processing.serial.*;

color backgroundColor = color(51);
color targetColor = color(0, 255, 0);
color inputColor = color(255, 255, 0);

Serial port;
int posX;

void setup() {
  size(640, 480);

  port = new Serial(this, Serial.list()[0], 9600);
  port.bufferUntil('\n');

  background(backgroundColor);  
}

void draw() {  
}

void drawFloat(float value, color strokeColor) {
  stroke(strokeColor);
  point(posX, map(value, 0, 100, 0, height));
  //line(posX, height, posX, height - map(value, 0, 100, 0, height));
}

void serialEvent(Serial port) {
  String data = port.readStringUntil('\n');

  if (data != null) {
    float[] values = float(splitTokens(data, ","));
    float mode = values[0];
    
    if (mode == 1) {
      float target = values[1];
      float input = values[2];
      
      // Cooking      
      drawFloat(target, targetColor); // Target
      drawFloat(input, inputColor); // Input

      if (posX >= width) {
        posX = 0;
        background(backgroundColor);
      } else {
        posX++;
      }
    } else if (mode == 2) {
      // Tuning complete
      float kP = values[1];
      float kI = values[2];
      float kD = values[3];
      
      println("Done tuning, P: " + kP + ", I: " + kI + ", D: " + kD);
    }    
  }
}

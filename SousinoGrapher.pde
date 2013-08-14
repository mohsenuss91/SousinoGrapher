import processing.serial.*;

color backgroundColor = color(50);
color targetColor = color(0, 255, 0);
color inputColor = color(255, 255, 0);
color markerColor = color(70);
color markerLabelColor = color(110);

Serial port;
int posX;

int markerLastTime;
int markerInterval = 10000;
int startTime;

int paddingTop = 100;

void setup() {
  size(640, 480);
  
  port = new Serial(this, Serial.list()[0], 9600);
  port.bufferUntil('\n');
  
  startTime = millis();

  clearPlot();
  frameRate(5);
}

void draw() {
  float[] values = new float[3];
  
  values[0] = 1;
  values[1] = 60;
  
  values[2] = map(posX, 0, width, 20, 80);
  drawPlot(values);
}

void clearPlot() {
  background(backgroundColor);
  stroke(markerColor);
  
  for (int i = 0; i < 10; i = i + 1) {
    float y = map(i, 0, 10, paddingTop, height);
    
    line(0, y, width, y);
  }
}

void serialEvent(Serial port) {
  String data = port.readStringUntil('\n');

  if (data != null) {
    drawPlot(float(splitTokens(data, ",")));
  }
}

void drawPlot(float[] values) {
    // Clear top
    noStroke();
    fill(backgroundColor);
    rect(0, 0, width, paddingTop - 20);
    
    // Marker
    if (millis() > markerLastTime + markerInterval) {
      markerLastTime = millis();
      
      int diff = (millis() - startTime) / 1000; 
      int minutes = floor(diff / 3600);
      int seconds = floor(diff % (3600 / 60));

      fill(markerLabelColor);
      stroke(markerColor);
      
      line(posX, paddingTop, posX, height);
      text(String.format("%02d:%02d", minutes, seconds), posX - 18, 93);      
    }
  
    float mode = values[0];
    
    if (mode == 1) {
      float target = values[1];
      float input = values[2];
      
      // Legend
      fill(targetColor);
      text(String.format("Target: %.1f", target), 10, 30);

      fill(inputColor);
      text(String.format("Input: %.1f", input), 10, 50);
      
      // Point      
      drawPoint(target, targetColor); // Target
      drawPoint(input, inputColor); // Input

      if (posX >= width) {
        posX = 0;
        clearPlot();
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

void drawPoint(float value, color strokeColor) {
  stroke(strokeColor);
  point(posX, map(value, 100, 0, paddingTop, height));
}


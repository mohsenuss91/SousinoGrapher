import processing.serial.*;

color backgroundColor = color(50);
color markerColor = color(60);
color markerLabelColor = color(80);

color targetColor = color(31, 255, 31);
color inputColor = color(255, 255, 31);
color tuningColor = color(255, 31, 31);

Serial port;

PGraphics panel;
PGraphics chart;
PGraphics chartBackground;

int paddingX = 40;
int paddingY = 25;
int chartX = 0; // Current chart drawing position (incremented each time data is plotted)
int viewportX = 0; // Viewport offset

int startTime; // When we ran the sketch

int markerTime;
int markerInterval = 10000;

int simulationTime;
int simulationInterval = 10;

int tailTimeout = 3000; // How long after releasing the mouse we should start tailing again

int mousePressX = 0;
int mouseReleaseTime;

boolean dragging;
boolean tail = true; // If we should keep up with the chart position

void setup() {
  size(640, 480);

  /*
  port = new Serial(this, Serial.list()[0], 9600);
  port.bufferUntil('\n');
  */

  startTime = millis();

  panel = createGraphics(width, 100);
  chart = createGraphics(width * 10, height - panel.height); 
  chartBackground = createGraphics(width, chart.height); 

  drawChartBackground();
  simulationEvent();
}

void draw() {
  background(backgroundColor);  
  image(panel, 0, 0);
  image(chartBackground, 0, panel.height - 5);
  copy(chart, viewportX, 0, width - (paddingX * 2), height, paddingX, panel.height, width - (paddingX * 2), height);
  
  if (markerTime + markerInterval < millis()) {
    markerTime = millis();    
    markerEvent();
  }
  
  if (simulationTime + simulationInterval < millis()) {
    simulationTime = millis();
    simulationEvent();
  }
  
  if (mouseReleaseTime > 0 && mouseReleaseTime + tailTimeout < millis()) {
    dragTimeoutEvent();
  }
}

void simulationEvent() {
  float[] values = new float[4];

  // Cooking
  values[0] = 1;
  values[1] = 60;
  values[2] = map(chartX, 0, width, 20, 80);

  // Tuning
  /*
  values[0] = 2;
  */
  
  // Simulation
  /*
  values[0] = 3;
  values[1] = 10;
  values[2] = 30;
  values[3] = 70;
  */

  drawChart(values);
}

void serialEvent(Serial port) {
  String data = port.readStringUntil('\n');

  if (data != null) {
    drawChart(float(splitTokens(data, ",")));
  }
}

void markerEvent() {
  int diff = (millis() - startTime) / 1000;
  int minutes = floor(diff / 3600);
  int seconds = floor(diff % (3600 / 60));

  chart.beginDraw();
  chart.fill(markerLabelColor);
  chart.stroke(markerColor);

  chart.line(chartX, paddingY, chartX, chart.height - paddingY);
  chart.text(String.format("%02d:%02d", minutes, seconds), chartX - 18, paddingY - 10);
  chart.endDraw();
}

void dragTimeoutEvent() {
  tail = true;
  mouseReleaseTime = 0;
}

void mousePressed() {
  mousePressX = viewportX - mouseX;
  mouseReleaseTime = 0;

  dragging = true;
  tail = false;  
}

void mouseDragged() {
  viewportX = max(0, mouseX + mousePressX);
}

void mouseReleased() {
  dragging = false; 
  mouseReleaseTime = millis();
}

void drawChartBackground() {
  chartBackground.beginDraw();
  chartBackground.stroke(markerColor);
  chartBackground.fill(markerLabelColor);
  chartBackground.textAlign(RIGHT);  

  for (int i = 0; i <= 10; i = i + 1) {
    float y = map(i, 0, 10, chartBackground.height - paddingY, paddingY);

    chartBackground.line(paddingX, y, chartBackground.width - paddingX, y);
    chartBackground.text(String.format("%d°", i * 10), paddingX - 5, y + 5);
  }

  chartBackground.endDraw();  
}

void drawChart(float[] values) {
  float type = values[0];

  // Cooking or tuning
  if (type == 1 || type == 2) { // Cooking
    float target = values[1];
    float input = values[2];

    // Panel
    panel.clear();
    panel.beginDraw();
    
    panel.fill(targetColor);
    panel.text(String.format("Target: %.1f°", target), 20, paddingY);

    panel.fill(inputColor);
    panel.text(String.format("Input: %.1f°", input), 20, paddingY + 20);

    if (type == 2) {
      panel.fill(tuningColor);
      panel.text("Tuning...", 20, paddingY + 40);     
    }
    
    panel.endDraw();

    // Plot values
    chart.beginDraw();
    chart.stroke(targetColor);
    chart.point(chartX, map(target, 100, 0, 0, chart.height));

    // Input
    chart.stroke(inputColor);
    chart.point(chartX, map(input, 100, 0, 0, chart.height));
    chart.endDraw();

    chartX++;

    if (tail && chartX > chartBackground.width - (paddingX * 2)) {
      viewportX = chartX - chartBackground.width + (paddingX * 2);
    }
    
    // Tuning
  } else if (type == 3) { // Tuning complete
    float kP = values[1];
    float kI = values[2];
    float kD = values[3];
    
    chart.beginDraw();    
    chart.fill(tuningColor);
    chart.stroke(tuningColor);
    chart.line(chartX, paddingY, chartX, chart.height - paddingY);
    chart.text(String.format("Tuning complete, kP: %.2f, kI: %.2f, kD: %.2f", kP, kI, kD), chartX - 5, chart.height - 10);
    chart.endDraw();   
  }
}


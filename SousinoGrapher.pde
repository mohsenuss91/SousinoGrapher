import processing.serial.*;

color backgroundColor = color(50);
color markerColor = color(60);
color markerLabelColor = color(80);

color targetColor = color(31, 255, 31);
color inputColor = color(255, 255, 31);
color outputColor = color(255, 31, 255);

Serial port;
Table table;

int panelTop = 25;
int panelLeft = 20;

int chartTop = 100;
int chartLeft = 40;
int chartRight = chartLeft;
int chartBottom = 25;

int viewportX = 0;

int simulationTime;
int simulationInterval = 10;
boolean simulating = false;

int mousePressX = 0;
int mouseReleaseTime;
int tailTimeout = 3000; // How long after releasing the mouse we should start tailing again

boolean dragging;
boolean tail = true; // If we should keep up with the chart position

void setup() {
  size(640, 480);

  table = new Table();
  table.addColumn("Time");
  table.addColumn("Target");
  table.addColumn("Input");
  table.addColumn("Output");

  try {
    port = new Serial(this, Serial.list()[0], 9600);
    port.bufferUntil('\n');
  } catch (ArrayIndexOutOfBoundsException e) {
    simulating = true;
    simulationEvent();
  }
}

void draw() {
  background(backgroundColor);

  // Simulation
  if (simulating && simulationTime + simulationInterval < millis()) {
    simulationTime = millis();
    simulationEvent();
  }  

  // Mouse drag timeout
  if (mouseReleaseTime > 0 && mouseReleaseTime + tailTimeout < millis()) {
    dragTimeoutEvent();
  }

  int rows = table.getRowCount();

  // Tail
  if (tail && rows > width) {
    viewportX = rows - width - 1;
  }  

  // Panel
  TableRow lastRow = table.getRow(rows - 1);

  textAlign(LEFT);

  fill(targetColor);
  text(String.format("Target: %.1f°", lastRow.getFloat("Target")), panelLeft, panelTop);

  fill(inputColor);
  text(String.format("Input: %.1f°", lastRow.getFloat("Input")), panelLeft, panelTop + 20);

  fill(outputColor);
  text(String.format("Output: %.1f", lastRow.getFloat("Output")), panelLeft, panelTop + 40);

  stroke(markerColor);
  fill(markerLabelColor);
  textAlign(RIGHT);  

  for (int i = 0; i <= 10; i = i + 1) {
    float y = map(i, 0, 10, height - chartBottom, chartTop);

    line(chartLeft, y, width, y);
    text(String.format("%d°", i * 10), 35, y + 5);
  }

  // Chart
  for (int x = 0; x < min(rows - viewportX - 1, width); x = x + 1) {
    TableRow row = table.getRow(viewportX + x);

    // Target
    stroke(targetColor);
    point(chartLeft + x, map(row.getFloat("Target"), 100, 0, chartTop, height - chartBottom));

    // Input
    stroke(inputColor);
    point(chartLeft + x, map(row.getFloat("Input"), 100, 0, chartTop, height - chartBottom));

    // Output
    stroke(outputColor);
    point(chartLeft + x, map(row.getFloat("Output"), 100, 0, chartTop, height - chartBottom));
  }
}

void simulationEvent() {
  TableRow row = table.addRow();
  row.setInt("Time", millis());
  row.setFloat("Target", 60);
  row.setFloat("Input", map(sin(table.getRowCount()), 0, width, 20, 80));
  row.setFloat("Output", map(sin(table.getRowCount()), 0, width, 0, 100));

  table.addRow(row);
}

void serialEvent(Serial port) {
  String data = port.readStringUntil('\n');

  if (data != null) {
    // {Target,T,55.00}
    String type = data.substring(1, data.indexOf(","));
    float value = float(data.substring(data.lastIndexOf(",") + 1, data.length() - 1));
    TableRow row = type == "Target" ? table.addRow() : table.getRow(table.getRowCount() - 1);

    row.setFloat(type, value);
  }
}

/*
void markerEvent() {
  int diff = millis() - startTime;
  int seconds = (diff / 1000) % 60;
  int minutes = diff / 1000 / 60; 
 
  chart.beginDraw();
  chart.fill(markerLabelColor);
  chart.stroke(markerColor);

  chart.line(chartX, paddingY, chartX, chart.height - paddingY);
  chart.text(String.format("%02d:%02d", minutes, seconds), chartX - 18, paddingY - 10);
  chart.endDraw();
}
*/

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
  viewportX = max(0, min(table.getRowCount() - 1, mouseX + mousePressX));
}

void mouseReleased() {
  dragging = false; 
  mouseReleaseTime = millis();
}
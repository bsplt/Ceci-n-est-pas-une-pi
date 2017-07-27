/*
 * CECI N'EST PAS UNE π
 * ARTISTIC RESEARCH OF AN APPROXIMATION TO THE VALUE PI BY MONTE CARLO METHOD
 *
 * Alexander Lehmann
 * Assignment for "Algorithmic Thinking" by Frieder Nake
 * 2017 Universtiy of Bremen & University of the Arts Bremen
 * Written in Processing 3.3
 */

// ----- VARIABLES OPEN TO TUNING -----

// Video settings
boolean settingsWindowFullscreen = true;
float settingsWindowedScale = 0.8;
float settingsFramesPerSecond = 60;

// Save each frame as PNG and change the timebase
boolean recordMode = false;

// Amount of samples for the Monte Carlo Simulation
int samplePointCountMin = 20;
int samplePointCountMax = 60;

// Duration of both visual cycles in milliseconds
float durationSampling = 9000;
float durationCandy = 20000;

// ----- GLOBAL VARIABLES, KEEP HANDS OFF -----

float maxColVal = PI;
color colLightBg = #FAFAFA;
color colDarkBg = #111111;
float sampleSphereScale = 0.3;
float piColOffset;
float colSaturation;
float globalYRot;

SamplePoint[] samplePoints;
Timer timer;

// ----- MAIN PROCESSING FUNCTIONS -----

void settings()
{
  if (settingsWindowFullscreen)
  {
    fullScreen(P3D);
    smooth(8);
  } else
  {
    int setDisplayWidth = int(displayWidth * settingsWindowedScale);
    int setDisplayHeight = int(displayHeight * settingsWindowedScale);
    size(setDisplayWidth, setDisplayHeight, P3D);
    smooth(8);
  }
}

void setup()
{
  frameRate(settingsFramesPerSecond);
  colorMode(HSB, maxColVal);
  textAlign(CENTER, CENTER);
  textMode(MODEL);
  textSize(height / 75);
  strokeWeight((float) width / 1500);
  if (settingsWindowFullscreen)
  {
    noCursor();
  }
  initPiSequence();
}

void draw()
{
  timer.tick();

  // A rudimentary version of a sequencer
  if (timer.time(recordMode) <= durationSampling) {
    drawSamplePoints();
  }
  if (timer.time(recordMode) > durationSampling) {
    drawCandyPoints();
  }
  if (timer.time(recordMode) > durationSampling + durationCandy)
  {
    initPiSequence();
  }

  if (recordMode)
  {
    saveFrame("export/pi-######.png");
  }
}

// ----- FUNCTIONS AND SIDE EFFECTS -----

void initPiSequence()
  // Resets and loads all data necessary for visualisation
{
  // minor changes by chance to the resulting color scheme
  piColOffset = random(maxColVal);
  colSaturation = random(maxColVal / 4, maxColVal / 2);

  globalYRot = 0;

  // The heart of the program, Monte Carlo Simulation of Pi
  int samplePointCount = int(random(samplePointCountMin, samplePointCountMax));
  samplePoints = new SamplePoint[samplePointCount];
  int monteCarloCounter = 0;
  for (int i = 0; i < samplePoints.length; i += 1)
  {
    float dim = height * sampleSphereScale;
    PVector sample = new PVector(random(-dim, dim), random(-dim, dim), random(-dim, dim));
    Boolean inSampleSphere = false;
    if (dist(0, 0, 0, sample.x, sample.y, sample.z) < height * sampleSphereScale)
    {
      monteCarloCounter += 1;
      inSampleSphere = true;
    }
    float piApproximation = (float) monteCarloCounter / (i + 1) * 6;
    samplePoints[i] = new SamplePoint(sample, piApproximation, durationSampling * 0.75, inSampleSphere);
  }

  timer = new Timer();
}

void drawSamplePoints()
  // first phase of the visual loop, "data aesthetics"
{
  background(colDarkBg);
  float lerp = map(timer.time(recordMode), durationSampling / 2, durationSampling, 0, 1);
  lerp = constrain(lerp, 0, 1);
  float startRotSpeed = 0;
  float endRotSpeed = TWO_PI * timer.deltaTime(recordMode) / (durationCandy / 1000);
  globalYRot += map(lerp, 0, 1, startRotSpeed, endRotSpeed);
  float easedLerp = cubicEasingInOut(lerp, 0, 1, 1);
  for (int i = 0; i < samplePoints.length; i += 1)
  {
    samplePoints[i].display(easedLerp, timer.time(recordMode), globalYRot);
  }
  drawGuides(lerp);
}

void drawCandyPoints()
  // seconds phase of the visual loop, "candy aesthetics"
{
  background(colLightBg);
  globalYRot += TWO_PI * timer.deltaTime(recordMode) / (durationCandy / 1000);
  for (int i = 0; i < samplePoints.length; i += 1)
  {
    samplePoints[i].displayCandy(globalYRot);
  }

  fill(colDarkBg);
  text("π = " +  samplePoints[samplePoints.length-1].pi, width / 2, height / 1.1);
}

void drawGuides(float lerp)
{
  noFill();
  stroke(0, 0, maxColVal, map(lerp, 0.1, 0.8, 0, maxColVal / 3));
  ellipse(width / 2, height / 2, height * sampleSphereScale * 2, height * sampleSphereScale * 2); 
  stroke(0, 0, maxColVal, maxColVal / 3);
  line(0, height / 2, width, height / 2);
}

float cubicEasingInOut (float time, float begin, float change, float duration)
  // Easing function after Robert Penner
{
  if ((time /= duration / 2) < 1)
  {
    return change / 2 * time * time * time + begin;
  }
  return change / 2 * ((time -= 2) * time * time + 2) + begin;
}

// ----- CLASSES -----

class SamplePoint
  // Sample in the MCS as well as visual feature in the loop
{
  PVector origin; 
  PVector projection; 
  float pi; 
  float piCol; 
  float appearanceTime; 
  boolean firstDisplay; 
  boolean show; 
  float candySize; 

  SamplePoint(PVector startVector, float approxPi, float maxAppearanceTime, boolean inSphere) {
    origin = startVector; 
    projection = unwrap(origin); 
    appearanceTime = random(maxAppearanceTime); 
    firstDisplay = true; 
    pi = approxPi; 
    piCol = (approxPi + piColOffset) % maxColVal; 
    show = inSphere; 
    candySize = (HALF_PI - abs(PI - approxPi)) * width / 20 / HALF_PI; 
    if (candySize < height / 200) candySize = height / 200;
  }

  void display(float stateLerp, float time, float rot)
  {
    if (show)
    {
      PVector inter = interpolate(stateLerp, origin, projection); 
      pushMatrix(); 
      translate(width / 2, height / 2); 
      rotateY(rot); 
      translate(inter.x, inter.y, inter.z); 
      if (time > appearanceTime)
      {
        stroke(colLightBg); 
        noFill(); 
        rotateY(-rot); 
        ellipse(0, 0, height / 250, height / 250); 
        if (firstDisplay)
        {
          line(0, -width / 15, 0, -width / 40);
          line(0, width / 15, 0, width / 40);
          line(-width / 15, 0, -width / 40, 0);
          line(width / 15, 0, width / 40, 0);
          firstDisplay = false;
        }
      }
      popMatrix();
    }
  }

  void displayCandy(float rot)
  {
    if (show) {
      pushMatrix(); 
      translate(width / 2, height / 2); 
      rotateY(rot); 
      translate(origin.x, origin.y, origin.z); 
      noStroke(); 
      fill(piCol, colSaturation, maxColVal); 
      sphere(candySize); 
      popMatrix();
    }
  }

  PVector interpolate(float lerp, PVector wrapped, PVector unwrapped)
    // Interpolates between a 3d vector in a spherical coordinate system and a projected 2d vector
  {
    PVector inter = new PVector(); 
    inter.x = map(lerp, 0, 1, unwrapped.x, wrapped.x); 
    inter.y = map(lerp, 0, 1, unwrapped.y, wrapped.y); 
    inter.z = map(lerp, 0, 1, 0, wrapped.z); 
    return inter;
  }

  PVector unwrap(PVector wrapped)
    // Projects a 3d vector in a spherical coordinate system on a 2d plane, like a map 
  {
    PVector unwrapped = new PVector(); 
    unwrapped.z = wrapped.mag(); 
    if (unwrapped.z > 0)
    {
      unwrapped.x = map(-atan2(wrapped.z, wrapped.x), 0, TWO_PI, 0, width); 
      unwrapped.y = map(asin(wrapped.y / unwrapped.z), 0, PI, 0, height);
    }
    return unwrapped;
  }
}

class Timer
  // Usage of this class frees the program from a hardcoded timebase
  // It can either be deltatime (for realtime) or fixed steps (for rendering)
  // Call the tick()-method once a frame so deltaTime will be advanced
{
  long startingTime; 
  long startingFrame; 
  long lastTime; 
  float deltaTime; 

  Timer()
  {
    this.reset();
  }

  void reset()
  {
    startingTime = millis(); 
    startingFrame = frameCount;
  }

  void tick()
  {
    deltaTime = (float) (millis() - lastTime) / 1000; 
    lastTime = millis();
  }

  float time(boolean frameBased)
  {
    if (frameBased)
    {
      return (float) (frameCount - startingFrame) / settingsFramesPerSecond * 1000;
    } else
    {
      return (float) millis() - startingTime;
    }
  }

  float deltaTime(boolean frameBased)
  {
    if (frameBased)
    {
      return (float) 1 / settingsFramesPerSecond;
    } else
    {
      return deltaTime;
    }
  }
}
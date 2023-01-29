#include <EEPROM.h>               //Used to save setpoint when power-off
#include<math.h> 
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>         //download here: https://www.electronoobs.com/eng_arduino_Adafruit_GFX.php
#include <Adafruit_SSD1306.h>     //downlaod here: https://www.electronoobs.com/eng_arduino_Adafruit_SSD1306.php
#define OLED_RESET 5
Adafruit_SSD1306 display(OLED_RESET);
#include "DHT.h"
#define DHTPIN 2     
#define DHTTYPE DHT22  
DHT dht(DHTPIN, DHTTYPE);

//Arduino Pins
#define SSR_PIN  11
#define but_up  4
#define but_down  5
#define but_stop  6
#define led  10

//Variables
uint8_t state = 0;
bool D4_state = 1;
bool D5_state = 1;
bool D6_state = 1;
bool LED_State = LOW;
float prev_isr_timeD4, prev_isr_timeD5, prev_isr_timeD6;

float real_temp;           //We will store here the real temp 
float Setpoint = 100;      //In degrees C
float SetpointDiff = 30;   //In degrees C
float elapsedTime, now_time, prev_time;        //Variables for time control
float refresh_rate = 200;                   //PID loop time in ms
float now_pid_error, prev_pid_error;
float temperatura;


///////////////////PID constants///////////////////////
float kp=2.5;         //Mine was 2.5
float ki=0.06;         //Mine was 0.06
float kd=0.8;         //Mine was 0.8
float PID_p, PID_i, PID_d, PID_total;
///////////////////////////////////////////////////////



void setup() {
  cli();
  Setpoint = EEPROM.read(0)+1; //we adf 
  sei();
  
  Serial.begin(9600);     //For debug
  dht.begin();
  pinMode(SSR_PIN, OUTPUT);  
  digitalWrite(SSR_PIN, LOW);    // When LOW, the SSR is Off
  
  pinMode(led, OUTPUT);  
  digitalWrite(led, LOW);
  //real_temp = temperatura;
  
  TCCR2B = TCCR2B & B11111000 | B00000111;    // D11 PWM is now 30.64 Hz
  
  pinMode(but_up, INPUT_PULLUP); 
  pinMode(but_down, INPUT_PULLUP); 
  pinMode(but_stop, INPUT_PULLUP); 
  PCICR |= B00000100;      //Bit2 = 1 -> "PCIE2" enabeled (PCINT16 to PCINT23)
  PCMSK2 |= B01110000;     //PCINT20, CINT21, CINT22 enabeled -> D4, D5, D6 will trigger interrupt

  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);  // initialize with the I2C addr 0x3C (for the 128x32 or 64 from eBay)
  delay(100);
  display.clearDisplay();
  display.setTextSize(2);  
  display.setTextColor(WHITE,BLACK);
  display.display();  
  delay(100);
  //EEPROM.write(1, Setpoint);
  
}

void loop() {  
 temperatura = dht.readTemperature();  
 if(temperatura > Setpoint)
 {
  digitalWrite(SSR_PIN, HIGH); 
 }
 else 
{
  digitalWrite(SSR_PIN, LOW);  
}
 
  display.clearDisplay();      
  display.setCursor(0,0);  
  display.print("Set: "); 
  display.println(Setpoint,1);
  display.print("Temp:");      
  display.print(temperatura);       
  display.display();//Finally display the created image
}





ISR (PCINT2_vect) 
{
  cli();  
  //1. Check D4 pin HIGH
  if(PIND & B00010000){ 
    if(D4_state == 0){
      D4_state = 1;
      prev_isr_timeD4 = millis();
    }
      
  }
  else if (D4_state == 1 && (millis() - prev_isr_timeD4 > 2)){
    Setpoint ++;
    int st = Setpoint;
    EEPROM.write(0, st);
    D4_state = 0;
  }


  //2. Check D5 pin HIGH
  if(PIND & B00100000){ 
    if(D5_state == 0){
      D5_state = 1;
      prev_isr_timeD5 = millis();
    }
      
  }
  else if (D5_state == 1 && (millis() - prev_isr_timeD5 > 2)){
    Setpoint --;
    int st = Setpoint;
    EEPROM.write(0, st);
    D5_state = 0;
  }




  //3. Check D6 pin HIGH
  if(PIND & B01000000){ 
    if(D6_state == 0){
      D6_state = 1;
      prev_isr_timeD6 = millis();
    }
      
  }
  else if (D6_state == 1 && (millis() - prev_isr_timeD6 > 2)){    
    if(state == 0 || state == 1){
      state = 2;
    }
    else if (state == 2){
      state = 0;
    }
    D6_state = 0;
  }
  sei();

  
} 
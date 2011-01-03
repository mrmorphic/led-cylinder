#include <LiquidCrystal.h>

/*
 * Program to drive the LCD display, which is HD44780 compatible.
 */

/* HD44780 pins */
int LCD_RS_Pin = 8 + 2; // PB2
int LCD_RW_Pin = 8 + 1; // PB1
int LCD_E_Pin  = 8 + 0;  // PB0

int LCD_D7_Pin = 7; // PD7
int LCD_D6_Pin = 6; // PD6
int LCD_D5_Pin = 5; // PD5
int LCD_D4_Pin = 4; // PD4
int LCD_D3_Pin = 3; // PD3
int LCD_D2_Pin = 2; // PD2
int LCD_D1_Pin = 1; // PD1
int LCD_D0_Pin = 0; // PD0

int LED_Pin = 8 + 3; // PB3

LiquidCrystal lcd(
  LCD_RS_Pin,
  LCD_RW_Pin,
  LCD_E_Pin,
//  LCD_D0_Pin,
//  LCD_D1_Pin,
//  LCD_D2_Pin,
//  LCD_D3_Pin,
  LCD_D4_Pin,
  LCD_D5_Pin,
  LCD_D6_Pin,
  LCD_D7_Pin
);

void setup() {                
  pinMode(LED_Pin, OUTPUT);     
  digitalWrite(LED_Pin, HIGH);
/*  pinMode(LCD_D7_Pin, OUTPUT);
  pinMode(LCD_D6_Pin, OUTPUT);
  pinMode(LCD_D5_Pin, OUTPUT);
  pinMode(LCD_D4_Pin, OUTPUT);
  pinMode(LCD_D3_Pin, OUTPUT);
  pinMode(LCD_D2_Pin, OUTPUT);
  pinMode(LCD_D1_Pin, OUTPUT);
  pinMode(LCD_D0_Pin, OUTPUT);
  pinMode(LCD_RS_Pin, OUTPUT);
  pinMode(LCD_RW_Pin, OUTPUT);
  pinMode(LCD_E_Pin, OUTPUT);
*/
  lcd.begin(16, 2);
  lcd.print("woot! i rulz");
}

long m = millis();

void loop()
{
  // Turn off the display:
  lcd.noDisplay();
  digitalWrite(LED_Pin, LOW);
  delay(500);
   // Turn on the display:
  lcd.display();
  digitalWrite(LED_Pin, HIGH);
  delay(500);
}


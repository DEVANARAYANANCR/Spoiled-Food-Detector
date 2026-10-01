#include <reg52.h>          // AT89S52 register definitions (Keil C51)

/* ---------- LCD (16x2, 8-bit mode) ---------- */
sfr LCD_Port = 0x80;             // P0 as LCD data port (D0-D7), needs external 10k pull-ups
sbit rs = P1^0;                  // P1.0 Register select pin
sbit rw = P1^1;                  // P1.1 Read/Write pin
sbit en = P1^2;                  // P1.2 Enable pin

/* ---------- MQ3 gas sensor & Push Button ---------- */
sbit gasSensor = P3^0;           // MQ3 DO (digital output) -> P3.0
sbit btn = P3^2;                 // Push button -> P3.2 (Active Low)

/* ---------- Buzzer ---------- */
sbit buzzer = P1^3;              // Buzzer control -> P1.3 (via NPN transistor driver)

typedef unsigned char uchar;

/* 1ms with 11.0592 Mhz crystal */
void delay(unsigned int count) {
    unsigned int i, j;
    for (i = 0; i < count; i++)
        for (j = 0; j < 111; j++);
}

void EN_Pulse(void) {
    en = 1; delay(1);
    en = 0; delay(5);
}

void LCD_sendData(char cmnd, bit isText) {
    LCD_Port = cmnd;      /* Send full byte in one shot (8-bit mode) */
    rs = isText; rw = 0;
    EN_Pulse();
}

void LCD_String(char *str) {
    uchar i;
    for (i = 0; str[i] != 0; i++) {
        LCD_sendData(str[i], 1);
    }
}

void LCD_Init(void) {
    delay(20);                   /* LCD Power ON Initialization time >15ms */
    LCD_sendData(0x38, 0);       /* 8-bit mode, 2 lines, 5x7 font */
    LCD_sendData(0x0C, 0);       /* Display ON Cursor OFF */
    LCD_sendData(0x06, 0);       /* Auto Increment cursor */
    LCD_sendData(0x01, 0);       /* clear display */
    LCD_sendData(0x80, 0);       /* cursor at home position */
}

void showDefaultScreen(void) {
    LCD_sendData(0x01, 0);       // Clear display
    LCD_sendData(0x80, 0);       // Line 1
    LCD_String("Press Button");
    LCD_sendData(0xC0, 0);       // Line 2
    LCD_String("For Checking");
}

void main(void) {
    uchar dotCount = 0;
    unsigned int elapsed = 0;
    bit gasDetectedFlag = 0;

    gasSensor = 1;        // Configure P3.0 as input
    btn = 1;              // Configure P3.2 as input (pull-up)
    buzzer = 0;           // Buzzer OFF initially
    LCD_Init();

    showDefaultScreen();  // Show initial message

    while (1) {
        // Check if push button is pressed (assuming active low: button connects pin to GND when pressed)
        if (btn == 0) {
            delay(50);    // Debounce delay
            if (btn == 0) {
                // Start 20-second checking phase
                LCD_sendData(0x01, 0);
                LCD_sendData(0x80, 0);
                LCD_String("Checking...");

                gasDetectedFlag = 0;
                elapsed = 0;
                dotCount = 0;

                // Loop for 20 seconds (20,000 ms) while checking sensor and animating dots
                while (elapsed < 20000) {
                    // Check if gas/spoilage is detected (0 = detected, adjust if your module logic differs)
                    if (gasSensor == 0) {
                        gasDetectedFlag = 1;
                    }

                    // Animate dots on line 2
                    LCD_sendData(0xC0, 0);
                    dotCount++;
                    if (dotCount == 1) {
                        LCD_String(".     ");
                    } else if (dotCount == 2) {
                        LCD_String("..    ");
                    } else if (dotCount == 3) {
                        LCD_String("...   ");
                        dotCount = 0;
                    }

                    delay(300);       // Dot animation speed
                    elapsed += 300;
                }

                // Display results for 10 seconds (10,000 ms)
                LCD_sendData(0x01, 0);
                LCD_sendData(0x80, 0);

                if (gasDetectedFlag == 1) {
                    LCD_String("Spoiled Food");
                    LCD_sendData(0xC0, 0);
                    LCD_String("Gas Detected");
                    buzzer = 1;       // Turn buzzer ON
                } else {
                    LCD_String("Food is Fresh");
                    LCD_sendData(0xC0, 0);
                    LCD_String("No Gas Found");
                    buzzer = 0;       // Buzzer OFF
                }

                delay(10000);         // Show result for 10 seconds

                // Reset buzzer and return to default prompt
                buzzer = 0;
                showDefaultScreen();
            }
        }
    }
}
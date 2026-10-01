# Spoiled Food Detector using 8051 (AT89S52)

A low-cost embedded system that checks whether food has started to spoil by sensing the gases it gives off. It uses an **AT89S52 (8051) microcontroller**, an **MQ-3 gas sensor module**, a **16x2 LCD** and a **buzzer**. Press the button, wait for the check to finish, and the result appears on the display.

> **Note:** This is an educational / mini-project prototype. It is a simple indicator and is **not** a certified food-safety device. Do not rely on it alone to decide whether food is safe to eat.

---

## Table of Contents

- [Features](#features)
- [Components Required](#components-required)
- [How It Works](#how-it-works)
- [Pin Connections](#pin-connections)
- [Circuit Notes](#circuit-notes)
- [Software and Tools](#software-and-tools)
- [Project Structure](#project-structure)
- [Build and Upload](#build-and-upload)
- [Usage](#usage)
- [Calibration Tips](#calibration-tips)
- [Limitations](#limitations)
- [Future Improvements](#future-improvements)


---

## Features

- Gas-based spoilage detection using the MQ-3 sensor (digital output)
- Push-button controlled: the sensor is checked only when you ask
- 20-second sampling window with an animated "Checking..." display
- Clear result on a 16x2 LCD: **Food is Fresh** or **Spoiled Food**
- Buzzer alarm when spoilage gas is detected
- Written in **Embedded C (Keil C51)**, with an equivalent **8051 assembly** version

---

## Components Required

| Component | Quantity | Notes |
|---|---|---|
| AT89S52 microcontroller (8051 core) | 1 | 40-pin DIP |
| MQ-3 gas sensor module | 1 | Uses the digital output (DO) pin |
| 16x2 character LCD (HD44780) | 1 | Used in 8-bit mode |
| Push button | 1 | Active low |
| Buzzer (active) | 1 | Driven through a transistor |
| NPN transistor (e.g. BC547) | 1 | Buzzer driver |
| 11.0592 MHz crystal | 1 | Required for the delay timing in the code |
| 2 x 33 pF capacitors | 2 | Crystal load capacitors |
| 10 uF capacitor + 10k resistor | 1 each | Power-on reset circuit |
| 10k resistor pack / resistors | 8 | Pull-ups for Port 0 |
| 10k potentiometer | 1 | LCD contrast |
| 1k resistor | 1 | Transistor base resistor |
| 5V power supply | 1 | Regulated 5V |
| Breadboard / PCB, jumper wires | - | |

---

## How It Works

1. On power-up the LCD shows:
   ```
   Press Button
   For Checking
   ```
2. When the push button is pressed (with a 50 ms debounce), the system enters the **checking phase** and the LCD shows `Checking...` with animated dots.
3. For **20 seconds** the microcontroller continuously reads the MQ-3 digital output. If the sensor output goes **LOW** even once, spoilage gas is flagged as detected.
4. After 20 seconds the result is shown for **10 seconds**:
   - **Gas detected:** `Spoiled Food / Gas Detected` and the buzzer turns ON
   - **No gas:** `Food is Fresh / No Gas Found` and the buzzer stays OFF
5. The buzzer is switched off and the system returns to the "Press Button" screen, ready for the next check.

### Flow

```
Power ON -> Show "Press Button" -> Wait for button
        -> Check sensor for 20 s -> Show result for 10 s
        -> Reset buzzer -> Back to start
```

---

## Pin Connections

### LCD (16x2, 8-bit mode)

| LCD Pin | Connected To |
|---|---|
| D0 - D7 | P0.0 - P0.7 (with 10k pull-ups to 5V) |
| RS | P1.0 |
| RW | P1.1 |
| EN | P1.2 |
| VSS, RW (if unused elsewhere) | GND |
| VDD | +5V |
| VEE (contrast) | Middle pin of 10k pot |
| A / K (backlight) | +5V (through resistor) / GND |

### Other connections

| Device | Microcontroller Pin |
|---|---|
| MQ-3 DO (digital out) | P3.0 |
| Push button (other end to GND) | P3.2 |
| Buzzer (via NPN transistor) | P1.3 |

### Microcontroller essentials

| Pin | Connection |
|---|---|
| EA (pin 31) | +5V |
| VCC (pin 40) | +5V |
| GND (pin 20) | GND |
| XTAL1 / XTAL2 | 11.0592 MHz crystal with 2 x 33 pF capacitors to GND |
| RST (pin 9) | Power-on reset circuit (10 uF + 10k) |

---

## Circuit Notes

- **Port 0 pull-ups:** Port 0 of the 8051 is open-drain, so it needs external 10k pull-up resistors to work as the LCD data bus.
- **Buzzer driver:** the buzzer is driven through an NPN transistor (P1.3 -> 1k -> base, emitter to GND, buzzer between +5V and collector), so the microcontroller pin does not supply the buzzer current directly.
- **Common ground:** the MQ-3 module, LCD, buzzer and microcontroller must all share the same ground.
- **Crystal:** the delay loops are tuned for **11.0592 MHz**. A different crystal will change all the timings.

---

## Software and Tools

- **Keil uVision (C51)** to compile the C code
- Any 8051 assembler (Keil A51, ASEM-51) for the assembly version
- An ISP programmer for the AT89S52 (e.g. USBasp or a dedicated AT89S programmer) with its software
- Proteus (optional) for simulation

---

## Project Structure

```
Spoiled-Food-Detector-8051/
|-- main.c               # Embedded C source (Keil C51)
|-- food_checker.asm     # Equivalent 8051 assembly source
|-- blink.c              # Simple LED blink test (C)
|-- blink.asm            # Simple LED blink test (assembly)
|-- README.md
```

Adjust the file names to match your repository.

---

## Build and Upload

1. Open Keil uVision and create a new project.
2. Select the device **Atmel AT89S52**.
3. Add `main.c` to the project (or `food_checker.asm` for the assembly version).
4. Enable **Create HEX File** under *Options for Target -> Output*.
5. Set the crystal frequency to **11.0592 MHz** under *Options for Target -> Target*.
6. Build the project to generate the `.hex` file.
7. Upload the `.hex` file to the AT89S52 using your ISP programmer.

> Tip: before testing the full project, upload the blink program to confirm your board, crystal and programmer are working.

---

## Usage

1. Power the circuit with a regulated 5V supply.
2. **Let the MQ-3 sensor warm up** (see calibration tips) before the first check.
3. Place the sensor close to the food sample.
4. Press the push button and wait while `Checking...` is displayed.
5. Read the result on the LCD. If spoilage gas is detected, the buzzer will sound during the result screen.

---

## Calibration Tips

- The MQ-3 heater needs a **warm-up period** (a few minutes, ideally longer on first use) for stable readings.
- Adjust the **onboard potentiometer** on the MQ-3 module to set the digital-output threshold. Test it with fresh food and with food you know has spoiled.
- The code assumes the sensor's **DO pin goes LOW when gas is detected**. If your module works the opposite way, change the condition `gasSensor == 0` in the code.

---

## Limitations

- The MQ-3 mainly responds to alcohol/ethanol and some other vapours, so it detects spoilage only indirectly and may react to other substances.
- The digital output only gives a yes/no result, not a measured gas level.
- Readings depend on temperature, humidity, sensor warm-up and the distance from the food.
- Not suitable as a certified food-safety tool.

---

## Future Improvements

- Use the MQ-3 analog output with an ADC (e.g. ADC0804) to show actual gas levels
- Add additional sensors (e.g. MQ-135, temperature and humidity)
- Add LED indicators (green / red)
- Add a GSM or Wi-Fi module for alerts
- Battery-powered portable version with a PCB design



;==============================================================
;  Food Spoilage Checker - AT89S52 (8051), 11.0592 MHz crystal
;  16x2 LCD (8-bit mode) + MQ3 digital output + push button
;  Assembly version of the Keil C program
;==============================================================

;---------------- Pin definitions ----------------
LCD_PORT    EQU 80h         ; P0 -> LCD D0-D7 (needs 10k pull-ups)
RS          BIT 90h         ; P1.0
RW          BIT 91h         ; P1.1
EN          BIT 92h         ; P1.2
BUZZER      BIT 93h         ; P1.3 (via NPN driver)
GAS         BIT 0B0h        ; P3.0  MQ3 DO (0 = gas detected)
BTN         BIT 0B2h        ; P3.2  Push button (active low)

GAS_FLAG    BIT 20h.0       ; gasDetectedFlag

; Register usage in main:
;   R2 = loop counter for 20 s checking phase (67 x 300 ms)
;   R3 = dotCount
; Delay routines use R4:R5 (count), R6, R7

            ORG 0000h
            LJMP START

;==============================================================
;  MAIN
;==============================================================
            ORG 0030h
START:
            MOV SP, #60h            ; move stack away from register banks / flag
            SETB GAS                ; P3.0 as input
            SETB BTN                ; P3.2 as input (pull-up)
            CLR  BUZZER             ; buzzer OFF
            ACALL LCD_INIT
            ACALL SHOW_DEFAULT      ; "Press Button / For Checking"

MAIN_LOOP:
            JB   BTN, MAIN_LOOP     ; wait until button pressed (0)

            MOV  R4, #HIGH 50       ; debounce 50 ms
            MOV  R5, #LOW 50
            ACALL DELAY_MS
            JB   BTN, MAIN_LOOP     ; still not pressed -> ignore

            ;---- Start checking phase ----
            MOV  A, #01h            ; clear display
            ACALL LCD_CMD
            MOV  A, #80h            ; line 1
            ACALL LCD_CMD
            MOV  DPTR, #STR_CHECK
            ACALL LCD_STRING

            CLR  GAS_FLAG
            MOV  R3, #0             ; dotCount = 0
            MOV  R2, #67            ; 67 x 300 ms ~= 20 s

CHECK_LOOP:
            JB   GAS, NO_GAS_NOW    ; GAS = 1 -> nothing detected
            SETB GAS_FLAG           ; GAS = 0 -> spoilage gas detected
NO_GAS_NOW:
            MOV  A, #0C0h           ; line 2
            ACALL LCD_CMD

            INC  R3
            CJNE R3, #1, NOT_ONE
            MOV  DPTR, #STR_DOT1
            ACALL LCD_STRING
            SJMP DOT_DONE
NOT_ONE:
            CJNE R3, #2, NOT_TWO
            MOV  DPTR, #STR_DOT2
            ACALL LCD_STRING
            SJMP DOT_DONE
NOT_TWO:
            MOV  DPTR, #STR_DOT3
            ACALL LCD_STRING
            MOV  R3, #0             ; dotCount = 0
DOT_DONE:
            MOV  R4, #HIGH 300      ; dot animation speed 300 ms
            MOV  R5, #LOW 300
            ACALL DELAY_MS

            DJNZ R2, CHECK_LOOP

            ;---- Show result ----
            MOV  A, #01h
            ACALL LCD_CMD
            MOV  A, #80h
            ACALL LCD_CMD

            JNB  GAS_FLAG, FOOD_FRESH

            MOV  DPTR, #STR_SPOIL1  ; "Spoiled Food"
            ACALL LCD_STRING
            MOV  A, #0C0h
            ACALL LCD_CMD
            MOV  DPTR, #STR_SPOIL2  ; "Gas Detected"
            ACALL LCD_STRING
            SETB BUZZER
            SJMP SHOW_RESULT

FOOD_FRESH:
            MOV  DPTR, #STR_FRESH1  ; "Food is Fresh"
            ACALL LCD_STRING
            MOV  A, #0C0h
            ACALL LCD_CMD
            MOV  DPTR, #STR_FRESH2  ; "No Gas Found"
            ACALL LCD_STRING
            CLR  BUZZER

SHOW_RESULT:
            MOV  R4, #HIGH 10000    ; show result 10 s
            MOV  R5, #LOW 10000
            ACALL DELAY_MS

            CLR  BUZZER
            ACALL SHOW_DEFAULT
            LJMP MAIN_LOOP

;==============================================================
;  SHOW_DEFAULT : "Press Button" / "For Checking"
;==============================================================
SHOW_DEFAULT:
            MOV  A, #01h
            ACALL LCD_CMD
            MOV  A, #80h
            ACALL LCD_CMD
            MOV  DPTR, #STR_PRESS
            ACALL LCD_STRING
            MOV  A, #0C0h
            ACALL LCD_CMD
            MOV  DPTR, #STR_FOR
            ACALL LCD_STRING
            RET

;==============================================================
;  LCD ROUTINES
;==============================================================
; EN_PULSE : EN high 1 ms, low 5 ms
EN_PULSE:
            SETB EN
            MOV  R4, #0
            MOV  R5, #1
            ACALL DELAY_MS
            CLR  EN
            MOV  R4, #0
            MOV  R5, #5
            ACALL DELAY_MS
            RET

; LCD_CMD : send command in A (RS = 0)
LCD_CMD:
            MOV  LCD_PORT, A
            CLR  RS
            CLR  RW
            ACALL EN_PULSE
            RET

; LCD_DATA : send character in A (RS = 1)
LCD_DATA:
            MOV  LCD_PORT, A
            SETB RS
            CLR  RW
            ACALL EN_PULSE
            RET

; LCD_STRING : DPTR -> null-terminated string in code memory
LCD_STRING:
            CLR  A
            MOVC A, @A+DPTR
            JZ   STR_END
            ACALL LCD_DATA
            INC  DPTR
            SJMP LCD_STRING
STR_END:
            RET

; LCD_INIT
LCD_INIT:
            MOV  R4, #0
            MOV  R5, #20            ; >15 ms power-on wait
            ACALL DELAY_MS
            MOV  A, #38h            ; 8-bit, 2 lines, 5x7
            ACALL LCD_CMD
            MOV  A, #0Ch            ; display ON, cursor OFF
            ACALL LCD_CMD
            MOV  A, #06h            ; auto increment cursor
            ACALL LCD_CMD
            MOV  A, #01h            ; clear display
            ACALL LCD_CMD
            MOV  A, #80h            ; cursor home
            ACALL LCD_CMD
            RET

;==============================================================
;  DELAY ROUTINES (11.0592 MHz, 1 machine cycle = 1.085 us)
;==============================================================
; DELAY_MS : delay = R4:R5 milliseconds (R4 = high byte, R5 = low byte)
;            R4:R5 are destroyed. Count must not be 0.
DELAY_MS:
DMS_LOOP:
            ACALL DELAY_1MS
            MOV  A, R5
            JNZ  DMS_SKIP
            DEC  R4
DMS_SKIP:
            DEC  R5
            MOV  A, R4
            ORL  A, R5
            JNZ  DMS_LOOP
            RET

; DELAY_1MS : ~923 machine cycles = ~1.0 ms
DELAY_1MS:
            MOV  R7, #2
D1MS_OUT:
            MOV  R6, #228
            DJNZ R6, $
            DJNZ R7, D1MS_OUT
            RET

;==============================================================
;  STRINGS (null terminated)
;==============================================================
STR_PRESS:  DB 'Press Button', 0
STR_FOR:    DB 'For Checking', 0
STR_CHECK:  DB 'Checking...', 0
STR_DOT1:   DB '.     ', 0
STR_DOT2:   DB '..    ', 0
STR_DOT3:   DB '...   ', 0
STR_SPOIL1: DB 'Spoiled Food', 0
STR_SPOIL2: DB 'Gas Detected', 0
STR_FRESH1: DB 'Food is Fresh', 0
STR_FRESH2: DB 'No Gas Found', 0

            END
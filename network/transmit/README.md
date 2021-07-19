# pico_LCD_Display
First attempt to run an LCD Display from the pico using c.

This will be a header file that can be used to run the HD44780U (LCD-II) based LCD Display from the Raspberry Pi Pico.

The lcd_display struct holds the number of the GPIO pin that is connected to each of the LCD Display's pins.

<b>NOTE:</b> <ul><li>If RW is set to 'n' the functions will operate without checking the 'busy flag'. All read functions will be disabled.</li><li>If any data pin in array position 4 - 7 (DB0 - DB3) is set to 'n' the functions will operate in '4-bit mode'.</li><ul>

<h3>LCD pin numbers assumed:</h3>
    <b>1</b> - GND : Tied to ground -- not included in lcd_display struct.<br />
    <b>2</b> - VDD : Tied to 5v -- not included in lcd_display struct.<br />
    <b>3</b> - VO  : for brigtness control -- not included in lcd_display.<br />
    <b>4</b> - RS  : Register Select -- Required - type: char -- supply GPIO pin number that is connected to RS pin on LCD Display.<br />
    <b>5</b> - RW  : Read/Write Select -- Required - type: char -- supply GPIO pin number that is connected to the RW pin on the LCD Display. <i>Set to 'n' if the pin is not connected to the pico.</i><br />
    <b>6</b> - E   : Enable Pin -- Required - type char -- supply GPIO pin number that is connected to E pin on the LCD Display.<br />
    <b>7 to 14</b> - DB  : Data Pins -- Required - type: array of 8 char -- supply GPIO pins that are connected to the LCD Display in an array from the DB7 pin to the DB0 pin. If any pins in array positions 4, 5, 6 or 7 are equal to 'n' (or anything equlivant to an integer > 30) the functions will opperate in '4 bit mode' using just the data pind DB7, DB6, DB5 and DB4 meaning that DB0 - DB3 do not need to be connected to the pico.<br />
    <b>15</b> - BL1 : Back light 5v -- Not included in lcd_display struct.<br />
    <b>16</b> - BL2 : Back light GND -- Not included in lcd_display struct.<br />

<h3>Recommended initlisation:</h3>
    
    const struct lcd_display display={RS_PIN, RW_PIN, E_PIN, {DB7_PIN, DB6_PIN, DB5_PIN, DB4_PIN, DB3_PIN, DB2_PIN, DB1_PIN, DB0_PIN}};

<h3>Functions available:</h3>
    
<h4>Intended for use outside of header:</h4>
    
        void lcd_init_pins(struct lcd_display display);
        void lcd_init_display(struct lcd_display display);
        void lcd_display_msg(struct lcd_display display, char *message);
        void lcd_jump_to_line_2(struct lcd_display display);
        void lcd_jump_to_pos(struct lcd_display display, uint pos);
        void lcd_set_cursor(struct lcd_display display, bool cursor);

<h4>Intended for use internally by the header:</h4>
    
	void lcd_set_pins(struct lcd_display display, uint rs, uint rw, char pin_state);
	void lcd_set_pins_4_only(struct lcd_display display, char rs, char rw, char pin_state);
	void lcd_wait_for_busy_flag(struct lcd_display display);


<h3>To use:</h3>

a. Define pin numbers<br />
for example (8 bit mode):
    
		#define E_PIN 2
		#define RS_PIN 0
		#define RW_PIN 1
		#define DB7_PIN 10
		#define DB6_PIN 9
		#define DB5_PIN 8  
		#define DB4_PIN 7
		#define DB3_PIN 6
		#define DB2_PIN 5
		#define DB1_PIN 4
		#define DB0_PIN 3

for example (4 bit mode with no RW pin connected):
	
 		#define E_PIN 2
 		#define RS_PIN 0
 		#define RW_PIN 'n'
 		#define DB7_PIN 10
 		#define DB6_PIN 9
 		#define DB5_PIN 8  
 		#define DB4_PIN 7
 		#define DB3_PIN 'n'
 		#define DB2_PIN 'n'
 		#define DB1_PIN 'n'
 		#define DB0_PIN 'n'
	
b. Set up a const sturuct LCD-display<br />
    for example:
        
	const struct lcd_display display={RS_PIN, RW_PIN, E_PIN, {DB7_PIN, DB6_PIN, DB5_PIN, DB4_PIN, DB3_PIN, DB2_PIN, DB1_PIN, DB0_PIN}};

c. Initlise pins on pico<br />
    for example:
    
    	lcd_init_pins(display);

d. Initlise display<br />
    for example:
    
    	lcd_init_display(display);

e. Write message<br />
    for example:
    
    	lcd_display_msg(display, "Hello, World!");

<h3>Example use of header file:</h3>

    #include <stdio.h>
    #include "pico/stdlib.h"
    #include "hardware/gpio.h"
    #include "pico/binary_info.h"
    #include "../pico_LCD_Display/h_files/pico_LCD_display.h"

    #define E_PIN 2
    #define RS_PIN 0
    #define RW_PIN 1
    #define DB7_PIN 10
    #define DB6_PIN 9
    #define DB5_PIN 8
    #define DB4_PIN 7
    #define DB3_PIN 6
    #define DB2_PIN 5
    #define DB1_PIN 4
    #define DB0_PIN 3


    void main() {

        const struct lcd_display display={RS_PIN, RW_PIN, E_PIN, {DB7_PIN, DB6_PIN, DB5_PIN, DB4_PIN, DB3_PIN, DB2_PIN, DB1_PIN, DB0_PIN}};

        stdio_init_all();

        lcd_init_pins(display);
        lcd_init_display(display);
        lcd_display_msg(display, "Hello, World!");
        lcd_jump_to_line_2(display);
        lcd_display_msg(display, "Hello again!");
        lcd_set_cursor(display, false);
    }

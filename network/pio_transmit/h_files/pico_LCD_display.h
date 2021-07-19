#include <stdio.h>
#include <string.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "pico/binary_info.h"

struct lcd_display {
	//if rw_pin is connected to ground set rw_pin to 'n' (or anything equlivant to an integer > 30)
	//if any of the db_pins in array positions greater than 4 are set to 'n' (or anything equlivant to an integer > 30) the functions will opperate with only 4 DB connections
	char rs_pin;
	char rw_pin;
	char e_pin;
	char db_pins[8];
};

void lcd_set_pins(struct lcd_display display, char rs, char rw, char pin_state);
void lcd_set_pins_4_only(struct lcd_display display, char rs, char rw, char pin_state);
void lcd_init_display(struct lcd_display display);
void lcd_init_pins(struct lcd_display display);
void lcd_wait_for_busy_flag(struct lcd_display display);
void lcd_display_msg(struct lcd_display display, char *message);
void lcd_jump_to_line_2(struct lcd_display display);
void lcd_jump_to_pos(struct lcd_display display, uint pos);
void lcd_set_cursor(struct lcd_display display, bool cursor);


void lcd_set_pins(struct lcd_display display, char rs, char rw, char pin_state)
// set the pins for the LCD Display
// char pin_state is a byte to hold the D7 to D0 pins
// rs - register select pin
// rw - read/write pin
{
	// check to see if the RW pin is connected. If not connected cannot check for bust state fo wait for 50 microseconds (37 recomended by datasheet)
	if (display.rw_pin <= 30)
		lcd_wait_for_busy_flag(display);
	else
		sleep_us(50);

	gpio_put(display.e_pin, 0);
	sleep_us(1);
	gpio_put(display.rs_pin, rs);
	if (display.rw_pin <= 30)
		gpio_put(display.rw_pin, rw);
	
	//setting the data pins (DB) here
	if ((display.db_pins[4] > 30) || (display.db_pins[5] > 30) || (display.db_pins[6] > 30) || (display.db_pins[7] > 30))
	{
		//set the first 4 bits
		for (int bit_idx = 0; bit_idx < 8; bit_idx++){
			if (bit_idx < 4)
				gpio_put(display.db_pins[bit_idx],  pin_state & (0x80 >> bit_idx));
			else {
				if (bit_idx == 4) {
					sleep_us(1);
					gpio_put(display.e_pin,1);
					sleep_us(1);
					gpio_put(display.e_pin,0);
					sleep_us(1);
				}
				gpio_put(display.db_pins[bit_idx-4],  pin_state & (0x80 >> bit_idx));
			}
		
		}

	} else {

		for (int bit_idx = 0; bit_idx < 8; bit_idx++){
			gpio_put(display.db_pins[bit_idx],  pin_state & (0x80 >> bit_idx));
			
		}
	}
	sleep_us(1);
	gpio_put(display.e_pin,1);
	sleep_us(1);
	gpio_put(display.e_pin,0);
	
}

void lcd_set_pins_4_only(struct lcd_display display, char rs, char rw, char pin_state)
{

	sleep_us(50);

	gpio_put(display.e_pin, 0);
	sleep_us(1);
	gpio_put(display.rs_pin, rs);
	if (display.rw_pin <= 30)
		gpio_put(display.rw_pin, rw);
	
	for (int bit_idx = 0; bit_idx < 4; bit_idx++){
		gpio_put(display.db_pins[bit_idx],  pin_state & (0x80 >> bit_idx));
		
	}
	sleep_us(1);
	gpio_put(display.e_pin,1);
	sleep_us(1);
	gpio_put(display.e_pin,0);
}

void lcd_init_display(struct lcd_display display)
/* Sets up the display as per the Datasheet */
{
	// Page 46 of HD44780 Datasheet as reference for following 4 bit initialization
	if ((display.db_pins[4] > 30) || (display.db_pins[5] > 30) || (display.db_pins[6] > 30) || (display.db_pins[7] > 30))
	{
		sleep_ms(20);
		lcd_set_pins_4_only(display, 0, 0, 0x30);
		sleep_ms(5);
		lcd_set_pins_4_only(display, 0, 0, 0x30);
		sleep_us(120);
		lcd_set_pins_4_only(display, 0, 0, 0x30);
		sleep_us(120);
		lcd_set_pins_4_only(display, 0, 0, 0x20); 
		sleep_ms(2);
		lcd_set_pins_4_only(display, 0, 0, 0x20);
		lcd_set_pins_4_only(display, 0, 0, 0x80);
		sleep_ms(2);

		
	} else {
	
		// Page 45 of HD44780 Datasheet as reference for following 8 bit initialization
		sleep_ms(45);
		lcd_set_pins(display, 0, 0, 0x30);
		sleep_ms(5);
		lcd_set_pins(display, 0, 0, 0x30);
		sleep_us(120);
		lcd_set_pins(display, 0, 0, 0x30);
		
		if (display.rw_pin > 30)
			sleep_ms(2);
		// Function set to 8-bit operation; 2 line display
		lcd_set_pins(display, 0, 0, 0x38);

	}

		// Turn on the display and cursor
		lcd_set_pins(display, 0, 0, 0x0e);
		// Set entry mode to increment and not shift display
		lcd_set_pins(display, 0, 0, 0x06);
		// Clear screen and move to home
		lcd_set_pins(display, 0, 0, 0x01);

		if (display.rw_pin > 30)
			sleep_ms(2);	
}

void lcd_init_pins(struct lcd_display display)
/* initilise the GPIO pins on the pico being used with the LCD Display and set them to output */
{
	gpio_init(display.e_pin);
	gpio_set_dir(display.e_pin, GPIO_OUT);
	gpio_put(display.e_pin, 0);
	gpio_init(display.rs_pin);
	gpio_set_dir(display.rs_pin, GPIO_OUT);
	// only set up the RW pin if it is connected
	if (display.rw_pin <= 30) {
		gpio_init(display.rw_pin);
		gpio_set_dir(display.rw_pin, GPIO_OUT);
	}
	
	if ((display.db_pins[4] > 30) || (display.db_pins[5] > 30) || (display.db_pins[6] > 30) || (display.db_pins[7] > 30)) {
		for (int i = 0; i < 4; i++)
		{
			gpio_init(display.db_pins[i]);
			gpio_set_dir(display.db_pins[i], GPIO_OUT);
		}
	} else {
	
		for (int i = 0; i < 8; i++)
		{
			gpio_init(display.db_pins[i]);
			gpio_set_dir(display.db_pins[i], GPIO_OUT);
		}
	}

}

void lcd_display_msg(struct lcd_display display, char *message)
/* Display a message to the LCD Display */
{
	for (int byte_idx = 0; byte_idx < strlen(message); byte_idx++) {
		char d_byte = message[byte_idx];
		lcd_set_pins(display, 1, 0, d_byte);
	}

}

void lcd_wait_for_busy_flag(struct lcd_display display)
/* Waits for the LCD's busy flag to clear.
   ONLY USE if RW pin connected to pico
*/

{
	//get the current state of the pins to return to once busy flag if off
	char start_state_DB[8];
	bool start_state_RS;
	bool start_state_RW;
	uint num_bits = 8;

	if ((display.db_pins[4] > 30) || (display.db_pins[5] > 30) || (display.db_pins[6] > 30) || (display.db_pins[7] > 30)) {
		num_bits = 4;
	}

	start_state_RS = gpio_get(display.rs_pin);
	start_state_RW = gpio_get(display.rw_pin);

	for (int i = 0; i < num_bits; i++){
		start_state_DB[i] = gpio_get(display.db_pins[i]);
	}

	//start checking the busy flag
	uint busy = 1;
	
	gpio_put(display.e_pin, 0);
	gpio_put(display.rs_pin, 0);
	gpio_put(display.rw_pin, 1);
	
	gpio_set_dir(display.db_pins[0], GPIO_IN);
	while (busy != 0) {

		sleep_us(1);
		gpio_put(display.e_pin, 1);
		sleep_us(1);
		busy = gpio_get(display.db_pins[0]);
		sleep_us(1);
		gpio_put(display.e_pin, 0);
		if (num_bits == 4) {
			sleep_us(1);
			gpio_put(display.e_pin, 1);
			sleep_us(1);
			gpio_put(display.e_pin, 0);
			sleep_us(1);
		}
	
	
	}
	// Set DB pins back to output
	gpio_set_dir(display.db_pins[0], GPIO_OUT);

	// Reset the pins to their orgional state
	gpio_put(display.rw_pin, start_state_RW);
	gpio_put(display.rs_pin, start_state_RS);
	for (int i = 0; i < num_bits; i++){
		gpio_put(display.db_pins[i], start_state_DB[i]);
	}
}

void lcd_jump_to_line_2(struct lcd_display display)
/* Simply jump the cursor to the start of line 2 ready to display a message there */
{
    	lcd_jump_to_pos(display, 40);
}

void lcd_jump_to_pos(struct lcd_display display, uint pos) 
/* jump the cursor to the positon in DDRAM as specified by pos */
{
	lcd_set_pins(display, 0,0, (0x80 + pos));
}

void lcd_set_cursor(struct lcd_display display, bool cursor)
/* set the cursor on (true) or off (false) */
{
//cursor = true --> cursor on
//cursor = false --> cursor off
	if (cursor)
		lcd_set_pins(display, 0, 0, 0x0e);
	else
		lcd_set_pins(display, 0, 0, 0x0c);
}

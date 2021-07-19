#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "pico/binary_info.h"
#include "./h_files/pico_LCD_display.h"

#define E_PIN 2
#define RS_PIN 11
#define RW_PIN 12
#define DB7_PIN 10
#define DB6_PIN 9
#define DB5_PIN 8
#define DB4_PIN 7
#define DB3_PIN 6
#define DB2_PIN 5
#define DB1_PIN 4
#define DB0_PIN 3

#define TX_PIN 16
#define CLK_PIN 17

#define TX_SPEED 5


void main() {

	const struct lcd_display display={RS_PIN, RW_PIN, E_PIN, {DB7_PIN, DB6_PIN, DB5_PIN, DB4_PIN, DB3_PIN, DB2_PIN, DB1_PIN, DB0_PIN}};

	const char *message = "Hello, World!";

	stdio_init_all();

	gpio_init(TX_PIN);
	gpio_init(CLK_PIN);
	gpio_set_dir(TX_PIN, GPIO_OUT);
	gpio_set_dir(CLK_PIN, GPIO_OUT);
	lcd_init_pins(display);
	lcd_init_display(display);
	lcd_display_msg(display, "Hello, World!");

	for (int byte_idx = 0; byte_idx < strlen(message); byte_idx++) {
		char tx_byte = message[byte_idx];
		lcd_jump_to_line_2(display);
		lcd_display_msg(display, "          ");
		lcd_jump_to_pos(display, byte_idx);
		for (int bit_idx = 0; bit_idx < 8; bit_idx++) {
			gpio_put(CLK_PIN, 0);
			sleep_ms(1000 / TX_SPEED / 2);
			int tx_bit = (tx_byte & (0x80 >> bit_idx));
			if (tx_bit) {
				gpio_put(TX_PIN, 1);
				lcd_jump_to_pos(display, 0x40 + bit_idx);
				lcd_display_msg(display, "1");
				lcd_jump_to_pos(display, byte_idx);
			} else {
				gpio_put(TX_PIN, 0);
				lcd_jump_to_pos(display, 0x40 + bit_idx);
				lcd_display_msg(display, "0");
				lcd_jump_to_pos(display, byte_idx);
			}
			gpio_put(CLK_PIN, 1);
			sleep_ms(1000 / TX_SPEED / 2);
		}
	}

	gpio_put(TX_PIN, 0);
	gpio_put(CLK_PIN, 0);

}

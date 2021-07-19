; Keyboard colours
; Green -- Clock -- 16
; White -- Data -- 26

PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR  = $600c
IFR  = $600d
IER  = $600e
     ;76543210
E  = %01000000
RW = %00100000
RS = %00010000

kb_buffer = $0300 ; 256 bytes for keyboard buffer ; 0000 - 00FF
		 ; stack 0100 - 01FF
keypress = $0200 ; 1 byte to store the number of irqs

kb_read   = $0201 ; 1 byte to point to the next place to read in the kbbuffer
kb_write  = $0202 ; 1 byte to point to the next place to write in the kbbuffer

kb_flag    = $0203 ; 1 byte for the keyboard register ;
		  ; 00000001 = release code recived
		  ; 00000010 = shift key down and not released
		  ; 00000100 = left ctrl
		  ; 00001000 = left alt
RELEASE = %00000001

mask_u = %00001111 ; mask out the upper nibble for the 4 bit commands to the LCD Screen

  .org $8000

reset:
  sei
  ldx #$ff ; reset the stack pointer to ff
  txs
  
  lda #$00
  tax 
  lda #$00
  sta kb_flag
  sta keypress
  sta kb_read
  sta kb_write
  sta kb_buffer, x

  lda #%11111111 ; Set  all the points on port B to output
  sta DDRB
  lda #%00000000 ; Set all the pins on port A to input
  sta DDRA
  lda #%10000010 ; enable CA1 as interrupt 
  sta IER
  lda #%00000001 ; Make CA1 positive active edge
  sta PCR

  jsr wait_long
  ; -----------------------------------------------------------------;
  ; initlising the LCD screen - wait neded ;
  
  lda #%00000011 ; Set 8-bit init; 
  sta PORTB
  ora #E
  sta PORTB ;first start up
  eor #E
  sta PORTB
 

  jsr wait_long ;can't check busy flag yet so need to wait
  
  lda #%00000011 ; Set 8-bit init; 
  sta PORTB
  ora #E
  sta PORTB ;first start up
  eor #E
  sta PORTB
  
  jsr wait_long
 
  lda #%00000011 ; Set 8-bit init; 
  sta PORTB
  ora #E
  sta PORTB ;first start up
  eor #E
  sta PORTB
  
  jsr wait_long
  
  lda #%00000010 ; Set 4-bit mode; 
  sta PORTB
  ora #E
  sta PORTB ;first start up
  eor #E
  sta PORTB

  ;---------------------------------------------------------------;
  ;end of screen initlising 

  ;setting up the display settings

  lda #%00101000 ; 4 bit; 2 line; 5x8 font
  jsr lcd_instruction
  
  lda #%00001000 ; Display off
  jsr lcd_instruction

  lda #%00000110 ;set mode
  jsr lcd_instruction

  lda #%00001100
  jsr lcd_instruction ; Display on; cursor on; blink off

  lda #%00000001
  jsr lcd_instruction ; Clear display
  
  cli
loop:  
  ; chexk kb buffer and print if needed
  sei
  lda kb_read
  cmp kb_write
  cli
  bne key_pressed

  jmp loop

key_pressed:
  ldx kb_read
  lda kb_buffer, x
  jsr print_char
  inc kb_read
  
  jmp loop
 

lcd_wait:
  pha
  lda #%01110000 ; Port B is input after first 3 bits E RS and RW
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB
  pha
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB
  lda #RW
  sta PORTB
  pla
  and #%00001000
  bne lcdbusy

  lda #RW
  sta PORTB
  lda #%11111111 ; Port B to output
  sta DDRB
  pla
  rts

lcd_instruction:
  pha
  jsr lcd_wait
  lsr ; move the instruction 4 bits down
  lsr
  lsr
  lsr
  and #mask_u ;mask out the upper part of the byte 
  sta PORTB
  ora #E
  sta PORTB
  and #mask_u
  sta PORTB
  pla
  and #mask_u ;mask out the upper part of the byte 
  sta PORTB
  ora #E
  sta PORTB
  and #mask_u
  sta PORTB
  rts

wait_long:
  pha
  txa
  pha
  lda #$FF
  tax
inner_loop:
  dex
  txa
  bne inner_loop
  pla
  tax
  pla
  rts

print_char:
  pha
  pha
  jsr lcd_wait
  lsr ; move the instruction 4 bits down
  lsr
  lsr
  lsr
  and #mask_u ;mask out the upper part of the byte 
  ora #RS
  sta PORTB
  ora #E 
  sta PORTB
  and #mask_u
  ora #RS
  sta PORTB
  pla
  and #mask_u ;mask out the upper part of the byte 
  ora #RS
  sta PORTB
  ora #E
  sta PORTB
  and #mask_u
  ora #RS
  sta PORTB
  pla
  rts

keyboard_irq:
  pha
  txa
  pha
  lda kb_flag
  and #RELEASE
  beq read_key
  lda kb_flag
  eor #RELEASE
  sta kb_flag
  lda PORTA
  jmp end_kb_irq
  
read_key:
  lda PORTA
  cmp #$F0
  beq toggle_release
  tax
  lda keymap, x
  ldx kb_write
  sta kb_buffer, x
  inc kb_write
  jmp end_kb_irq

toggle_release:
  lda kb_flag
  ora #RELEASE
  sta kb_flag
end_kb_irq:
  pla
  tax
  pla
  rts

nmi:
  rti
irq:
  jsr keyboard_irq
  rti

  .org $fe00
keymap:
  .byte "????????????? `?" ; 00-0F
  .byte "?????q1???zsaw2?" ; 10-1F
  .byte "?cxde43?? vftr5?" ; 20-2F
  .byte "?nbhgy6???mju78?" ; 30-3F
  .byte "?,kio09??./l;p-?" ; 40-4F
  .byte "??'?[=?????]?\??" ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568???+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; a0-aF
  .byte "????????????????" ; b0-bF
  .byte "????????????????" ; c0-cF
  .byte "????????????????" ; d0-dF
  .byte "????????????????" ; e0-eF
  .byte "????????????????" ; f0-fF

  ; shift --> 12 hex
  ; shift --> 59


  .org $fffa
  .word nmi
  .word reset
  .word irq

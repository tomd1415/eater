PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
     ;76543210
E  = %01000000
RW = %00100000
RS = %00010000

mask_u = %00001111 ; mask out the upper nibble for the 4 bit commands to the LCD Screen

  .org $8000

reset:
  ldx #$ff ; reset the stack pointer to ff
  txs

  lda #%11111111 ; Set  all the points on port B to output
  sta DDRB
  lda #%00000000 ; Set all the pins on port A to input
  sta DDRA

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

  lda #%00001110
  jsr lcd_instruction ; Display on; cursor on; blink off

  lda #%00000001
  jsr lcd_instruction ; Clear display
  
  ; end of setting up lcd screen settings

  ; printing message to the screen

  ldx #0
print:
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print
 

loop:
  jmp loop

message: .asciiz "Hello, world!"

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

nmi:
  rti

irq:
  rti
 
  .org $fffa
  .word nmi
  .word reset
  .word irq

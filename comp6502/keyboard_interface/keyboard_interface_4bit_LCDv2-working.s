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

value = $0200 ; 2 bytes for the number to be converted
mod10 = $0202 ; 2 bytes for the area to complete the calculations
message = $0204 ; 6 bytes to store the converted number in ASCII

keypress = $020a ; 1 byte to store the number of irqs

kbread   = $020b ; 1 byte to point to the next place to read in the kbbuffer
kbwrite  = $020c ; 1 byte to point to the next place to write in the kbbuffer
kbbuffer = $0300 ; 256 bytes for keyboard buffer

mask_u = %00001111 ; mask out the upper nibble for the 4 bit commands to the LCD Screen

  .org $8000

reset:
  sei
  ldx #$ff ; reset the stack pointer to ff
  txs
  
  lda #$00
  sta keypress
  sta kbread
  sta kbwrite

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
  
  ; end of setting up lcd screen settings
  cli
  ; converting the number to display
loop:  
  lda #0
  sta message

  lda #%00000010
  jsr lcd_instruction
  ; initialise the number to convert
  sei
  lda keypress
  sta value
  cli

print:
  lda keypress
  jsr print_char
 
  jmp loop

;message2: .asciiz "Hello, world!"
;number: .word 1729

push_char:
  pha
  ldy #0

char_loop:
  lda message,y
  tax
  pla
  sta message,y
  iny
  txa
  pha
  bne char_loop

  pla
  sta message,y

  rts

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
irq:
end_irq:
  pha
  lda PORTA
  sta keypress
  tax
  lda keymap, x
  sta keypress
  pla
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

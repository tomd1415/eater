PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
     ;76543210
E  = %01000000
RW = %00100000
RS = %00010000

  .org $8000

reset:
  ldx #$ff ; reset the stack pointer to ff
  txs

  lda #%11111111 ; Set  all the points on port B to output
  sta DDRB
  lda #%11111111 ; Set all the pins on port A to output
  sta DDRA

  lda #%00000000
  sta PORTA

  jsr wait_long
 
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
  
  lda #%00000010 ; 4 bit; 2 line; 5x8 font
  jsr lcd_instruction
  lda #%00001000
  jsr lcd_instruction2
  
  lda #%00000000 ; Display off
  jsr lcd_instruction
  lda #%00001000
  jsr lcd_instruction2

  lda #%00000000
  jsr lcd_instruction
  lda #%00000110 ; increment and shift cursor; don't shift display
  jsr lcd_instruction2

  lda #%00000000
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction2

  lda #%00000000
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction2
  
;write a letter
  jsr lcd_wait
  lda #%00010100
  sta PORTB
  ora #E
  sta PORTB
  eor #E
  sta PORTB
  lda #%00011000
  sta PORTB
  ora #E
  sta PORTB
  eor #E
  sta PORTB
  lda #%01010101
  sta PORTA


;  ldx #0
; print:
;  lda message,x
;  beq loop
;  jsr print_char
;  inx
;  jmp print
 
  lda #%00100001
  pha
loop:
  pla
  rol
  sta PORTA
  pha
  
  lda #$FF
  tax
loop2:  
  jsr wait_long
  dex
  txa
  bne loop2

  pla
  rol
  sta PORTA
  pha

  lda #$FF
  tax
loop3:  
  jsr wait_long
  dex
  txa
  bne loop3

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
  jsr lcd_wait
  ;jsr wait_long
  sta PORTB
  ora #E
  sta PORTB
  eor #E
  sta PORTB
  rts

lcd_instruction2:
  ;jsr lcd_wait
  ;jsr wait_long
  sta PORTB
  ora #E
  sta PORTB
  eor #E
  sta PORTB
  rts

wait_long:
  pha
  txa
  pha
;  tya
;  pha
;  lda #$00
;  tay
;outer_loop:
  lda #$FF
  tax
inner_loop:
;  lda #%00110000
;  sta PORTA
  dex
  txa
  bne inner_loop
 ; dey
 ; tya
 ; bne outer_loop
 ; pla
 ; tay
  pla
  tax
  pla
  rts

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS
  sta PORTA
  lda #(RS | E)
  sta PORTA
  lda #RS
  sta PORTA
  rts

 nmi:
  rti

 irq:
  rti
 
  .org $fffa
  .word nmi
  .word reset
  .word irq

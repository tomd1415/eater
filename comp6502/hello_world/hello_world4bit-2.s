PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E = %01000000
RW = %00100000
RS = %00010000

  .org $8000

reset:
  ldx #$ff ; reset the stack pointer to ff
  txs

  lda #%11111111 ; Set  all the points on port B to output
  sta DDRB
  lda #%00000000 ; Set the top 3 pins on port A to output
  sta DDRA

  lda #%00000010 ; Set 4-bit mode; 
  jsr lcd_instruction   ;2-line display; 5x8 font
  
  lda #%00000010 ; 4 bit 2 line
  jsr lcd_instruction
  lda #%00001100
  jsr lcd_instruction
  
  lda #%00000000
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction

  lda #%00000000
  jsr lcd_instruction
  lda #%00000110 ; increment and shift cursor; don't shift display
  jsr lcd_instruction

  lda #%00000000
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction

;  ldx #0
; print:
;  lda message,x
;  beq loop
;  jsr print_char
;  inx
;  jmp print
 
loop:
  jmp loop

message: .asciiz "Hello, world!"

lcd_wait:
  pha
  lda #%00000000 ; Port B is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  nop
  nop
  lda PORTB
  and #%10000000
  bne lcdbusy

  lda #RW
  sta PORTA
  lda #%11111111 ; Port B to output
  sta DDRB
  pla
  rts

lcd_instruction:
  jsr lcd_wait
  sta PORTB
  ora #E
  sta PORTB
  lda #0
  sta PORTB
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

  .org $fffc
  .word reset
  .word $0000

; ============================================================
; secondboot.asm - Stage 2 / Mini Kernel
; 功能: 在 console 顯示 "Hello OS"
; 編譯: nasm -f bin secondboot.asm -o secondboot.bin
; ============================================================

[BITS 16]           ; 仍在實模式
[ORG 0x8000]        ; 由 firstboot 載入到 0x8000

start:
    ; 初始化 segment registers
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; 清除螢幕 (BIOS INT 10h, AH=00h, AL=03h: 設為 80x25 文字模式)
    mov ax, 0x0003
    int 0x10

    ; 顯示 "Hello OS"
    mov si, msg_hello
    call print_string

    ; 顯示第二行提示
    mov si, msg_halt
    call print_string

    ; 停在這裡
.hang:
    hlt
    jmp .hang

; -----------------------------------------------
; 副程式: print_string
; 輸入: SI 指向以 0 結尾的字串
; -----------------------------------------------
print_string:
    mov ah, 0x0E        ; BIOS TTY 輸出
    mov bh, 0x00
    mov bl, 0x0A        ; 亮綠色文字
.loop:
    lodsb
    test al, al
    jz  .done
    int 0x10
    jmp .loop
.done:
    ret

; -----------------------------------------------
; 字串資料
; -----------------------------------------------
msg_hello   db 'Hello OS', 0x0D, 0x0A, 0
msg_halt    db 'Stage2 kernel loaded. System halted.', 0x0D, 0x0A, 0

; -----------------------------------------------
; 填充至 512 bytes (一個完整 sector)
; -----------------------------------------------
times 512 - ($ - $$) db 0

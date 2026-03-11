; ============================================================
; firstboot.asm - Stage 1 Bootloader
; 功能: 從磁碟載入第二個 sector (secondboot) 到記憶體並跳轉執行
; 編譯: nasm -f bin firstboot.asm -o firstboot.bin
; ============================================================

[BITS 16]           ; 實模式 16-bit
[ORG 0x7C00]        ; BIOS 把 bootloader 載入到 0x7C00

start:
    ; 初始化 segment registers
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  ; stack 在 bootloader 下方
    sti

    ; 顯示載入訊息
    mov si, msg_loading
    call print_string

    ; -----------------------------------------------
    ; 使用 BIOS INT 13h 讀取第二個 sector
    ; AH = 02h  : 讀取磁區功能
    ; AL = 1    : 讀取 1 個 sector
    ; CH = 0    : Cylinder 0
    ; CL = 2    : Sector 2 (第二個 sector，從 1 開始計數)
    ; DH = 0    : Head 0
    ; DL = 0x80 : 第一顆硬碟 (若用軟碟改成 0x00)
    ; ES:BX     : 資料存放的目標位址 0x0000:0x8000
    ; -----------------------------------------------
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x8000  ; 載入到記憶體 0x8000

    mov ah, 0x02    ; BIOS read sectors
    mov al, 1       ; 讀 1 個 sector
    mov ch, 0       ; cylinder 0
    mov cl, 2       ; sector 2
    mov dh, 0       ; head 0
    mov dl, 0x80    ; 第一顆硬碟

    int 0x13        ; 呼叫 BIOS 磁碟中斷
    jc  disk_error  ; 若 Carry Flag = 1 表示錯誤

    ; 載入成功，跳轉到 secondboot
    mov si, msg_ok
    call print_string

    jmp 0x0000:0x8000   ; 跳到第二段 bootloader

; -----------------------------------------------
; 磁碟錯誤處理
; -----------------------------------------------
disk_error:
    mov si, msg_error
    call print_string
    hlt

; -----------------------------------------------
; 副程式: print_string
; 輸入: SI 指向以 0 結尾的字串
; -----------------------------------------------
print_string:
    mov ah, 0x0E        ; BIOS TTY 輸出模式
    mov bh, 0x00        ; 頁碼 0
    mov bl, 0x07        ; 灰色文字
.loop:
    lodsb               ; AL = [SI], SI++
    test al, al         ; 是否為 0 (結尾)?
    jz  .done
    int 0x10            ; BIOS 顯示字元
    jmp .loop
.done:
    ret

; -----------------------------------------------
; 字串資料
; -----------------------------------------------
msg_loading db 'Stage1: Loading second sector...', 0x0D, 0x0A, 0
msg_ok      db 'Stage1: OK! Jumping to Stage2.', 0x0D, 0x0A, 0
msg_error   db 'Stage1: Disk read ERROR!', 0x0D, 0x0A, 0

; -----------------------------------------------
; 填充至 510 bytes，加上 Boot Signature
; -----------------------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55               ; Boot signature

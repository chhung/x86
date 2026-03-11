# Bootloader 實驗 - 兩階段開機流程

## 檔案結構

```
.
├── firstboot.asm    # Stage 1: Bootloader (sector 1)
├── secondboot.asm   # Stage 2: Mini Kernel (sector 2)
├── build.sh         # 一鍵編譯 + 建立磁碟 + 啟動 Bochs
├── bochsrc.txt      # Bochs 模擬器設定
└── README.md        # 本說明文件
```

---

## 運作流程

```
開機
 │
 ▼
BIOS 讀取 sector 1 (0x7C00)
 │
 ▼
firstboot.bin 執行
 ├─ 顯示 "Stage1: Loading second sector..."
 ├─ INT 13h 讀取 sector 2 到記憶體 0x8000
 └─ jmp 0x8000
         │
         ▼
     secondboot.bin 執行
      ├─ 清除螢幕
      ├─ 顯示 "Hello OS"
      └─ hlt (停止)
```

---

## 安裝需求

```bash
# Ubuntu / Debian
sudo apt update
sudo apt install nasm bochs bochs-x

# macOS (Homebrew)
brew install nasm bochs
```

---

## 執行步驟

### 方法一: 使用 build.sh (一鍵執行)

```bash
chmod +x build.sh
./build.sh
```

### 方法二: 手動執行

```bash
# 1. 編譯
nasm -f bin firstboot.asm  -o firstboot.bin
nasm -f bin secondboot.asm -o secondboot.bin

# 2. 建立 32MB 磁碟映像
dd if=/dev/zero of=disk.img bs=512 count=65536

# 3. 寫入 bootloader 到 sector 1
dd if=firstboot.bin  of=disk.img bs=512 count=1 seek=0 conv=notrunc

# 4. 寫入 kernel 到 sector 2
dd if=secondboot.bin of=disk.img bs=512 count=1 seek=1 conv=notrunc

# 5. 驗證 Boot Signature
xxd -s 510 -l 2 disk.img
# 應顯示: 55 aa

# 6. 啟動 Bochs
bochs -f bochsrc.txt -q
```

---

## 預期輸出

Bochs 視窗中應顯示:

```
Stage1: Loading second sector...
Stage1: OK! Jumping to Stage2.
Hello OS
Stage2 kernel loaded. System halted.
```

---

## 記憶體配置說明

| 位址     | 用途                        |
|----------|-----------------------------|
| `0x7C00` | firstboot.bin (Stage 1)     |
| `0x8000` | secondboot.bin (Stage 2)    |
| `0x7C00` | Stack (向下增長)            |

---

## BIOS INT 13h 說明

| 暫存器 | 值      | 說明                      |
|--------|---------|---------------------------|
| AH     | `0x02`  | 功能: 讀取磁區            |
| AL     | `1`     | 讀取 1 個 sector          |
| CH     | `0`     | Cylinder 0                |
| CL     | `2`     | **Sector 2** (從 1 開始)  |
| DH     | `0`     | Head 0                    |
| DL     | `0x80`  | 第一顆硬碟                |
| ES:BX  | `0:0x8000` | 目標記憶體位址         |

---

## 常見問題

**Q: Bochs 找不到 BIOS 檔案?**  
A: 確認 `$BXSHARE` 環境變數，通常為 `/usr/share/bochs`。可修改 bochsrc.txt:
```
romimage: file=/usr/share/bochs/BIOS-bochs-latest
```

**Q: 想用 QEMU 替代 Bochs?**
```bash
qemu-system-i386 -drive format=raw,file=disk.img
```

**Q: 如何在真實硬體測試? (USB 隨身碟)**
```bash
# 危險! 確認 /dev/sdX 是你的 USB，不是系統硬碟
sudo dd if=disk.img of=/dev/sdX bs=512 count=2 conv=notrunc
```

#!/bin/bash
# ============================================================
# build.sh - 編譯、建立磁碟映像、啟動 Bochs
# ============================================================

set -e  # 任何錯誤即停止

echo "=============================="
echo " 步驟 1: 編譯 ASM 檔案"
echo "=============================="

nasm -f bin firstboot.asm  -o firstboot.bin
echo "[OK] firstboot.bin  ($(wc -c < firstboot.bin) bytes)"

nasm -f bin secondboot.asm -o secondboot.bin
echo "[OK] secondboot.bin ($(wc -c < secondboot.bin) bytes)"

echo ""
echo "=============================="
echo " 步驟 2: 建立 32MB 磁碟映像"
echo "=============================="

# 建立 32MB 的空白磁碟 (32 * 1024 * 1024 / 512 = 65536 個 sector)
dd if=/dev/zero of=disk.img bs=512 count=65536 status=none
echo "[OK] disk.img 建立完成 (32MB)"

echo ""
echo "=============================="
echo " 步驟 3: 寫入 Boot Sectors"
echo "=============================="

# 把 firstboot.bin 寫到第 1 個 sector (offset 0)
dd if=firstboot.bin  of=disk.img bs=512 count=1 seek=0 conv=notrunc status=none
echo "[OK] firstboot.bin  -> sector 1 (offset 0)"

# 把 secondboot.bin 寫到第 2 個 sector (offset 512)
dd if=secondboot.bin of=disk.img bs=512 count=1 seek=1 conv=notrunc status=none
echo "[OK] secondboot.bin -> sector 2 (offset 512)"

echo ""
echo "=============================="
echo " 步驟 4: 驗證磁碟映像"
echo "=============================="

# 檢查 Boot Signature (最後兩個 byte 應為 55 AA)
BOOT_SIG=$(xxd -s 510 -l 2 disk.img | awk '{print $2$3}')
echo "Boot Signature (offset 510-511): $BOOT_SIG"
if [[ "$BOOT_SIG" == *"55aa"* ]]; then
    echo "[OK] Boot Signature 正確 (55 AA)"
else
    echo "[WARN] Boot Signature 可能有誤，請檢查"
fi

echo ""
echo "=============================="
echo " 步驟 5: 啟動 Bochs"
echo "=============================="
bochs -f bochsrc.txt -q

echo ""
echo "[完成]"

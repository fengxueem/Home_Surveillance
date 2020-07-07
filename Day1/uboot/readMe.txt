please do this first
mtd -r write /tmp/TP-LINK-uboot-writable.bin  firmware
then write the uboot
mtd -r write /tmp/TP-LINK-updated-uboot.bin u-boot
For more details: please read http://www.geektalks.org/best-u-boot-mod-for-tp-link-703n/

Note that this can only be applied to tp-link-703n

cmd_/home/buildbot/slave-local/ar71xx_generic/build/build_dir/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/linux-dev//include/linux/hsi/.install := bash scripts/headers_install.sh /home/buildbot/slave-local/ar71xx_generic/build/build_dir/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/linux-dev//include/linux/hsi ./include/uapi/linux/hsi hsi_char.h; bash scripts/headers_install.sh /home/buildbot/slave-local/ar71xx_generic/build/build_dir/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/linux-dev//include/linux/hsi ./include/linux/hsi ; bash scripts/headers_install.sh /home/buildbot/slave-local/ar71xx_generic/build/build_dir/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/linux-dev//include/linux/hsi ./include/generated/uapi/linux/hsi ; for F in ; do echo "\#include <asm-generic/$$F>" > /home/buildbot/slave-local/ar71xx_generic/build/build_dir/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/linux-dev//include/linux/hsi/$$F; done; touch /home/buildbot/slave-local/ar71xx_generic/build/build_dir/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/linux-dev//include/linux/hsi/.install

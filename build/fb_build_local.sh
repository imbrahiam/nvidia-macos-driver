#!/bin/bash
# Build NVRMFB.kext (x86_64) from the repo source. Usage: fb_build.sh <repo> <out>
set -uo pipefail
SRC=$1/kexts; OUT=$2; mkdir -p "$OUT/NVRMFB.kext/Contents/MacOS"
OGKM=${OGKM:-$HOME/nvidia-macos-driver-deps/open-gpu-kernel-modules-610.57.04}
SDK=$(xcrun --show-sdk-path); KHDR="$SDK/System/Library/Frameworks/Kernel.framework/Headers"; KMS="$OGKM/src/nvidia-modeset"
INC=( -I"$KMS/os-interface/include" -I"$KMS/kapi/interface" -I"$KMS/kapi/include" -I"$KMS/interface" -I"$KMS/include"
      -I"$OGKM/src/common/sdk/nvidia/inc" -I"$OGKM/src/common/inc" -I"$OGKM/src/common/unix/common/inc" -I"$OGKM/src/common/modeset"
      -I"$OGKM/src/common/unix/common/utils/interface" -I"$OGKM/src/common/unix/nvidia-push/interface" -I"$OGKM/src/common/shared/inc" -I"$OGKM/src/nvidia/arch/nvalloc/unix/include" -I"$OGKM/src/nvidia/arch/nvalloc/common/inc" )
DEFS=( -DNVCPU_X86_64 -DNV_KERNEL_INTERFACE_LAYER -DNVRM -D__x86_64__=1 ${FBDEFS:-} )
CFLAGS=( -arch x86_64 -fapple-kext -mkernel -nostdinc -I"$KHDR" -I"$SRC/NVRMFB" -I"$SRC/NVRMFB/fb" "${INC[@]}"
  -DKERNEL -DKERNEL_PRIVATE -DDRIVER_PRIVATE -DAPPLE -DNeXT "${DEFS[@]}"
  -std=c++17 -fno-rtti -fno-exceptions -fno-builtin -fno-common
  -Wall -Wno-unused-parameter -Wno-inconsistent-missing-override -Wno-unused-function -O2 )
xcrun clang++ "${CFLAGS[@]}" -c "$SRC/NVRMFB/fb/nvrm-fb.cpp" -o "$OUT/nvrm-fb.o" 2>"$OUT/fb.err" || { grep -E "error" "$OUT/fb.err" | head -20; exit 1; }
xcrun clang++ -arch x86_64 -fapple-kext -nostdlib -Xlinker -kext -lkmodc++ -lkmod -lcc_kext "$OUT/nvrm-fb.o" -o "$OUT/NVRMFB.kext/Contents/MacOS/NVRMFB" 2>"$OUT/fbld.err" || { head "$OUT/fbld.err"; exit 1; }
cp "$SRC/NVRMFB/fb/Info.plist" "$OUT/NVRMFB.kext/Contents/Info.plist"
echo "NVRMFB $(md5 -q "$OUT/NVRMFB.kext/Contents/MacOS/NVRMFB") $(stat -f %z "$OUT/NVRMFB.kext/Contents/MacOS/NVRMFB") B"

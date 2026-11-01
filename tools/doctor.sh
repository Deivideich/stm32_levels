#!/usr/bin/env bash
# Check the tools you need up to a given level.
#     tools/doctor.sh        # level 1 (default)
#     tools/doctor.sh 3      # levels 1-3 (adds the ARM toolchain)
lvl="${1:-1}"; miss=0
need() { if command -v "$1" >/dev/null 2>&1; then printf '  ok        %s\n' "$1"
         else printf '  MISSING   %-22s %s\n' "$1" "${2:-}"; miss=1; fi; }
opt()  { if command -v "$1" >/dev/null 2>&1; then printf '  ok        %s\n' "$1"
         else printf '  optional  %-22s %s\n' "$1" "${2:-}"; fi; }

echo "Tools up to level $lvl"
need gcc "host compiler"
need make
need git
need nm "binutils"
need objdump "binutils"
opt  clang "used in Level 14 to compare against gcc"
opt  cppcheck "Level 2 (CI)"
if [ "$lvl" -ge 3 ]; then
  need arm-none-eabi-gcc "ARM toolchain (pin the version in the README)"
  need arm-none-eabi-objcopy
  need arm-none-eabi-size
  need openocd "flash and debug"
  if command -v gdb-multiarch >/dev/null 2>&1 || command -v arm-none-eabi-gdb >/dev/null 2>&1; then
    echo "  ok        gdb"
  else
    echo "  MISSING   gdb-multiarch or arm-none-eabi-gdb"; miss=1
  fi
fi
command -v gcc >/dev/null 2>&1 && echo "gcc: $(gcc --version | head -1)"
exit $miss

DEBUG = 0
FRONTEND_SUPPORTS_RGB565 = 1

CORE_DIR := .

ifeq ($(platform),)
platform = unix
ifeq ($(shell uname -a),)
   platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   platform = osx
   arch = intel
ifeq ($(shell uname -p),powerpc)
   arch = ppc
endif
    ifeq ($(shell uname -p),arm)
        arch = arm
    endif
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   platform = win
endif
endif

core = snes
NEED_BPP = 32
NEED_BLIP = 1
NEED_STEREO_SOUND = 1
CORE_DEFINE := -DWANT_SNES_EMU

TARGET_NAME := mednafen_snes
GIT_VERSION := $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
ifneq ($(GIT_VERSION),unknown)
    EXTRA_CXXFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\"
endif

ifeq ($(platform), unix)
    TARGET := $(TARGET_NAME)_libretro.so
    fpic := -fPIC
    SHARED := -shared -Wl,--no-undefined -Wl,--version-script=link.T
    ifneq ($(shell uname -p | grep -E '((i.|x)86|amd64)'),)
      IS_X86 = 1
    endif
    ifneq ($(findstring Haiku,$(shell uname -s)),)
    LDFLAGS += -lroot
    else
    LDFLAGS += -ldl
    endif

else ifeq ($(platform), classic_armv7_a7)
    TARGET := $(TARGET_NAME)_libretro.so
    fpic := -fPIC
    SHARED := -shared -Wl,--no-undefined -Wl,--version-script=link.T
    CFLAGS += -Ofast \
    -flto=4 -fwhole-program -fuse-linker-plugin \
    -fdata-sections -ffunction-sections -Wl,--gc-sections \
    -fno-stack-protector -fno-ident -fomit-frame-pointer \
    -falign-functions=1 -falign-jumps=1 -falign-loops=1 \
    -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-unroll-loops \
    -fmerge-all-constants -fno-math-errno \
    -marm -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
    CXXFLAGS += $(CFLAGS)
    HAVE_NEON = 1
    ARCH = arm
    LDFLAGS += -ldl

else ifeq ($(platform), classic_armv8_a35)
    TARGET := $(TARGET_NAME)_libretro.so
    fpic := -fPIC
    SHARED := -shared -Wl,--no-undefined -Wl,--version-script=link.T
    CFLAGS += -Ofast \
    -flto=4 -fwhole-program -fuse-linker-plugin \
    -fdata-sections -ffunction-sections -Wl,--gc-sections \
    -fno-stack-protector -fno-ident -fomit-frame-pointer \
    -falign-functions=1 -falign-jumps=1 -falign-loops=1 \
    -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-unroll-loops \
    -fmerge-all-constants -fno-math-errno \
    -marm -mtune=cortex-a35 -mfpu=neon-fp-armv8 -mfloat-abi=hard
    CXXFLAGS += $(CFLAGS)
    HAVE_NEON = 1
    ARCH = arm
    LDFLAGS += -ldl
    CFLAGS += -march=armv8-a
    LDFLAGS += -static-libgcc -static-libstdc++

else ifeq ($(platform), osx)
   TARGET := $(TARGET_NAME)_libretro.dylib
   fpic := -fPIC
   SHARED := -dynamiclib

else ifneq (,$(findstring ios,$(platform)))
   TARGET := $(TARGET_NAME)_libretro_ios.dylib
   fpic := -fPIC -DHAVE_POSIX_MEMALIGN=1
   SHARED := -dynamiclib
   CFLAGS += -DIOS

else ifeq ($(platform), tvos-arm64)
   EXT?=dylib
   TARGET := $(TARGET_NAME)_libretro_tvos.$(EXT)
   fpic := -fPIC -DHAVE_POSIX_MEMALIGN=1
   SHARED := -dynamiclib

# PS2
else ifeq ($(platform), ps2)
    TARGET := $(TARGET_NAME)_libretro_$(platform).a
    CC = mips64r5900el-ps2-elf-gcc
    CXX = mips64r5900el-ps2-elf-g++
    AR = mips64r5900el-ps2-elf-ar
    CFLAGS += -Os -march=r5900 -mtune=r5900 -G0 -ffast-math -fomit-frame-pointer -DPS2 -DABGR1555 -fno-expensive-optimizations -fcommon -Wno-error=overloaded-virtual
    CXXFLAGS += -Os -march=r5900 -mtune=r5900 -G0 -ffast-math -fomit-frame-pointer -DPS2 -DABGR1555 -fno-expensive-optimizations -fcommon -Wno-error=overloaded-virtual
    LDFLAGS += -Wl,--allow-multiple-definition
    STATIC_LINKING = 1
    STATIC_LINKING_LINK = 1
    PLATFORM_DEFINES := -DPS2 -DVIDEO_ABGR1555 -DIOAPI_NO_64
    FRONTEND_SUPPORTS_RGB565 = 0

else
   TARGET := $(TARGET_NAME)_libretro.dll
   CC ?= gcc
   CXX ?= g++
   IS_X86 = 1
   SHARED := -shared -Wl,--no-undefined -Wl,--version-script=link.T
   LDFLAGS += -static-libgcc -static-libstdc++ -lwinmm
endif

include Makefile.common

# Hard-lock compiler variables for PS2 to prevent any pollution from Makefile.common
ifeq ($(platform), ps2)
    CC  := mips64r5900el-ps2-elf-gcc
    CXX := mips64r5900el-ps2-elf-g++
    AR  := mips64r5900el-ps2-elf-ar
endif

WARNINGS := -Wall \
    -Wno-sign-compare \
    -Wno-unused-variable \
    -Wno-unused-function \
    -Wno-uninitialized \
    -Wno-error=overloaded-virtual

OBJECTS := $(SOURCES_CXX:.cpp=.o) $(SOURCES_C:.c=.o)

all: $(TARGET)

ifeq ($(DEBUG),0)
   FLAGS += -O2 -DNDEBUG
else
   FLAGS += -O0 -g -DDEBUG
endif

LDFLAGS += $(fpic) $(SHARED)
FLAGS += $(fpic) $(NEW_GCC_FLAGS) $(INCFLAGS)

FLAGS += $(ENDIANNESS_DEFINES) -DSIZEOF_DOUBLE=8 $(WARNINGS) -DMEDNAFEN_VERSION=\"0.9.31\" -DPACKAGE=\"mednafen\" -DMEDNAFEN_VERSION_NUMERIC=931 -DPSS_STYLE=1 -DMPC_FIXED_POINT $(CORE_DEFINE) -DSTDC_HEADERS -D__STDC_LIMIT_MACROS -D__LIBRETRO__ -D_LOW_ACCURACY_ $(EXTRA_INCLUDES) $(SOUND_DEFINE) $(PLATFORM_DEFINES)

CXXFLAGS += $(FLAGS) $(EXTRA_CXXFLAGS)
CFLAGS   += $(FLAGS)

$(TARGET): $(OBJECTS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else
	$(CXX) -o $@ $^ $(LDFLAGS)
endif

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(TARGET) $(OBJECTS)

.PHONY: clean
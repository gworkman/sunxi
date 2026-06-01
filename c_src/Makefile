# c_src/Makefile
SUNXI_TOOLS_DIR = sunxi-tools

# MIX_APP_PATH is provided by elixir_make
PREFIX = $(MIX_APP_PATH)/priv

# Dependencies to check via pkg-config
DEPENDENCIES = libusb-1.0 zlib

# libfdt detection
# 1. allow user-provided overrides
# 2. Try pkg-config
# 3. Try Homebrew on macOS (host only)
# 4. Fallback to common locations (host only)

# Default to host if not provided
MIX_TARGET ?= host

# Initialize variables if not already set by environment
LIBFDT_CFLAGS ?=
LIBFDT_LIBS ?=

# Detect OS
UNAME_S := $(shell uname -s)

# Try pkg-config if not overridden
ifeq ($(LIBFDT_CFLAGS),)
	ifeq ($(shell pkg-config --exists libfdt && echo yes),yes)
		LIBFDT_CFLAGS = $(shell pkg-config --cflags libfdt)
		LIBFDT_LIBS = $(shell pkg-config --libs libfdt)
	endif
endif

# If we are building for the host, attempt fallback discovery
ifeq ($(MIX_TARGET),host)
	# Try Homebrew on macOS if still not found
	ifeq ($(LIBFDT_CFLAGS),)
		ifeq ($(UNAME_S),Darwin)
			BREW_PREFIX := $(shell brew --prefix dtc 2>/dev/null)
			ifneq ($(BREW_PREFIX),)
				LIBFDT_CFLAGS = -I$(BREW_PREFIX)/include
				LIBFDT_LIBS = -L$(BREW_PREFIX)/lib -lfdt
			endif
		endif
	endif

	# Final fallbacks for host
	ifeq ($(LIBFDT_CFLAGS),)
		ifeq ($(UNAME_S),Darwin)
			# Default to Intel Homebrew path as a last resort on macOS
			DTC_PREFIX ?= /usr/local/opt/dtc
			LIBFDT_CFLAGS ?= -I$(DTC_PREFIX)/include
			LIBFDT_LIBS ?= -L$(DTC_PREFIX)/lib -lfdt
		else
			# On Linux, assume it's in standard paths
			LIBFDT_CFLAGS ?=
			LIBFDT_LIBS ?= -lfdt
		endif
	endif

	# Check function to verify libfdt.h existence on host
	ifeq ($(UNAME_S),Darwin)
	    CHECK_LIBFDT = (ls $(DTC_PREFIX)/include/libfdt.h > /dev/null 2>&1 || (echo "Error: libfdt.h not found. Please install 'dtc' (brew install dtc)"; exit 1))
	else
	    CHECK_LIBFDT = (ls /usr/include/libfdt.h > /dev/null 2>&1 || ls /usr/local/include/libfdt.h > /dev/null 2>&1) || (echo "Error: libfdt.h not found. Please install 'libfdt-dev' (sudo apt-get install libfdt-dev)"; exit 1)
	endif
else
	# Cross-compiling: if pkg-config failed, provide a generic fallback for cross-toolchain
	ifeq ($(LIBFDT_CFLAGS),)
		LIBFDT_CFLAGS ?=
		LIBFDT_LIBS ?= -lfdt
	endif
	CHECK_LIBFDT = true
endif

.PHONY: all clean check_deps install

all: install

install: check_deps $(PREFIX)/bin/sunxi-fel

check_deps:
	@for dep in $(DEPENDENCIES); do \
		pkg-config --exists $$dep || (echo "Error: $$dep not found. Please install the development version of $$dep."; exit 1); \
	done
	@# Only run CHECK_LIBFDT if we aren't using pkg-config or brew (which we've already checked)
	@if [ "$(BREW_PREFIX)" = "" ]; then $(CHECK_LIBFDT); fi

$(PREFIX)/bin/sunxi-fel: $(SUNXI_TOOLS_DIR)/Makefile
	mkdir -p $(PREFIX)/bin
	# Inject detected flags into the sub-make via CFLAGS and LIBS
	$(MAKE) -C $(SUNXI_TOOLS_DIR) CFLAGS+="$(LIBFDT_CFLAGS)" LIBS+="$(LIBFDT_LIBS)"
	cp $(SUNXI_TOOLS_DIR)/sunxi-fel $(PREFIX)/bin/

clean:
	$(MAKE) -C $(SUNXI_TOOLS_DIR) clean
	rm -rf $(PREFIX)/bin/sunxi-fel

# c_src/Makefile
SUNXI_TOOLS_DIR = sunxi-tools

# MIX_APP_PATH is provided by elixir_make
PREFIX = $(MIX_APP_PATH)/priv
OBJDIR = $(MIX_APP_PATH)/obj
BUILD_DIR = $(OBJDIR)/sunxi-tools

# Dependencies to check via pkg-config
DEPENDENCIES = libusb-1.0 zlib

# libfdt detection
# 1. Allow user-provided overrides (LIBFDT_CFLAGS/LIBFDT_LIBS, or DTC_PREFIX)
# 2. Try pkg-config
# 3. Try Homebrew on macOS (host only, Apple Silicon or Intel)
# 4. Fall back to default compiler search paths

# Default to host if not provided
MIX_TARGET ?= host

# Detect OS
UNAME_S := $(shell uname -s)

# DTC_PREFIX is a shorthand for pointing at a dtc install directly
ifneq ($(DTC_PREFIX),)
	LIBFDT_CFLAGS ?= -I$(DTC_PREFIX)/include
	LIBFDT_LIBS ?= -L$(DTC_PREFIX)/lib -lfdt
endif

# Try pkg-config if not overridden
ifeq ($(LIBFDT_LIBS),)
	ifeq ($(shell pkg-config --exists libfdt && echo yes),yes)
		LIBFDT_CFLAGS := $(shell pkg-config --cflags libfdt)
		LIBFDT_LIBS := $(shell pkg-config --libs libfdt)
	endif
endif

ifeq ($(MIX_TARGET),host)
	# Try Homebrew on macOS if still not found. `brew` may not be on the PATH
	# (e.g. when compiling from an editor), so also check the default prefixes.
	ifeq ($(LIBFDT_LIBS),)
		ifeq ($(UNAME_S),Darwin)
			BREW_DTC := $(firstword $(patsubst %/include/libfdt.h,%,$(wildcard \
				$(shell brew --prefix dtc 2>/dev/null)/include/libfdt.h \
				/opt/homebrew/opt/dtc/include/libfdt.h \
				/usr/local/opt/dtc/include/libfdt.h)))
			ifneq ($(BREW_DTC),)
				LIBFDT_CFLAGS := -I$(BREW_DTC)/include
				LIBFDT_LIBS := -L$(BREW_DTC)/lib -lfdt
			endif
		endif
	endif

	ifeq ($(UNAME_S),Darwin)
		LIBFDT_INSTALL_HINT = 'dtc' (brew install dtc)
	else
		LIBFDT_INSTALL_HINT = 'libfdt-dev' (sudo apt-get install libfdt-dev)
	endif

	# Verify that libfdt.h is reachable with the flags we ended up with
	CHECK_LIBFDT = echo '\#include <libfdt.h>' | $(CC) $(LIBFDT_CFLAGS) -E -x c - > /dev/null 2>&1 || \
		(echo "Error: libfdt.h not found. Please install $(LIBFDT_INSTALL_HINT), or set DTC_PREFIX to its install location."; exit 1)
else
	CHECK_LIBFDT = true
endif

# Otherwise assume libfdt is in the compiler's default search paths
ifeq ($(LIBFDT_LIBS),)
	LIBFDT_LIBS := -lfdt
endif

.PHONY: all clean check_deps install

all: install

install: check_deps $(PREFIX)/bin/sunxi-fel

check_deps:
	@for dep in $(DEPENDENCIES); do \
		pkg-config --exists $$dep || (echo "Error: $$dep not found. Please install the development version of $$dep."; exit 1); \
	done
	@$(CHECK_LIBFDT)

$(PREFIX)/bin/sunxi-fel: $(SUNXI_TOOLS_DIR)/Makefile
	mkdir -p $(PREFIX)/bin
	mkdir -p $(OBJDIR)
	rm -rf $(BUILD_DIR)
	cp -R $(SUNXI_TOOLS_DIR) $(BUILD_DIR)
	$(MAKE) -C $(BUILD_DIR) clean
	$(MAKE) -C $(BUILD_DIR) CFLAGS+="$(LIBFDT_CFLAGS)" LIBS+="$(LIBFDT_LIBS)" sunxi-fel
	cp $(BUILD_DIR)/sunxi-fel $(PREFIX)/bin/

clean:
	rm -rf $(PREFIX)/bin/sunxi-fel $(OBJDIR)

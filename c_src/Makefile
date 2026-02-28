# c_src/Makefile
SUNXI_TOOLS_DIR = sunxi-tools

# MIX_APP_PATH is provided by elixir_make
PREFIX = $(MIX_APP_PATH)/priv

# Dependencies to check via pkg-config
DEPENDENCIES = libusb-1.0 zlib

# macOS specific: dtc (which provides libfdt) is often not in pkg-config
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    DTC_PREFIX ?= /usr/local/opt/dtc
    LIBFDT_CFLAGS ?= -I$(DTC_PREFIX)/include
    LIBFDT_LIBS ?= -L$(DTC_PREFIX)/lib -lfdt
    CHECK_LIBFDT = ls $(DTC_PREFIX)/include/libfdt.h > /dev/null 2>&1 || (echo "Error: libfdt.h not found. Please install 'dtc' (brew install dtc)"; exit 1)
else
    # On Linux, we expect libfdt to be in pkg-config or standard paths
    DEPENDENCIES += libfdt
    CHECK_LIBFDT = true
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
	$(MAKE) -C $(SUNXI_TOOLS_DIR) LIBFDT_CFLAGS="$(LIBFDT_CFLAGS)" LIBFDT_LIBS="$(LIBFDT_LIBS)"
	cp $(SUNXI_TOOLS_DIR)/sunxi-fel $(PREFIX)/bin/

clean:
	$(MAKE) -C $(SUNXI_TOOLS_DIR) clean
	rm -rf $(PREFIX)/bin/sunxi-fel

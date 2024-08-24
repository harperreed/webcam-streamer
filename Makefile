# Variables
SWIFT = swift
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
DEBUG_DIR = $(BUILD_DIR)/debug
PRODUCT_NAME = WebcamStreamer

# Targets and rules
.PHONY: all clean build run release debug

all: build

build:
	$(SWIFT) build

run: build
	$(SWIFT) run

release:
	$(SWIFT) build -c release
	@echo "Release binary is at $(RELEASE_DIR)/$(PRODUCT_NAME)"

debug:
	$(SWIFT) build -c debug
	@echo "Debug binary is at $(DEBUG_DIR)/$(PRODUCT_NAME)"

clean:
	rm -rf $(BUILD_DIR)

# Install the release binary to /usr/local/bin
install: release
	cp $(RELEASE_DIR)/$(PRODUCT_NAME) /usr/local/bin/$(PRODUCT_NAME)
	@echo "Installed $(PRODUCT_NAME) to /usr/local/bin"

# Uninstall the binary from /usr/local/bin
uninstall:
	rm -f /usr/local/bin/$(PRODUCT_NAME)
	@echo "Uninstalled $(PRODUCT_NAME) from /usr/local/bin"

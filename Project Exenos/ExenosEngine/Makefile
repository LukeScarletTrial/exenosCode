CC = clang
CFLAGS = -O3 -arch arm64 -fPIC -std=c11 \
         -I$(SRC_DIR) \
         -I../ExenosBridge/include \
         -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) \
         -mios-version-min=15.0 \
         -fmodules -fcxx-modules

LDFLAGS = -dynamiclib \
          -arch arm64 \
          -framework Metal \
          -framework QuartzCore \
          -framework UIKit \
          -framework Foundation \
          -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) \
          -mios-version-min=15.0

SRC_DIR = src
BUILD_DIR = build

SOURCES = $(SRC_DIR)/luaz_core.c \
          $(SRC_DIR)/luaz_reload.c \
          $(SRC_DIR)/luaz_metal.m \
          ../ExenosBridge/src/exenos_bridge.c

OBJECTS = $(patsubst %.c,$(BUILD_DIR)/%.o,$(patsubst %.m,$(BUILD_DIR)/%.o,$(notdir $(SOURCES))))

TARGET = $(BUILD_DIR)/libexenos.dylib

.PHONY: all clean

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.m
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/exenos_bridge.o: ../ExenosBridge/src/exenos_bridge.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^
	codesign -s "-" $@

clean:
	rm -rf $(BUILD_DIR)

install: $(TARGET)
	cp $(TARGET) ../ExenosIDE/libs/

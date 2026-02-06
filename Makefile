#  Part of Grbl
#
#  Copyright (c) 2009-2011 Simen Svale Skogsrud
#  Copyright (c) 2012-2016 Sungeun K. Jeon for Gnea Research LLC
#
#  Grbl is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  Grbl is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Grbl.  If not, see <http://www.gnu.org/licenses/>.


# Makefile for GRBL CoreXY -- Newmatik Fork
#
# DEVICE ....... The AVR device you compile for
# CLOCK ........ Target AVR clock rate in Hertz
# PROGRAMMER ... Options to avrdude for the Arduino Uno USB bootloader
# AVR_TOOLCHAIN  Path to the AVR GCC toolchain bin/ directory.
#                GRBL requires avr-gcc <= 7.x to fit in the ATmega328P 32KB flash.
#                The Arduino IDE ships avr-gcc 7.3.0 which works perfectly.
#                Override with: make AVR_TOOLCHAIN=/path/to/bin

# Auto-detect Arduino IDE toolchain on macOS; fall back to system PATH
ARDUINO_AVR_GCC := $(wildcard $(HOME)/Library/Arduino15/packages/arduino/tools/avr-gcc/7.3.0-atmel3.6.1-arduino7/bin)
AVR_TOOLCHAIN ?= $(ARDUINO_AVR_GCC)

# Prefix for AVR tools (empty string if using system PATH)
ifneq ($(AVR_TOOLCHAIN),)
  AVR_PREFIX = $(AVR_TOOLCHAIN)/
else
  AVR_PREFIX =
endif

DEVICE     ?= atmega328p
CLOCK      = 16000000
PROGRAMMER ?= -c arduino -P /dev/cu.usbmodem* -b 115200
SOURCE    = main.c motion_control.c gcode.c spindle_control.c coolant_control.c serial.c \
             protocol.c stepper.c eeprom.c settings.c planner.c nuts_bolts.c limits.c jog.c\
             print.c probe.c report.c system.c
BUILDDIR = build
SOURCEDIR = grbl
# FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0x24:m
FUSES      = -U hfuse:w:0xd2:m -U lfuse:w:0xff:m

# Tune the lines below only if you know what you are doing:

AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE) -B 10 -F
COMPILE = $(AVR_PREFIX)avr-gcc -Wall -Os -DF_CPU=$(CLOCK) -mmcu=$(DEVICE) -I. -ffunction-sections -flto


OBJECTS = $(addprefix $(BUILDDIR)/,$(notdir $(SOURCE:.c=.o)))

# symbolic targets:
all:	grbl.hex

$(BUILDDIR)/%.o: $(SOURCEDIR)/%.c
	$(COMPILE) -MMD -MP -c $< -o $@

.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $(BUILDDIR)/$@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.

#.c.s:
	$(COMPILE) -S $< -o $(BUILDDIR)/$@

flash:	all
	$(AVRDUDE) -U flash:w:grbl.hex:i

fuse:
	$(AVRDUDE) $(FUSES)

# Xcode uses the Makefile targets "", "clean" and "install"
install: flash fuse

# if you use a bootloader, change the command below appropriately:
load: all
	bootloadHID grbl.hex

clean:
	rm -f grbl.hex $(BUILDDIR)/*.o $(BUILDDIR)/*.d $(BUILDDIR)/*.elf

# file targets:
$(BUILDDIR)/main.elf: $(OBJECTS)
	$(COMPILE) -o $(BUILDDIR)/main.elf $(OBJECTS) -lm -Wl,--gc-sections

grbl.hex: $(BUILDDIR)/main.elf
	rm -f grbl.hex
	$(AVR_PREFIX)avr-objcopy -j .text -j .data -O ihex $(BUILDDIR)/main.elf grbl.hex
	$(AVR_PREFIX)avr-size --format=berkeley $(BUILDDIR)/main.elf
# If you have an EEPROM section, you must also create a hex file for the
# EEPROM and add it to the "flash" target.

# Targets for code debugging and analysis:
disasm:	main.elf
	$(AVR_PREFIX)avr-objdump -d $(BUILDDIR)/main.elf

cpp:
	$(COMPILE) -E $(SOURCEDIR)/main.c

# include generated header dependencies
-include $(BUILDDIR)/$(OBJECTS:.o=.d)

# GRBL CoreXY -- Newmatik Fork

A fork of [gnea/grbl](https://github.com/gnea/grbl) (v1.1) pre-configured for **CoreXY kinematics** and a **macOS command-line build chain**. Targets the Arduino Uno R3 (ATmega328P).

## What Changed from Upstream

| Change | File |
|---|---|
| CoreXY kinematics enabled | `grbl/config.h` -- `#define COREXY` |
| Homing cycles reconfigured for CoreXY (X and Y homed separately) | `grbl/config.h` -- `HOMING_CYCLE_0/1/2` |
| Programmer set to Arduino USB bootloader | `Makefile` -- `PROGRAMMER` |
| Removed old commit logs and Arduino IDE example sketches | `doc/log/`, `grbl/examples/` |

## Prerequisites (macOS)

### 1. Homebrew

If you don't have Homebrew yet:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. AVR Toolchain

GRBL requires **avr-gcc 7.x** to fit within the ATmega328P's 32 KB flash. Newer versions (9.x+) produce significantly larger binaries that exceed the flash limit.

**Recommended: Install the Arduino IDE** (even if you won't use it directly). It ships avr-gcc 7.3.0 which the Makefile auto-detects:

- Download from [arduino.cc](https://www.arduino.cc/en/software)
- Open it once and install the **Arduino AVR Boards** package via **Tools > Board > Boards Manager**
- The toolchain will be installed to `~/Library/Arduino15/packages/arduino/tools/avr-gcc/7.3.0-atmel3.6.1-arduino7/`

You also need `avrdude` for flashing (the Arduino IDE bundles one, but the Makefile uses the system `avrdude`):

```bash
brew install avrdude
```

Verify the installation:

```bash
~/Library/Arduino15/packages/arduino/tools/avr-gcc/7.3.0-atmel3.6.1-arduino7/bin/avr-gcc --version
avrdude -v
```

**Alternative:** If you want to use Homebrew's avr-gcc, install version 8:

```bash
brew tap osx-cross/avr
brew install avr-gcc@8
```

Then point the Makefile to it:

```bash
make AVR_TOOLCHAIN="$(brew --prefix avr-gcc@8)/bin"
```

### 3. VS Code / Cursor Extension (optional)

Install the **C/C++** extension (`ms-vscode.cpptools`) for IntelliSense and code navigation.

## Build

Compile the firmware from the project root:

```bash
make clean && make
```

The Makefile auto-detects the Arduino IDE's avr-gcc 7.3.0 on macOS. To use a different toolchain, override the path:

```bash
make AVR_TOOLCHAIN=/path/to/avr-gcc/bin
```

This produces `grbl.hex` in the project root directory. The build output shows the firmware size. `text` plus `data` must not exceed 32,256 bytes: the ATmega328P has 32,768 bytes of flash and the Arduino Uno bootloader occupies 512 of them. `make` fails if the image is larger, which is what happens with avr-gcc 9 or newer.

Every push to `master` and every pull request is built with avr-gcc 7.3.0 by the GitHub Actions workflow in `.github/workflows/build.yml`.

## Flash to Arduino Uno

### 1. Find Your Serial Port

Plug in the Arduino Uno via USB and identify the serial device:

```bash
ls /dev/cu.usbmodem*
```

You should see something like `/dev/cu.usbmodem11401`.

### 2. Flash

If the Makefile's `PROGRAMMER` line already matches your serial port (it uses a wildcard by default), simply run:

```bash
make flash
```

If you have multiple serial devices, specify the exact port:

```bash
make flash PROGRAMMER="-c arduino -P /dev/cu.usbmodem11401 -b 115200"
```

### 3. Verify

Connect to the Arduino with a serial terminal at **115200 baud** to confirm GRBL is running:

```bash
screen /dev/cu.usbmodem11401 115200
```

You should see a GRBL welcome message. Press `Ctrl-A` then `K` then `Y` to exit screen.

## Configuration

All compile-time configuration lives in two files:

- **`grbl/config.h`** -- Feature toggles (CoreXY, homing, safety door, laser mode, etc.)
- **`grbl/defaults.h`** -- Default machine parameters (steps/mm, max rates, acceleration, travel limits)

After editing either file, rebuild and re-flash:

```bash
make clean && make && make flash
```

Runtime settings (steps/mm, acceleration, etc.) can also be changed over serial with `$` commands without recompiling. See `doc/markdown/settings.md` for the full settings reference.

## CoreXY Notes

- CoreXY is enabled via `#define COREXY` in `grbl/config.h`.
- The A and B motors **must** have the same steps/mm. Set `$100` and `$101` to identical values.
- Homing is configured to home Z first, then X, then Y in separate cycles (required for CoreXY).
- If motions move in unexpected directions, check motor wiring against the [CoreXY theory](http://corexy.com/theory.html).

## Project Structure

```
.
├── Makefile              # Build and flash configuration
├── COPYING               # GPLv3 license
├── grbl/                 # Firmware source code
│   ├── config.h          # Compile-time feature configuration
│   ├── defaults.h        # Default machine parameters
│   ├── cpu_map.h         # ATmega328P pin mapping
│   ├── main.c            # Entry point
│   ├── stepper.c/h       # Stepper motor driver
│   ├── planner.c/h       # Motion planner with look-ahead
│   ├── gcode.c/h         # G-code parser
│   ├── motion_control.c/h
│   ├── serial.c/h        # UART communication
│   └── ...               # Additional modules
├── build/                # Compiled object files (gitignored)
└── doc/
    ├── csv/              # Error, alarm, and setting code references
    ├── markdown/         # Commands, settings, jogging, laser mode docs
    └── script/           # Python streaming scripts for testing
```

## Supported G-Codes

```
Non-Modal Commands: G4, G10L2, G10L20, G28, G30, G28.1, G30.1, G53, G92, G92.1
Motion Modes:       G0, G1, G2, G3, G38.2, G38.3, G38.4, G38.5, G80
Feed Rate Modes:    G93, G94
Unit Modes:         G20, G21
Distance Modes:     G90, G91
Arc IJK Distance:   G91.1
Plane Select:       G17, G18, G19
Tool Length Offset: G43.1, G49
Cutter Comp:        G40
Coord Systems:      G54, G55, G56, G57, G58, G59
Control Modes:      G61
Program Flow:       M0, M1, M2, M30
Coolant Control:    M7*, M8, M9
Spindle Control:    M3, M4, M5
Valid Words:        F, I, J, K, L, N, P, R, S, T, X, Y, Z
```

## Credits

This is a fork of [GRBL](https://github.com/gnea/grbl) by Sungeun "Sonny" Jeon ([@chamnit](https://github.com/chamnit)), built on the original Grbl v0.6 by Simen Svale Skogsrud.

## License

GPLv3. See [COPYING](COPYING) for the full license text.

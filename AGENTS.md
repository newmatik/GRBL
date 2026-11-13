# AGENTS.md

Canonical instruction file for AI coding agents in this repository. `CLAUDE.md` only imports it.

## What this is

A fork of [gnea/grbl](https://github.com/gnea/grbl) v1.1 for the Arduino Uno R3 (ATmega328P), configured for CoreXY
kinematics. The repository is **public** and licensed GPLv3 (`COPYING`). `README.md` holds the build and flash
instructions.

## Rules

- **Keep the divergence from upstream small.** The fork differs in `grbl/config.h`, the `Makefile`, the README and the
  removed `doc/log/` and `grbl/examples/` folders. Do not reformat, refactor or "clean up" upstream sources under
  `grbl/` or `doc/`; change them only for a concrete machine requirement or a bug fix, and list every change in the
  README table "What Changed from Upstream". The `upstream` remote is `https://github.com/gnea/grbl.git`.
- **Machine configuration lives in `grbl/config.h` and `grbl/defaults.h`.** A change there changes how a real machine
  moves and homes. Make it only when the requirement is stated, and update the README section "CoreXY Notes" with it.
- **Never flash hardware.** `make flash`, `make fuse` and `make install` write to a connected board and are manual bench
  steps for a person.
- **Public repository.** No customer names, internal machine details, credentials or other confidential information in
  code, commits, issues or pull requests.
- No AI attribution in commits, comments or pull requests.

## Commands

- Build: `make clean && make` (needs avr-gcc 7.x; see README). The build fails if the image exceeds the 32,256 bytes of
  application flash.
- There are no tests and no linter. CI (`.github/workflows/build.yml`) builds the firmware with avr-gcc 7.3.0 on every
  push to `master` and every pull request.
- Build output (`build/`, `grbl.hex`) is git-ignored; never commit it.

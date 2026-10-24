# nix-flakify

A catch-all repository for Nix flakes that provide development environments for
projects that don't maintain their own flakes.

Each project's environment lives under `<github-owner>/<repo>`, with its own
`flake.nix` and `flake.lock` to keep dependencies pinned independently. Using the
upstream GitHub organization or owner avoids clashes between repository names.

## Environments

| Project | Environment | Shells |
| --- | --- | --- |
| [Tasks](https://github.com/tasks/tasks) | `tasks/tasks` | `default` |
| [Voice](https://github.com/PaulWoitaschek/Voice) | `PaulWoitaschek/Voice` | `default`, `emulator` |
| [QMK](https://github.com/qmk/qmk_firmware) | `qmk/qmk_firmware` | `default` |
| [Royal Kludge RK61 (non-RGB)](https://github.com/Diff-fusion/qmk_firmware/tree/royal_kludge_61) | `Diff-fusion/qmk_firmware` | `default` |
| [Akko 5075B VIA](https://github.com/akkogear/qmk_firmware/tree/rgblight) | `akkogear/qmk_firmware` | `default` |

## Usage

You'll need Nix with flakes enabled. For automatic environment loading, you'll
also need direnv with nix-direnv configured.

With this repository checked out at `~/Work/nix-flakify`, point the project's
`.envrc` at its environment here. For Tasks:

```sh
use flake "path:$HOME/Work/nix-flakify/tasks/tasks"
```

Run `direnv allow` in the project directory after updating `.envrc`.

To enter an environment directly:

```sh
nix develop "path:$HOME/Work/nix-flakify/tasks/tasks"
```

For Voice, use `PaulWoitaschek/Voice` in place of `tasks/tasks`. To enter its
emulator shell:

```sh
nix develop "path:$HOME/Work/nix-flakify/PaulWoitaschek/Voice#emulator"
```

Run these commands from the corresponding project's checkout so build commands
and shell settings use that project's working directory.

## Keyboard firmware

Use the environment matching your firmware checkout. The RK61 and Akko ports
live in separate QMK forks and need different ARM compiler versions.

| Firmware checkout | Branch | `.envrc` |
| --- | --- | --- |
| `qmk/qmk_firmware` | `master` | `use flake "path:$HOME/Work/nix-flakify/qmk/qmk_firmware"` |
| `Diff-fusion/qmk_firmware` | `royal_kludge_61` | `use flake "path:$HOME/Work/nix-flakify/Diff-fusion/qmk_firmware"` |
| `akkogear/qmk_firmware` | `rgblight` | `use flake "path:$HOME/Work/nix-flakify/akkogear/qmk_firmware"` |

Run `direnv allow` after updating `.envrc`. Initialize the firmware checkout's
submodules before building:

```sh
git submodule update --init --recursive
```

The upstream QMK environment includes the QMK CLI, ARM and AVR toolchains, and
common flashing tools. Build with `qmk compile -kb <keyboard> -km <keymap>`.

The RK61 environment preserves the local setup's ARM GCC 10 toolchain from
nixpkgs 21.11 for the older SN32F260 port. Build the non-RGB RK61 with:

```sh
make royal_kludge/rk61:default
```

It also provides the existing `build-rk61`, `clean-build`, and `flash-rk61`
helpers. Shell entry does not initialize submodules or flash hardware.

The Akko environment uses the fork's original nixpkgs revision and ARM GCC 12
toolchain. If you don't have a checkout yet:

```sh
git clone --branch rgblight --recurse-submodules \
  https://github.com/akkogear/qmk_firmware.git akko-qmk-firmware
```

Build the appropriate 5075B VIA layout from the firmware checkout:

```sh
make akko/5075b/ansi:default VIA_ENABLE=yes
# Or, for ISO:
make akko/5075b/iso:default VIA_ENABLE=yes
```

These environments provide build tools; firmware source and patches stay in the
firmware checkout. The RK61's ChibiOS-contrib submodule and the Akko fork need
local source fixes for the verified builds; the environments do not apply them.
Before flashing, match the firmware to the exact hardware
revision; 5075 variants and RK61 RGB/non-RGB models are not interchangeable.

## Adding a project

Copy the project's `flake.nix` and `flake.lock` into `<github-owner>/<repo>` here,
using the upstream owner's and repository's spelling. Update the project's
`.envrc` to use that directory, keeping any other project-specific settings
intact.

Flakes here must work independently of the project's source tree. If a flake
reads versions from project files, record the required values in the flake and
keep them in sync when updating the project's toolchain.

This is a public repository. Keep credentials, private URLs, and other sensitive
project details out of committed files.

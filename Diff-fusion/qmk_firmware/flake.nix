{
  description = "QMK Firmware build environment for RK61 keyboard";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-legacy = {
      url = "github:NixOS/nixpkgs/21.11";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-legacy, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # This fork's ChibiOS-contrib code needs the older ARM GCC toolchain.
        pkgs-old = import nixpkgs-legacy { inherit system; };

        pkgs = import nixpkgs {
          inherit system;
        };

        # Use older ARM GCC from the old nixpkgs
        gcc-arm-embedded-compat = pkgs-old.gcc-arm-embedded;

        # Python environment with QMK dependencies
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          # requirements.txt
          appdirs
          argcomplete
          colorama
          hjson
          milc
          pygments
          # requirements-dev.txt (optional, for development)
          nose2
          flake8
          pep8-naming
          yapf
        ]);

        # Build script for RK61
        buildRK61 = pkgs.writeShellScriptBin "build-rk61" ''
          set -e
          echo "Building QMK firmware for RK61..."
          make royal_kludge/rk61:default
          echo "Build complete! Firmware is in .build/"
        '';

        # Clean script
        cleanBuild = pkgs.writeShellScriptBin "clean-build" ''
          set -e
          echo "Cleaning build artifacts..."
          make clean
          echo "Clean complete!"
        '';

        # Flash script
        flashRK61 = pkgs.writeShellScriptBin "flash-rk61" ''
          set -e
          echo "Flashing RK61 firmware..."
          echo "Note: Make sure your keyboard is in bootloader mode"
          make royal_kludge/rk61:default:flash
        '';

      in
      {
        devShells.default = pkgs.mkShell {
          name = "qmk-rk61-dev";

          buildInputs = [
            # ARM toolchain for Cortex-M0 (RK61 uses SN32F260)
            # Using older version for compatibility with ChibiOS-contrib
            gcc-arm-embedded-compat

            # Build tools
            pkgs.gnumake
            pkgs.git
            pkgs.diffutils
            pkgs.clang-tools
            pkgs.patch

            # Flashing tools
            pkgs.dfu-util
            pkgs.dfu-programmer

            # Python dependencies used by QMK's build scripts
            pythonEnv

            # Helper scripts
            buildRK61
            cleanBuild
            flashRK61
          ];

          shellHook = ''
            echo "QMK Firmware build environment for RK61"
            echo "========================================"
            echo ""
            echo "Available commands:"
            echo "  build-rk61  - Build the RK61 firmware"
            echo "  clean-build - Clean build artifacts"
            echo "  flash-rk61  - Flash firmware to RK61"
            echo ""
            echo "Or use make directly:"
            echo "  make royal_kludge/rk61:default"
            echo ""
            echo "Keyboard: Royal Kludge RK61"
            echo "MCU: SN32F260 (ARM Cortex-M0)"
            echo ""
          '';
        };

      }
    );
}

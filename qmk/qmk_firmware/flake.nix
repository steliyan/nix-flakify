{
  description = "Upstream QMK firmware development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          avrlibc = pkgs.pkgsCross.avr.libc;
          avrFlags = builtins.concatStringsSep " " [
            "-isystem ${avrlibc}/avr/include"
            "-B${avrlibc}/avr/lib/avr5"
            "-L${avrlibc}/avr/lib/avr5"
            "-B${avrlibc}/avr/lib/avr35"
            "-L${avrlibc}/avr/lib/avr35"
            "-B${avrlibc}/avr/lib/avr51"
            "-L${avrlibc}/avr/lib/avr51"
          ];
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              qmk
              gnumake
              git
              diffutils
              patch
              gcc-arm-embedded
              pkgsCross.avr.buildPackages.gcc
              pkgsCross.avr.buildPackages.binutils
              avrlibc
              avrdude
              dfu-programmer
              dfu-util
              teensy-loader-cli
            ];

            AVR_CFLAGS = avrFlags;
            AVR_ASFLAGS = avrFlags;

            shellHook = ''
              unset NIX_CFLAGS_COMPILE_FOR_TARGET
            '';
          };
        });
    };
}

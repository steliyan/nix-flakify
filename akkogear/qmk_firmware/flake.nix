{
  description = "Akko 5075B VIA QMK firmware development environment";

  # Match the fork's util/nix/sources.json and its ARM GCC 12 toolchain.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/98b00b6947a9214381112bdb6f89c25498db4959";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          pythonEnv = pkgs.python3.withPackages (ps: with ps; [
            appdirs
            argcomplete
            colorama
            dotty-dict
            hid
            hjson
            jsonschema
            milc
            pygments
            pyserial
            pyusb
            pillow
          ]);
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              qmk
              gcc-arm-embedded
              gnumake
              git
              diffutils
              patch
              dfu-util
              pythonEnv
            ];

            shellHook = ''
              unset NIX_CFLAGS_COMPILE_FOR_TARGET
            '';
          };
        });
    };
}

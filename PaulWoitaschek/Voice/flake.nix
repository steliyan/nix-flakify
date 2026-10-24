{
  description = "Voice Android development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];
      versions = {
        sdk-compile = "37";
        jvm-toolchain = "25";
      };
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };
          jdk = pkgs.${"jdk" + versions.jvm-toolchain};
          buildToolsVersion = "36.0.0";
          sdkOptions = {
            platformVersions = [ versions.sdk-compile ];
            buildToolsVersions = [ buildToolsVersion ];
            includeEmulator = false;
            includeSystemImages = false;
            includeSources = false;
            includeNDK = false;
          };
          androidSdk = (pkgs.androidenv.composeAndroidPackages sdkOptions).androidsdk;
          emulatorSdk = (pkgs.androidenv.composeAndroidPackages (sdkOptions // {
            includeEmulator = true;
            includeSystemImages = true;
            systemImageTypes = [ "google_apis_playstore" ];
            platformVersions = [ "36" versions.sdk-compile ];
            abiVersions = [ (if pkgs.stdenv.hostPlatform.isAarch64 then "arm64-v8a" else "x86_64") ];
          })).androidsdk;
          mkDevShell = sdk: extraPackages: pkgs.mkShell {
            packages = [ jdk sdk ] ++ extraPackages;

            JAVA_HOME = jdk.home;
            ANDROID_HOME = "${sdk}/libexec/android-sdk";
            ANDROID_SDK_ROOT = "${sdk}/libexec/android-sdk";

            shellHook = ''
              export GRADLE_USER_HOME="$PWD/.gradle/user-home"
              export GRADLE_OPTS="''${GRADLE_OPTS:-} -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/${buildToolsVersion}/aapt2"
            '';
          };
        in
        {
          default = mkDevShell androidSdk [ ];
          emulator = mkDevShell emulatorSdk [ pkgs.python3 pkgs.ffmpeg ];
        });
    };
}

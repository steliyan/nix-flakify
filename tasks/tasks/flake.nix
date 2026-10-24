{
  description = "Flake for Tasks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # The Android SDK is unfree and requires accepting its license, so we
        # re-import nixpkgs with the necessary config instead of using
        # legacyPackages.
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        versions = {
          android-compileSdk = "37";
          jdk = "25";
        };
        # Keep platform 34 for :wear-datalayer and build tools 36 for AGP.
        buildToolsVersion = "37.0.0";

        androidComposition = pkgs.androidenv.composeAndroidPackages {
          # These resolve against the SDK manifest pinned by flake.lock.
          cmdLineToolsVersion = "latest";
          platformToolsVersion = "latest";
          buildToolsVersions = [
            buildToolsVersion
            "36.0.0"
          ];
          platformVersions = [
            versions.android-compileSdk
            "34"
          ];
          # Android builds use prebuilt native dependencies.
          includeCmake = false;
          includeNDK = false;
          includeEmulator = false;
          includeSystemImages = false;
          includeSources = false;
        };

        androidSdk = androidComposition.androidsdk;
        androidSdkRoot = "${androidSdk}/libexec/android-sdk";

        # JVM targets and CI use this JDK; Android bytecode targets JVM 17.
        jdk = pkgs."jdk${versions.jdk}";
        # Match .ruby-version for Fastlane.
        ruby = pkgs.ruby_4_0;
      in
      {
        devShells.default = pkgs.mkShell {
          packages =
            [
              jdk
              androidSdk
              # fastlane tooling (Gemfile / fastlane/)
              ruby
              (pkgs.bundler.override { inherit ruby; })
            ]
            # kmp/build-libical.sh uses CMake for iOS builds with Xcode.
            ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.cmake ];

          ANDROID_HOME = androidSdkRoot;
          ANDROID_SDK_ROOT = androidSdkRoot;
          # jdk.home resolves to the correct JAVA_HOME on both Linux
          # (.../lib/openjdk) and macOS (the store root).
          JAVA_HOME = jdk.home;

          # Maven's Linux aapt2 needs Nix's runtime libraries. On macOS,
          # let AGP select its own compatible Maven binary.
          GRADLE_OPTS =
            pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux
              "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/${buildToolsVersion}/aapt2";

          shellHook = ''
            echo "Tasks dev shell"
            echo "  JDK:         $(java -version 2>&1 | head -n1)"
            echo "  ANDROID_HOME=$ANDROID_HOME"
            echo "Build with: ./gradlew :app:assembleGenericDebug"
          '';
        };
      }
    );
}

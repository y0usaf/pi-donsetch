{
  description = "DonSeTch's pi extension with its prebuilt binary";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (pkgs) lib;
    pkgJson = lib.importJSON ./package.json;
    meta = {
      inherit (pkgJson) description;
      homepage = "https://github.com/dondai44423/donsetch";
      license = lib.licenses.agpl3Only;
      platforms = [system];
    };
  in {
    packages.${system} = {
      donsetch = pkgs.stdenvNoCC.mkDerivation {
        pname = "donsetch";
        inherit (pkgJson) version;
        src = pkgs.fetchurl {
          url = "https://github.com/dondai44423/donsetch/releases/download/v${pkgJson.version}/donsetch-linux-x64.tar.gz";
          hash = "sha256-0x4udaeRMyxMcnPxrPprucuVhbtvlQyR7WIa4E1zXTU=";
        };
        nativeBuildInputs = [pkgs.patchelf];
        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          tar -xzf $src -C $out/bin
          install -m755 $out/bin/donsetch $out/bin/donsetch.tmp
          mv $out/bin/donsetch.tmp $out/bin/donsetch
          chmod 644 $out/bin/libonnxruntime.so
          patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/bin/donsetch
          patchelf --set-rpath $out/bin:${pkgs.stdenv.cc.cc.lib}/lib $out/bin/donsetch
          runHook postInstall
        '';
        meta = meta // {mainProgram = "donsetch";};
      };

      default = pkgs.stdenvNoCC.mkDerivation {
        pname = "pi-donsetch";
        inherit (pkgJson) version;
        src = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [./package.json ./pi-extension.ts ./README.md ./LICENSE];
        };
        dontBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out/binaries
          cp package.json pi-extension.ts README.md LICENSE $out/
          ln -s ${self.packages.${system}.donsetch}/bin/donsetch $out/binaries/donsetch
          runHook postInstall
        '';
        inherit meta;
      };
    };

    checks.${system}.default = pkgs.runCommand "donsetch-runs" {} ''
      ${lib.getExe self.packages.${system}.donsetch} --version > $out
    '';
  };
}

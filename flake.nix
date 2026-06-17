{
  description = "Ido Samuelson résumé — custom Typst dark-sidebar theme + matching HTML site (one source: resume.json)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      # Typst with the Font Awesome package available offline (contact icons).
      typst-with = pkgs.typst.withPackages (ps: [ ps.fontawesome ]);

      # Helvetica-like sans (Liberation) + symbol fallback (DejaVu) + Font Awesome 7 (icons).
      fonts = pkgs.symlinkJoin {
        name = "resume-fonts";
        paths = [ pkgs.liberation_ttf pkgs.dejavu_fonts pkgs.font-awesome ];
      };

      # Same data drives both renderers.
      data = builtins.fromJSON (builtins.readFile ./resume.json);
      siteHtml = pkgs.writeText "index.html" (import ./site.nix { inherit lib data; });

      # Only the files the render needs — keeps the build input small/deterministic.
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./resume.typ
          ./resume.json
          ./assets
        ];
      };

      resume = pkgs.stdenvNoCC.mkDerivation {
        pname = "resume";
        version = "1.0";
        inherit src;
        nativeBuildInputs = [ typst-with ];
        buildPhase = ''
          runHook preBuild
          typst compile --font-path ${fonts}/share/fonts resume.typ resume.pdf
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/assets
          cp resume.pdf $out/resume.pdf
          cp ${siteHtml} $out/index.html
          cp assets/photo.png $out/assets/photo.png
          runHook postInstall
        '';
      };
    in
    {
      # `nix build` -> result/{index.html (dark-sidebar site), resume.pdf, assets/photo.png}
      packages.default = resume;
      packages.pdf = resume;

      # `nix run .#live` -> recompile resume.pdf on every save (open it in a hot-reloading viewer).
      apps.live = {
        type = "app";
        program = toString (pkgs.writeShellScript "resume-live" ''
          echo "Watching resume.typ/resume.json -> resume.pdf (open resume.pdf in a viewer)"
          exec ${typst-with}/bin/typst watch --font-path ${fonts}/share/fonts resume.typ resume.pdf
        '');
      };

      # `nix run .#site` -> build the HTML site + PDF and serve it locally (open the printed URL).
      apps.site = {
        type = "app";
        program = toString (pkgs.writeShellScript "resume-site" ''
          out=$(${pkgs.nix}/bin/nix build --no-link --print-out-paths .#default)
          echo "Serving $out  (Ctrl-C to stop)"
          exec ${pkgs.python3}/bin/python3 -m http.server --directory "$out" 8000
        '');
      };
      apps.default = self.apps.${system}.live;

      # `nix develop` -> typst (+ fontawesome) and fonts for ad-hoc `typst compile`.
      devShells.default = pkgs.mkShell {
        packages = [ typst-with fonts ];
        env.TYPST_FONT_PATHS = "${fonts}/share/fonts";
      };

      formatter = pkgs.nixpkgs-fmt;
    });
}

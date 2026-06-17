{
  description = "Ido Samuelson résumé — custom Typst dark-sidebar theme (reads resume.json)";

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

      # Only the files the render needs — keeps the build input small/deterministic.
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./resume.typ
          ./resume.json
          ./assets
        ];
      };

      resume-pdf = pkgs.stdenvNoCC.mkDerivation {
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
          mkdir -p $out
          cp resume.pdf $out/resume.pdf
          # Minimal web view: embed the PDF so a static host (gh-pages) shows the résumé at /.
          cat > $out/index.html <<'EOF'
          <!doctype html>
          <html lang="en">
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>Ido Samuelson — Résumé</title>
            <style>html, body { margin: 0; height: 100%; } embed { width: 100%; height: 100vh; border: 0; }</style>
          </head>
          <body><embed src="resume.pdf" type="application/pdf" /></body>
          </html>
          EOF
          runHook postInstall
        '';
      };
    in
    {
      # `nix build` / `nix build .#pdf` -> result/resume.pdf (+ result/index.html)
      packages.default = resume-pdf;
      packages.pdf = resume-pdf;

      # `nix run .#live` -> recompile resume.pdf on every save of resume.typ/json.
      # Open resume.pdf in a viewer that hot-reloads (e.g. zathura) alongside it.
      apps.live = {
        type = "app";
        program = toString (pkgs.writeShellScript "resume-live" ''
          echo "Watching resume.typ/resume.json -> resume.pdf (open resume.pdf in a viewer)"
          exec ${typst-with}/bin/typst watch --font-path ${fonts}/share/fonts resume.typ resume.pdf
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

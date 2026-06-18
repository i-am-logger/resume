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

      # Inter (primary) + Liberation/DejaVu fallback + Font Awesome 7 (icons).
      fonts = pkgs.symlinkJoin {
        name = "resume-fonts";
        paths = [ pkgs.inter pkgs.liberation_ttf pkgs.dejavu_fonts pkgs.font-awesome ];
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
          mkdir -p $out/assets/fonts
          cp resume.pdf $out/resume.pdf
          cp ${siteHtml} $out/index.html
          cp assets/photo.png $out/assets/photo.png
          cp ${pkgs.inter}/share/fonts/truetype/InterVariable.ttf $out/assets/fonts/InterVariable.ttf
          runHook postInstall
        '';
      };
    in
    {
      # `nix build` -> result/{index.html (dark-sidebar site), resume.pdf, assets/photo.png}
      packages.default = resume;
      packages.pdf = resume;

      # `nix run .#live` -> build the HTML site, serve it with hot-reload, and
      # rebuild on every edit of resume.json / site.nix / resume.typ. Open the printed URL.
      apps.live = {
        type = "app";
        program = toString (pkgs.writeShellScript "resume-live" ''
          set -euo pipefail
          SD=$(mktemp -d); export SD
          REBUILD='o=$(${pkgs.nix}/bin/nix build --no-link --print-out-paths .#default 2>/dev/null) || { echo "[build failed]"; exit 0; }; rm -rf "$SD"/* 2>/dev/null || true; cp -rL "$o"/. "$SD"/; chmod -R u+w "$SD"; echo "[rebuilt -> browser reloads]"'
          sh -c "$REBUILD"
          ${pkgs.live-server}/bin/live-server "$SD" &
          trap 'kill %1 2>/dev/null || true' EXIT
          # watchexec keeps watching across atomic-save edits (entr exits after the first);
          # rebuilds the site on any change to the sources, live-server reloads the browser.
          exec ${pkgs.watchexec}/bin/watchexec --debounce 300ms \
            -w resume.json -w site.nix -w resume.typ -w flake.nix \
            -- sh -c "$REBUILD"
        '');
      };
      apps.default = self.apps.${system}.live;

      # `nix run .#watch-pdf` -> recompile resume.pdf on save (open it in a PDF viewer).
      apps.watch-pdf = {
        type = "app";
        program = toString (pkgs.writeShellScript "resume-watch-pdf" ''
          exec ${typst-with}/bin/typst watch --font-path ${fonts}/share/fonts resume.typ resume.pdf
        '');
      };

      # `nix develop` -> typst (+ fontawesome) and fonts for ad-hoc `typst compile`.
      devShells.default = pkgs.mkShell {
        packages = [ typst-with fonts ];
        env.TYPST_FONT_PATHS = "${fonts}/share/fonts";
      };

      formatter = pkgs.nixpkgs-fmt;
    });
}

{
  description = "Ido Samuelson résumé — custom Typst dark-sidebar theme + matching HTML site (one source: resume.json)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # The résumé's own theming project — drives the live theme + light/dark picker.
    vogix16-themes = {
      url = "github:i-am-logger/vogix16-themes";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , vogix16-themes
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

      # All vogix16 themes (day + night base16 maps) → the live theme / light-dark picker.
      themeDirs = builtins.attrNames (lib.filterAttrs
        (n: t: t == "directory" && builtins.pathExists (vogix16-themes + "/${n}/day.toml"))
        (builtins.readDir vogix16-themes));
      readColors = f: (builtins.fromTOML (builtins.readFile f)).colors;
      themes = lib.listToAttrs (map
        (n: lib.nameValuePair n {
          day = readColors (vogix16-themes + "/${n}/day.toml");
          night = readColors (vogix16-themes + "/${n}/"
            + (if builtins.pathExists (vogix16-themes + "/${n}/night.toml") then "night.toml" else "day.toml"));
        })
        themeDirs);

      siteHtml = pkgs.writeText "index.html" (import ./site.nix { inherit lib data themes; });

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
          cp assets/favicon.ico $out/favicon.ico
          cp assets/favicon.svg $out/assets/favicon.svg
          cp assets/lang-rust.svg $out/assets/lang-rust.svg
          cp assets/lang-nix.svg $out/assets/lang-nix.svg
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
          PORT=4321
          SD=$(mktemp -d); export SD
          # Copy ONLY the known output files (no recursion) so an empty $o can never
          # turn into a copy of "/"; skip entirely unless the build produced index.html.
          # Guard first: only copy when the build produced a real output ($o non-empty AND has
          # index.html) — that check is what prevents an empty $o from ever becoming a copy of "/".
          # Then copy the WHOLE output (no hand-maintained file list); chmod so the next rebuild can
          # overwrite the read-only store copies.
          REBUILD='o=$(${pkgs.nix}/bin/nix build --no-link --print-out-paths .#default 2>/dev/null); if [ -z "$o" ] || [ ! -f "$o/index.html" ]; then echo "[build failed - keeping previous]"; exit 0; fi; ${pkgs.coreutils}/bin/cp -fRL "$o"/. "$SD"/ && ${pkgs.coreutils}/bin/chmod -R u+w "$SD"; echo "[rebuilt -> reload http://localhost:'"$PORT"']"'
          sh -c "$REBUILD"
          # free the fixed port from a previous run, then serve on it.
          ${pkgs.procps}/bin/pkill -x live-server 2>/dev/null || true
          ${pkgs.live-server}/bin/live-server --port "$PORT" "$SD" &
          trap 'kill %1 2>/dev/null || true' EXIT
          echo "Serving http://localhost:$PORT  — edit resume.json / site.nix / resume.typ to auto-reload"
          # watchexec survives atomic-save edits (entr exits after the first); rebuild on any change.
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

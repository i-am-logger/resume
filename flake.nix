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

      # Rebuild + copy-into-serve-dir as a SCRIPT FILE (not an inline string). watchexec re-shells
      # and word-splits an inline `sh -c "<string>"`, which mangled the build invocation (nix ran
      # with no subcommand) — the cause of the perpetual "[build failed]". A single script path
      # survives that. Reads $FLAKE_DIR (absolute flake path) and $SD (serve dir) from the env.
      rebuildScript = pkgs.writeShellScript "resume-rebuild" ''
        ${pkgs.nix}/bin/nix build --no-link --print-out-paths "$FLAKE_DIR#default" >/tmp/resume-out.txt 2>/tmp/resume-live.log
        o=$(${pkgs.coreutils}/bin/cat /tmp/resume-out.txt 2>/dev/null)
        if [ -z "$o" ] || [ ! -f "$o/index.html" ]; then
          echo "[build failed - keeping previous]"
          ${pkgs.coreutils}/bin/tail -n 4 /tmp/resume-live.log
          exit 0
        fi
        ${pkgs.coreutils}/bin/cp -fRL "$o"/. "$SD"/ && ${pkgs.coreutils}/bin/chmod -R u+w "$SD"
        echo "[rebuilt -> reload http://localhost:4321]"
      '';
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
          export PATH="${pkgs.git}/bin:$PATH"   # Nix needs git on PATH to read the flake's git tree
          PORT=4321
          FLAKE_DIR="$PWD"; export FLAKE_DIR    # absolute flake path (the rebuild runs from another cwd)
          SD=$(mktemp -d); export SD
          ${rebuildScript}                       # initial build + copy into the serve dir
          # free the fixed port from a previous run, then serve on it.
          ${pkgs.procps}/bin/pkill -x live-server 2>/dev/null || true
          ${pkgs.live-server}/bin/live-server --port "$PORT" "$SD" &
          trap 'kill %1 2>/dev/null || true' EXIT
          echo "Serving http://localhost:$PORT  — edit resume.json / site.nix / resume.typ to auto-reload"
          # --postpone: don't also rebuild on launch (the script already built above).
          # Watch the directory (not individual file paths) + filter by extension: editors save
          # atomically (write temp, rename over), which replaces the file's inode and breaks a
          # per-file watch after the first save — that's why hot reload stopped. A dir watch
          # survives it. watchexec ignores .git / gitignored paths (result) by default.
          exec ${pkgs.watchexec}/bin/watchexec --postpone --debounce 300ms \
            -w "$FLAKE_DIR" --exts json,nix,typ \
            -- ${rebuildScript}
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

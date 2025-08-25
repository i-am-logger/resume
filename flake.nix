{
  description = "Your personal jsonresume built with Nix";

  inputs.jsonresume-nix.url = "github:TaserudConsulting/jsonresume-nix";
  inputs.jsonresume-nix.inputs.flake-utils.follows = "flake-utils";
  inputs.flake-utils.url = "flake-utils";

  outputs =
    { jsonresume-nix
    , self
    , flake-utils
    , nixpkgs
    , ...
    } @ inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
      in
      {
        # Specify formatter package for "nix fmt ." and "nix fmt . -- --check"
        formatter = pkgs.alejandra;

        # Specify the builder package to use to build your resume, this
        # will decide which theme to use.
        #
        # To show available packaged themes:
        # nix flake show github:TaserudConsulting/jsonresume-nix
        #
        # If you miss a theme, consider opening a pull request :)
        packages = {
          builder = jsonresume-nix.packages.${system}.resumed-elegant;
          inherit (jsonresume-nix.packages.${system}) fmt-as-json;

          # Build production build (HTML)
          #
          # This may need customizations, such as using the correct file
          # format and copying other resources (such as images).
          default = pkgs.runCommand "resume" { } ''
            # Preprocess resume.json to ensure basics.profiles exists as an array
            cp ${./resume.json} resume.original.json
            ${lib.getExe pkgs.jq} '(.basics.profiles //= []) | (.basics.profiles |= (if type=="array" then . else [] end))' \
              resume.original.json > resume.json

            HOME=$(mktemp -d) ${lib.getExe' self.packages.${system}.builder "resumed-render"}
            # Inject print-only CSS to hide social links, LinkedIn icons/links anywhere, and its surrounding hr in the profile card
            ${lib.getExe pkgs.gnused} -i \
              -e 's|</head>|<style><!-- __print_hide_social_links__ -->@media print { body .social-links, body .social-links * { display: none !important; visibility: hidden !important; } body a[href*="linkedin.com"], body a[href*="linkedin.com"] * { display: none !important; visibility: hidden !important; } body .link-linkedin, body .icon-linkedin { display: none !important; visibility: hidden !important; } body .icon-linkedin:before { content: "" !important; } .profile-card hr { display: none !important; } }</style></head>|' \
              resume.html
            # Inject Military Service section and move IAF entry from Work Experience
            ${lib.getExe pkgs.gnused} -i \
              -e 's|</body>|<script>(function(){var $=window.jQuery;if(!$)return;var $bg=$(".background-details");var $li=$("#work-experience .info ul.list-unstyled > li").filter(function(){return $(this).text().indexOf("Israeli Air Force")!==-1;}).first();if(!$li.length)return;if(!$("#military-service").length){var html="<div class=\"detail\" id=\"military-service\"><div class=\"icon\"><i class=\"fs-lg icon-trophy\"></i><span class=\"mobile-title\">Military Service</span></div><div class=\"info\"><h4 class=\"title text-uppercase\">Military Service</h4><ul class=\"list-unstyled clear-margin\"></ul></div></div>";var $edu=$("#education").closest(".detail");if($edu.length){$(html).insertBefore($edu);}else{$bg.append(html);}$(".floating-nav ul.list-unstyled").append("<li><a href=\"#military-service\"><i class=\"mr-10 icon-trophy\"></i>Military Service</a></li>");}$li.appendTo($("#military-service .info ul"));})();</script></body>|' \
              resume.html
            mkdir $out
            cp -v resume.html $out/index.html
            # Copy other resources such as images here...
          '';

          # Build a PDF from the rendered HTML using wkhtmltopdf
          pdf = pkgs.runCommand "resume-pdf" { } ''
            # Preprocess resume.json to ensure basics.profiles exists as an array
            cp ${./resume.json} resume.original.json
            ${lib.getExe pkgs.jq} '(.basics.profiles //= []) | (.basics.profiles |= (if type=="array" then . else [] end))' \
              resume.original.json > resume.json

            HOME=$(mktemp -d) ${lib.getExe' self.packages.${system}.builder "resumed-render"}
            mkdir -p $out
            ${lib.getExe' pkgs.wkhtmltopdf "wkhtmltopdf"} \
              --quiet \
              --enable-local-file-access \
              resume.html $out/resume.pdf
          '';
        };

        # Allows to run live preview servers using "nix run .#live-<theme>"
        # We provide one app per theme so you can quickly compare.
        apps = let
          mkLive = builderDrv: builtins.toString (pkgs.writeShellScript "entr-reload" ''
            set -euo pipefail

            # Build and then inject a Download PDF entry into the floating menu
            RENDER_SCRIPT=$(mktemp -t render-resume.XXXXXX)
cat > "$RENDER_SCRIPT" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# Work in a temporary dir to avoid touching the source resume.json
WORKDIR=$(mktemp -d)
ORIG_JSON="$PWD/resume.json"
PATCHED_JSON="$WORKDIR/resume.json"

# Ensure basics.profiles exists and is an array to satisfy theme expectations
${lib.getExe pkgs.jq} '(.basics.profiles //= []) | (.basics.profiles |= (if type=="array" then . else [] end))' \
  "$ORIG_JSON" > "$PATCHED_JSON"

pushd "$WORKDIR" >/dev/null
HOME=$(mktemp -d) ${lib.getExe' builderDrv "resumed-render"}
popd >/dev/null

# Bring the generated resume.html back to project root
cp -f "$WORKDIR/resume.html" "$PWD/resume.html"

${lib.getExe pkgs.gnused} -i \
  -e 's|<nav class=\"floating-nav js-floating-nav\"><ul class=\"list-unstyled\">|<nav class=\"floating-nav js-floating-nav\"><ul class=\"list-unstyled\"><li><a href=\"#\" onclick=\"window.print(); return false;\"><i class=\"mr-10 icon-newspaper\"></i>Download PDF</a></li>|' \
  "$PWD/resume.html"
# Inject print-only CSS to hide social links (idempotent), LinkedIn icons/links anywhere, and surrounding hr in profile card
if ! ${lib.getExe pkgs.gnugrep} -q "__print_hide_social_links__" "$PWD/resume.html"; then
  ${lib.getExe pkgs.gnused} -i \
    -e 's|</head>|<style><!-- __print_hide_social_links__ -->@media print { body .social-links, body .social-links * { display: none !important; visibility: hidden !important; } body a[href*="linkedin.com"], body a[href*="linkedin.com"] * { display: none !important; visibility: hidden !important; } body .link-linkedin, body .icon-linkedin { display: none !important; visibility: hidden !important; } body .icon-linkedin:before { content: "" !important; } .profile-card hr { display: none !important; } }</style></head>|' \
    "$PWD/resume.html"
fi

# Inject Military Service section and move IAF entry from Work Experience (idempotent-ish)
${lib.getExe pkgs.gnused} -i \
  -e 's|</body>|<script>(function(){var $=window.jQuery;if(!$)return;var $bg=$(".background-details");var $li=$("#work-experience .info ul.list-unstyled > li").filter(function(){return $(this).text().indexOf("Israeli Air Force")!==-1;}).first();if(!$li.length)return;if(!$("#military-service").length){var html="<div class=\"detail\" id=\"military-service\"><div class=\"icon\"><i class=\"fs-lg icon-trophy\"></i><span class=\"mobile-title\">Military Service</span></div><div class=\"info\"><h4 class=\"title text-uppercase\">Military Service</h4><ul class=\"list-unstyled clear-margin\"></ul></div></div>";var $edu=$("#education").closest(".detail");if($edu.length){$(html).insertBefore($edu);}else{$bg.append(html);}$(".floating-nav ul.list-unstyled").append("<li><a href=\"#military-service\"><i class=\"mr-10 icon-trophy\"></i>Military Service</a></li>");}$li.appendTo($("#military-service .info ul"));})();</script></body>|' \
  "$PWD/resume.html"
EOS
            chmod +x "$RENDER_SCRIPT"

            "$RENDER_SCRIPT"

            ${lib.getExe' pkgs.nodePackages.live-server "live-server"} \
              --watch=resume.html --open=resume.html --wait=300 &

            printf "\n%s" resume.{toml,nix,json} |
              ${lib.getExe pkgs.xe} -s 'test -f "$1" && echo "$1"' |
              ${lib.getExe pkgs.entr} -p "$RENDER_SCRIPT"
          '');
        in {
          # Keep the original 'live' as elegant for convenience
          live.type = "app";
          live.program = mkLive jsonresume-nix.packages.${system}.resumed-elegant;

          live-elegant.type = "app";
          live-elegant.program = mkLive jsonresume-nix.packages.${system}.resumed-elegant;

          live-full.type = "app";
          live-full.program = mkLive jsonresume-nix.packages.${system}.resumed-full;

          live-fullmoon.type = "app";
          live-fullmoon.program = mkLive jsonresume-nix.packages.${system}.resumed-fullmoon;

          live-kendall.type = "app";
          live-kendall.program = mkLive jsonresume-nix.packages.${system}.resumed-kendall;

          live-macchiato.type = "app";
          live-macchiato.program = mkLive jsonresume-nix.packages.${system}.resumed-macchiato;

          live-stackoverflow.type = "app";
          live-stackoverflow.program = mkLive jsonresume-nix.packages.${system}.resumed-stackoverflow;
        };
      })
    // { inherit inputs; };
}

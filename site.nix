# Generates the HTML site (two-tone dark-header sidebar) from resume.json.
# Colours: vogix16 "yoga" palette (day), applied semantically — monochromatic base for
# structure, base0D (link) only for clickable links. Self-contained (inline SVG + bundled font).
# `themes` = every vogix16 theme (day+night base16 map); a client-side picker swaps the CSS
# variables live and prints in whatever theme is selected.
{ lib, data, themes }:
let
  b = data.basics;
  esc = s: lib.replaceStrings [ "&" "<" ">" ] [ "&amp;" "&lt;" "&gt;" ] (toString s);
  isBlank = d: d == null || d == "";
  ym = d: if isBlank d then "Current" else d;
  ymRange = s: e: "${ym s} - ${ym e}";
  # Year only (drop the month) — date ranges read cleaner on a résumé.
  yr = d: if isBlank d then "Current" else lib.head (lib.splitString "-" d);
  yrRange = s: e: "${yr s} - ${yr e}";

  stripScheme = u: lib.removePrefix "https://" (lib.removePrefix "http://" u);
  phone = p: if lib.stringLength p == 10
    then "${lib.substring 0 3 p}-${lib.substring 3 3 p}-${lib.substring 6 4 p}" else p;

  jobs = lib.filter (w: w.name != "Israeli Air Force") data.work;
  profileRows = lib.concatMapStringsSep "" (p:
    ''<div>${if p.network == "GitHub" then icGithub else icLink}<a href="${p.url}" target="_blank" rel="noopener">${esc (stripScheme p.url)}</a></div>'')
    (b.profiles or [ ]);

  svg = body: ''<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${body}</svg>'';
  icLoc = svg ''<path d="M12 21s7-7.5 7-12a7 7 0 10-14 0c0 4.5 7 12 7 12z"/><circle cx="12" cy="9" r="2.5"/>'';
  icPhone = svg ''<path d="M5 3h3.5l1.8 5-2.2 1.4a13 13 0 006.5 6.5l1.4-2.2 5 1.8V20a1.5 1.5 0 01-1.6 1.5C9.6 21 3 14.4 3 5.1 3 4 4 3 5 3z"/>'';
  icMail = svg ''<rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M3 6.5l9 6.5 9-6.5"/>'';
  icLink = svg ''<path d="M10 13.5a4 4 0 005.7.3l3-3a4 4 0 10-5.7-5.7l-1.3 1.3"/><path d="M14 10.5a4 4 0 00-5.7-.3l-3 3a4 4 0 105.7 5.7l1.3-1.3"/>'';
  icDl = svg ''<path d="M12 3v12"/><path d="M7 11l5 5 5-5"/><path d="M4 20h16"/>'';
  icPrint = svg ''<path d="M6 9V3h12v6"/><rect x="4" y="9" width="16" height="8" rx="2"/><path d="M6 14h12v6H6z"/>'';
  icPalette = svg ''<path d="M12 3a9 9 0 000 18 1.8 1.8 0 001.4-3 1.8 1.8 0 011.4-3H17a4 4 0 004-4c0-3.3-4-5-9-5z"/><circle cx="7.5" cy="11.5" r=".6"/><circle cx="10" cy="7.5" r=".6"/><circle cx="14.5" cy="7.5" r=".6"/>'';
  icExt = svg ''<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/>'';
  icRust = svg ''<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 11-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 11-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 112.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 112.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"/>'';
  icNix = svg ''<path d="M12 2.5v19M4 7l16 9.5M4 17l16-9.5"/>'';
  icGithub = ''<svg class="ic" viewBox="0 0 16 16" fill="currentColor"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82a7.65 7.65 0 014 0c1.53-1.03 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0016 8c0-4.42-3.58-8-8-8z"/></svg>'';

  # uppercase keyword/highlight line with muted separators (shared by projects + experience)
  sepLine = items: ''<div class="kw">'' + lib.concatMapStringsSep ''<span class="sep"> | </span>'' (x: esc x) items + "</div>";

  langs = lib.concatMapStringsSep "" (l:
    ''<div class="item"><strong>${esc l.language}</strong><div class="muted">${esc l.fluency}</div></div>'')
    data.languages;
  skills = lib.concatMapStringsSep "" (s: ''<span class="chip">${esc s.name}</span>'') data.skills;
  edu = lib.concatMapStringsSep "" (e:
    ''<div class="item"><strong>${esc e.institution}</strong><div>${esc e.area}</div>''
    + lib.optionalString (e ? score && e.score != "") ''<div>${esc e.score}</div>''
    + ''<div><strong>${yr e.startDate} - ${yr (e.endDate or null)}</strong></div><div>${esc e.studyType}</div></div>'')
    data.education;
  certs = lib.concatMapStringsSep "" (c:
    ''<div class="item"><strong>${esc c.name}</strong><div class="muted">${esc c.issuer}</div><div class="muted">${esc c.date}</div></div>'')
    data.certificates;
  vols = lib.concatMapStringsSep "" (v:
    ''<div class="item"><strong>${esc v.organization}</strong><div>${esc v.position}</div>''
    + ''<div class="muted"><strong>${yr v.startDate} - ${yr (v.endDate or null)}</strong></div></div>'')
    data.volunteer;

  jobsHtml = lib.concatMapStringsSep "" (w:
    ''<div class="entry"><div class="erow"><span class="org">${esc w.name}</span>''
    + ''<span class="date">${yrRange w.startDate (w.endDate or null)}</span></div>''
    + ''<div class="pos">${esc w.position}</div>''
    + lib.optionalString (w ? url) ''<div class="urlrow">${icLink}<a href="${w.url}" target="_blank" rel="noopener">${esc (stripScheme w.url)}</a></div>''
    + lib.optionalString (w.summary != "") "<p>${esc w.summary}</p>"
    + lib.optionalString (w.highlights != []) (sepLine w.highlights)
    + "</div>")
    jobs;

  langIcon = l: ''<img class="langicon" src="assets/lang-${lib.toLower l}.svg" alt="${l}" />'';
  projHtml = ''<div class="cards">'' + lib.concatMapStringsSep "" (p:
    ''<div class="card"><div class="chead"><span class="cname">${esc p.name}</span>''
    + ''<a class="crepo" href="${p.url}" target="_blank" rel="noopener">${icGithub}${esc (stripScheme p.url)}</a></div>''
    + ''<div class="cdesc">${esc p.description}</div>''
    + ''<div class="cmetarow"><div class="cmeta">''
    + lib.concatMapStringsSep "" (l: ''<span class="m2">${langIcon l}${esc l}</span>'') p.languages
    + ''<span class="m2">★ ${toString p.stars}</span>''
    + ''<span class="m2">${esc p.loc}</span>''
    + lib.optionalString (p ? tests) ''<span class="m2">${esc p.tests}</span>''
    + ''</div>''
    + lib.optionalString (p ? demo) ''<a class="cdemo" href="${p.demo}" target="_blank" rel="noopener">${icExt}${esc (stripScheme p.demo)}</a>''
    + ''</div></div>'')
    data.projects
    + "</div>";

  themeOpts = lib.concatMapStringsSep "" (n: ''<option value="${n}">${lib.replaceStrings [ "_" ] [ " " ] n}</option>'') (lib.attrNames themes);
  # Default theme/variant — drives BOTH the first-paint :root vars and the JS init (kept in sync).
  # variant "system" follows the OS prefers-color-scheme (day/night chosen at runtime).
  defName = "yoga";
  defVariant = "system";
  rootVars = c: ''--bg: ${c.base00}; --surface: ${c.base01}; --sel: ${c.base02}; --comment: ${c.base03}; --border: ${c.base04}; --text: ${c.base05}; --heading: ${c.base06}; --link: ${c.base0D};'';
  defDay = themes.${defName}.day;
  defNight = themes.${defName}.night;
in
''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${esc b.name} — Résumé</title>
<link rel="icon" href="favicon.ico" sizes="any" />
<link rel="icon" type="image/svg+xml" href="assets/favicon.svg" />
<style>
@font-face { font-family: "Inter"; src: url("assets/fonts/InterVariable.ttf") format("truetype-variations"); font-weight: 100 900; font-display: swap; }
:root { ${rootVars defDay} }
@media (prefers-color-scheme: dark) { :root { ${rootVars defNight} } }
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body { font-family: "Inter", Arial, "Liberation Sans", sans-serif; color: var(--text); font-size: 13px; line-height: 1.55; background: var(--bg); }
.ic { width: 14px; height: 14px; flex: 0 0 auto; vertical-align: -2px; }
.page { display: flex; align-items: stretch; min-height: 100vh; }
.sidebar { width: 33%; background: var(--surface); }
.head { background: var(--heading); color: var(--bg); padding: 28px 24px 22px; }
.headtop { display: flex; align-items: center; gap: 15px; margin-bottom: 16px; }
.photo { width: 94px; height: 94px; flex: 0 0 auto; border-radius: 12px;
  background: #f4efe6 url("assets/photo.png") center / contain no-repeat;
  box-shadow: 0 2px 9px rgba(0,0,0,.22); }
.headname { min-width: 0; }
.head h1 { font-size: 22px; font-weight: 700; margin: 0; color: var(--bg); letter-spacing: .2px; }
.subtitle { font-size: 12.5px; color: var(--comment); margin: 4px 0 0; }
.contact div { display: flex; align-items: center; gap: 9px; font-size: 12px; margin: 6px 0; color: var(--surface); }
.contact .ic { color: var(--comment); }
.contact a { color: var(--surface); text-decoration: underline; }
.sections { padding: 18px 24px 26px; }
.sections h2 { font-size: 14px; font-weight: 700; color: var(--heading); border-bottom: 1px solid var(--border); padding-bottom: 4px; margin: 18px 0 9px; }
.sections h2:first-child { margin-top: 0; }
.item { margin-bottom: 10px; font-size: 12.5px; line-height: 1.5; }
.muted { color: var(--comment); }
.chips { display: flex; flex-wrap: wrap; gap: 6px; }
.chip { background: var(--sel); color: var(--heading); border-radius: 4px; padding: 2px 8px; font-size: 11.5px; }
.main { flex: 1; padding: 30px 36px 36px; min-width: 0; }
.summary { margin: 0 0 8px; font-size: 13px; text-align: justify; }
.main h3 { font-size: 16px; font-weight: 700; color: var(--heading); border-bottom: 1.5px solid var(--heading); padding-bottom: 4px; margin: 26px 0 14px; }
.entry { margin-bottom: 16px; }
.erow { display: flex; justify-content: space-between; align-items: baseline; gap: 14px; }
.org { font-weight: 700; font-size: 14.5px; color: var(--heading); }
.date { color: var(--comment); font-size: 12px; white-space: nowrap; }
.pos { color: var(--border); font-size: 12.5px; margin-top: 1px; }
.urlrow { display: inline-flex; align-items: center; gap: 5px; font-size: 11.5px; }
.urlrow .ic { width: 12px; height: 12px; color: var(--link); }
a { color: var(--link); text-decoration: none; }
.urlrow a { text-decoration: underline; }
.entry p { margin: 6px 0; font-size: 12.5px; text-align: justify; }
.kw { color: var(--border); font-size: 9px; letter-spacing: .4px; text-transform: uppercase; margin-top: 5px; }
.kw .sep { color: var(--comment); }
.cards { display: grid; grid-template-columns: 1fr 1fr; gap: 9px; margin-top: 11px; }
.card { border: 1px solid var(--sel); border-radius: 5px; padding: 8px 11px; background: var(--bg); }
.chead { display: flex; justify-content: space-between; align-items: baseline; gap: 10px; }
.cname { font-weight: 700; color: var(--heading); font-size: 12.5px; flex: 0 0 auto; }
.crepo { color: var(--link); font-size: 8.5px; display: inline-flex; align-items: center; gap: 4px; white-space: nowrap; }
.crepo .ic { width: 10px; height: 10px; color: var(--comment); flex: 0 0 auto; }
.cdesc { font-size: 11px; margin: 5px 0 7px; color: var(--text); min-height: 30px; }
.cmetarow { display: flex; justify-content: space-between; align-items: center; gap: 10px; }
.cmeta { display: flex; flex-wrap: wrap; gap: 8px; font-size: 8.5px; color: var(--comment); align-items: center; text-transform: uppercase; letter-spacing: .3px; min-width: 0; }
.m2 { display: inline-flex; align-items: center; gap: 4px; }
.m2 .ic { width: 10px; height: 10px; }
.langicon { width: 10px; height: 10px; }
.cdemo { display: inline-flex; align-items: center; gap: 5px; color: var(--link); font-size: 8.5px; flex: 0 0 auto; white-space: nowrap; }
.cdemo .ic { width: 11px; height: 11px; color: var(--comment); }
.toolbar { position: fixed; bottom: 18px; right: 18px; display: flex; align-items: center; gap: 8px; z-index: 10; }
.tbtn { display: inline-flex; align-items: center; gap: 7px; color: var(--text); padding: 8px 14px; border-radius: 12px; text-decoration: none; font: inherit; font-size: 13px; cursor: pointer;
  background: var(--surface);
  background: linear-gradient(rgba(255,255,255,.10), rgba(255,255,255,.02)), color-mix(in srgb, var(--surface) 26%, transparent);
  -webkit-backdrop-filter: blur(24px) saturate(180%); backdrop-filter: blur(24px) saturate(180%);
  border: 1px solid rgba(150,150,150,.30);
  box-shadow: 0 8px 28px rgba(0,0,0,.28), inset 0 1px 0 rgba(255,255,255,.55); }
.tbtn:hover { filter: brightness(1.06); }
.tbtn .ic { color: var(--text); opacity: .7; }
.tbtn select { background: transparent; color: inherit; border: none; font: inherit; cursor: pointer; outline: none; text-transform: capitalize; }
.tbtn select option { color: #222; background: #fff; text-transform: capitalize; }
.poweredby { position: fixed; bottom: 18px; left: 18px; display: inline-flex; align-items: center; gap: 6px; font-size: 11px; color: var(--text); border-radius: 12px; padding: 6px 11px; text-decoration: none; z-index: 10;
  background: var(--surface);
  background: linear-gradient(rgba(255,255,255,.10), rgba(255,255,255,.02)), color-mix(in srgb, var(--surface) 26%, transparent);
  -webkit-backdrop-filter: blur(24px) saturate(180%); backdrop-filter: blur(24px) saturate(180%);
  border: 1px solid rgba(150,150,150,.30);
  box-shadow: 0 8px 28px rgba(0,0,0,.28), inset 0 1px 0 rgba(255,255,255,.55); }
.poweredby:hover { filter: brightness(1.06); }
.poweredby .ic { width: 12px; height: 12px; color: var(--text); opacity: .7; }
.poweredby b { color: var(--text); font-weight: 700; }
@page { margin: 0; }
@media print {
  .toolbar, .poweredby { display: none !important; }
  * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
  /* Persistent two-tone background so the sidebar surface fills every page edge-to-edge
     (instead of the .sidebar box ending in a hard rectangle on the last page). */
  html { background: linear-gradient(to right, var(--surface) 0, var(--surface) 33%, var(--bg) 33%, var(--bg) 100%); }
  .page { min-height: 0; }
  /* Don't slice an entry/card across a page break. */
  .entry, .item, .erow, .card { break-inside: avoid; }
  .main h3, .sections h2 { break-after: avoid; }
}
/* Column-stack only on small SCREENS — never in print (A4's narrower width was triggering it). */
@media screen and (max-width: 720px) { .page { flex-direction: column; } .sidebar, .main { width: 100%; } }
</style>
</head>
<body>
<div class="toolbar">
  <label class="tbtn" title="Theme">${icPalette}<select id="themeSel">${themeOpts}</select></label>
  <button class="tbtn" id="variantBtn" title="System / light / dark">🖥 System</button>
  <a class="tbtn" href="#" onclick="window.print();return false;">${icPrint} Print</a>
</div>
<a class="poweredby" href="https://github.com/i-am-logger/vogix16-themes" target="_blank" rel="noopener">${icPalette} Powered by <b>Vogix16</b></a>
<div class="page">
  <aside class="sidebar">
    <div class="head">
      <div class="headtop">
        <div class="photo" role="img" aria-label="${esc b.name}"></div>
        <div class="headname">
          <h1>${esc b.name}</h1>
          <div class="subtitle">Technology Executive</div>
        </div>
      </div>
      <div class="contact">
        <div>${icLoc}<span>${esc b.location.address}</span></div>
        <div>${icPhone}<a href="tel:${b.phone}">${phone b.phone}</a></div>
        <div>${icMail}<a href="mailto:${b.email}">${esc b.email}</a></div>
        ${profileRows}
      </div>
    </div>
    <div class="sections">
      <h2>Skills</h2><div class="chips">${skills}</div>
      <h2>Languages</h2>${langs}
      <h2>Education</h2>${edu}
      <h2>Military Service</h2>
      <div class="item"><strong>Air Force</strong><div>sergeant</div><div><strong>1994 - 1997</strong></div><div>Israel</div><div>Light Helicopter Technician</div></div>
      <h2>Certifications</h2>${certs}
      <h2>Volunteering</h2>${vols}
    </div>
  </aside>
  <main class="main">
    <p class="summary">${esc b.summary}</p>
    <h3>Open Source Projects</h3>
    ${projHtml}
    <h3>Experience</h3>
    ${jobsHtml}
  </main>
</div>
<script>
const THEMES = ${builtins.toJSON themes};
const KEYS = ["base00","base01","base02","base03","base04","base05","base06","base0D"];
const VARS = ["--bg","--surface","--sel","--comment","--border","--text","--heading","--link"];
const DEFAULT = { name: "${defName}", variant: "${defVariant}" };
const SV = 3; // bump to invalidate stale saved settings (variant is now system|day|night)
const ORDER = ["system", "day", "night"];
const mq = window.matchMedia("(prefers-color-scheme: dark)");
let CUR = { name: DEFAULT.name, variant: DEFAULT.variant };
function resolved(variant) { return (variant === "day" || variant === "night") ? variant : (mq.matches ? "night" : "day"); }
function applyTheme(name, variant) {
  if (!THEMES[name]) name = DEFAULT.name;
  if (ORDER.indexOf(variant) < 0) variant = DEFAULT.variant;
  CUR = { name: name, variant: variant };
  const c = THEMES[name][resolved(variant)];
  for (let i = 0; i < KEYS.length; i++) document.documentElement.style.setProperty(VARS[i], c[KEYS[i]]);
  const sel = document.getElementById("themeSel"); if (sel) sel.value = name;
  const btn = document.getElementById("variantBtn"); if (btn) btn.textContent = variant === "system" ? "🖥 System" : (variant === "night" ? "☾ Dark" : "☀ Light");
  try { localStorage.setItem("resumeTheme", JSON.stringify({ v: SV, name: name, variant: variant })); } catch (e) {}
}
// Script sits at end of <body>, so the controls already exist — bind directly.
const _sel = document.getElementById("themeSel");
if (_sel) _sel.addEventListener("change", function () { applyTheme(this.value, CUR.variant); });
const _btn = document.getElementById("variantBtn");
if (_btn) _btn.addEventListener("click", function () { applyTheme(CUR.name, ORDER[(ORDER.indexOf(CUR.variant) + 1) % ORDER.length]); });
// Follow the OS live while in "system" mode.
if (mq.addEventListener) mq.addEventListener("change", function () { if (CUR.variant === "system") applyTheme(CUR.name, "system"); });
(function () {
  let s = null;
  try { s = JSON.parse(localStorage.getItem("resumeTheme")); } catch (e) {}
  if (!s || s.v !== SV || !THEMES[s.name] || ORDER.indexOf(s.variant) < 0) s = { name: DEFAULT.name, variant: DEFAULT.variant };
  applyTheme(s.name, s.variant);
})();
</script>
</body>
</html>
''

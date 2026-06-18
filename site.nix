# Generates the HTML site (two-tone dark-header sidebar) from resume.json.
# Colours: vogix16 "yoga" palette (day), applied semantically — monochromatic base for
# structure, base0D (link) only for clickable links. Self-contained (inline SVG + bundled font).
{ lib, data }:
let
  b = data.basics;
  esc = s: lib.replaceStrings [ "&" "<" ">" ] [ "&amp;" "&lt;" "&gt;" ] (toString s);
  isBlank = d: d == null || d == "";
  ym = d: if isBlank d then "Current" else d;
  ymRange = s: e: "${ym s} - ${ym e}";

  stripScheme = u: lib.removePrefix "https://" (lib.removePrefix "http://" u);
  phone = p: if lib.stringLength p == 10
    then "${lib.substring 0 3 p}-${lib.substring 3 3 p}-${lib.substring 6 4 p}" else p;

  jobs = lib.filter (w: w.name != "Israeli Air Force") data.work;
  profileRows = lib.concatMapStringsSep "" (p:
    ''<div>${if p.network == "GitHub" then icGithub else icLink}<a href="${p.url}">${esc (stripScheme p.url)}</a></div>'')
    (b.profiles or [ ]);

  svg = body: ''<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${body}</svg>'';
  icLoc = svg ''<path d="M12 21s7-7.5 7-12a7 7 0 10-14 0c0 4.5 7 12 7 12z"/><circle cx="12" cy="9" r="2.5"/>'';
  icPhone = svg ''<path d="M5 3h3.5l1.8 5-2.2 1.4a13 13 0 006.5 6.5l1.4-2.2 5 1.8V20a1.5 1.5 0 01-1.6 1.5C9.6 21 3 14.4 3 5.1 3 4 4 3 5 3z"/>'';
  icMail = svg ''<rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M3 6.5l9 6.5 9-6.5"/>'';
  icLink = svg ''<path d="M10 13.5a4 4 0 005.7.3l3-3a4 4 0 10-5.7-5.7l-1.3 1.3"/><path d="M14 10.5a4 4 0 00-5.7-.3l-3 3a4 4 0 105.7 5.7l1.3-1.3"/>'';
  icDl = svg ''<path d="M12 3v12"/><path d="M7 11l5 5 5-5"/><path d="M4 20h16"/>'';
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
    + ''<div><strong>${ym e.startDate} - ${ym (e.endDate or null)}</strong></div><div>${esc e.studyType}</div></div>'')
    data.education;
  certs = lib.concatMapStringsSep "" (c:
    ''<div class="item"><strong>${esc c.name}</strong><div class="muted">${esc c.issuer}</div><div class="muted">${esc c.date}</div></div>'')
    data.certificates;
  vols = lib.concatMapStringsSep "" (v:
    ''<div class="item"><strong>${esc v.organization}</strong><div>${esc v.position}</div>''
    + ''<div class="muted"><strong>${ym v.startDate} - ${ym (v.endDate or null)}</strong></div></div>'')
    data.volunteer;

  jobsHtml = lib.concatMapStringsSep "" (w:
    ''<div class="entry"><div class="erow"><span class="org">${esc w.name}</span>''
    + ''<span class="date">${ymRange w.startDate (w.endDate or null)}</span></div>''
    + ''<div class="pos">${esc w.position}</div>''
    + lib.optionalString (w ? url) ''<div class="urlrow">${icLink}<a href="${w.url}">${esc (stripScheme w.url)}</a></div>''
    + lib.optionalString (w.summary != "") "<p>${esc w.summary}</p>"
    + lib.optionalString (w.highlights != []) (sepLine w.highlights)
    + "</div>")
    jobs;

  projHtml = lib.concatMapStringsSep "" (p:
    ''<div class="entry"><div class="erow"><span class="org">${esc p.name}</span>''
    + ''<span class="date"><span class="urlrow">${icLink}<a href="${p.url}">${esc (stripScheme p.url)}</a></span></span></div>''
    + "<p>${esc p.description}</p>"
    + lib.optionalString (p ? keywords) (sepLine p.keywords)
    + "</div>")
    data.projects;
in
''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${esc b.name} — Résumé</title>
<style>
@font-face { font-family: "Inter"; src: url("assets/fonts/InterVariable.ttf") format("truetype-variations"); font-weight: 100 900; font-display: swap; }
:root {
  --bg: #f7f4ee; --surface: #ece5d8; --sel: #d2c8bd; --comment: #a89c90;
  --border: #6c5d52; --text: #51463e; --heading: #3b342f; --link: #1f5fa6;
}
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body { font-family: "Inter", Arial, "Liberation Sans", sans-serif; color: var(--text); font-size: 13px; line-height: 1.55; background: var(--bg); }
.ic { width: 14px; height: 14px; flex: 0 0 auto; vertical-align: -2px; }
.page { display: flex; align-items: stretch; min-height: 100vh; }
.sidebar { width: 33%; background: var(--surface); }
.head { background: var(--heading); color: var(--bg); padding: 28px 24px 22px; }
.photo { width: 96px; height: 96px; border-radius: 6px; object-fit: cover; display: block; margin-bottom: 14px; }
.head h1 { font-size: 23px; font-weight: 700; margin: 0; color: var(--bg); letter-spacing: .2px; }
.subtitle { font-size: 13px; color: var(--comment); margin: 3px 0 16px; }
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
.kw { color: var(--border); font-size: 10px; letter-spacing: .4px; text-transform: uppercase; margin-top: 5px; }
.kw .sep { color: var(--comment); }
.dl { position: fixed; top: 16px; right: 16px; display: inline-flex; align-items: center; gap: 7px; background: var(--heading); color: var(--bg); padding: 10px 16px; border-radius: 6px; text-decoration: none; font-size: 13px; box-shadow: 0 2px 8px rgba(0,0,0,.25); z-index: 10; }
.dl:hover { background: #2a2521; }
.dl .ic { color: var(--bg); }
@media print { .dl { display: none; } }
@media (max-width: 720px) { .page { flex-direction: column; } .sidebar, .main { width: 100%; } }
</style>
</head>
<body>
<a class="dl" href="resume.pdf" download>${icDl} Download PDF</a>
<div class="page">
  <aside class="sidebar">
    <div class="head">
      <img class="photo" src="assets/photo.png" alt="${esc b.name}" />
      <h1>${esc b.name}</h1>
      <div class="subtitle">Technology Executive</div>
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
</body>
</html>
''

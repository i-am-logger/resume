# Generates the HTML site (two-tone dark-header sidebar, matching the reference PDF) from resume.json.
{ lib, data }:
let
  b = data.basics;
  esc = s: lib.replaceStrings [ "&" "<" ">" ] [ "&amp;" "&lt;" "&gt;" ] (toString s);
  months = {
    "01" = "Jan"; "02" = "Feb"; "03" = "Mar"; "04" = "Apr"; "05" = "May"; "06" = "Jun";
    "07" = "Jul"; "08" = "Aug"; "09" = "Sep"; "10" = "Oct"; "11" = "Nov"; "12" = "Dec";
  };
  isBlank = d: d == null || d == "";
  ym = d: if isBlank d then "Current" else d; # show raw YYYY-MM like the reference
  ymRange = s: e: "${ym s} - ${ym e}";

  stripScheme = u: lib.removePrefix "https://" (lib.removePrefix "http://" u);
  phone = p: if lib.stringLength p == 10
    then "${lib.substring 0 3 p}-${lib.substring 3 3 p}-${lib.substring 6 4 p}" else p;

  jobs = lib.filter (w: w.name != "Israeli Air Force") data.work;

  # minimal, license-free inline SVG icons (stroke uses currentColor)
  svg = body: ''<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${body}</svg>'';
  icLoc = svg ''<path d="M12 21s7-7.5 7-12a7 7 0 10-14 0c0 4.5 7 12 7 12z"/><circle cx="12" cy="9" r="2.5"/>'';
  icPhone = svg ''<path d="M5 3h3.5l1.8 5-2.2 1.4a13 13 0 006.5 6.5l1.4-2.2 5 1.8V20a1.5 1.5 0 01-1.6 1.5C9.6 21 3 14.4 3 5.1 3 4 4 3 5 3z"/>'';
  icMail = svg ''<rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M3 6.5l9 6.5 9-6.5"/>'';
  icLink = svg ''<path d="M10 13.5a4 4 0 005.7.3l3-3a4 4 0 10-5.7-5.7l-1.3 1.3"/><path d="M14 10.5a4 4 0 00-5.7-.3l-3 3a4 4 0 105.7 5.7l1.3-1.3"/>'';
  icDl = svg ''<path d="M12 3v12"/><path d="M7 11l5 5 5-5"/><path d="M4 20h16"/>'';

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
    + lib.optionalString (w.highlights != [])
      (''<div class="kw">'' + lib.concatStringsSep " | " (map esc w.highlights) + "</div>")
    + "</div>")
    jobs;

  projHtml = lib.concatMapStringsSep "" (p:
    ''<div class="entry"><div class="erow"><span class="org">${esc p.name}</span>''
    + ''<span class="date"><span class="urlrow">${icLink}<a href="${p.url}">${esc (stripScheme p.url)}</a></span></span></div>''
    + "<p>${esc p.description}</p>"
    + lib.optionalString (p ? keywords) (''<div class="kw">'' + lib.concatStringsSep " | " (map esc p.keywords) + "</div>")
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
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body { font-family: Arial, "Liberation Sans", Helvetica, sans-serif; color: #2b2b2b; font-size: 13px; line-height: 1.5; background: #fff; }
.ic { width: 14px; height: 14px; flex: 0 0 auto; vertical-align: -2px; }
.page { display: flex; align-items: stretch; min-height: 100vh; }
.sidebar { width: 33%; background: #eceef0; }
.head { background: #46535f; color: #eef2f5; padding: 28px 24px 22px; }
.photo { width: 96px; height: 96px; border-radius: 6px; object-fit: cover; display: block; margin-bottom: 14px; }
.head h1 { font-size: 23px; font-weight: 700; margin: 0; color: #fff; letter-spacing: .2px; }
.subtitle { font-size: 13px; color: #b9c3cd; margin: 3px 0 16px; }
.contact div { display: flex; align-items: center; gap: 9px; font-size: 12px; margin: 6px 0; color: #d7dde3; }
.contact .ic { color: #aab4be; }
.contact a { color: #cfd7df; text-decoration: underline; }
.sections { padding: 18px 24px 26px; }
.sections h2 { font-size: 14px; font-weight: 700; color: #2b2b2b; border-bottom: 1px solid #c4c8cc; padding-bottom: 4px; margin: 16px 0 8px; }
.sections h2:first-child { margin-top: 0; }
.item { margin-bottom: 9px; font-size: 12.5px; line-height: 1.45; }
.muted { color: #5a5f64; }
.chips { display: flex; flex-wrap: wrap; gap: 5px; }
.chip { background: #dde1e5; color: #3a4654; border-radius: 4px; padding: 2px 8px; font-size: 11.5px; }
.main { flex: 1; padding: 28px 34px 34px; min-width: 0; }
.summary { margin: 0 0 6px; font-size: 13px; }
.main h3 { font-size: 16px; font-weight: 700; color: #2b2b2b; border-bottom: 1.5px solid #2b2b2b; padding-bottom: 4px; margin: 22px 0 12px; }
.entry { margin-bottom: 14px; }
.erow { display: flex; justify-content: space-between; align-items: baseline; gap: 14px; }
.org { font-weight: 700; font-size: 14.5px; }
.date { color: #555; font-size: 12px; white-space: nowrap; }
.pos { color: #3a4654; font-size: 12.5px; margin-top: 1px; }
.urlrow { display: inline-flex; align-items: center; gap: 5px; font-size: 11.5px; }
.urlrow .ic { width: 12px; height: 12px; color: #6a7682; }
a { color: #3a4654; text-decoration: none; }
.urlrow a { text-decoration: underline; }
.entry p { margin: 5px 0; font-size: 12.5px; }
.entry ul { margin: 5px 0; padding-left: 18px; font-size: 12.5px; }
.entry li { margin: 1px 0; }
.kw { color: #5a5f64; font-size: 11.5px; margin-top: 2px; }
.dl { position: fixed; top: 16px; right: 16px; display: inline-flex; align-items: center; gap: 7px; background: #46535f; color: #fff; padding: 10px 16px; border-radius: 6px; text-decoration: none; font-size: 13px; box-shadow: 0 2px 8px rgba(0,0,0,.25); z-index: 10; }
.dl:hover { background: #36414b; }
.dl .ic { color: #fff; }
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

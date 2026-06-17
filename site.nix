# Generates the HTML site (dark-sidebar, matching resume.typ / the PDF) from resume.json.
{ lib, data }:
let
  b = data.basics;
  esc = s: lib.replaceStrings [ "&" "<" ">" ] [ "&amp;" "&lt;" "&gt;" ] (toString s);
  months = {
    "01" = "Jan"; "02" = "Feb"; "03" = "Mar"; "04" = "Apr"; "05" = "May"; "06" = "Jun";
    "07" = "Jul"; "08" = "Aug"; "09" = "Sep"; "10" = "Oct"; "11" = "Nov"; "12" = "Dec";
  };
  isBlank = d: d == null || d == "";
  yr = d: if isBlank d then "Present" else lib.elemAt (lib.splitString "-" d) 0;
  monYr = d:
    if isBlank d then "Present"
    else let p = lib.splitString "-" d; in
      if lib.length p >= 2 then "${months.${lib.elemAt p 1}} ${lib.elemAt p 0}" else lib.elemAt p 0;
  span = s: e: "${monYr s} – ${monYr e}";
  yspan = s: e: "${yr s} – ${yr e}";
  stripUrl = u: lib.removePrefix "https://" (lib.removePrefix "https://github.com/" u);
  phone = p: if lib.stringLength p == 10
    then "(${lib.substring 0 3 p}) ${lib.substring 3 3 p}-${lib.substring 6 4 p}" else p;
  ic = n: ''<i class="fa-solid fa-${n}"></i>'';

  jobs = lib.filter (w: w.name != "Israeli Air Force") data.work;
  mil = lib.filter (w: w.name == "Israeli Air Force") data.work;

  skills = lib.concatMapStringsSep "" (s: "<li>${esc s.name}</li>") data.skills;
  langs = lib.concatMapStringsSep "" (l:
    ''<div class="item"><strong>${esc l.language}</strong> — <span class="muted">${esc l.fluency}</span></div>'')
    data.languages;
  edu = lib.concatMapStringsSep "" (e:
    ''<div class="item"><strong>${esc e.studyType}, ${esc e.area}</strong><div>${esc e.institution}</div>''
    + ''<div class="muted">${yspan e.startDate (e.endDate or null)}''
    + lib.optionalString (e ? score && e.score != "") " · ${esc e.score}" + "</div></div>")
    data.education;
  milHtml = lib.concatMapStringsSep "" (m:
    ''<div class="item"><strong>${esc m.name}</strong><div>${esc m.position}</div>''
    + ''<div class="muted">${yspan m.startDate (m.endDate or null)} · Israel</div></div>'')
    mil;
  certs = lib.concatMapStringsSep "" (c:
    ''<div class="item"><strong>${esc c.name}</strong><div class="muted">${esc c.issuer} · ${yr c.date}</div></div>'')
    data.certificates;
  vols = lib.concatMapStringsSep "" (v:
    ''<div class="item"><strong>${esc v.organization}</strong><div>${esc v.position}</div>''
    + ''<div class="muted">${yspan v.startDate (v.endDate or null)}</div></div>'')
    data.volunteer;

  jobsHtml = lib.concatMapStringsSep "" (w:
    ''<div class="entry"><div class="erow"><span class="org">${esc w.name}</span>''
    + ''<span class="date">${span w.startDate (w.endDate or null)}</span></div>''
    + ''<div class="pos">${esc w.position}''
    + lib.optionalString (w ? url) '' <a href="${w.url}">${esc (stripUrl w.url)}</a>'' + "</div>"
    + lib.optionalString (w.summary != "") "<p>${esc w.summary}</p>"
    + lib.optionalString (w.highlights != [])
      ("<ul>" + lib.concatMapStrings (h: "<li>${esc h}</li>") w.highlights + "</ul>")
    + "</div>")
    jobs;

  projHtml = lib.concatMapStringsSep "" (p:
    ''<div class="entry"><div class="erow"><span class="org">${esc p.name}</span>''
    + ''<span class="date"><a href="${p.url}">${esc (stripUrl p.url)}</a></span></div>''
    + "<p>${esc p.description}</p>"
    + lib.optionalString (p ? keywords)
      (''<div class="kw">'' + lib.concatStringsSep "  ·  " (map esc p.keywords) + "</div>")
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
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" />
<style>
* { box-sizing: border-box; }
html, body { margin: 0; }
body { font-family: "Liberation Sans", Arial, Helvetica, sans-serif; color: #2c2c2c; font-size: 13px; line-height: 1.5; background: #e9ecef; }
.page { display: flex; min-height: 100vh; max-width: 1000px; margin: 0 auto; background: #fff; box-shadow: 0 0 24px rgba(0,0,0,.12); }
.sidebar { width: 33%; background: #3a4654; color: #e9edf2; padding: 30px 22px; }
.main { flex: 1; padding: 30px 32px; }
.photo { width: 132px; height: 132px; border-radius: 50%; object-fit: cover; display: block; margin: 0 auto 12px; border: 2px solid #dfe6ee; }
.sidebar h1 { text-align: center; font-size: 23px; margin: 0; color: #fff; }
.subtitle { text-align: center; color: #aeb8c4; font-size: 12px; margin: 2px 0 16px; }
.contact div { font-size: 12px; margin: 5px 0; }
.contact i { color: #aeb8c4; width: 16px; text-align: center; }
.sidebar h2 { font-size: 11px; letter-spacing: 1.3px; text-transform: uppercase; color: #cdd5df; border-bottom: 1px solid #586676; padding-bottom: 3px; margin: 17px 0 8px; }
.sidebar .item { margin-bottom: 7px; font-size: 12px; }
.sidebar .muted { color: #aeb8c4; }
ul.skills { list-style: none; padding: 0; margin: 0; }
ul.skills li { font-size: 12px; padding: 1px 0; }
.main h3 { color: #3a4654; font-size: 18px; border-bottom: 1.5px solid #3a4654; padding-bottom: 3px; margin: 20px 0 10px; }
.summary { margin: 0; }
.entry { margin-bottom: 13px; }
.erow { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; }
.org { font-weight: bold; font-size: 15px; }
.date { color: #5c5c5c; font-size: 12px; white-space: nowrap; }
.pos { color: #3a4654; font-size: 12.5px; }
.pos a, .date a, .contact a { color: inherit; text-decoration: none; }
.entry p { margin: 3px 0; font-size: 12.5px; }
.entry ul { margin: 3px 0; padding-left: 18px; font-size: 12px; }
.kw { color: #5c5c5c; font-size: 11.5px; }
.dl { position: fixed; top: 16px; right: 16px; background: #3a4654; color: #fff; padding: 10px 16px; border-radius: 6px; text-decoration: none; font-size: 13px; box-shadow: 0 2px 8px rgba(0,0,0,.25); z-index: 10; }
.dl:hover { background: #2c3540; }
@media print { .dl { display: none; } .page { box-shadow: none; max-width: none; } body { background: #fff; } }
</style>
</head>
<body>
<a class="dl" href="resume.pdf" download><i class="fa-solid fa-download"></i> Download PDF</a>
<div class="page">
  <aside class="sidebar">
    <img class="photo" src="assets/photo.png" alt="${esc b.name}" />
    <h1>${esc b.name}</h1>
    <div class="subtitle">Technology Executive</div>
    <div class="contact">
      <div>${ic "location-dot"} ${esc b.location.city}, United States</div>
      <div>${ic "phone"} ${phone b.phone}</div>
      <div>${ic "envelope"} <a href="mailto:${b.email}">${esc b.email}</a></div>
    </div>
    <h2>Skills</h2><ul class="skills">${skills}</ul>
    <h2>Languages</h2>${langs}
    <h2>Education</h2>${edu}
    ${lib.optionalString (mil != []) "<h2>Military Service</h2>${milHtml}"}
    <h2>Certifications</h2>${certs}
    <h2>Volunteering</h2>${vols}
  </aside>
  <main class="main">
    <p class="summary">${esc b.summary}</p>
    <h3>Experience</h3>
    ${jobsHtml}
    <h3>Open Source Projects</h3>
    ${projHtml}
  </main>
</div>
</body>
</html>
''

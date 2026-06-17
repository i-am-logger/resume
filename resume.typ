// Custom dark-sidebar résumé theme — reads resume.json, renders to print-perfect PDF.
#import "@preview/fontawesome:0.6.0": *
#let data = json("resume.json")
#let b = data.basics

// ---- palette ----
#let slate     = rgb("#3a4654")
#let side-fg   = rgb("#e9edf2")
#let side-muted= rgb("#aeb8c4")
#let side-head = rgb("#cdd5df")
#let side-rule = rgb("#586676")
#let ink       = rgb("#2c2c2c")
#let ink-muted = rgb("#5c5c5c")
#let accent    = rgb("#3a4654")

// ---- geometry ----
#let side-w    = 2.55in
#let side-pad  = 0.27in
#let body-left = 2.85in

#set document(title: b.name + " — Résumé", author: b.name)
#set page(
  paper: "us-letter",
  margin: (left: body-left, right: 0.5in, top: 0.5in, bottom: 0.45in),
  background: place(left + top, rect(width: side-w, height: 100%, fill: slate)),
)
#set text(font: ("Liberation Sans", "DejaVu Sans"), size: 9.5pt, fill: ink)
#set par(justify: false, leading: 0.6em)

// ---- helpers ----
#let months = (
  "01": "Jan", "02": "Feb", "03": "Mar", "04": "Apr", "05": "May", "06": "Jun",
  "07": "Jul", "08": "Aug", "09": "Sep", "10": "Oct", "11": "Nov", "12": "Dec",
)
#let yr(d) = if d == none or d == "" { "Present" } else { d.split("-").at(0) }
#let mon-yr(d) = {
  if d == none or d == "" { return "Present" }
  let p = d.split("-")
  if p.len() >= 2 { months.at(p.at(1), default: "") + " " + p.at(0) } else { p.at(0) }
}
#let span(s, e) = mon-yr(s) + " – " + (if e == none or e == "" { "Present" } else { mon-yr(e) })
#let yspan(s, e) = yr(s) + " – " + yr(e)
#let phone(p) = if p.len() == 10 { "(" + p.slice(0, 3) + ") " + p.slice(3, 6) + "-" + p.slice(6, 10) } else { p }
#let gh(u) = u.replace("https://github.com/", "").replace("https://", "")

// sidebar section heading
#let s-head(t) = {
  v(6pt)
  text(fill: side-head, weight: "bold", size: 8.3pt, tracking: 1.1pt)[#upper(t)]
  v(1.5pt)
  line(length: 100%, stroke: 0.5pt + side-rule)
  v(2.5pt)
}
// main section heading
#let m-head(t) = {
  v(6pt)
  text(fill: accent, weight: "bold", size: 12.5pt)[#t]
  v(1pt)
  line(length: 100%, stroke: 0.8pt + accent)
  v(5pt)
}

// split the Israeli Air Force entry out of work into Military Service
#let mil  = data.work.filter(w => w.name == "Israeli Air Force")
#let jobs = data.work.filter(w => w.name != "Israeli Air Force")

// ============================ SIDEBAR ============================
#place(top + left, dx: -body-left + side-pad, dy: 0pt, block(width: side-w - 2 * side-pad, {
  set text(fill: side-fg, size: 8.3pt)
  set par(leading: 0.45em)

  align(center, box(clip: true, radius: 50%, stroke: 2pt + rgb("#dfe6ee"),
    image("assets/photo.png", width: 1.2in, height: 1.2in, fit: "cover")))
  v(6pt)
  align(center, text(size: 15pt, weight: "bold", fill: white)[#b.name])
  v(1pt)
  align(center, text(size: 8.6pt, fill: side-muted)[Technology Executive])
  v(5pt)

  set text(size: 8pt)
  stack(spacing: 4pt,
    [#box(width: 11pt)[#text(fill: side-muted)[#fa-icon("location-dot")]]#(b.location.city + ", United States")],
    [#box(width: 11pt)[#text(fill: side-muted)[#fa-icon("phone")]]#phone(b.phone)],
    [#box(width: 11pt)[#text(fill: side-muted)[#fa-icon("envelope")]]#link("mailto:" + b.email)[#text(fill: side-fg)[#b.email]]],
  )

  s-head("Skills")
  for s in data.skills { box(s.name); linebreak() }

  s-head("Languages")
  for l in data.languages { [*#l.language* — #text(fill: side-muted)[#l.fluency]]; linebreak() }

  s-head("Education")
  for e in data.education {
    text(weight: "bold")[#e.studyType, #e.area]; linebreak()
    [#e.institution]; linebreak()
    text(fill: side-muted)[#yspan(e.startDate, e.endDate)]
    if "score" in e and e.score != "" { text(fill: side-muted)[ · #e.score] }
    v(1pt)
  }

  if mil.len() > 0 {
    s-head("Military Service")
    for m in mil {
      text(weight: "bold")[#m.name]; linebreak()
      [#m.position]; linebreak()
      text(fill: side-muted)[#yspan(m.startDate, m.endDate) · Israel]
    }
  }

  s-head("Certifications")
  for c in data.certificates {
    text(weight: "bold")[#c.name]; linebreak()
    text(fill: side-muted)[#c.issuer · #yr(c.date)]
    v(1pt)
  }

  s-head("Volunteering")
  for vo in data.volunteer {
    text(weight: "bold")[#vo.organization]; linebreak()
    [#vo.position]; linebreak()
    text(fill: side-muted)[#yspan(vo.startDate, vo.at("endDate", default: none))]
    v(1pt)
  }
}))

// ============================ MAIN ============================
#text(size: 9pt)[#b.summary]

#m-head("Experience")
#for w in jobs {
  grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
    text(weight: "bold", size: 10.5pt)[#w.name],
    text(fill: ink-muted, size: 8.3pt)[#span(w.startDate, w.at("endDate", default: none))],
  )
  text(fill: accent, size: 8.8pt)[#w.position]
  if "url" in w { text(size: 7.6pt)[  #link(w.url)[#text(fill: ink-muted)[#gh(w.url)]]] }
  if w.summary != "" { linebreak(); text(size: 8.7pt)[#w.summary] }
  if w.highlights.len() > 0 {
    set text(size: 8.2pt)
    list(..w.highlights)
  }
  v(6pt)
}

#m-head("Open Source Projects")
#for p in data.projects {
  grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
    text(weight: "bold", size: 10.5pt)[#p.name],
    text(size: 7.6pt)[#link(p.url)[#text(fill: accent)[#gh(p.url)]]],
  )
  text(size: 8.7pt)[#p.description]
  if "keywords" in p { linebreak(); text(fill: ink-muted, size: 7.8pt)[#p.keywords.join("   ·   ")] }
  v(6pt)
}

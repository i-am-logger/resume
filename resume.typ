// Custom two-tone dark-header sidebar résumé theme — reads resume.json, renders a print-perfect PDF.
// Grid layout so the sidebar can flow onto page 2 (the grey background persists across pages).
#import "@preview/fontawesome:0.6.0": *
#let data = json("resume.json")
#let b = data.basics

// ---- palette ----
#let slate    = rgb("#46535f")   // dark header band
#let side-bg  = rgb("#eceef0")   // light sidebar section area
#let side-fg  = rgb("#eef2f5")
#let side-mut = rgb("#b9c3cd")
#let con-fg   = rgb("#d7dde3")
#let con-ic   = rgb("#aab4be")
#let ink      = rgb("#2b2b2b")
#let ink-mut  = rgb("#5a5f64")
#let accent   = rgb("#3a4654")
#let rule-c   = rgb("#c4c8cc")
#let chip-bg  = rgb("#dde1e5")

// ---- geometry ----
#let side-w   = 2.55in
#let side-pad = 0.26in
#let top-m    = 0.32in

#set document(title: b.name + " — Résumé", author: b.name)
#set page(
  paper: "us-letter",
  margin: (top: top-m, bottom: top-m, left: 0pt, right: 0pt),
  background: place(left + top, rect(width: side-w, height: 100%, fill: side-bg)),
)
#set text(font: ("Liberation Sans", "DejaVu Sans"), size: 9.5pt, fill: ink)
#set par(justify: false, leading: 0.6em)

// ---- helpers ----
#let raw(d) = if d == none or d == "" { "Current" } else { d }
#let yspan(s, e) = (if s == none { "" } else { s.split("-").at(0) }) + " - " + (if e == none or e == "" { "Current" } else { e.split("-").at(0) })
#let rspan(s, e) = raw(s) + " - " + raw(e)
#let ym(d) = if d == none or d == "" { "" } else { let p = d.split("-"); if p.len() >= 2 { p.at(0) + "-" + p.at(1) } else { d } }
#let phoneFmt(p) = if p.len() == 10 { p.slice(0, 3) + "-" + p.slice(3, 6) + "-" + p.slice(6, 10) } else { p }
#let stripScheme(u) = u.replace("https://", "").replace("http://", "")

#let s-head(t) = {
  v(7pt)
  text(fill: ink, weight: "bold", size: 9.5pt)[#t]
  v(1.5pt)
  line(length: 100%, stroke: 0.6pt + rule-c)
  v(2.5pt)
}
#let m-head(t) = {
  v(6pt)
  text(fill: ink, weight: "bold", size: 13pt)[#t]
  v(1pt)
  line(length: 100%, stroke: 1pt + ink)
  v(5pt)
}
#let chip(t) = box(fill: chip-bg, inset: (x: 5pt, y: 1.5pt), outset: (y: 1.5pt), radius: 3pt,
  text(fill: accent, size: 7.8pt)[#t])
#let urlIcon(u) = [#text(fill: con-ic, size: 7pt)[#fa-icon("link")] #text(size: 7.6pt)[#link(u)[#text(fill: accent)[#stripScheme(u)]]]]

#let jobs = data.work.filter(w => w.name != "Israeli Air Force")

#grid(
  columns: (side-w, 1fr),
  column-gutter: 0.3in,

  // ============================ SIDEBAR ============================
  {
    // ---- dark header band (bleeds to the page top via outset) ----
    block(width: 100%, fill: slate, outset: (top: top-m), inset: (x: side-pad, top: 0.16in, bottom: 0.14in), {
      set text(fill: side-fg)
      set par(leading: 0.5em)
      box(clip: true, radius: 6pt, image("assets/photo.png", width: 0.82in, height: 0.82in, fit: "cover"))
      v(7pt)
      text(size: 14pt, weight: "bold", fill: white)[#b.name]
      v(2pt)
      text(size: 8.8pt, fill: side-mut)[Technology Executive]
      v(7pt)
      set text(size: 8.2pt, fill: con-fg)
      stack(spacing: 3.5pt,
        [#box(width: 12pt)[#text(fill: con-ic)[#fa-icon("location-dot")]]#b.location.address],
        [#box(width: 12pt)[#text(fill: con-ic)[#fa-icon("phone")]]#phoneFmt(b.phone)],
        [#box(width: 12pt)[#text(fill: con-ic)[#fa-icon("envelope")]]#link("mailto:" + b.email)[#text(fill: con-fg)[#b.email]]],
      )
    })
    // ---- light section area ----
    block(width: 100%, inset: (x: side-pad, top: 0.06in, bottom: 0.2in), {
      set text(fill: ink, size: 8pt)
      set par(leading: 0.46em)

      s-head("Skills")
      box(for s in data.skills { chip(s.name); [ ] })

      s-head("Languages")
      for l in data.languages { [*#l.language* \ #text(fill: ink-mut)[#l.fluency]]; v(2pt) }

      s-head("Education")
      for e in data.education {
        text(weight: "bold")[#e.institution]; linebreak()
        [#e.area]; linebreak()
        if "score" in e and e.score != "" { [#e.score]; linebreak() }
        text(weight: "bold")[#yspan(e.startDate, e.endDate)]; linebreak()
        [#e.studyType]
        v(2pt)
      }

      s-head("Military Service")
      text(weight: "bold")[Air Force]; linebreak()
      [sergeant]; linebreak()
      text(weight: "bold")[1994 - 1997]; linebreak()
      [Israel]; linebreak()
      [Light Helicopter Technician]
      v(2pt)

      s-head("Certifications")
      for c in data.certificates {
        text(weight: "bold")[#c.name]; linebreak()
        text(fill: ink-mut)[#c.issuer]; linebreak()
        text(fill: ink-mut)[#ym(c.date)]
        v(2pt)
      }

      s-head("Volunteering")
      for vo in data.volunteer {
        text(weight: "bold")[#vo.organization]; linebreak()
        [#vo.position]; linebreak()
        text(fill: ink-mut, weight: "bold")[#rspan(vo.startDate, vo.at("endDate", default: none))]
        v(2pt)
      }
    })
  },

  // ============================ MAIN ============================
  block(inset: (right: 0.5in, top: 0.04in), {
    text(size: 9pt)[#b.summary]

    m-head("Open Source Projects")
    for p in data.projects {
      grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
        text(weight: "bold", size: 11pt)[#p.name],
        urlIcon(p.url),
      )
      text(size: 8.8pt)[#p.description]
      if "keywords" in p { linebreak(); text(fill: ink-mut, size: 7.8pt)[#p.keywords.join(" · ")] }
      v(6pt)
    }

    m-head("Experience")
    for w in jobs {
      grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
        text(weight: "bold", size: 11pt)[#w.name],
        text(fill: ink-mut, size: 8.3pt)[#rspan(w.startDate, w.at("endDate", default: none))],
      )
      text(fill: accent, size: 8.8pt)[#w.position]
      if "url" in w { linebreak(); urlIcon(w.url) }
      if w.summary != "" { linebreak(); text(size: 8.8pt)[#w.summary] }
      if w.highlights.len() > 0 { linebreak(); text(fill: ink-mut, size: 7.8pt)[#w.highlights.join(" · ")] }
      v(7pt)
    }
  }),
)

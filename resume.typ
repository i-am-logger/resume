// Custom two-tone résumé theme — reads resume.json, renders a print-perfect PDF.
// Colours: vogix16 "yoga" palette (day), applied semantically — monochromatic base for
// structure, the functional `link` colour (base0D) only for clickable links.
// Grid layout so the sidebar can flow onto page 2 (the surface background persists).
#import "@preview/fontawesome:0.6.0": *
#let data = json("resume.json")
#let b = data.basics

// ---- vogix16 "yoga" (day) ----
#let c-bg      = rgb("#f7f4ee")  // base00 background
#let c-surface = rgb("#ece5d8")  // base01 surface (sidebar sections)
#let c-sel     = rgb("#d2c8bd")  // base02 selection (chips)
#let c-comment = rgb("#a89c90")  // base03 comment (muted: dates, separators)
#let c-border  = rgb("#6c5d52")  // base04 border (rules, secondary text)
#let c-text    = rgb("#51463e")  // base05 text
#let c-heading = rgb("#3b342f")  // base06 heading (+ dark header band)
#let c-link    = rgb("#1f5fa6")  // base0D link  (the one functional accent)

// ---- geometry ----
#let side-w   = 2.55in
#let side-pad = 0.26in
#let top-m    = 0.32in

#set document(title: b.name + " — Résumé", author: b.name)
#set page(
  paper: "us-letter",
  fill: c-bg,
  margin: (top: top-m, bottom: top-m, left: 0pt, right: 0pt),
  background: place(left + top, rect(width: side-w, height: 100%, fill: c-surface)),
)
#set text(font: ("Inter", "Liberation Sans", "DejaVu Sans"), size: 9.5pt, fill: c-text)
#set par(justify: true, leading: 0.62em)

// ---- helpers ----
#let raw(d) = if d == none or d == "" { "Current" } else { d }
#let yspan(s, e) = (if s == none { "" } else { s.split("-").at(0) }) + " - " + (if e == none or e == "" { "Current" } else { e.split("-").at(0) })
#let rspan(s, e) = raw(s) + " - " + raw(e)
#let ym(d) = if d == none or d == "" { "" } else { let p = d.split("-"); if p.len() >= 2 { p.at(0) + "-" + p.at(1) } else { d } }
#let phoneFmt(p) = if p.len() == 10 { p.slice(0, 3) + "-" + p.slice(3, 6) + "-" + p.slice(6, 10) } else { p }
#let stripScheme(u) = u.replace("https://", "").replace("http://", "")

#let s-head(t) = {
  v(8pt)
  text(fill: c-heading, weight: "bold", size: 9.5pt)[#t]
  v(1.5pt)
  line(length: 100%, stroke: 0.6pt + c-border)
  v(3pt)
}
#let m-head(t) = {
  v(9pt)
  text(fill: c-heading, weight: "bold", size: 13pt)[#t]
  v(1pt)
  line(length: 100%, stroke: 1pt + c-heading)
  v(6pt)
}
#let chip(t) = box(fill: c-sel, inset: (x: 5pt, y: 1.5pt), outset: (y: 1.5pt), radius: 3pt,
  text(fill: c-heading, size: 7.8pt)[#t])
// Uppercase keyword/highlight line, muted separators — shared by projects + experience.
#let sepline(items) = items.map(x => text(fill: c-border, size: 6.5pt, tracking: 0.2pt)[#upper(x)]).join(text(fill: c-comment, size: 6.5pt)[ | ])
#let urlIcon(u) = [#text(fill: c-link, size: 7pt)[#fa-icon("link")] #text(size: 7.6pt)[#link(u)[#text(fill: c-link)[#stripScheme(u)]]]]
#let langIcon(l) = box(baseline: 1.5pt, image("assets/lang-" + lower(l) + ".svg", height: 6.5pt))
#let projCard(p) = block(breakable: false, width: 100%, fill: c-surface, stroke: 0.7pt + rgb("#dcd4c8"), radius: 5pt, inset: (x: 10pt, y: 8pt), {
  set par(justify: false, leading: 0.5em)
  text(weight: "bold", size: 10.5pt, fill: c-heading)[#p.name]
  v(3pt)
  text(size: 8.3pt, fill: c-text)[#p.description]
  v(5pt)
  text(size: 6.5pt, fill: c-comment, tracking: 0.2pt)[#for l in p.languages [#langIcon(l) #upper(l)#h(8pt)]★ #p.stars#h(8pt)#upper(p.loc)#if "tests" in p [#h(8pt)#upper(p.tests)]]
  v(4pt)
  text(size: 6.8pt)[#link(p.url)[#text(fill: c-link)[#fa-icon("github") #stripScheme(p.url)]]#if "demo" in p [\ #link(p.demo)[#text(fill: c-link)[#fa-icon("arrow-up-right-from-square") #stripScheme(p.demo)]]]]
})

#let jobs = data.work.filter(w => w.name != "Israeli Air Force")

#grid(
  columns: (side-w, 1fr),
  column-gutter: 0.3in,

  // ============================ SIDEBAR ============================
  {
    set par(justify: false)
    // ---- dark header band (bleeds to the page top via outset) ----
    block(width: 100%, fill: c-heading, outset: (top: top-m), inset: (x: side-pad, top: 0.16in, bottom: 0.14in), {
      set text(fill: c-bg)
      set par(leading: 0.5em)
      box(clip: true, radius: 6pt, image("assets/photo.png", width: 0.82in, height: 0.82in, fit: "cover"))
      v(7pt)
      text(size: 14pt, weight: "bold", fill: c-bg)[#b.name]
      v(2pt)
      text(size: 8.8pt, fill: c-comment)[Technology Executive]
      v(7pt)
      set text(size: 8.2pt, fill: c-surface)
      stack(spacing: 3.5pt,
        [#box(width: 12pt)[#text(fill: c-comment)[#fa-icon("location-dot")]]#b.location.address],
        [#box(width: 12pt)[#text(fill: c-comment)[#fa-icon("phone")]]#phoneFmt(b.phone)],
        [#box(width: 12pt)[#text(fill: c-comment)[#fa-icon("envelope")]]#link("mailto:" + b.email)[#text(fill: c-surface)[#b.email]]],
        ..b.at("profiles", default: ()).map(p => [#box(width: 12pt)[#text(fill: c-comment)[#fa-icon(lower(p.network))]]#link(p.url)[#text(fill: c-surface)[#stripScheme(p.url)]]]),
      )
    })
    // ---- light section area ----
    block(width: 100%, inset: (x: side-pad, top: 0.06in, bottom: 0.2in), {
      set text(fill: c-text, size: 8pt)
      set par(leading: 0.46em)

      s-head("Skills")
      box(for s in data.skills { chip(s.name); [ ] })

      s-head("Languages")
      for l in data.languages { [*#l.language* \ #text(fill: c-comment)[#l.fluency]]; v(2pt) }

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
        text(fill: c-comment)[#c.issuer]; linebreak()
        text(fill: c-comment)[#ym(c.date)]
        v(2pt)
      }

      s-head("Volunteering")
      for vo in data.volunteer {
        text(weight: "bold")[#vo.organization]; linebreak()
        [#vo.position]; linebreak()
        text(fill: c-comment, weight: "bold")[#rspan(vo.startDate, vo.at("endDate", default: none))]
        v(2pt)
      }
    })
  },

  // ============================ MAIN ============================
  block(inset: (right: 0.5in, top: 0.04in), {
    text(size: 9pt)[#b.summary]

    m-head("Open Source Projects")
    grid(columns: (1fr, 1fr), column-gutter: 8pt, row-gutter: 8pt,
      ..data.projects.map(p => projCard(p)))
    v(2pt)

    m-head("Experience")
    for w in jobs {
      grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
        text(weight: "bold", size: 11pt, fill: c-heading)[#w.name],
        text(fill: c-comment, size: 8.3pt)[#rspan(w.startDate, w.at("endDate", default: none))],
      )
      text(fill: c-border, size: 8.8pt)[#w.position]
      if "url" in w { linebreak(); urlIcon(w.url) }
      if w.summary != "" { linebreak(); text(size: 8.8pt)[#w.summary] }
      if w.highlights.len() > 0 { linebreak(); v(1pt); sepline(w.highlights) }
      v(9pt)
    }
  }),
)

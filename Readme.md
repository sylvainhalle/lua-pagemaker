lua-pagemaker: Magazine-Style Page Layouts in Pure LaTeX
======================================================

**Did you know you can reproduce an IEEE *Spectrum*-style page layout in pure LaTeX?**

`lua-pagemaker` is a lightweight Lua-driven layout engine for LaTeX, built on top of the excellent but notoriously rigid `flowfram` package. Its purpose is simple:

> Bring LaTeX closer to Adobe InDesign or Aldus PageMaker  
> while preserving the simplicity and portability of TeX.

With a small declarative DSL written in Lua, you can describe page geometry, arbitrary column structures (including variable-width columns), and static boxes such as figures, banners, pull quotes, or sidebars. During compilation, Lua computes all frame coordinates and emits the corresponding `flowfram` primitives.

The result:

- multi-column layouts (per page, with variable widths)
- figures spanning multiple columns
- top banners, sidebars, bottom callouts
- decorative rules drawn with TikZ
- predictable geometry
- pure LaTeX + LuaLaTeX, no external tools

## Example: an IEEE *Spectrum*-like page

The repository includes an example very close to a pixel-perfect reproduction of a layout from the [*IEEE Spectrum* magazine](https://spectrum.ieee.org/magazine/2025/december/).

[![Screenshot](Example/Preview.jpg?raw=true)](Example/paper.pdf)

You can generate pages containing:

- a hero image
- a large pull-quote
- columns of different widths
- bottom-aligned figures
- decorative horizontal and vertical rules

*(Screenshot placeholder: e.g. `fig/spectrum-example.png`.)*


## Core Ideas

### Declarative page layouts (in Lua)

Each page is described in `pages.lua` as a clean, readable structure:

- global page geometry  
- a list of pages  
- each page defines:
  - its own **columns** (with arbitrary fractional widths)
  - optional **static boxes**
  - optional **decorative borders**

The system encourages thinking like a magazine designer: columns, blocks, banners, sidebars — not TeX primitives.

### Static frames and flow frames

`lua-pagemaker` distinguishes two categories:

**Flow frames**  
Where your normal body text goes.  
Each column is automatically clipped above and below to avoid overlapping static boxes.

**Static frames**  
Reserved space for:

- hero images  
- banners  
- sidebars  
- bottom boxes  
- pull quotes  

Static frames can be anchored:

- at the top (`top = ...`)
- or the bottom (`bottom = ...`)
- and can span any range of columns (`colfrom`–`colto`)

Static boxes may also specify:

- `image = "foo.png"` → height computed from aspect ratio  
- `valign = "t" | "c" | "b"` → vertical alignment inside the box  

### Coordinates in screen space

Coordinates are given in an intuitive system:

- origin = top-left of the text block
- *x* grows to the right
- *y* grows downward

This mirrors CSS, SVG, and GUI toolkits.  
`layout.lua` converts to TeX’s bottom-left–based coordinates automatically.

### Works with any class or page size

You specify:

```lua
width  = 7.88,
height = 10.5,
left   = 0.5,
right  = 0.5,
top    = 0.75,
bottom = 1.0,
colsep = 0.25,
```

`lua-pagemaker` computes the text block and uses it as the reference system for all coordinates.

## Features

- Per-page column definitions  
- Arbitrary (fractional) column widths  
- Static boxes spanning multiple columns  
- Image-based automatic box height  
- Simple DSL for decorative rules (`hline_left`, `hline_right`, `vline_left`, `vline_right`)  
- TikZ overlay for line drawing  
- Coordinates in inches  
- Lua-based preprocessing for predictable TeX output  


## How It Works

The system uses three components.

### 1. `pages.lua` — Declarative layout description

This file does **not** contain logic.  
It receives a DSL table (`dsl`) and returns a configuration table.

Example (simplified):

```lua
return function(dsl)
  local hline_right = dsl.hline_right
  local vline_right = dsl.vline_right

  local config = {
    width  = 7.88,
    height = 10.5,
    top    = 0.75,
    bottom = 1.0,
    left   = 0.5,
    right  = 0.5,
    colsep = 0.25,
    pages  = {}
  }

  local H = config.height
  local T = config.top
  local B = config.bottom

  config.pages[1] = {
    columns = {
      { width = 1/2 },
      { width = 1/2 }
    },
    boxes = {
      {
        name    = "hero",
        colfrom = 1, colto = 2,
        top     = 0,
        h       = 5.5
      }
    },
    borders = {
      hline_right(0.6),
      vline_right(1.5, 0)
    }
  }

  return config
end
```

### 2. `layout.lua` — Geometry engine

This script:

- creates the DSL helpers (`hline_right`, `vline_left`, etc.)
- loads and evaluates `pages.lua`
- computes:
  - the text block dimensions
  - column coordinates
  - how static boxes clip columns
  - positions of decorative borders
- emits:
  - `\newflowframe` for text columns  
  - `\newstaticframe` for boxes  
- installs a TikZ overlay for line drawing

You load it in the preamble:

```latex
\directlua{dofile("layout.lua")}
```

### 3. Your LaTeX document

Your TeX file defines the content of static boxes:

```latex
\begin{staticcontents*}{hero}
  \centering
  \includegraphics[width=\textwidth]{fig/hero.png}
\end{staticcontents*}
```

Then you write the body text normally. It automatically flows into whatever frames the Lua layer defined.

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/sylvainhalle/lua-pagemaker.git
cd lua-pagemaker
```

### 2. Compile the example

```bash
lualatex example.tex
```

You must use **LuaLaTeX**.

### 3. Modify `pages.lua`

Adjust pages, columns, static boxes, and decorative rule positions.

### Example page configuration

```lua
return {
  width  = 7.88,
  height = 10.75,
  left   = 0.5,
  right  = 0.75,
  top    = 0.5,
  bottom = 0.75,

  colsep    = 0.25,
  figtop    = 0,
  figbottom = 0.5,

  pages = {
    {
      cols = 2,
      boxes = {
        { name="topbanner", colfrom=1, colto=2,
          top=0, h=3.875 }
      }
    },

    {
      cols = 3,
      boxes = {
        { name="guifig", colfrom=2, colto=3,
          top=0,
          image="fig/GUI_pipe.png",
          label="fig:bbgui",
          figbottom=1,
          caption="A pipeline in BeepBeep Studio" },

        { name="code-examples", colfrom=1, colto=2,
          bottom=0, h=2.5 }
      }
    }
  }
}
```


## Limitations

- Requires **LuaLaTeX** (not pdfLaTeX or XeLaTeX).
- May conflict with packages that heavily alter page breaking.
- No automatic column balancing (by design).
- With highly variable column widths and deep static boxes, `flowfram` may warn about unequal frame widths.


## Roadmap / Ideas

- Anchor-based positioning (`anchor="top-right"`, with `dx`, `dy` offsets).
- Predefined layout templates (`threecol_topfigure`, `sidebar_right`, etc.).
- Debug overlay showing all frames.
- Conversion into a package (`lua-pagemaker.sty`).
- Visual tooling for debugging layouts.

## License

MIT License.  
You are free to use, modify, and distribute.


## Acknowledgements

- Hans Hagen and the LuaTeX team  
- Paul Isambert for `flowfram`  
- The Lua community  
- Everyone who wants LaTeX to behave a little more like a real DTP engine

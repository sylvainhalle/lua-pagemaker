-- layout.lua
-- Colonnes à largeur variable + boîtes statiques top/bottom
-- Origine : coin supérieur gauche de la zone de texte

local config = require "pages"

-- Dimensions de la zone de texte (en pouces)
local TX_H = config.height - config.top  - config.bottom
local TX_W = config.width  - config.left - config.right

------------------------------------------------------------
-- Emission des frames TeX
------------------------------------------------------------

local function flowframe(name, page, x, y, w, h)
  local rev_y = TX_H - y - h
  tex.sprint(string.format(
    "\\newflowframe[%d]{%fin}{%fin}{%fin}{%fin}[%s]",
    page, w, h, x, rev_y, name
  ))
end

local function staticframe(name, page, x, y, w, h, align)
  local valign = align or "c"
  local rev_y = TX_H - y - h
  tex.print(string.format(
    "\\newstaticframe[%d]{%fin}{%fin}{%fin}{%fin}[%s]",
    page, w, h, x, rev_y, name
  ))
  tex.sprint(string.format(
    "\\setstaticframe*{%s}{valign=%s}", name, valign))
end

------------------------------------------------------------
-- Dessin des bordures
------------------------------------------------------------

local function drawline(x1, y1, x2, y2)
  return string.format(
    "\\draw [line width=0.5pt, black] (%f,%f) -- (%f,%f);\n", x1, y1, x2, y2)
end


------------------------------------------------------------
-- Colonnes à largeur variable
------------------------------------------------------------

-- Largeur (en pouces) occupée par toutes les colonnes (sans les espacements)
local function columns_content_width(numcols, spacing)
  return TX_W - (numcols - 1) * spacing
end

-- Largeur d’un span de colonnes [colfrom..colto]
local function wof(columns, colfrom, cto)
  local colto   = cto or colfrom
  local spacing = config.colsep
  local C_W     = columns_content_width(#columns, spacing)

  local w = 0
  for i = colfrom, colto do
    w = w + (columns[i].width * C_W)
    if i < colto then
      w = w + spacing
    end
  end
  return w
end



-- Coordonnée x du bord gauche de la colonne colindex
local function xof(columns, colindex)
  local spacing = config.colsep
  local C_W     = columns_content_width(#columns, spacing)

  local x = 0
  for i = 1, #columns do
    if i == colindex then
      return x
    end
    x = x + (columns[i].width * C_W) + spacing
  end
  return nil
end

------------------------------------------------------------
-- Helpers boîtes statiques
------------------------------------------------------------

local function box_col_range(b)
  local from = b.colfrom or 1
  local to   = b.colto   or from
  return from, to
end

local function box_top(b)
  return b.top or 0
end

local function box_bottom(b)
  return b.bottom or 0
end

------------------------------------------------------------
-- Fonction principale : une page
------------------------------------------------------------

local function columnswith(page, columns, boxes, borders)
  local colcoords = {}
  local lines = {}

  --------------------------------------------------------
  -- 1) Colonnes pleine hauteur
  --------------------------------------------------------
  for i = 1, #columns do
    local x1 = xof(columns, i)
    local w  = wof(columns, i)  -- une seule colonne

    colcoords[i] = {
      x1 = x1,
      y1 = 0,
      x2 = x1 + w,
      y2 = TX_H
    }
  end

  --------------------------------------------------------
  -- 2) On découpe les colonnes touchées par les boîtes
  --------------------------------------------------------
  if boxes then
    for c = 1, #columns do
      for _, b in ipairs(boxes) do
        local from, to = box_col_range(b)
        if from <= c and c <= to then
          if b.top ~= nil then
            -- Boîte en haut
            local t = box_top(b)
            colcoords[c].y1 = math.max(colcoords[c].y1, b.h + t)
          else
            -- Boîte en bas (bottom peut être nil → 0)
            local bot = box_bottom(b)
            colcoords[c].y2 = math.min(colcoords[c].y2, TX_H - b.h - bot)
          end
        end
      end
    end
  end

  --------------------------------------------------------
  -- 3) Création des flow frames
  --------------------------------------------------------
  for c = 1, #columns do
    local col = colcoords[c]
    local w   = col.x2 - col.x1
    local h   = col.y2 - col.y1
    local pad = config.colsep / 2

    flowframe(
      string.format("pg%dcol%d", page, c),
      page,
      col.x1, col.y1, w, h
    )
    if columns[c].borderleft then
      table.insert(lines, drawline(col.x1 + config.left - pad, col.y1 + config.top, col.x1 + config.left - pad, col.y1 + h + config.top))
    end
    if columns[c].borderright then
      table.insert(lines, drawline(col.x1 + w + config.left + pad, col.y1 + config.top, col.x1 + w + config.left + pad, col.y1 + h + config.top))
    end
  end

  --------------------------------------------------------
  -- 4) Création des static frames
  --------------------------------------------------------
  if boxes then
    for _, b in ipairs(boxes) do
      local from, to = box_col_range(b)
      local x        = xof(columns, from)
      local w        = wof(columns, from, to)

      local y
      if b.bottom ~= nil then
        y = TX_H - b.h - box_bottom(b)
      else
        y = box_top(b)
      end

      staticframe(b.name, page, x, y, w, b.h, b.valign)
    end
  end
  
  --------------------------------------------------------
  -- 5) Dessin des bordures
  --------------------------------------------------------
  if #lines > 0 or #borders > 0 then
    tex.print("\\makeatletter")
    tex.print("\\AddEverypageHook{")
    tex.print(string.format(
      "  \\ifnum\\value{page}=%d\\tikz[remember picture,overlay,shift={(current page.north west)},x=1in,y=-1in]{", page))
    for _,l in pairs(lines) do
      tex.print(l)
    end
    for _,b in pairs(borders) do
      tex.print(string.format("\\draw [line width=0.5pt, black] (%f,%f) -- (%f,%f);", b[1][1], b[1][2], b[2][1], b[2][2]))
    end
    tex.print("}")
    tex.print("\\fi}")
    tex.print("\\makeatother")
  end
end

------------------------------------------------------------
-- Application à toutes les pages décrites dans pages.lua
------------------------------------------------------------

for pg, layout in ipairs(config.pages) do
  -- layout.columns = { {width = ...}, ... }
  -- layout.boxes   = { {name=..., colfrom=..., colto=..., h=..., top=.../bottom=...}, ... }
  columnswith(pg, layout.columns, layout.boxes or {}, layout.borders or {})
end

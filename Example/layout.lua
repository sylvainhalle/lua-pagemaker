-- layout.lua
-- Colonnes à largeur variable + boîtes statiques top/bottom
-- Origine : coin supérieur gauche de la zone de texte

------------------------------------------------------------
-- 1) DSL pour les bordures (utilisé par pages.lua)
------------------------------------------------------------

local dsl = {}

-- Helpers pour positions verticales (avec "from top/bottom" si besoin)
dsl.posmeta = {
  __index = {
    from = function(self, ref)
      self.ref = ref
      return self
    end
  }
}

function dsl.at(value)
  return setmetatable({ value = value, ref = "top" }, dsl.posmeta)
end

function dsl.top(offset)
  return dsl.at(offset):from("top")
end

function dsl.bottom(offset)
  return dsl.at(offset):from("bottom")
end

-- Bordures abstraites : on stocke juste leur "intention"
function dsl.hline(pos)
  return { kind = "hline", pos = pos }
end

function dsl.vline(pos)
  return { kind = "vline", pos = pos }
end

-- Version "pratique" : lignes complètes gauche→droite / bas→haut
function dsl.hline_right(y)
  return { kind = "hline_right", y = y }
end

function dsl.hline_left(y)
  return { kind = "hline_left", y = y }
end

function dsl.vline_right(y_top, y_bottom)
  return { kind = "vline_right", y_top = y_top, y_bottom = y_bottom or 0 }
end

function dsl.vline_left(y_top, y_bottom)
  return { kind = "vline_left", y_top = y_top, y_bottom = y_bottom or 0 }
end

------------------------------------------------------------
-- 2) Charger pages.lua (qui retourne une fonction) et construire config
------------------------------------------------------------

local build_config = dofile("pages.lua")  -- -> fonction(dsl)
local config       = build_config(dsl)    -- -> table de config

-- Dimensions de la zone de texte (en pouces)
local TX_H = config.height - config.top  - config.bottom
local TX_W = config.width  - config.left - config.right

------------------------------------------------------------
-- 3) Résolution des bordures du DSL → coordonnées numériques
------------------------------------------------------------

local function resolve_pos_y(pos)
  -- pos peut être soit un nombre, soit une "position" construite avec dsl.at/top/bottom
  if type(pos) == "number" then
    return pos
  end
  if type(pos) == "table" then
    if pos.ref == "top" then
      return pos.value
    elseif pos.ref == "bottom" then
      return TX_H - pos.value
    end
  end
  return 0
end

local function resolve_borders(cfg)
  for _, page in ipairs(cfg.pages) do
    local resolved = {}
    if page.borders then
      for _, b in ipairs(page.borders) do
        if b.kind == "hline_left" then
          local y = resolve_pos_y(b.y)
          table.insert(resolved, { {0, y}, {cfg.width - cfg.right, y} })
        elseif b.kind == "hline_right" then
          local y = resolve_pos_y(b.y)
          table.insert(resolved, { {cfg.left, y}, {cfg.width - cfg.right, y} })
        elseif b.kind == "vline_right" then
          local y1 = resolve_pos_y(b.y_top)
          local y2 = TX_H - resolve_pos_y(b.y_bottom)
          local x  = cfg.width - cfg.right + cfg.colsep/2
          table.insert(resolved, { {x, y1}, {x, y2} })
        elseif b.kind == "vline_left" then
          local y1 = resolve_pos_y(b.y_top)
          local y2 = TX_H - resolve_pos_y(b.y_bottom)
          local x  = cfg.left - cfg.colsep/2
          table.insert(resolved, { {x, y1}, {x, y2} })
        end
      end
    end
    page.borders_resolved = resolved
  end
end

resolve_borders(config)

------------------------------------------------------------
-- 4) Emission des frames TeX
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
  local rev_y  = TX_H - y - h
  tex.print(string.format(
    "\\newstaticframe[%d]{%fin}{%fin}{%fin}{%fin}[%s]",
    page, w, h, x, rev_y, name
  ))
  tex.sprint(string.format("\\setstaticframe*{%s}{valign=%s}", name, valign))
end

------------------------------------------------------------
-- 5) TikZ : dessin des lignes
------------------------------------------------------------

local function drawline(x1, y1, x2, y2)
  return string.format(
    "\\draw [line width=0.5pt, black] (%f,%f) -- (%f,%f);\n",
    x1, y1, x2, y2
  )
end

------------------------------------------------------------
-- 6) Colonnes à largeur variable
------------------------------------------------------------

local function columns_content_width(numcols, spacing)
  return TX_W - (numcols - 1) * spacing
end

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
  return 0
end

------------------------------------------------------------
-- 7) Helpers pour boîtes statiques
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
-- 8) Traitement d’une page
------------------------------------------------------------

local function columnswith(page, columns, boxes, borders)
  columns = columns or {}
  boxes   = boxes   or {}
  borders = borders or {}

  local colcoords = {}
  local lines     = {}

  -- 1) Colonnes pleine hauteur
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

  -- 2) On découpe les colonnes touchées par les boîtes
  for c = 1, #columns do
    for _, b in ipairs(boxes) do
      local from, to = box_col_range(b)
      if from <= c and c <= to then
        if b.top ~= nil then
          local t = box_top(b)
          colcoords[c].y1 = math.max(colcoords[c].y1, b.h + t)
        else
          local bot = box_bottom(b)
          colcoords[c].y2 = math.min(colcoords[c].y2, TX_H - b.h - bot)
        end
      end
    end
  end

  -- 3) Création des flow frames
  for c = 1, #columns do
    local col = colcoords[c]
    local w   = col.x2 - col.x1
    local h   = col.y2 - col.y1
    local pad = config.colsep / 2

    flowframe(string.format("pg%dcol%d", page, c),
              page, col.x1, col.y1, w, h)

    if columns[c].borderleft then
      table.insert(lines,
        drawline(col.x1 + config.left - pad,
                 col.y1 + config.top,
                 col.x1 + config.left - pad,
                 col.y1 + h + config.top))
    end
    if columns[c].borderright then
      table.insert(lines,
        drawline(col.x1 + w + config.left + pad,
                 col.y1 + config.top,
                 col.x1 + w + config.left + pad,
                 col.y1 + h + config.top))
    end
  end

  -- 4) Création des static frames
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

  -- 5) TikZ : bordures
  if #lines > 0 or #borders > 0 then
    tex.print("\\makeatletter")
    tex.print("\\AddEverypageHook{")
    tex.print(string.format(
      "  \\ifnum\\value{page}=%d\\tikz[remember picture,overlay,shift={(current page.north west)},x=1in,y=-1in]{",
      page))
    for _, l in ipairs(lines) do
      tex.print(l)
    end
    for _, b in ipairs(borders) do
      tex.print(string.format(
        "\\draw [line width=0.5pt, black] (%f,%f) -- (%f,%f);",
        b[1][1], b[1][2], b[2][1], b[2][2]))
    end
    tex.print("}")
    tex.print("\\fi}")
    tex.print("\\makeatother")
  end
end

------------------------------------------------------------
-- 9) Application à toutes les pages
------------------------------------------------------------

for pg, layout in ipairs(config.pages) do
  columnswith(pg,
              layout.columns,
              layout.boxes or {},
              layout.borders_resolved or {})
end

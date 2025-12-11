-- pages.lua
-- Décrit la géométrie et la mise en page du document.
-- Ne contient pas de logique : uniquement des valeurs + appels au DSL.

return function(dsl)
  -- Raccourcis pour le DSL (helpers définis dans layout.lua)
  local hline_right = dsl.hline_right
  local hline_left  = dsl.hline_left
  local vline_right = dsl.vline_right
  local vline_left  = dsl.vline_left

  -- Configuration globale du document (en pouces)
  local config = {
    width     = 7.88,  -- largeur totale de la page
    height    = 10.5,  -- hauteur totale de la page
    top       = 0.75,  -- marge haute
    bottom    = 1.0,   -- marge basse
    left      = 0.5,   -- marge gauche
    right     = 0.5,   -- marge droite
    colsep    = 0.15,  -- espace entre colonnes
    pages     = {}
  }

  -- Raccourcis locaux si tu veux les réutiliser
  local W  = config.width
  local H  = config.height
  local T  = config.top
  local B  = config.bottom
  local L  = config.left
  local R  = config.right
  local S  = config.colsep
  local I  = 5.5 -- hauteur de la "big image" de la page 1

  config.pages = {
    {   -- Page 1
      columns = {
        { width = 1/2, borderright = true },
        { width = 1/2, borderleft  = true }
      },
      boxes = {
        {
          name    = "bigimage",
          colfrom = 1,
          colto   = 2,
          top     = 0,
          h       = I,
          valign  = "t",
        },
        {
          name    = "title",
          colfrom = 1,
          colto   = 1,
          top     = I,
          h       = H - I - T - B,
          valign  = "t",
        }
      },
      borders = {
        hline_right(0.6),
        hline_right(1.5),
        vline_right(1.75, 0),
        vline_left(T - 0.5, 0),
      }
    },

    {   -- Page 2
      columns = {
        { width = 1/3, borderleft = true, borderright = true },
        { width = 1/3 },
        { width = 1/3, borderleft = true }
      },
      boxes = {
        {
          name    = "topblank",
          colfrom = 1,
          colto   = 3,
          top     = 0,
          h       = 1
        },
        {
          name    = "topquote",
          colfrom = 2,
          colto   = 2,
          top     = 1,
          h       = 2.5
        },
        {
          name    = "figurechip",
          colfrom = 2,
          colto   = 3,
          bottom  = 0,
          h       = 3.5
        }
      },
      borders = {
        hline_left(0.6),
        hline_left(1.5),
        vline_right(0.25, 0)
      }
    }
  }

  return config
end

local config = {
  width     = 7.88,
  height    = 10.5,
  top       = 0.75,
  bottom    = 1,
  left      = 0.5,
  right     = 0.5,
  colsep    = 0.15,
  figtop    = 0,
  figbottom = 0.5,
  pages     = {}
}

local W  = config.width
local H  = config.height
local T  = config.top
local B  = config.bottom
local L  = config.left
local R  = config.right
local S  = config.colsep   -- sep btw columns
local I  = 5.5 -- Height of big image

local function hline_left(h)
  return {{0, h}, {W - R + S / 2, h}}
end

local function hline_right(h)
  return {{L - S / 2, h}, {W, h}}
end

config.pages = {
		{   -- Page 1
			columns = {
				{ width = 1/2, borderright = true},
				{ width = 1/2, borderleft = true }
			},
			boxes = {
			  {name    = "bigimage",
				 colfrom = 1, 
				 colto   = 2, 
				 top     = 0,
				 h       = I,
			     valign  = "t"},
			  {name    = "title",
				 colfrom = 1, 
				 colto   = 1, 
				 top     = I,
				 h       = H - I - T - B,
			     valign  = "t"}
			},
			borders = {
				hline_right(0.6),
				hline_right(1.5),
				{{W-R+S/2, 1.75}, {W-R+S/2,H-B}},
				{{L-S/2, T - 0.5}, {L-S/2,H-B}}
			}
		},
		{   -- Page 2
			columns = {
				{ width = 1/3, borderleft = true, borderright = true},
				{ width = 1/3 },
				{ width = 1/3, borderleft = true }
			},
			boxes = {
			  {name    = "topblank",
				 colfrom = 1, 
				 colto   = 3, 
				 top     = 0,
				 h       = 1},
			  {name    = "topquote",
				 colfrom = 2, 
				 colto   = 2, 
				 top     = 1,
				 h       = 2.5},
				{name    = "figurechip", 
				 colfrom = 2, 
				 colto   = 3, 
				 bottom  = 0,
				 h       = 3.5}
			},
			borders = {
				hline_left(0.6),
				hline_left(1.5),
				{{7.88 - 0.5 + 0.25 / 2, 0.25}, {7.88 - 0.5 + 0.25 / 2, 10.5 - 1}}
			}
		}
	}
return config
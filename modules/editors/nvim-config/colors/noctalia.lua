-- Noctalia (Material You) colourscheme. The palette is rendered by matugen
-- from the noctalia template into the noctalia cache, base16-nvim owns the
-- syntax/LSP/treesitter/Diff/Telescope groups, and the groups the rest of this
-- config names by hand are set below.
--
-- Self-contained on purpose: configFiles only installs config/{options,keymaps,
-- autocmds}.lua from lua/config/, so anything else in that directory would
-- never reach ~/.config/nvim.

local function rgb(hex)
	local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
	return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

--- Mixes `fg` toward `bg`; alpha 1 keeps fg, 0 returns bg.
local function blend(fg, bg, alpha)
	local fr, fg_g, fb = rgb(fg)
	local br, bg_g, bb = rgb(bg)
	local mix = function(f, b)
		return math.floor(f * alpha + b * (1 - alpha))
	end
	return string.format("#%02x%02x%02x", mix(fr, br), mix(fg_g, bg_g), mix(fb, bb))
end

--- Accent slots, named after the base16 slot they come from. Referenced by
--- lua/plugins/lualine.lua and lua/plugins/buffers.lua as Base16<Name> /
--- Base16Bg<Name>.
local ACCENTS = {
	Red = "base08",
	Orange = "base09",
	Yellow = "base0A",
	Green = "base0B",
	Cyan = "base0C",
	Blue = "base0D",
	Violet = "base0E",
}

--- Sets every group base16-nvim leaves undefined.
local function apply()

	local p = require("base16-colorscheme").colors
	local bg = p.base00
	local hi = function(group, opts)
		vim.api.nvim_set_hl(0, group, opts)
	end

	local accent = {}
	for name, slot in pairs(ACCENTS) do
		accent[name] = p[slot]
		hi("Base16" .. name, { fg = p[slot] })
		hi("Base16Bg" .. name, { bg = p[slot], fg = bg, bold = true })
	end

	-- Mode chips: lualine sections a/z, plus cursor and cursorline per mode.
	for mode, color in pairs({
		Normal = accent.Green,
		Insert = accent.Orange,
		Visual = p.base05,
		Command = accent.Violet,
		Replace = accent.Cyan,
		Terminal = accent.Yellow,
	}) do
		hi(mode .. "Mode", { fg = color })
		hi(mode .. "ModeBg", { bg = color, fg = bg, bold = true })
		hi(mode .. "ModeCursor", { bg = blend(color, bg, 0.6), fg = bg })
		hi(mode .. "ModeLine", { bg = blend(color, bg, 0.1) })
	end

	hi("StatusLineBg", { bg = bg, fg = p.base05 })

	-- base16 underlines LSP references; a blended background reads better.
	local reference = { bg = blend(p.base04, bg, 0.3) }
	hi("LspReferenceText", reference)
	hi("LspReferenceRead", reference)
	hi("LspReferenceWrite", reference)

	-- Gitsigns inline/ghost-line groups; the sign column comes from base16.
	hi("GitSignsAddLn", { link = "DiffAdd" })
	hi("GitSignsAddInline", { link = "DiffAdd" })
	hi("GitSignsDeleteInline", { link = "DiffDelete" })
	hi("GitSignsChangeInline", { link = "DiffChange" })
	hi("GitSignsDeleteLn", { bg = "NONE", fg = "NONE" })
	hi("GitSignsDeleteVirtLn", { bg = blend(p.base08, bg, 0.4), fg = bg })

	-- lualine's diff component.
	hi("LuaLineDiffAdded", { fg = accent.Green })
	hi("LuaLineDiffModified", { fg = accent.Blue })
	hi("LuaLineDiffRemoved", { fg = accent.Red })
end

-- The palette lives in the noctalia cache, not the config tree: ~/.config/nvim
-- is installed read-only from the Nix store, so matugen cannot write into it.
-- dofile rather than require because the path is outside the runtimepath.
local palette = (vim.env.XDG_CACHE_HOME or (vim.env.HOME .. "/.cache")) .. "/noctalia/nvim-palette.lua"
local ok, matugen = pcall(dofile, palette)
if ok and type(matugen) == "table" then
	matugen.setup()
else
	require("base16-colorscheme").setup(nil)
end
apply()

vim.g.colors_name = "noctalia"

-- matugen rewrites the palette and signals every nvim with SIGUSR1; reloading
-- the colourscheme re-runs apply() against the new one. The rendered module has
-- its own SIGUSR1 handler for its base16 palette and Telescope groups, and both
-- read the same file, so the order they fire in does not matter.
local signal = vim.uv.new_signal()
signal:start(
	"sigusr1",
	vim.schedule_wrap(function()
		vim.cmd.colorscheme("noctalia")
	end)
)

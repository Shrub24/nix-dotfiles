-- The gitsigns on_attach maps are verbatim, including the inert `return
-- "<Ignore>"` in the ]h/[h callbacks: those need `expr = true` to fire.
local function gitsigns_on_attach(bufnr)
  local gs = package.loaded.gitsigns

  local function map(mode, l, r, desc)
    vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
  end

  map("n", "]h", function()
    if vim.wo.diff then
      return "]c"
    end
    vim.schedule(function()
      gs.next_hunk()
    end)
    return "<Ignore>"
  end, "Next Hunk")

  map("n", "[h", function()
    if vim.wo.diff then
      return "[c"
    end
    vim.schedule(function()
      gs.prev_hunk()
    end)
    return "<Ignore>"
  end, "Prev Hunk")

  -- Review workflow
  map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage Hunk (Accept)")
  map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset Hunk (Reject)")
  map("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
  map("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
  map("n", "<leader>hp", gs.preview_hunk, "Preview Hunk")
  map("n", "<leader>gb", function()
    gs.blame_line({ full = true })
  end, "Blame Line")
  map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle Blame")
  map("n", "<leader>gc", function()
    gs.toggle_linehl()
    gs.toggle_deleted()
    gs.toggle_word_diff()
    gs.preview_hunk_inline()
  end, "Toggle VS Code Diff Mode")

  map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
end

return {
  {
    "gitsigns.nvim",
    auto_enable = true,
    event = { "BufReadPre", "BufNewFile" },
    after = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "▎" },
          change = { text = "▎" },
          delete = { text = "" },
          topdelete = { text = "" },
          changedelete = { text = "▎" },
          untracked = { text = "▎" },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = { interval = 1000, follow_files = true },
        attach_to_untracked = false,
        current_line_blame = false,
        current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", delay = 1000 },
        preview_config = {
          border = "rounded",
          style = "minimal",
          relative = "cursor",
          row = 0,
          col = 1,
        },
        on_attach = gitsigns_on_attach,
      })
    end,
  },
  {
    "diffview-plus.nvim",
    auto_enable = true,
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose", "DiffviewToggleFiles" },
  },
}

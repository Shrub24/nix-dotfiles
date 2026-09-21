--- Optional error/notification capture, off unless asked for.
---
---   NVIM_ERRORLOG=/tmp/nvim.log nvim-nix
---
--- Nothing is written when the variable is unset, so normal startup pays no
--- file I/O. Two streams are captured:
---
---   vim.notify  every notification, whatever renders it (noice, snacks)
---   :messages   the full message history, dumped on exit and on focus loss
---
--- Lua errors raised in autocmds/commands are written to stderr by neovim
--- itself and never reach Lua, so redirect the process to catch those:
---
---   nvim-nix 2>>/tmp/nvim.err
---
--- LSP traffic is separate again and always on:
---   :lua vim.print(vim.lsp.log.get_filename())
local path = vim.env.NVIM_ERRORLOG
if not path or path == "" then
  return
end

local f = io.open(path, "a")
if not f then
  vim.notify("errorlog: cannot open " .. path, vim.log.levels.WARN)
  return
end

local function write(kind, msg)
  local text = type(msg) == "table" and vim.inspect(msg) or tostring(msg)
  pcall(f.write, f, string.format("[%s] %-8s %s\n", os.date("%H:%M:%S"), kind, text))
  pcall(f.flush, f)
end

write("SESSION", "--- pid " .. vim.fn.getpid() .. " cwd " .. vim.fn.getcwd() .. " ---")

local levels = { [0] = "TRACE", [1] = "DEBUG", [2] = "INFO", [3] = "WARN", [4] = "ERROR", [5] = "ERROR" }

-- Plugins replace vim.notify during their own setup (snacks is a startup
-- plugin and does exactly this), so a single wrap at init would be silently
-- undone. Capture whatever is current each time, and re-install after the
-- events that follow plugin setup.
local wrapped
local function install_notify()
  local current = vim.notify
  if current == wrapped then
    return
  end
  local inner = current
  wrapped = function(msg, level, opts)
    write(levels[level or vim.log.levels.INFO] or "NOTIFY", msg)
    return inner(msg, level, opts)
  end
  vim.notify = wrapped
end

install_notify()
vim.api.nvim_create_autocmd({ "DeferredUIEnter", "UIEnter", "User" }, {
  group = vim.api.nvim_create_augroup("ErrorLogNotify", { clear = true }),
  callback = install_notify,
})

-- The message history includes neovim's own errors and everything echoed to
-- the cmdline, which vim.notify never sees.
local function dump_messages(label)
  local ok, res = pcall(vim.api.nvim_exec2, "messages", { output = true })
  if ok and res.output and res.output ~= "" then
    write(label, res.output)
  end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("ErrorLog", { clear = true }),
  callback = function()
    dump_messages("MESSAGES")
    pcall(f.close, f)
  end,
})

-- Pulling the window out of focus is the point at which a hung or warning
-- dialog is most likely and most useful to have on disk already.
vim.api.nvim_create_autocmd("FocusLost", {
  group = "ErrorLog",
  callback = function()
    dump_messages("MESSAGES")
  end,
})

vim.api.nvim_create_user_command("ErrorLog", function(cmd)
  if cmd.args == "dump" then
    dump_messages("MESSAGES")
    vim.notify("errorlog: dumped to " .. path)
  else
    vim.cmd.edit(path)
  end
end, { nargs = "?", complete = function() return { "dump", "open" } end })

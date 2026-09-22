# LazyVim keymap parity checklist

Captured from the live LazyVim session on 2026-09-18 with
`nvim_get_keymap` after forcing `User VeryLazy` — the running editor, not
the source files. Leader is rendered as a leading space.

The ported `lua/config/keymaps.lua` covers only what the config set
explicitly. LazyVim's core and its enabled extras supply the rest, so this
file is the checklist for restoring muscle memory. Tick a line once the

<!-- 2026-09-18: LazyVim's core keymaps ported verbatim to
     lua/config/keymaps-core.lua (marked DONE below). Plugin-specific maps
     (aerial, trouble, todo-comments, yanky, dial, treesitter-context,
     snacks picker sources) land with their plugin specs; remaining entries
     here are still open. -->

map exists in the new config.

```
 1                         Harpoon to File 1
 2                         Harpoon to File 2
 3                         Harpoon to File 3
 4                         Harpoon to File 4
 5                         Harpoon to File 5
 6                         Harpoon to File 6
 7                         Harpoon to File 7
 8                         Harpoon to File 8
 9                         Harpoon to File 9
 a                         +ai
 aa                        Sidekick Toggle CLI
 ac                        herdr-nvim: comment line
 ac                        herdr-nvim: comment selection
 ad                        Detach a CLI Session
 af                        Send File
 al                        herdr-nvim: list comments
 ap                        Sidekick Select Prompt
 aS                        herdr-nvim: send comments to agent
 as                        Select CLI
 at                        Send This
 av                        Send Visual Selection
 bb                        Switch to Other Buffer  <!-- DONE: <leader>bb/` -->
 bd                        Delete Buffer  <!-- DONE: <leader>bd -->
 bD                        Delete Buffer and Window  <!-- DONE: <leader>bd -->
 bi                        Delete Invisible Buffers  <!-- DONE: <leader>bi -->
 bj                        Pick Buffer
 bl                        Delete Buffers to the Left  <!-- DONE: <leader>bd -->
 bo                        Delete Other Buffers  <!-- DONE: <leader>bo -->
 bP                        Delete Non-Pinned Buffers
 bp                        Toggle Pin
 br                        Delete Buffers to the Right  <!-- DONE: <leader>bd -->
 ?                         Buffer Keymaps (which-key)
 ,                         Buffers
 cd                        Line Diagnostics  <!-- DONE: <leader>cd -->
 cf                        Format  <!-- DONE: <leader>cf -->
 cF                        Format Injected Langs  <!-- DONE: <leader>cf -->
 cm                        Mason
 :                         Command History
 cs                        Aerial (Symbols)
 cS                        LSP references/definitions/... (Trouble)
 da                        Run with Args
 dB                        Breakpoint Condition
 db                        Toggle Breakpoint
 dc                        Run/Continue
 dC                        Run to Cursor
 de                        Stop on exceptions
 dg                        Go to Line (No Execute)
 di                        Step Into
 dj                        Down
 dk                        Up
 dl                        Run Last
 do                        Step Out
 dO                        Step Over
 dph                       Toggle Profiler Highlights  <!-- DONE: <leader>dpp -->
 dP                        Pause
 dpp                       Toggle Profiler  <!-- DONE: <leader>dpp -->
 dps                       Profiler Scratch Buffer
 dr                        Toggle REPL
 ds                        Session
 D                         Toggle DBUI
 dt                        Terminate
 dv                        Toggle Dap View
 dw                        Widgets
 E                         Explorer Snacks (cwd)
 e                         Explorer Snacks (root dir)
 fb                        Buffers
 fB                        Buffers (all)
 fc                        Find Config File
 fE                        Explorer Snacks (cwd)
 fe                        Explorer Snacks (root dir)
 fF                        Find Files (cwd)
 ff                        Find Files (Root Dir)
 fg                        Find Files (git-files)
                           Find Files (Root Dir)
 fn                        New File
 fp                        Projects
 fr                        Recent
 fR                        Recent (cwd)
 fT                        Terminal (cwd)  <!-- DONE: <leader>fT -->
 ft                        Terminal (Root Dir)  <!-- DONE: <leader>ft -->
 ga                        Audit Agent (Unstaged vs Staged)
 gb                        Git Blame Line  <!-- DONE: <leader>gb -->
 gB                        Git Browse (open)  <!-- DONE: <leader>gB -->
 gd                        Git Diff (hunks)
 gD                        Git Diff (origin)
 gf                        Git Current File History  <!-- DONE: <leader>gf -->
 gG                        Lazygit (cwd)  <!-- DONE: <leader>gG -->
 gg                        Lazygit (Root Dir)  <!-- DONE: <leader>gg -->
 gi                        List Issues (Octo)
 gI                        Search Issues (Octo)
 gl                        Git Log  <!-- DONE: <leader>gl -->
 gL                        Git Log (cwd)  <!-- DONE: <leader>gL -->
 gp                        List PRs (Octo)
 gP                        Search PRs (Octo)
 /                         Grep (Root Dir)
 gr                        List Repos (Octo)
 gs                        Git Status
 gS                        Search (Octo)
 gY                        Git Browse (copy)  <!-- DONE: <leader>gY -->
  h
 H                         Harpoon File
 h                         Harpoon Quick Menu
  j
  k
 K                         Keywordprg
  l
 L                         Clear Highlights
 l                         Lazy
 n                         Notification History
 p                         Open Yank History
 ql                        Load Recent
 qp                        Load Project
 qq                        Quit All
 qs                        Save Project
 Rb                        Open scratchpad
 rc                        Debug Cleanup
 rf                        Extract Function
 rF                        Extract Function To File
 ri                        Inline Variable
 rP                        Debug Print Location
 rp                        Debug Print Variable
 rr
 r                         +refactor
 R                         +Rest
 Rr                        Replay the last request
 rs                        Select Refactor
 rx                        Extract Variable
 sa                        Autocmds
 sb                        Buffer Lines
 sB                        Grep Open Buffers
 sc                        Command History
 sC                        Commands
 sD                        Buffer Diagnostics
 sd                        Diagnostics
 sG                        Grep (cwd)
 sg                        Grep (Root Dir)
 sh                        Help Pages
 sH                        Highlights
 si                        Icons
 sj                        Jumps
 sk                        Keymaps
 sl                        Location List
 sM                        Man Pages
 sm                        Marks
 sna                       Noice All
 snd                       Dismiss All
 snh                       Noice History
 snl                       Noice Last Message
 sn                        +noice
 snt                       Noice Picker (Telescope/FzfLua)
 -                         Split Window Below  <!-- DONE: <leader>- -->
 |                         Split Window Right  <!-- DONE: <leader>| -->
 sp                        Search for Plugin Spec
 sq                        Quickfix List
 s"                        Registers
 sR                        Resume
 sr                        Search and Replace
 s/                        Search History
 S                         Select Scratch Buffer
 st                        Todo
 sT                        Todo/Fix/Fixme
 su                        Undotree
 `                         Switch to Other Buffer  <!-- DONE: <leader>bb/` -->
 sW                        Visual selection or word (cwd)
 sw                        Visual selection or word (Root Dir)
 ta                        Attach to Test (Neotest)
 <Tab>d                    Close Tab
 <Tab>f                    First Tab
 <Tab>l                    Last Tab
 <Tab>]                    Next Tab
 <Tab>o                    Close Other Tabs
 <Tab>[                    Previous Tab
 <Tab><Tab>                New Tab
 td                        Debug Nearest
 tl                        Run Last (Neotest)
 .                         Toggle Scratch Buffer
 to                        Show Output (Neotest)
 tO                        Toggle Output Panel (Neotest)
 tr                        Run Nearest (Neotest)
 tS                        Stop (Neotest)
 ts                        Toggle Summary (Neotest)
 t                         +test
 tT                        Run All Test Files (Neotest)
 tt                        Run File (Neotest)
 tw                        Toggle Watch (Neotest)
 ua                        Toggle Animations
 uA                        Toggle Tabline
 ub                        Toggle Dark Background
 uC                        Colorschemes
 uc                        Toggle Conceal Level
 ud                        Toggle Diagnostics
 uD                        Toggle Dimming
 uF                        Toggle Auto Format (Buffer)  <!-- DONE: <leader>cf -->
 uf                        Toggle Auto Format (Global)  <!-- DONE: <leader>cf -->
 ug                        Toggle Indent Guides
 uh                        Toggle Inlay Hints
 ui                        Inspect Pos  <!-- DONE: <leader>ui -->
 uI                        Inspect Tree  <!-- DONE: <leader>uI -->
 ul                        Toggle Line Numbers
 uL                        Toggle Relative Number
 un                        Dismiss All Notifications
 up                        Toggle Mini Pairs
 ur                        Redraw / Clear hlsearch / Diff Update
 uS                        Toggle Smooth Scroll
 us                        Toggle Spelling
 uT                        Toggle Treesitter Highlight
 uw                        Toggle Wrap
 uz                        Toggle Zen Mode
 uZ                        Toggle Zoom Mode
 wd                        Delete Window  <!-- DONE: <leader>wd -->
 wm                        Toggle Zoom Mode
 W                         Open Oil
 xl                        Location List
 xL                        Location List (Trouble)
 xq                        Quickfix List
 xQ                        Quickfix List (Trouble)
 xT                        Todo/Fix/Fixme (Trouble)
 xt                        Todo (Trouble)
 xX                        Buffer Diagnostics (Trouble)
 xx                        Diagnostics (Trouble)
```

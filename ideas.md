# Ideas

Deferred ideas with their evidence. Each entry says what is known and what would have to be decided before it starts.

## Phone answers for our ask_user_question

Sessions driven from the dashboard cannot answer `ask_user_question`, because it renders with `ctx.ui.custom` in the terminal.
The dashboard's own `ask_user` answers in the browser, but it is excluded for now (`--exclude-tools` in
`pkgs/pi-bolt/default.nix`), so a phone session cannot ask the user anything.

Routes, from source (dashboard 0.9.0, rpiv-ask-user-question 2.13.9):

- **Adapter.** The dashboard subscribes to `rpiv:ask-user:prompt` and answers through `rpiv:ask-user:answer`
  (`rpiv-ask-user-question/events.ts`). The terminal overlay stays as it is, and the browser gets a dialog.
- **Bus primitives.** Ask through `ctx.ui.select`, `confirm` and `input`, which the PromptBus routes to both adapters
  (`bridge.ts` around 3225-3380). This loses previews and tabs.

Decide first: adapter or bus primitives, and whether the change goes upstream. The dashboard bus already gives first-response-wins
and survives refresh and restart, so the bus route may be the one to propose.

-- vim-tmux-navigator (nvim side): Ctrl+h/j/k/l moves between nvim splits,
-- and past the edge into the surrounding tmux pane. The tmux half lives in
-- home/tmux/tmux.conf — the two must stay in sync (see home/tmux.nix).
-- Lazy-loaded: only the keys/cmds below pull the plugin in.
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
    },
  },
}

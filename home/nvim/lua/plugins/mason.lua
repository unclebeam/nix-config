-- No Mason, ever (see CLAUDE.md): LSPs and formatters are Nix packages,
-- declared in home/neovim.nix (plus helix's set, shared via PATH),
-- never downloaded by the editor. LazyVim guards every mason call with
-- LazyVim.has("mason-lspconfig.nvim"), so with these disabled it falls
-- back to enabling servers straight from PATH.
-- (If a DAP extra is ever enabled, jay-babu/mason-nvim-dap.nvim needs the
-- same enabled = false treatment.)
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
}

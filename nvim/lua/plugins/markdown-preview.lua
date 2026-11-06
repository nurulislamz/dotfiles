return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  ft = "markdown",
  build = "cd app && npx --yes yarn install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
    vim.g.mkdp_echo_preview_url = 1
    if vim.fn.has("wsl") == 1 then
      vim.cmd([[function! MarkdownPreviewChrome(url)
        call jobstart(['/mnt/c/Program Files/Google/Chrome/Application/chrome.exe', a:url], {'detach': v:true})
      endfunction]])
      vim.g.mkdp_browserfunc = "MarkdownPreviewChrome"
    end
  end,
  keys = {
    { "<leader>mv", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Toggle browser preview" },
  },
}

local ok, kagami = pcall(require, "kagami")
if not ok then
  return
end

if vim.g.loaded_kagami == 1 then
  return
end
vim.g.loaded_kagami = 1

vim.api.nvim_create_user_command("KagamiOpen", function()
  kagami.open()
end, {})

vim.api.nvim_create_user_command("KagamiClose", function()
  kagami.close()
end, {})

vim.api.nvim_create_user_command("KagamiToggle", function()
  kagami.toggle()
end, {})

vim.api.nvim_create_user_command("KagamiRefresh", function()
  kagami.refresh()
end, {})


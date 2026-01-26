local M = {}

local git = require("neogit.lib.git")

---@param section_name string
---@param item_name    string|string[]|nil
---@param opts         table|nil
function M.open(section_name, item_name, opts)
  opts = opts or {}

  -- Hack way to do an on-close callback
  if opts.on_close then
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      buffer = opts.on_close.handle,
      once = true,
      callback = opts.on_close.fn,
    })
  end

  -- Build the CodeDiff command based on section and item
  local cmd

  -- selene: allow(if_same_then_else)
  if
    (section_name == "recent" or section_name == "log" or (section_name and section_name:match("unmerged$")))
    and item_name
  then
    -- Commit or range of commits
    if type(item_name) == "table" then
      local range = string.format("%s..%s", item_name[1], item_name[#item_name])
      cmd = string.format("CodeDiff history %s", range)
    else
      local commit = item_name:match("[a-f0-9]+")
      -- Show the commit's changes (commit vs parent)
      cmd = string.format("CodeDiff history %s^..%s", commit, commit)
    end
  elseif section_name == "range" and item_name then
    -- Range comparison
    cmd = string.format("CodeDiff history %s", item_name)
  elseif (section_name == "stashes" or section_name == "commit") and item_name then
    -- Single commit (compare with parent)
    cmd = string.format("CodeDiff history %s^..%s", item_name, item_name)
  elseif section_name == "conflict" and item_name then
    -- Specific conflict file
    cmd = string.format("CodeDiff merge %s", vim.fn.fnameescape(item_name))
  elseif section_name == "conflict" and not item_name then
    -- All conflicts
    cmd = "CodeDiff merge"
  elseif section_name == "worktree" and not item_name then
    -- Worktree diff (all changes)
    cmd = "CodeDiff"
  elseif section_name == "staged" then
    -- Staged changes
    if opts.only and item_name then
      -- Single staged file - compare working tree with HEAD
      local file_path = git.repo.worktree_root .. "/" .. item_name
      cmd = string.format("CodeDiff file HEAD %s", vim.fn.fnameescape(file_path))
    else
      -- All staged changes - compare staged area (index) with HEAD
      cmd = "CodeDiff HEAD"
    end
  elseif section_name == "unstaged" then
    -- Unstaged changes
    if opts.only and item_name then
      -- Single unstaged file - compare working tree with current buffer
      local file_path = git.repo.worktree_root .. "/" .. item_name
      -- Open the file and compare it with git HEAD version
      vim.cmd("edit " .. vim.fn.fnameescape(file_path))
      cmd = "CodeDiff file HEAD"
    else
      -- All unstaged changes
      cmd = "CodeDiff"
    end
  elseif section_name == "merge" then
    -- Merge conflicts
    if opts.only and item_name then
      cmd = string.format("CodeDiff merge %s", vim.fn.fnameescape(item_name))
    else
      cmd = "CodeDiff merge"
    end
  elseif section_name == nil and item_name ~= nil then
    -- Commit without section
    cmd = string.format("CodeDiff history %s^..%s", item_name, item_name)
  else
    -- Default: show working directory changes
    cmd = "CodeDiff"
  end

  -- Execute the command
  if cmd then
    vim.cmd(cmd)
  end
end

return M

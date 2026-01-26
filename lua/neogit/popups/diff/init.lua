local M = {}

local config = require("neogit.config")
local popup = require("neogit.lib.popup")
local actions = require("neogit.popups.diff.actions")

function M.create(env)
  local has_diff_integration = config.check_integration("diffview") or config.check_integration("codediff")
  local commit_selected = (env.section and env.section.name == "log") and type(env.item.name) == "string"

  local p = popup
    .builder()
    :name("NeogitDiffPopup")
    :group_heading("Diff")
    :action_if(has_diff_integration and env.item, "d", "this", actions.this)
    :action_if(has_diff_integration and commit_selected, "h", "this..HEAD", actions.this_to_HEAD)
    :action_if(has_diff_integration, "r", "range", actions.range)
    :action("p", "paths")
    :new_action_group()
    :action_if(has_diff_integration, "u", "unstaged", actions.unstaged)
    :action_if(has_diff_integration, "s", "staged", actions.staged)
    :action_if(has_diff_integration, "w", "worktree", actions.worktree)
    :new_action_group("Show")
    :action_if(has_diff_integration, "c", "Commit", actions.commit)
    :action_if(has_diff_integration, "t", "Stash", actions.stash)
    :env(env)
    :build()

  p:show()

  return p
end

return M

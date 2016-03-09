require 'torch'
require 'os'
require 'io'
require 'table'

dofile('games/init.lua')

function main(gname)
  -- Create game and grab the display and the pane ID
  g, g_disp, state_win = init_game(gname)

  -- Prepare files to write timeseries information
  game_state_filename = gname .. "-game-state-ts.txt"
  action_state_filename = gname .. "-action-state.txt"
  -- local game_state_file = io.open(game_state_filename, "w")
  -- local action_file = io.open(action_state_filename, "w")

  -- Create the buffer to store actions to be read and written to file
  action_buffer = {}

  -- Action loop to process keyboard inputs and take actions
  while true do
    -- Convert keyboard to up/down/left/right
    print("Waiting...")
    local res = io.read()
    local line = string.gsub(res, "\n", "")
    local action = 5
    if line == "a" then
      action = 3
    elseif line == "d" then
      action = 4
    elseif line == "w" then
      action = 1
    elseif line == "s" then
      action = 2
    else
      print("Not valid!")
    end
    print("Action " .. action .. " pressed!")

    -- Act on the game with action
    g:act(action)

    -- Add this to the action buffer
    if action ~= 5 then
      table.insert(action_buffer, action)
    end

    -- Display image to broswer
    g_disp.image(g.map:to_image(), {win=state_win})

    -- TODO: Put these two actions into a separate thread; the thread needs the game object g for snapshot, and the action buffer for write_action
    -- Get game state snapshot and write to file
    local snapshot = get_snapshot(g)
    write_snapshot(snapshot, game_state_filename)

    -- Write action state to file from buffer
    write_action(action_buffer, action_state_filename)
  end
end

-- Initializes a game with the specified game name
function init_game(gname)
  g_opts = {games_config_path = 'games/config/game_config.lua'}
  g_init_vocab()
  g_init_game()
  g = g_factory:init_game(gname)
  s = g:to_sentence()
  g_disp = require('display')
  state_win = g_disp.image(g.map:to_image())
  print('state_win:' .. state_win .. type(state_win))
  return g, g_disp, state_win
end

-- Write action to file
function write_action(action_buffer, action_state_filename)
  f = io.open(action_state_filename, "a")
  if next(action_buffer) == nil then
    f:write(5)
  else
    f:write(table.remove(action_buffer, 1))
  end
  f:write("\n")
  f:close()
end

-- Write snapshot to file
function write_snapshot(snapshot, game_state_filename)
  f = io.open(game_state_filename, "a")
  out = ""
  for i, l in ipairs(snapshot) do
    n = l .. " "
    out = out .. n
  end
  f:write(out .. "\n")
  f:close()
end

-- Get desired game info
function get_snapshot(g, file)
  items = g.agents[1]["map"]["items"]
  snapshot = {}
  for i=1,#items do
    for j=1,#items[i] do
      if next(items[i][j]) == nil then
        table.insert(snapshot, i)
        table.insert(snapshot, j)
        table.insert(snapshot, 1)
        table.insert(snapshot, 0)
        table.insert(snapshot, 0)
        table.insert(snapshot, 0)
      else
        attr = items[i][j][1]["attr"]
        if attr["loc"] then
          table.insert(snapshot, attr["loc"]["y"])
          table.insert(snapshot, attr["loc"]["x"])
        end

        if attr["type"] then
          table.insert(snapshot, type_mapping[attr["type"]])
        end

        if attr["color"] then
          table.insert(snapshot, color_num[attr["color"]])
        else
          table.insert(snapshot, 0)
        end

        if attr["open"] then
          table.insert(snapshot, door_open[attr["open"]])
        else
          table.insert(snapshot, 0)
        end

        if attr["goal"] then
          table.insert(snapshot, goal_num[attr["goal"]])
        else
          table.insert(snapshot, 0)
        end
      end
    end
  end
  print(snapshot)
  return snapshot
end

function get_type_mapping()
  t = {}
  t["0"] = 1
  t["block"] = 2
  t["water"] = 3
  t["switch"] = 4
  t["door"] = 5
  t["pushableblock"] = 6
  t["corner"] = 7
  t["goal"] = 8
  t["agent"] = 9
  return t
end

function get_door_open()
  t = {}
  t["0"] = 0
  t["closed"] = 1
  t["open"] = 2
  return t
end

function get_goal_num()
  t = {}
  t["0"] = 0
  t["goal1"] = 1
  t["goal2"] = 2
  t["goal3"] = 3
  return t
end

function get_color_num()
  t = {}
  t["0"] = 0
  t["color1"] = 1
  t["color2"] = 2
  t["color3"] = 3
  return t
end

local cmd = torch.CmdLine()
cmd:text()
cmd:text('Play games in MazeBase using wasd commands')
cmd:text()
cmd:text('Options:')
cmd:option('-gname', 'Goto', 'name of Mazebase game to play')
cmd:text()

type_mapping = get_type_mapping()
door_open = get_door_open()
goal_num = get_goal_num()
color_num = get_color_num()

local opt = cmd:parse(arg)
print(opt)
gname = opt.gname

main(gname)

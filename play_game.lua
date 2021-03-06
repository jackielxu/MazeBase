require 'torch'
require 'os'
require 'io'
require 'table'
require 'math'

dofile('games/init.lua')

function main(gname)
  -- Create game and grab the display and the pane ID; get all objects
  g, g_disp, state_win = init_game(gname)
  objects, agent_x, agent_y = get_all_objects(g)
  print(objects)

  -- Prepare files to write timeseries information
  game_state_filename = gname .. "-triangle-feature-state-ts.txt"
  action_state_filename = gname .. "-triangle-action-state-ts.txt"

  -- Create the buffer to store actions to be read and written to file
  action_buffer = {}

  -- Action loop to process keyboard inputs and take actions
  while true do
    -- Convert keyboard to up/down/left/right
    -- Please be careful in the inputs (doesn't check if the agent hits a wall)
    -- TODO: Fix this.
    print("Waiting...")
    local res = io.read()
    local line = string.gsub(res, "\n", "")
    local action = 5
    if line == "a" then
      action = 3
      agent_x = agent_x - 1
    elseif line == "d" then
      action = 4
      agent_x = agent_x + 1
    elseif line == "w" then
      action = 1
      agent_y = agent_y - 1
    elseif line == "s" then
      action = 2
      agent_y = agent_y + 1
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
    local snapshot = get_feature_snapshot(g, objects, agent_x, agent_y)
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

-- Write actions to file
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

-- Get all objects on the board at the beginning
function get_all_objects(g)
  items = g.agents[1]["map"]["items"]
  objects = {}
  local counter = 1
  local agent_x = 0
  local agent_y = 0
  for i=1,#items do
    for j=1,#items do
      if next(items[i][j]) ~= nil then
        if items[i][j][1]["attr"]["type"] ~= "agent" then
          objects[counter] = {items[i][j][1]["attr"]["loc"]["x"], items[i][j][1]["attr"]["loc"]["y"]}
          counter = counter + 1
        else
          agent_x = items[i][j][1]["attr"]["loc"]["x"]
          agent_y = items[i][j][1]["attr"]["loc"]["y"]
        end
      end
    end
  end
  return objects, agent_x, agent_y
end

-- Get game state information about pairwise distance from agent to objects
function get_feature_snapshot(g, objects, agent_x, agent_y)
  snapshot = {}

  for i=1,#objects do
    table.insert(snapshot, math.sqrt((agent_x - objects[i][1])*(agent_x - objects[i][1]) + (agent_y - objects[i][2])*(agent_y - objects[i][2])))
  end

  print(snapshot)
  return snapshot
end

local cmd = torch.CmdLine()
cmd:text()
cmd:text('Play games in MazeBase using wasd commands')
cmd:text()
cmd:text('Options:')
cmd:option('--gname', 'Goto', 'name of Mazebase game to play')
cmd:text()

local opt = cmd:parse(arg)
print(opt)
gname = opt.gname

main(gname)

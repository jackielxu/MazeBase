require 'torch'

dofile('games/init.lua')

function main(gname)
  g, g_disp, state_win = init_game(gname)
  while true do
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
    g:act(action)
    g_disp.image(g.map:to_image(), {win=state_win})
  end
end

function init_game(gname)
  g_opts = {games_config_path = 'games/config/game_config.lua'}
  -- Insert the place where we specify what game we want
  g_init_vocab()
  g_init_game()
  g = g_factory:init_game(gname)
  s = g:to_sentence()
  g_disp = require('display')
  state_win = g_disp.image(g.map:to_image())
  return g, g_disp, state_win
end

local cmd = torch.CmdLine()
cmd:text()
cmd:text('Play games in MazeBase using wasd commands')
cmd:text()
cmd:text('Options:')
cmd:option('-gname', 'Goto', 'name of Mazebase game to play')
cmd:text()

local opt = cmd:parse(arg)
print(opt)
gname = opt.gname

main(gname)

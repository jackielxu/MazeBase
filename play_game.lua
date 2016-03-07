dofile('MazeBase/games/init.lua')

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
	g_opts = {games_config_path = 'MazeBase/games/config/game_config.lua'}
	-- Insert the place where we specify what game we want
	g_init_vocab()
	g_init_game()
	g = new_game()
	s = g:to_sentence()
	g_disp = require('display')
	state_win = g_disp.image(g.map:to_image())
	return g, g_disp, state_win
end

if arg[1] == nil then
	gname = "Goto"
else
	gname = arg[1]
end

main(gname)

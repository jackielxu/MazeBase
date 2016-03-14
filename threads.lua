p = require "play_game"
lanes = require "lanes".configure()

local linda = lanes.linda()

local function loop()
for i=1,10 do
  print ("sending:" .. i)
  linda:set("x",i)
  end
print("end sender")
end

function receiver()
  while true do
    print("receiving")
    local val=linda:get("x")
    if val==nil then
      print("nil received")
    else
      print("received:" .. val)
      break
    end
  end
  print("end receiver")
  end

  a = lanes.gen("*",loop)()
  b = lanes.gen("*", receiver)()

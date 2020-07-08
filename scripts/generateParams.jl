
using JSON


greetings = Dict("data" => "IVA inside, chat with me using @iva in your utterences", "type" => "message")  
pong = Dict("data" => "I just got a message from ", "type" => "message")
ping = Dict("type" => "ping", "data" => "")
basis = Dict(:greetings => greetings,
             :pong => pong, 
             :ping => ping)

open("resources/chatBasis.json", "w") do f
    JSON.print(f, basis)
end


dt = 2
botName = "@iva"

paramsIVACHACOLA = Dict(:dt => dt,
                        :botName => botName)

open("resources/paramsivachatcola.json", "w") do f
    JSON.print(f, paramsIVACHACOLA)
end

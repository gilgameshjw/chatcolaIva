
using HTTP
using JSON


function connectAndRunIVA(wsChatcola, io::IOStream) # ::HTTP.WebSockets.WebSockets)
    
    ivaURL = "ws://172.105.78.103:7777/ws"

    str1 = "{\"brain\":\"chatcola0\",\"lang\":\"en\",\"utterance\":\"\"}"
    str2 = "{\"brain\":\"chatcola0\",\"lang\":\"en\",\"utterance\":\"ping\"}"

    HTTP.WebSockets.open(ivaURL) do wsIVA

        # first message
        write(wsIVA, JSON.json(str1))
        s = wsIVA |> readavailable |> String
        dicMssg = JSON.parse(s)
        println(dicMssg)
        answ = copy(chatBasis["pong"]) |> 
                                (d -> (d["data"] = "LIVE BOT IVA:: " * dicMssg["utterance"];
                                       d))
        write(wsChatcola, JSON.json(answ))
        
        # second message
        write(wsIVA, JSON.json(str2))
        s = wsIVA |> readavailable |> String
        dicMssg = JSON.parse(s) # |> println
        println(dicMssg)
        answ = copy(chatBasis["pong"]) |> 
                                (d -> (d["data"] = "LIVE BOT IVA:: " * dicMssg["utterance"];
                                       d))
        write(wsChatcola, JSON.json(answ))

    end
    
end
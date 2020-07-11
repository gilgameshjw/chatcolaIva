
using HTTP
using JSON

using DandelionWebSockets

# Explicitly import the callback functions that we're going to add more methods for.
import DandelionWebSockets: on_text, on_binary,
                            state_connecting, state_open, state_closing, state_closed


mutable struct IvaHandler <: WebSocketHandler
    connection::Union{WebSocketConnection, Nothing}
    stop_channel::Channel{Any}

    IvaHandler(chan::Channel{Any}) = new(nothing, chan)
end

# These are called when you get text/binary frames, respectively.
on_binary(::IvaHandler, data::AbstractVector{UInt8}) = println("Received data: $(String(data))")

# These are called when the WebSocket state changes.

state_closing(::IvaHandler)    = println("State: CLOSING")
function state_connecting(e::IvaHandler, c::WebSocketConnection)
    println("State: CONNECTING TO IVA")
    e.connection = c
end







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
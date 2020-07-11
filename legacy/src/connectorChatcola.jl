
using HTTP
using JSON

using DandelionWebSockets

# Explicitly import the callback functions that we're going to add more methods for.
import DandelionWebSockets: on_text, on_binary,
                            state_connecting, state_open, state_closing, state_closed


mutable struct ChatcolaHandler <: WebSocketHandler
    connection::Union{WebSocketConnection, Nothing}
    stop_channel::Channel{Any}

    ChatcolaHandler(chan::Channel{Any}) = new(nothing, chan)
end

# These are called when you get text/binary frames, respectively.
on_text(::ChatcolaHandler, s::String)  = put!(cChatcola, s) # println("Received text: $s")
on_binary(::ChatcolaHandler, data::AbstractVector{UInt8}) = println("Received data: $(String(data))")

# These are called when the WebSocket state changes.

state_closing(::ChatcolaHandler)    = println("State: CLOSING")
function state_connecting(e::ChatcolaHandler, c::WebSocketConnection)
    println("State: CONNECTING")
    e.connection = c
end


function getChatcolaCredentials(slug,
                                urlToken="https://chatcola.com/api/auth/chatToken")
    
    dicRequest = Dict("slug" => slug,
                      "name" => "iva.0.0.1")
    
    HTTP.request("POST", 
                 urlToken,
                 ["Content-Type" => "application/json"],
                 JSON.json(dicRequest)) |>
        (r -> JSON.parse(String(r.body)))

end

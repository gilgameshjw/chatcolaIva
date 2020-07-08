#!/usr/bin/julia

using HTTP
using JSON
using Dates
using Logging


include("src/connectorChatcola.jl")
include("src/connectorIVA.jl")


if length(ARGS) != 1
    println("error:: expecting a slug arguments, e.g.")
    println("./scriptRunChatcolaIVA.jl 86f3270c-6a91-4ef9-b8de-804affe365d6")
    exit(code=1)
end

# e.g "86f3270c-6a91-4ef9-b8de-804affe365d6"
slug = ARGS[1]


loggerFilename = "logs/chatcola.log"
io = open(loggerFilename, "a")
logger = io |> SimpleLogger |> global_logger
@info now(), "start liveServer"; flush(io)


dataCreds = JSON.parsefile("resources/creds.json")

if slug != dataCreds["slug"]
    dataCreds = try 
    
            getChatcolaCredentials(slug)
            @info "could successfully get credentials"; flush(io)
    
                catch 
    
            @error "Could not obtain credentials"; flush(io)
            exit(code=1)
                end
    
    open("resources/creds.json", "w") do f
        JSON.print(f, dataCreds)
    end
end


chatBasis = JSON.parsefile("resources/chatBasis.json")
paramsIVACHACOLA = JSON.parsefile("resources/paramsivachatcola.json")

wssURL = "wss://chatcola.com/s/" * dataCreds["data"]["token"]

@info now(), "start liveServer"; flush(io)

chatBasis = JSON.parsefile("resources/chatBasis.json")
paramsIVACHACOLA = JSON.parsefile("resources/paramsivachatcola.json")
#dataCreds = JSON.parsefile("resources/creds.json")

wssURL = "wss://chatcola.com/s/" * dataCreds["data"]["token"]

@info now(), "start liveServer"; flush(io)


dt = paramsIVACHACOLA["dt"]
botName = paramsIVACHACOLA["botName"]
# hack = 0

HTTP.WebSockets.open(wssURL) do ws
    
    println(typeof(ws))
    
    x = readavailable(ws)
    # println(String(x))
    # if hack == 0
    write(ws, JSON.json(chatBasis["greetings"]))
    #    hack += 1
    # end
    
    lastId = nothing    
    t1 = now()
    
    while !eof(ws)
        
        s = readavailable(ws)
        # println(String(s))
        data = JSON.parse(String(s))
        println(data)
       
        
        if (data["type"] == "message")
         
            @info now(), "data", data; flush(io)
            author = data["data"]["author"]
            lastId = data["data"]["_id"]
            
            println(author)
            if author != "@iva.0.0.1" 
                                
                utterance = data["data"]["content"]
                
                copy(chatBasis["pong"]) |> 
                    (d -> (d["data"] = d["data"] * " " * author;
                           d)) |>
                    (A -> write(ws, JSON.json(A)))
                
                
                if occursin(botName, utterance)
                    println("call iva")

                    connectAndRunIVA(ws, io)

                end
                
                
                # Logging
                @info now(), "ping", data; flush(io)
                # @info now(), "pong", answ; flush(io)
                
            end
            
        end
        
        t2 = now()
        deltaT = ((t2 - t1).value / 1000)
        if deltaT >= 5
            write(ws, JSON.json(chatBasis["ping"]))
            # println("PING****")
            @info now(), "***PING***"; flush(io)
            t1 = now()
        end
        
        sleep(dt)

    end

end
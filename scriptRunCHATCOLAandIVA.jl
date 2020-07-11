#!/usr/bin/julia

using HTTP
using JSON
using Dates
using Logging


include("src/connectChatcola.jl")
include("src/connectIVA.jl")


if length(ARGS) != 1
    println("error:: expecting a slug arguments, e.g.")
    println("./scriptRunChatcolaIVA.jl 86f3270c-6a91-4ef9-b8de-804affe365d6")
    exit(code=1)
end

# e.g "86f3270c-6a91-4ef9-b8de-804affe365d6"
slug = ARGS[1]
ivaBotname = "chatcola0" # ARGS[2]

loggerFilename = "logs/chatcola.log"
io = open(loggerFilename, "a")
logger = io |> SimpleLogger |> global_logger
@info now(), "start liveServer"; flush(io)


dataCreds = JSON.parsefile("resources/creds.json")

if slug != dataCreds["slug"]
    
    # println(slug)
    dataCreds = try 
            
            getChatcolaCredentials(slug)
            # @info "could successfully get credentials"; flush(io)
    
                catch 
    
            @error "Could not obtain credentials"; flush(io)
            exit(code=1)
        
                end
      
    # println(dataCreds)
    dataCreds["slug"] = slug
    cat 
    open("resources/creds.json", "w") do f
        JSON.print(f, dataCreds)
    end
    
end


chatBasis = JSON.parsefile("resources/chatBasis.json")
paramsIVACHACOLA = JSON.parsefile("resources/paramsivachatcola.json")

@info now(), "start liveServer"; flush(io)

chatBasis = JSON.parsefile("resources/chatBasis.json")
paramsIVACHACOLA = JSON.parsefile("resources/paramsivachatcola.json")
dataCreds = JSON.parsefile("resources/creds.json")

dt = paramsIVACHACOLA["dt"]
botName = paramsIVACHACOLA["botName"]

wssURL = "wss://chatcola.com/s/" * dataCreds["data"]["token"]
ivaURL = "ws://172.105.78.103:7777/ws"

@info now(), "start liveServer"; flush(io)


#==========================
    IVA
==========================#

cIVA = Channel{String}(1) # conversatin channel
stateIVA = Channel{Bool}(1)
put!(stateIVA, false)

on_text(::IvaHandler, s::String)  = (put!(cIVA, s);
                                     @info now(), "iva:", s;
                                     #put!(stateIVA, true);
                                     flush(io))
stop_chanIVA = Channel{Any}(3)
clientIVA = WSClient()
handlerIVA = IvaHandler(stop_chanIVA)
wsconnect(clientIVA, ivaURL, handlerIVA)



function connectAndRunIVA(handler::IvaHandler, io::IOStream, mssg::String)
    
    #println("DBG1: ", mssg)
    # send message
    mssg = JSON.json("{\"brain\":\"$ivaBotname\",\"lang\":\"en\",\"utterance\":\"$mssg\"}")
    println("sending: " , mssg)
    send_text(handlerIVA.connection, mssg)
    
    
    # wait for the answer
    while length(cIVA.data) == 0   
        sleep(1)
    end    
    #println("DBG2")
    
    put!(stateIVA, true)
    
    # return parsed answer
    take!(cIVA) |>
        JSON.parse
    
end


#=========================
    CHATCOLA
=========================#

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
         
            if data["type"] != "pong"
                @info now(), "data", data; flush(io)
            end
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
                    println(stateIVA.data[1])
                    
                    utterance = utterance |> 
                                    split |> (V -> join(filter(s -> s != "@iva", V), " "))
                    
                    if !(take!(stateIVA))
                        
                        connectAndRunIVA(handlerIVA, io, "") |>
                            (U -> copy(chatBasis["pong"]) |> 
                                (d -> (d["data"] = "LIVE BOT IVA:: " * U["utterance"];
                                       d))) |>
                                    (A -> write(ws, JSON.json(A)))
                        @info now(), "iva starting::"; flush(io)
        
                    else
                    
                        connectAndRunIVA(handlerIVA, io, utterance) |>
                            (U -> copy(chatBasis["pong"]) |> 
                                (d -> (d["data"] = "LIVE BOT IVA:: " * U["utterance"];
                                       d))) |>
                                    (A -> write(ws, JSON.json(A)))
                        @info now(), "to iva:: ", utterance; flush(io)
                        
                    end
                        
                end
                
            end
            
        end
        
        t2 = now()
        deltaT = ((t2 - t1).value / 1000)
        if deltaT >= 5
            write(ws, JSON.json(chatBasis["ping"]))
            # println("PING****")
            ### @info now(), "***PING***"; flush(io)
            t1 = now()
        end
        
        sleep(dt)

    end

end


take!(stop_chanIVA)
take!(stop_chanCHATCOLA)

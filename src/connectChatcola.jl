
using HTTP
using JSON


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


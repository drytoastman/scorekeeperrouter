#!/usr/bin/lua

local json = require ("dkjson")

function readstate()
    file = io.open("/tmp/scorekeeper.json", "r")
    io.input(file)
    local obj, pos, err = json.decode(io.read())
    io.close(file)
    return obj
end

function service2link(addr, service)
    if service == 'REGISTRATION' then
        return string.format("http://%s/register", addr)
    end
    return string.format("http://%s/results", addr)
end

function service2name(service)
    if service == 'REGISTRATION' then
        return 'Registration'
    elseif service == 'DATAENTRY' then
        return 'Data Entry'
    else
        return 'Database'
    end
end

function redirect(state, service, target)
    for sid, entry in pairs(state) do
        if entry.services[service] ~= nil then
            io.write("Status: 302 Found\r\n")
            io.write(string.format("Location: http://%s/%s\r\n\r\n", entry.addr, target))
            os.exit(0)
        end
    end
end

function servererror(msg)
    io.write("Status: 500 Internal Server Error\r\n")
    io.write("Content-Type: text/plain\r\n\r\n")
    io.write(msg)
    os.exit(0)
end


function main_process()
    local host  = os.getenv("HTTP_HOST")
    local uri   = os.getenv("REQUEST_URI")
    local state = readstate()

    if (string.find(host, 'results')) or (string.find(uri, 'results')) then
        redirect(state, 'DATAENTRY', 'results')
    end

    if (string.find(host, 'register')) or (string.find(uri, 'register')) then
        redirect(state, 'REGISTRATION', 'register')
    end


    io.write("Status: 200 OK\r\n")
    io.write("Content-Type: text/html\r\n\r\n")
    io.write([[
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset='UTF-8' />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Scorekeeper Redirector</title>

    <style type="text/css">
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol
    }

    div.server { 
        border: 1px solid #CCC;
        border-radius: 1rem;
        padding: 1rem;
        margin-bottom: 1rem;
    }

    div.addr {
        font-weight: 500;
        font-size: 1.3rem;
    }

    div.service {
        margin-left: 1rem;
        font-size: 1.2rem;
    }

    div.service a {
        display: inline-block;
        width: 5rem;
        text-align: right;
        margin-right: 0.5rem;
    }

    div.active::after {
        content: "\2a active";
        font-size: 1.0rem;
        font-weight: bold;
        color: green;
    }
    </style>
    </head>
    <body>

    <h3>Discovered Scorekeeper Servers</h3>
    ]])
    for sid, entry in pairs(state) do
        if entry.services.DATABASE then
            io.write("<div class='server'>\n")
            io.write(string.format("<div class='addr'>%s</div>\n", entry.addr))
            io.write(string.format("<div class='service %s'><a href='http://%s/results'>Results</a></div>\n",
                    entry.services.DATAENTRY and "active" or "", entry.addr))
            io.write(string.format("<div class='service %s'><a href='http://%s/register'>Register</a></div>\n",
                    entry.services.REGISTRATION and "active" or "", entry.addr))
            io.write(string.format("<div class='service'><a href='http://%s/admin'>Admin</a></div>\n",
                    entry.addr))
            io.write("</div>\n")
        end
    end
    io.write([[
    </body>
    </html>
    ]])
end


local ok, msg = pcall(main_process)
if not ok then
    servererror(msg)
end


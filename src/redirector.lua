#!/usr/bin/lua

local json = require ("dkjson")

function readstate()
    file = io.open("/tmp/scorekeeper.json", "r")
    io.input(file)
    local obj, pos, err = json.decode(io.read())
    io.close(file)
    return obj
end

function resulthtml(state)
    ret = {""}
    table.insert(ret, [[
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
            table.insert(ret, "<div class='server'>\n")
            table.insert(ret, string.format("<div class='addr'>%s</div>\n",
                    entry.addr))
            table.insert(ret, string.format("<div class='service %s'><a href='http://%s/results'>Results</a></div>\n",
                    entry.services.DATAENTRY and "active" or "", entry.addr))
            table.insert(ret, string.format("<div class='service %s'><a href='http://%s/register'>Register</a></div>\n",
                    entry.services.REGISTRATION and "active" or "", entry.addr))
            table.insert(ret, string.format("<div class='service'><a href='http://%s/admin'>Admin</a></div>\n",
                    entry.addr))
            table.insert(ret, "</div>\n")
        end
    end
    table.insert(ret, "</body></html>")
    return table.concat(ret, "")
end


function should_redirect(state, service, target)
    for sid, entry in pairs(state) do
        if entry.services[service] ~= nil then
            return string.format("http://%s/%s\r\n\r\n", entry.addr, target)
        end
    end
end

function find_redirect(state, host, uri)
    local redirectto = nil

    if (string.find(host, 'register')) or (string.find(uri, 'register')) then
        redirectto = should_redirect(state, 'REGISTRATION', 'register')
    end

    if (string.find(host, 'results')) or (string.find(uri, 'results')) then
        redirectto = should_redirect(state, 'DATAENTRY', 'results')
    end

    return redirectto
end


function cgi_process()
    local host  = os.getenv("HTTP_HOST")
    local uri   = os.getenv("REQUEST_URI")
    local state = readstate()
    local redirect = find_redirect(state, host, uri)

    if redirect ~= nil then
        io.write("Status: 302 Found\r\n")
        io.write("Location: "..redirect.."\r\n\r\n")
    else
        io.write("Status: 200 OK\r\n")
        io.write("Content-Type: text/html\r\n\r\n")
        io.write(resulthtml(state))
    end
end


function httpd_process()
    local socket = require ("socket")

    sock, err = socket.tcp4()
    sock:setoption('reuseaddr', true)
    res, err = sock:bind('127.0.0.1', 9000)
    res, err = sock:listen()

    while 1 do
        local client = sock:accept()
        client:settimeout(5)

        local hostline = nil
        local queryline = nil
        while 1 do
            local line,err = client:receive("*l")
            if line == nil or line == "\r\n" or line == "" then break end
            if (string.sub(line, 1, 3) == "GET") then
                queryline = line
            end
            if (string.sub(line, 1, 5) == "Host:") then
                hostline = line
            end
        end

        local state = readstate()
        local redirect = find_redirect(state, hostline, queryline)

        if redirect ~= nil then
            client:send("HTTP/1.1 302 Found\r\n")
            client:send("Location: "..redirect.."\r\n\r\n")
        else
            client:send("HTTP/1.1 200 OK\r\n")
            client:send("Content-Type: text/html\r\n\r\n")
            client:send(resulthtml(state))
        end

        client:close()
    end
end


if os.getenv("REQUEST_URI") == nil then
    -- Assuming we are started as a daemon for proxying, way easier to implement vs FastGCI
    httpd_process()
else
    -- Assuming we are started as a cgi script
    local ok, msg = pcall(cgi_process)
    if not ok then
        io.write("Status: 500 Internal Server Error\r\n")
        io.write("Content-Type: text/plain\r\n\r\n")
        io.write(msg)
    end
end


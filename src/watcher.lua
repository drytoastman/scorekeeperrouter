#!/usr/bin/lua

local socket = require ("socket")
local json   = require ("dkjson")

function dump(servers)
    file = io.open("/scorekeeper/state", "w")
    io.output(file)
    io.write(json.encode(servers))
    io.close(file)
end

function main_process() 
    local group = "224.0.0.251"
    local port = 5454
    local c = socket.udp()

    c:settimeout(1)
    c:setoption("reuseport", true)
    c:setsockname("0.0.0.0", port)
    c:setoption("ip-add-membership", {multiaddr=group, interface="192.168.10.8"})

    servers = {}

    while 1 do
        local msg, src = c:receivefrom()
        if msg then
           local obj, pos, err = json.decode(msg)

           if err then
              -- print ("Error: ", err)
           else
              for ii = 1,#obj do
                sid = obj[ii].serverid
                srv = obj[ii].service
                if servers[sid] == nil then
                    servers[sid] = {}
                end
                servers[sid].addr = src
                if servers[sid].services == nil then
                    servers[sid].services = {}
                end
                if servers[sid].services[srv] == nil then
                    --print(string.format("%s, %s, %s alive", sid, srv, src))
                    servers[sid].services[srv] = os.time() + 5
                    pcall(dump, servers)
                end
                servers[sid].services[srv] = os.time() + 5
              end
           end
        end

        now = os.time()
        for sid, entry in pairs(servers) do
            for service, timeout in pairs(entry.services) do
                if now > timeout then
                    -- print(string.format("%s, %s, %s dead", sid, service, entry.addr))
                    servers[sid].services[service] = nil
                    pcall(dump, servers)
                end
            end
        end
    end

end

main_process()


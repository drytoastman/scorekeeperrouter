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
    local sock = socket.udp()
    local servers = {}
    pcall(dump, servers)

    sock:settimeout(1)
    sock:setoption("reuseport", true)
    sock:setsockname("0.0.0.0", port)

    -- Run ifconfig and parse out IP addresses that are not localhost, we listen to all
    local handle = io.popen('ifconfig')
    local result = handle:read("*a")
    for ip in string.gmatch(result, "inet addr:(%d+.%d+.%d+.%d+)") do
        if string.sub(ip, 1, 5) ~= "127.0" then
            --print(string.format("Add membership on %s", ip))
            sock:setoption("ip-add-membership", {multiaddr=group, interface=ip})
        end
    end
    handle:close()


    while 1 do
        local msg, src = sock:receivefrom()
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


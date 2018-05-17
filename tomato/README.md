
# Overview

No easy way to get recent optware or entware onto the tomato based systems as they kernel is too old.
We must build a custom lua and luasocket.  This repo contains the dependencies for Linux 26 on MIPS (RT-AC66U).

1. Enable JFFS for the system
   * Make dir /jffs/bin

2. Move admin page to port 8080

3. Add script commands for WAN up
  * export LUA_PATH=/jffs/bin/?.lua LUA_CPATH=/jffs/bin/?.so
  * /jffs/bin/lua /jffs/bin/watcher.lua &
  * /jffs/bin/lua /jffs/bin/redirector.lua &

5. Add custom config lines to DHCP/DNS panel (change IP to IP of router)
  * local=/lan/
  * domain=lan
  * address=/results.lan/192.168.1.1
  * address=/register.lan/192.168.1.1

6. Copy local bin dir to /jffs/bin

7. Copy everything in ../src/ to /jffs/bin


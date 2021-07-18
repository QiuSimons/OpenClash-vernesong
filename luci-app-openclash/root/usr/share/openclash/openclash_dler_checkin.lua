#!/usr/bin/lua

require "nixio"
require "luci.util"
require "luci.sys"
local uci = require("luci.model.uci").cursor()
local fs = require "luci.openclash"
local json = require "luci.jsonc"

local function dler_checkin()
	local info, path, checkin
	local email = uci:get("openclash", "config", "dler_email")
	local passwd = uci:get("openclash", "config", "dler_passwd")
	local enable = uci:get("openclash", "config", "dler_checkin") or 0
	local interval = uci:get("openclash", "config", "dler_checkin_interval") or 1
	local multiple = uci:get("openclash", "config", "dler_checkin_multiple") or 1
	path = "/tmp/dler_checkin"
	if email and passwd and enable == "1" then
		checkin = string.format("curl -sL -d 'email=%s' -d 'passwd=%s' -d 'multiple=%s' -X POST https://dler.cloud/api/v1/checkin -o %s", email, passwd, multiple, path)
		if not nixio.fs.access(path) then
			luci.sys.exec(checkin)
		else
			if fs.readfile(path) == "" or not fs.readfile(path) then
				luci.sys.exec(checkin)
			else
				if (os.time() - fs.mtime(path) > interval*3600+1) then
					luci.sys.exec(checkin)
				else
					os.exit(0)
				end
			end
		end
		info = fs.readfile(path)
		if info then
			info = json.parse(info)
		end
		if info.ret == 200 then
			luci.sys.exec(string.format('echo "%s Dler Cloud Checkin Successful, Result:【%s】" >> /tmp/openclash.log', os.date("%Y-%m-%d %H:%M:%S"), info.data.checkin))
			os.exit(0)
		else
			if info.msg then
				luci.sys.exec(string.format('echo "%s Dler Cloud Account Checkin Failed, Result:【%s】" >> /tmp/openclash.log', os.date("%Y-%m-%d %H:%M:%S"), info.msg))
			else
				luci.sys.exec(string.format('echo "%s Dler Cloud Checkin Failed! Please Check And Try Again..."" >> /tmp/openclash.log', os.date("%Y-%m-%d %H:%M:%S")))
			end
			os.exit(0)
		end
	else
		os.exit(0)
	end
end

dler_checkin()
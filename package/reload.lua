--[[

-- usage --

package.reload:register(object) -> object:destroy()
package.reload:register(cb)     -> cb()

package.reload:register(cb,...) -> cb(...)
package.reload:register(ref,cb) -> cb(ref)

]]

local M
local N = ...
local fiber = require 'fiber'
local log = require 'log'

local function numstr( n )
	if n == 1 then return '1st'
	elseif n == 2 then return '2nd'
	elseif n == 3 then return '3rd'
	else return tostring(n)..'th'
	end
end

package.loaded[N] = nil

if not package.reload then
	
	local fio = require('fio');
	local src = debug.getinfo(3, "S").source:sub(2);
	
	-- Keep original file path, even if it was a symlink
	--local lnk = fio.readlink(src);
	--if lnk then src = lnk end;

	M = setmetatable({
		O      = {};
		F      = {};
		C      = {};
		loaded = {};
		count  = 1;
		script = src;
		started = os.date("%Y-%m-%dT%H:%M:%S");

		-- spin   = 1; -- id of currently starting generation
		-- turn   = 0; -- id of successfully loaded generation
		-- roll step ring

	},{
		__tostring = function () return 'package.reload{}' end;
		__call = function(m,...)
			if type(box.cfg) ~= 'function' then box.session.su('admin') end
			dofile(M.script)
		end;
	})
	local loaded = {}
	for m in pairs(package.loaded) do
		M.loaded[m] = package.loaded[m]
		table.insert(loaded,m)
	end
	log.info("1st load. loaded: %s",table.concat(loaded, ", "))
	package.reload = M
else
	M = package.reload
	M:_reload()
end

function M:wait_start()
	if self._wait_start == nil then
		self._wait_start = fiber.channel(1)
	elseif self._wait_start then
		---
	else
		return
	end
	return self._wait_start:get()
end

function M:_reload()
	M.count = M.count + 1
	local unload = {}
	for m in pairs(package.loaded) do
		if not M.loaded[m] then
			table.insert(unload,m)
			package.loaded[m] = nil
		end
	end
	log.info("%s load. Unloading {%s}",numstr(M.count),table.concat(unload, ", "))
	M.reloaded = os.date("%Y-%m-%dT%H:%M:%S");
	M:cleanup()
end

function M:cleanup()
	log.info("%s:cleanup...",N)
	if self.main then
		package.loaded[self.main] = nil
	end
	collectgarbage()
	for ref,cb in pairs(self.O) do
		cb(ref)
		self.O[ref] = nil
	end
	for f in pairs(self.F) do
		f()
		self.F[f] = nil
	end
	for t in pairs(self.C) do
		local cb = t[1]
		table.remove(t,1)
		cb(unpack(t))
		self.C[t] = nil
	end
	log.info("%s:cleanup finished",N)
	collectgarbage()
end

M.deregister = M.cleanup

function M:register(...)
	assert( self == M, "Static call" )
	if select('#',...) == 1 then
		local arg = ...
		if type(arg) == 'table' then
			if arg.destroy then
				self.O[ arg ] = arg.destroy
			else
				error("One arg call with object, but have no destroy method")
			end
		elseif type(arg) == 'function' then
			self.F[arg] = arg
		else
			error("One arg call with unsupported type: ",type(arg))
		end
	else
		local arg1 = ...
		if type(arg1) == 'function' then
			local t = {...}
			self.C[t] = t
		elseif select('#',...) == 2 then
			local ref,cb = ...
			if type(cb) == 'function' then
				self.O[ref] = cb
			else
				error("Bad arguments")
			end
		else
			error("Bad arguments: ", ...)
		end
	end
end
local yaml = require 'yaml'
fiber.create(function()
	local x = 0
	repeat
		-- log.error("Cleanup wait...")
		fiber.sleep(x/1e5)
		x = x + 1
	until type(box.cfg) ~= 'function' and box.info.status == 'running'
	require('log').error("Cleanup %s, %s", x, box.info.status)
	package.loaded[N] = nil
	if M._wait_start then
		while M._wait_start:has_readers() do
			M._wait_start:put(true)
		end
		M._wait_start = false
	end
	return
end)
return M

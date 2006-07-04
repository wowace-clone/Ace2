--[[
Name: AceConsole-2.0
Revision: $Rev: 3508 $
Author(s): ckknight (ckknight@gmail.com)
           cladhaire (cladhaire@gmail.com)
Inspired By: AceChatCmd 1.x by Turan (<email here>)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceConsole-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceConsole-2.0
Description: Mixin to allow for input/output capabilities. This uses the
             AceOptions data table format to determine input.
             http://wiki.wowace.com/index.php/AceOptions_data_table
Dependencies: AceLibrary, AceOO-2.0
]]

local MAJOR_VERSION = "AceConsole-2.0"
local MINOR_VERSION = "$Revision: 5508 $"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0.") end

-- localize --
local MAP_ONOFF = { [false] = "|cffff0000Off|r", [true] = "|cff00ff00On|r" }
local MAP_ENABLEDDISABLED = { [false] = "|cffff0000Disabled|r", [true] = "|cff00ff00Enabled|r" }
local USAGE = "Usage"
local IS_CURRENTLY_SET_TO = "|cffffff7f%s|r is currently set to |cffffff7f[|r%s|cffffff7f]|r"
local IS_NOW_SET_TO = "|cffffff7f%s|r is now set to |cffffff7f[|r%s|cffffff7f]|r"
local IS_NOT_A_VALID_OPTION_FOR = "|cffffff7f%s|r is not a valid option for |cffffff7f%s|r"
local IS_NOT_A_VALID_VALUE_FOR = "|cffffff7f%s|r is not a valid value for |cffffff7f%s|r"
local NO_OPTIONS_AVAILABLE = "No options available"
local OPTION_HANDLER_NOT_FOUND = "Option handler |cffffff7f%q|r not found."
local OPTION_HANDLER_NOT_VALID = "Option handler not valid."
local OPTION_IS_DISABLED = "Option %q is disabled."
local TOGGLE_STANDBY = "Enable/disable this addon"
local TOGGLE_DEBUGGING = "Enable/disable debugging"
local PRINT_ADDON_INFO = "Print out addon info"
local SET_PROFILE = "Set profile for this addon"
local SET_PROFILE_USAGE = "{char || class || realm || <profile name>}"
local STANDBY = "Standby"
local ABOUT = "About"
local PROFILE = "Profile"
local DEBUGGING = "Debugging"
-- localize --

local NONE = NONE or "None"

local AceOO = AceLibrary("AceOO-2.0")
local AceEvent

local AceConsole = AceOO.Mixin { "Print", "CustomPrint", "RegisterChatCommand" }

local _G = getfenv(0)

local print
if DEFAULT_CHAT_FRAME then
	function print(text, name, r, g, b, frame, delay)
		if not name then
			(frame or DEFAULT_CHAT_FRAME):AddMessage(text, r, g, b, 1, delay or 5)
		else
			(frame or DEFAULT_CHAT_FRAME):AddMessage("|cffffff78" .. tostring(name) .. ":|r " .. text, r, g, b, 1, delay or 5)
		end
	end
else
	function print(text, name)
		if name then
			_G.print(tostring(name) .. ": " .. string.gsub(text, "|c%x%x%x%x%x%x%x%x(.-)|r", "%1"))
		else
			_G.print((string.gsub(text, "|c%x%x%x%x%x%x%x%x(.-)|r", "%1")))
		end
	end
end

local tmp
function AceConsole:CustomPrint(r, g, b, frame, delay, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	a1 = tostring(a1)
	if string.find(a1, "%%") then
		print(string.format(a1, tostring(a2), tostring(a3), tostring(a4), tostring(a5), tostring(a6), tostring(a7), tostring(a8), tostring(a9), tostring(a10), tostring(a11), tostring(a12), tostring(a13), tostring(a14), tostring(a15), tostring(a16), tostring(a17), tostring(a18), tostring(a19), tostring(a20)), self, r, g, b, frame or self.printFrame, delay)
	else
		if not tmp then
			tmp = {}
		end
		table.insert(tmp, a1)
		if a2 ~= nil then table.insert(tmp, tostring(a2))
		if a3 ~= nil then table.insert(tmp, tostring(a3))
		if a4 ~= nil then table.insert(tmp, tostring(a4))
		if a5 ~= nil then table.insert(tmp, tostring(a5))
		if a6 ~= nil then table.insert(tmp, tostring(a6))
		if a7 ~= nil then table.insert(tmp, tostring(a7))
		if a8 ~= nil then table.insert(tmp, tostring(a8))
		if a9 ~= nil then table.insert(tmp, tostring(a9))
		if a10 ~= nil then table.insert(tmp, tostring(a10))
		if a11 ~= nil then table.insert(tmp, tostring(a11))
		if a12 ~= nil then table.insert(tmp, tostring(a12))
		if a13 ~= nil then table.insert(tmp, tostring(a13))
		if a14 ~= nil then table.insert(tmp, tostring(a14))
		if a15 ~= nil then table.insert(tmp, tostring(a15))
		if a16 ~= nil then table.insert(tmp, tostring(a16))
		if a17 ~= nil then table.insert(tmp, tostring(a17))
		if a18 ~= nil then table.insert(tmp, tostring(a18))
		if a19 ~= nil then table.insert(tmp, tostring(a19))
		if a20 ~= nil then table.insert(tmp, tostring(a20))
		end end end end end end end end end end end end end end end end end end end
		print(table.concat(tmp, " "), self, r, g, b, frame or self.printFrame, delay)
		for k,v in tmp do
			tmp[k] = nil
		end
		table.setn(tmp, 0)
	end
end

function AceConsole:Print(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	AceConsole.CustomPrint(self, nil, nil, nil, nil, nil, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
end

local work
local argwork

local function findTableLevel(self, options, chat, text, index, passTable)
	if not index then
		index = 1
		if work then
			for k,v in pairs(work) do
				work[k] = nil
			end
			table.setn(work, 0)
			for k,v in pairs(argwork) do
				argwork[k] = nil
			end
			table.setn(argwork, 0)
		else
			work = {}
			argwork = {}
		end
		for token in string.gfind(text, "([^%s]+)") do 
			local num = tonumber(token)
			if num then
				token = num
			end
			table.insert(work, token) 
		end
	end
	
	local path = chat
	for i = 1, index - 1 do
		path = path .. " " .. tostring(work[i])
	end
	
	if type(options.args) == "table" then
		local disabled, hidden = options.disabled, options.hidden
		if hidden then
			if type(hidden) == "function" then
				hidden = hidden()
			elseif type(hidden) == "string" then
				local handler = options.handler or self
				hidden = handler[hidden](handler)
			end
		end
		if hidden then
			disabled = true
		elseif disabled then
			if type(disabled) == "function" then
				disabled = disabled()
			elseif type(disabled) == "string" then
				local handler = options.handler or self
				disabled = handler[disabled](handler)
			end
		end
		if not disabled then
			local next = work[index] and string.lower(work[index])
			if next then
				for k,v in options.args do
					if string.lower(k) == next then
						return findTableLevel(options.handler or self, v, chat, text, index + 1, options.pass and options or nil)
					end
				end
			end
		end
	end
	for i = index, table.getn(work) do
		table.insert(argwork, work[i])
	end
	return options, path, argwork, options.handler or self, passTable, passTable and work[index - 1]
end

local function validateOptionsMethods(self, options, position)
	if type(options) ~= "table" then
		return "Options must be a table.", position
	end
	self = options.handler or self
	if options.type == "execute" then
		if options.func and type(options.func) ~= "string" and type(options.func) ~= "function" then
			return "func must be a string or function", position
		end
		if options.func and type(options.func) == "string" and type(self[options.func]) ~= "function" then
			return string.format("%q is not a proper function", options.func), position
		end
	else
		if options.get then
			if type(options.get) ~= "string" and type(options.get) ~= "function" then
				return "get must be a string or function", position
			end
			if type(options.get) == "string" and type(self[options.get]) ~= "function" then
				return string.format("%q is not a proper function", options.get), position
			end
		end
		if options.set then
			if type(options.set) ~= "string" and type(options.set) ~= "function" then
				return "set must be a string or function", position
			end
			if type(options.set) == "string" and type(self[options.set]) ~= "function" then
				return string.format("%q is not a proper function", options.set), position
			end
		end
		if options.validate and type(options.validate) ~= "table" then
			if type(options.validate) ~= "string" and type(options.validate) ~= "function" then
				return "validate must be a string or function", position
			end
			if type(options.validate) == "string" and type(self[options.validate]) ~= "function" then
				return string.format("%q is not a proper function", options.validate), position
			end
		end
	end
	if options.disabled and type(options.disabled) == "string" and type(self[options.disabled]) ~= "function" then
		return string.format("%q is not a proper function", options.disabled), position
	end
	if options.hidden and type(options.hidden) == "string" and type(self[options.hidden]) ~= "function" then
		return string.format("%q is not a proper function", options.hidden), position
	end
	if options.type == "group" and type(options.args) == "table" then
		for k,v in pairs(options.args) do
			if type(v) == "table" then
				local newposition
				if position then
					newposition = position .. ".args." .. k
				else
					newposition = "args." .. k
				end
				local err, pos = validateOptionsMethods(self, v, newposition)
				if err then
					return err, pos
				end
			end
		end
	end
end

local function validateOptions(self, options, position, baseOptions, fromPass)
	if not baseOptions then
		baseOptions = options
	end
	if type(options) ~= "table" then
		return "Options must be a table.", position
	end
	local kind = options.type
	if type(kind) ~= "string" then
		return '"type" must be a string.', position
	elseif kind ~= "group" and kind ~= "range" and kind ~= "text" and kind ~= "execute" and kind ~= "toggle" and kind ~= "color" then
		return '"type" must either be "range", "text", "group", "toggle", "execute", or "color".', position
	end
	if not fromPass then
		if kind == "execute" then
			if type(options.func) ~= "string" and type(options.func) ~= "function" then
				return '"func" must be a string or function', position
			end
		elseif kind == "range" or kind == "text" or kind == "toggle" then
			if type(options.set) ~= "string" and type(options.set) ~= "function" then
				return '"set" must be a string or function', position
			end
			if kind == "text" and options.get == false then
			elseif type(options.get) ~= "string" and type(options.get) ~= "function" then
				return '"get" must be a string or function', position
			end
		elseif kind == "group" and options.pass then
			if options.pass ~= true then
				return '"pass" must be either nil, true, or false', position
			end
			if not options.func then
				if type(options.set) ~= "string" and type(options.set) ~= "function" then
					return '"set" must be a string or function', position
				end
				if type(options.get) ~= "string" and type(options.get) ~= "function" then
					return '"get" must be a string or function', position
				end
			elseif type(options.func) ~= "string" and type(options.func) ~= "function" then
				return '"func" must be a string or function', position
			end
		end
	else
		if kind == "group" then
			return 'cannot have "type" = "group" as a subgroup of a passing group', position
		end
	end
	if options ~= baseOptions then
		if type(options.desc) ~= "string" then
			return '"desc" must be a string', position
		end
	end
	if options ~= baseOptions or kind == "range" or kind == "text" or kind == "toggle" or kind == "color" then
		if type(options.name) ~= "string" then
			return '"name" must be a string', position
		end
	end
	if options.message and type(options.message) ~= "string" then
		return '"message" must be a string or nil', position
	end
	if options.error and type(options.error) ~= "string" then
		return '"error" must be a string or nil', position
	end
	if options.current and type(options.current) ~= "string" then
		return '"current" must be a string or nil', position
	end
	if options.disabled then
		if type(options.disabled) ~= "function" and type(options.disabled) ~= "string" and options.disabled ~= true then
			return '"disabled" must be a function, string, or boolean', position
		end
	end
	if options.hidden then
		if type(options.hidden) ~= "function" and type(options.hidden) ~= "string" and options.hidden ~= true then
			return '"hidden" must be a function, string, or boolean', position
		end
	end
	if kind == "text" then
		if type(options.validate) == "table" then
		else
			if type(options.usage) ~= "string" then
				return '"usage" must be a string', position
			elseif options.validate and type(options.validate) ~= "string" and type(options.validate) ~= "function" then
				return '"validate" must be a string or function', position
			end
		end
	elseif kind == "range" then
		if options.min or options.max then
			if type(options.min) ~= "number" then
				return '"min" must be a number', position
			elseif type(options.max) ~= "number" then
				return '"max" must be a number', position
			elseif options.min >= options.max then
				return '"min" must be less than "max"', position
			end
		end
		if options.isPercent and options.isPercent ~= true then
			return '"isPercent" must either be nil, true, or false', position
		end
	elseif kind == "toggle" then
		if options.map then
			if type(options.map) ~= "table" then
				return '"map" must be a table', position
			elseif type(options.map[true]) ~= "string" then
				return '"map[true]" must be a string', position
			elseif type(options.map[false]) ~= "string" then
				return '"map[false]" must be a string', position
			end
		end
	elseif kind == "color" then
		if options.hasAlpha and options.hasAlpha ~= true then
			return '"hasAlpha" must be nil, true, or false', position
		end
	elseif kind == "group" then
		if options.pass and options.pass ~= true then
			return '"pass" must be nil, true, or false', position
		end
		if type(options.args) ~= "table" then
			return '"args" must be a table', position
		end
		for k,v in pairs(options.args) do
			if type(k) ~= "string" then
				return '"args" keys must be strings', position
			end
			if not string.find(k, "^%w+$") then
				return string.format('"args" keys must be standard strings. %q is not appropriate.', k), position
			end
			if type(v) ~= "table" then
				return '"args" values must be tables', position and position .. "." .. k or k
			end
			local newposition
			if position then
				newposition = position .. ".args." .. k
			else
				newposition = "args." .. k
			end
			local err, pos = validateOptions(self, v, newposition, baseOptions, options.pass)
			if err then
				return err, pos
			end
		end
	end
end

local colorTable
local colorFunc
local colorCancelFunc

function AceConsole:RegisterChatCommand(slashCommands, options, name)
	if type(slashCommands) ~= "table" then
		error(string.format("Bad argument #2 to `RegisterInputCommand' (expected table, got %s)", tostring(type(slashCommands))), 2)
	end
	if type(options) ~= "table" and type(options) ~= "function" and options ~= nil then
		error(string.format("Bad argument #3 to `RegisterInputCommand' (expected table, function, or nil, got %s)", tostring(type(options))), 2)
	end
	if name then
		if type(name) ~= "string" then
			error(string.format("Bad argument #4 to `RegisterInputCommand' (expected string or nil, got %s)", tostring(type(name))), 2)
		elseif not string.find(name, "^%w+$") or string.upper(name) ~= name or string.len(name) == 0 then
			error("Argument #4 must be an uppercase, letters-only string with at least 1 character", 2)
		end
	end
	if table.getn(slashCommands) == 0 then
		error("Argument #2 must include at least one string")
	end
	
	for k,v in pairs(slashCommands) do
		if type(k) ~= "number" then
			error("All keys in argument #2 must be numbers", 2)
		end
		if type(v) ~= "string" then
			error("All values in argument #2 must be strings", 2)
		elseif not string.find(v, "^/[A-Za-z][A-Za-z0-9_]*$") then
			error("All values in argument #2 must be in the form of \"/word\"", 2)
		end
	end
	
	if not options then
		options = {
			type = 'group',
			args = {}
		}
	end
	
	if type(options) == "table" then
		local err, position = validateOptions(self, options)
		if err then
			if position then
				error(position .. ": " .. err, 2)
			else
				error(err, 2)
			end
		end
		
		if not options.type or string.lower(options.type) == "group" then
			if type(self.ToggleStandby) == "function" and type(self.IsEnabled) == "function" then
				if type(options.args) ~= "table" then
					options.args = {}
				end
				if options.args.standby == nil then
					options.args.standby = {
						name = STANDBY,
						desc = TOGGLE_STANDBY,
						type = "toggle",
						get = "IsEnabled",
						set = "ToggleStandby",
						map = MAP_ENABLEDDISABLED
					}
				end
			end
			if type(self.PrintAddonInfo) == "function" then
				if type(options.args) ~= "table" then
					options.args = {}
				end
				if options.args.about == nil then
					options.args.about = {
						name = ABOUT,
						desc = PRINT_ADDON_INFO,
						type = "execute",
						func = "PrintAddonInfo",
					}
				end
			end
			if type(self.SetProfile) == "function" and type(self.GetProfile) == "function" then
				if type(options.args) ~= "table" then
					options.args = {}
				end
				if options.args.profile == nil then
					options.args.profile = {
						name = PROFILE,
						desc = SET_PROFILE,
						get = function()
							local profile = self:GetProfile()
							if profile then
								local a,b = string.find(profile, "/")
								if a then
									profile = string.sub(profile, 1, a - 1)
								end
							end
							return profile
						end,
						set = "SetProfile",
						usage = SET_PROFILE_USAGE,
						type = "text",
						input = true,
						validate = function(x) return not tonumber(x) end,
					}
				end
			end
			if type(self.SetDebugging) == "function" and type(self.IsDebugging) == "function" then
				if type(options.args) ~= "table" then
					options.args = {}
				end
				if options.args.debug == nil then
					options.args.debug = {
						name = DEBUGGING,
						desc = TOGGLE_DEBUGGING,
						type = "toggle",
						get = "IsDebugging",
						set = "SetDebugging"
					}
				end
			end
		end
	end
	
	local chat = slashCommands[1]
	
	local realOptions = options
	local handler
	if type(options) == "function" then
		handler = options
	else
		function handler(msg)
			if not msg then
				msg = ""
			else
				msg = string.gsub(msg, "^%s*(.-)%s*$", "%1")
				msg = string.gsub(msg, "%s+", " ")
			end
			
			local options, path, args, handler, passTable, passValue = findTableLevel(self, options, chat, msg)
			
			local hidden, disabled = options.hidden, options.disabled
			if hidden then
				if type(hidden) == "function" then
					hidden = hidden()
				elseif type(hidden) == "string" then
					hidden = handler[hidden](handler)
				end
			end
			if hidden then
				disabled = true
			elseif disabled then
				if type(disabled) == "function" then
					disabled = disabled()
				elseif type(disabled) == "string" then
					disabled = handler[disabled](handler)
				end
			end
			local kind = string.lower(options.type or "group")
			if disabled then
				print(string.format(OPTION_IS_DISABLED, path), realOptions.name or self)
			elseif kind == "text" then
				if table.getn(args) > 0 then
					if (type(options.validate) == "table" and table.getn(args) > 1) or (type(options.validate) ~= "table" and not options.input) then
						local arg = table.concat(args, " ")
						for k,v in pairs(args) do
							args[k] = nil
						end
						table.setn(args, 0)
						table.insert(args, arg)
					end
					if options.validate then
						local good
						if type(options.validate) == "function" then
							good = options.validate(unpack(args))
						elseif type(options.validate) == "table" then
							local arg = args[1]
							arg = type(arg) == "string" and string.lower(arg) or arg
							for _,v in ipairs(options.validate) do
								if type(arg) == "string" then
									if string.lower(v) == arg then
										args[1] = v
										good = true
										break
									end
								elseif v == arg then
									good = true
									break
								end
							end
						else
							good = handler[options.validate](handler, unpack(args))
						end
						if not good then
							local usage
							if type(options.validate) == "table" then
								usage = "{" .. table.concat(options.validate, " || ") .. "}"
							else
								usage = options.usage or "{value}"
							end
							print(string.format(self.error or IS_NOT_A_VALID_OPTION_FOR, tostring(table.concat(args, " ")), path), realOptions.name or self)
							print(string.format("|cffffff7f%s:|r %s %s", USAGE, path, usage))
							return
						end
					end
					
					if passTable then
						if type(passTable.set) == "function" then
							passTable.set(passValue, unpack(args))
						else
							handler[passTable.set](handler, passTable.set, unpack(args))
						end
					else
						if type(options.set) == "function" then
							options.set(unpack(args))
						else
							handler[options.set](handler, unpack(args))
						end
					end
				end
				
				local var
				if passTable then
					if not passTable.get then
					elseif type(passTable.get) == "function" then
						var = passTable.get(passValue)
					else
						var = handler[passTable.get](handler, passValue)
					end
				else
					if not options.get then
					elseif type(options.get) == "function" then
						var = options.get()
					else
						var = handler[options.get](handler)
					end
				end
				
				if table.getn(args) > 0 then
					if (passTable and passTable.get) or options.get then
						print(string.format(options.message or IS_NOW_SET_TO, tostring(options.name), tostring(var or NONE)), realOptions.name or self)
					end
				else
					local usage
					if type(options.validate) == "table" then
						usage = "{" .. table.concat(options.validate, " || ") .. "}"
					else
						usage = options.usage or "{value}"
					end
					print(string.format("|cffffff7f%s:|r %s %s", USAGE, path, usage), realOptions.name or self)
					if (passTable and passTable.get) or options.get then
						print(string.format(options.current or IS_CURRENTLY_SET_TO, tostring(options.name), tostring(var or NONE)))
					end
				end
			elseif kind == "execute" then
				if passTable then
					if type(passFunc) == "function" then
						set(passValue)
					else
						handler[passFunc](handler, passValue)
					end
				else
					if type(options.func) == "function" then
						options.func()
					else
						local handler = options.handler or self
						handler[options.func](handler)
					end
				end
			elseif kind == "toggle" then
				local var
				if passTable then
					if type(passTable.get) == "function" then
						var = passTable.get(passValue)
					else
						var = handler[passTable.get](handler, passValue)
					end
					if type(passTable.set) == "function" then
						passTable.set(passValue, not var)
					else
						handler[passTable.set](handler, passValue, not var)
					end
					if type(passTable.get) == "function" then
						var = passTable.get(passValue)
					else
						var = handler[passTable.get](handler, passValue)
					end
				else
					local handler = options.handler or self
					if type(options.get) == "function" then
						var = options.get()
					else
						var = handler[options.get](handler)
					end
					if type(options.set) == "function" then
						options.set(not var)
					else
						handler[options.set](handler, not var)
					end
					if type(options.get) == "function" then
						var = options.get()
					else
						var = handler[options.get](handler)
					end
				end
				
				print(string.format(options.message or IS_NOW_SET_TO, tostring(options.name), (options.map or MAP_ONOFF)[var or false] or NONE), realOptions.name or self)
			elseif kind == "range" then
				local arg
				if table.getn(args) <= 1 then
					arg = args[1]
				else
					arg = table.concat(args, " ")
				end
	
				if arg then
					local min = options.min or 0
					local max = options.max or 1
					local good = false
					if type(arg) == "number" then
						if options.isPercent then
							arg = arg / 100
						end

						if arg >= min and arg <= max then
							good = true
						end
					end
					if not good then
						local usage
						local min = options.min or 0
						local max = options.max or 1
						if options.isPercent then
							min, max = min * 100, max * 100
						end
						local bit = "-"
						if min < 0 or max < 0 then
							bit = " - "
						end
						usage = string.format("{%s%s%s}", min, bit, max)
						print(string.format(self.error or IS_NOT_A_VALID_VALUE_FOR, tostring(arg), path), realOptions.name or self)
						print(string.format("|cffffff7f%s:|r %s %s", USAGE, path, usage))
						return
					end
					
					if passTable then
						if type(passTable.set) == "function" then
							passTable.set(passValue, arg)
						else
							handler[passTable.set](handler, passValue, arg)
						end
					else
						if type(options.set) == "function" then
							options.set(arg)
						else
							local handler = options.handler or self
							handler[options.set](handler, arg)
						end
					end
				end
				
				local var
				if passTable then
					if type(passTable.get) == "function" then
						var = passTable.get(passValue)
					else
						var = handler[passTable.get](handler, passValue)
					end
				else
					if type(options.get) == "function" then
						var = options.get()
					else
						local handler = options.handler or self
						var = handler[options.get](handler)
					end
				end
				
				if arg then
					if var and options.isPercent then
						var = tostring(var * 100) .. "%"
					end
					print(string.format(options.message or IS_NOW_SET_TO, tostring(options.name), tostring(var or NONE)), realOptions.name or self)
				else
					local usage
					local min = options.min or 0
					local max = options.max or 1
					if options.isPercent then
						min, max = min * 100, max * 100
						var = tostring(var * 100) .. "%"
					end
					local bit = "-"
					if min < 0 or max < 0 then
						bit = " - "
					end
					usage = "{" .. min .. bit .. max .. "}"
					print(string.format("|cffffff7f%s:|r %s %s", USAGE, path, usage), realOptions.name or self)
					print(string.format(options.current or IS_CURRENTLY_SET_TO, tostring(options.name), tostring(var or NONE)))
				end
			elseif kind == "color" then
				if table.getn(args) > 0 then
					local r,g,b,a
					if table.getn(args) == 1 then
						local arg = tostring(args[1])
						if options.hasAlpha then
							if string.len(arg) == 8 and string.find(arg, "^%x*$")  then
								r,g,b,a = tonumber(string.sub(arg, 1, 2), 16) / 255, tonumber(string.sub(arg, 3, 4), 16) / 255, tonumber(string.sub(arg, 5, 6), 16) / 255, tonumber(string.sub(arg, 7, 8), 16) / 255
							end
						else
							if string.len(arg) == 6 and string.find(arg, "^%x*$") then
								r,g,b = tonumber(string.sub(arg, 1, 2), 16) / 255, tonumber(string.sub(arg, 3, 4), 16) / 255, tonumber(string.sub(arg, 5, 6), 16) / 255
							end
						end
					elseif table.getn(args) == 4 and options.hasAlpha then
						local a1,a2,a3,a4 = args[1], args[2], args[3], args[4]
						if type(a1) == "number" and type(a2) == "number" and type(a3) == "number" and type(a4) == "number" and a1 <= 1 and a2 <= 1 and a3 <= 1 and a4 <= 1 then
							r,g,b,a = a1,a2,a3,a4
						elseif (type(a1) == "number" or string.len(a1) == 2) and string.find(a1, "^%x*$") and (type(a2) == "number" or string.len(a2) == 2) and string.find(a2, "^%x*$") and (type(a3) == "number" or string.len(a3) == 2) and string.find(a3, "^%x*$") and (type(a4) == "number" or string.len(a4) == 2) and string.find(a4, "^%x*$") then
							r,g,b,a = tonumber(a1, 16) / 255, tonumber(a2, 16) / 255, tonumber(a3, 16) / 255, tonumber(a4, 16) / 255
						end
					elseif table.getn(args) == 3 and not options.hasAlpha then
						local a1,a2,a3 = args[1], args[2], args[3]
						if type(a1) == "number" and type(a2) == "number" and type(a3) == "number" and a1 <= 1 and a2 <= 1 and a3 <= 1 then
							r,g,b = a1,a2,a3
						elseif (type(a1) == "number" or string.len(a1) == 2) and string.find(a1, "^%x*$") and (type(a2) == "number" or string.len(a2) == 2) and string.find(a2, "^%x*$") and (type(a3) == "number" or string.len(a3) == 2) and string.find(a3, "^%x*$") then
							r,g,b = tonumber(a1, 16) / 255, tonumber(a2, 16) / 255, tonumber(a3, 16) / 255
						end
					end
					if not r then
						print(string.format(self.error or IS_NOT_A_VALID_OPTION_FOR, table.concat(args, ' '), path), realOptions.name or self)
						print(string.format("|cffffff7f%s:|r %s {0-1} {0-1} {0-1}%s", USAGE, path, options.hasAlpha and " {0-1}" or ""))
						return
					end
					if passTable then
						if type(passTable.set) == "function" then
							passTable.set(passValue, r,g,b,a)
						else
							handler[passTable.set](handler, passValue, r,g,b,a)
						end
					else
						if type(options.set) == "function" then
							options.set(r,g,b,a)
						else
							handler[options.set](handler, r,g,b,a)
						end
					end
					
					local r,g,b,a
					if passTable then
						if type(passTable.get) == "function" then
							r,g,b,a = passTable.get(passValue)
						else
							r,g,b,a = handler[passTable.get](handler, passValue)
						end
					else
						if type(options.get) == "function" then
							r,g,b,a = options.get()
						else
							r,g,b,a = handler[options.get](handler)
						end
					end
					
					local s
					if type(r) == "number" and type(g) == "number" and type(b) == "number" then
						if options.hasAlpha and type(a) == "number" then
							s = string.format("|c%02x%02x%02x%02x%02x%02x%02x%02x|r", a*255, r*255, g*255, b*255, r*255, g*255, b*255, a*255)
						else
							s = string.format("|cff%02x%02x%02x%02x%02x%02x|r", r*255, g*255, b*255, r*255, g*255, b*255)
						end
					else
						s = NONE
					end
					print(string.format(options.message or IS_NOW_SET_TO, tostring(options.name), s), realOptions.name or self)
				else
					local r,g,b,a
					if passTable then
						if type(passTable.get) == "function" then
							r,g,b,a = passTable.get(passValue)
						else
							r,g,b,a = handler[passTable.get](handler, passValue)
						end
					else
						if type(options.get) == "function" then
							r,g,b,a = options.get()
						else
							r,g,b,a = handler[options.get](handler)
						end
					end
					
					if not colorTable then
						colorTable = {}
						local t = colorTable
						
						if ColorPickerOkayButton then
							local ColorPickerOkayButton_OnClick = ColorPickerOkayButton:GetScript("OnClick")
							ColorPickerOkayButton:SetScript("OnClick", function()
								if ColorPickerOkayButton_OnClick then
									ColorPickerOkayButton_OnClick()
								end
								if t.active then
									ColorPickerFrame.cancelFunc = nil
									ColorPickerFrame.func = nil
									ColorPickerFrame.opacityFunc = nil
									local r,g,b,a
									if t.passValue then
										if type(t.get) == "function" then
											r,g,b,a = t.get(t.passValue)
										else
											r,g,b,a = t.handler[t.get](t.handler, t.passValue)
										end
									else
										if type(t.get) == "function" then
											r,g,b,a = t.get()
										else
											r,g,b,a = t.handler[t.get](t.handler)
										end
									end
									if r ~= t.r or g ~= t.g or b ~= t.b or (t.hasAlpha and a ~= t.a) then
										local s
										if type(r) == "number" and type(g) == "number" and type(b) == "number" then
											if t.hasAlpha and type(a) == "number" then
												s = string.format("|c%02x%02x%02x%02x%02x%02x%02x%02x|r", a*255, r*255, g*255, b*255, r*255, g*255, b*255, a*255)
											else
												s = string.format("|cff%02x%02x%02x%02x%02x%02x|r", r*255, g*255, b*255, r*255, g*255, b*255)
											end
										else
											s = NONE
										end
										print(string.format(t.message, tostring(t.name), s), realOptions.name or self)
									end
									for k,v in pairs(t) do
										t[k] = nil
									end
								end
							end)
						end
					else
						for k,v in pairs(colorTable) do
							colorTable[k] = nil
						end
					end
					
					if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
						r,g,b = 1, 1, 1
					end
					if type(a) ~= "number" then
						a = 1
					end
					local t = colorTable
					t.r = r
					t.g = g
					t.b = b
					if hasAlpha then
						t.a = a
					end
					t.hasAlpha = options.hasAlpha
					t.handler = handler
					t.set = passTable and passTable.set or options.set
					t.get = passTable and passTable.get or options.get
					t.name = options.name
					t.message = options.message or IS_NOW_SET_TO
					t.passValue = passValue
					t.active = true
					
					if not colorFunc then
						colorFunc = function()
							local r,g,b = ColorPickerFrame:GetColorRGB()
							if t.hasAlpha then
								local a = 1 - OpacitySliderFrame:GetValue()
								if type(t.set) == "function" then
									if t.passValue then
										t.set(t.passValue, r,g,b,a)
									else
										t.set(r,g,b,a)
									end
								else
									if t.passValue then
										t.handler[t.set](t.handler, t.passValue, r,g,b,a)
									else
										t.handler[t.set](t.handler, r,g,b,a)
									end
								end
							else
								if type(t.set) == "function" then
									if t.passValue then
										set(t.passValue, r,g,b)
									else
										set(r,g,b)
									end
								else
									if t.passValue then
										t.handler[t.set](t.handler, t.passValue, r,g,b)
									else
										t.handler[t.set](t.handler, r,g,b)
									end
								end
							end
						end
					end
					
					ColorPickerFrame.func = colorFunc
					ColorPickerFrame.hasOpacity = options.hasAlpha
					if options.hasAlpha then
						ColorPickerFrame.opacityFunc = ColorPickerFrame.func
						ColorPickerFrame.opacity = 1 - a
					end
					ColorPickerFrame:SetColorRGB(r,g,b)
					
					if not colorCancelFunc then
						colorCancelFunc = function()
							if t.hasAlpha then
								if type(t.set) == "function" then
									if t.passValue then
										t.set(t.passValue, t.r,t.g,t.b,t.a)
									else
										t.set(t.r,t.g,t.b,t.a)
									end
								else
									if t.passValue then
										t.handler[t.set](t.handler, t.passValue, t.r,t.g,t.b,t.a)
									else
										t.handler[t.set](t.handler, t.r,t.g,t.b,t.a)
									end
								end
							else
								if type(t.set) == "function" then
									if t.passValue then
										t.set(t.passValue, t.r,t.g,t.b)
									else
										t.set(t.r,t.g,t.b)
									end
								else
									if t.passValue then
										t.handler[t.set](t.handler, t.passValue, t.r,t.g,t.b)
									else
										t.handler[t.set](t.handler, t.r,t.g,t.b)
									end
								end
							end
							for k,v in pairs(t) do
								t[k] = nil
							end
							ColorPickerFrame.cancelFunc = nil
							ColorPickerFrame.func = nil
							ColorPickerFrame.opacityFunc = nil
						end
					end
					
					ColorPickerFrame.cancelFunc = colorCancelFunc
					
					ShowUIPanel(ColorPickerFrame)
				end
			elseif kind == "group" then
				if table.getn(args) == 0 then
					-- usage statement
					local usage
					if next(options.args) then
						local order = {}
						for k in pairs(options.args) do
							table.insert(order, k)
						end
						table.sort(order)
						if options == realOptions then
							if options.desc then
								print(tostring(options.desc), realOptions.name or self)
								print(string.format("|cffffff7f%s:|r %s %s", USAGE, path, "{" .. table.concat(order, " || ") .. "}"))
							elseif self.description or self.notes then
								print(tostring(self.description or self.notes), realOptions.name or self)
								print(string.format("|cffffff7f%s:|r %s %s", USAGE, path, "{" .. table.concat(order, " || ") .. "}"))
							else
								print(string.format("|cffffff7f%s:|r %s %s", USAGE, path, "{" .. table.concat(order, " || ") .. "}"), realOptions.name or self)
							end
						else
							if options.desc then
								print(string.format("|cffffff7f%s:|r %s %s", USAGE, path, "{" .. table.concat(order, " || ") .. "}"), realOptions.name or self)
								print(tostring(options.desc))
							else
								print(string.format("|cffffff7f%s:|r %s %s", USAGE, path, "{" .. table.concat(order, " || ") .. "}"), realOptions.name or self)
							end
						end
						for _,k in ipairs(order) do
							local v = options.args[k]
							local hidden, disabled = v.hidden, v.disabled
							if hidden then
								if type(hidden) == "function" then
									hidden = hidden()
								elseif type(hidden) == "string" then
									local handler = v.handler or self
									hidden = handler[hidden](handler)
								end
							end
							if hidden then
								disabled = true
							elseif disabled then
								if type(disabled) == "function" then
									disabled = disabled()
								elseif type(disabled) == "string" then
									local handler = v.handler or self
									disabled = handler[disabled](handler)
								end
							end
							if v.get and v.type ~= "group" and v.type ~= "pass" and v.type ~= "execute" then
								local a1,a2,a3,a4
								if type(v.get) == "function" then
									if options.pass then
										a1,a2,a3,a4 = v.get(k)
									else
										a1,a2,a3,a4 = v.get()
									end
								else
									local handler = v.handler or self
									if options.pass then
										a1,a2,a3,a4 = handler[v.get](handler, k)
									else
										a1,a2,a3,a4 = handler[v.get](handler)
									end
								end
								if v.type == "color" then
									if v.hasAlpha then
										if not a1 or not a2 or not a3 or not a4 then
											s = NONE
										else
											s = string.format("|c%02x%02x%02x%02x%02x%02x%02x%02x|r", a4*255, a1*255, a2*255, a3*255, a4*255, a1*255, a2*255, a3*255)
										end
									else
										if not a1 or not a2 or not a3 then
											s = NONE
										else
											s = string.format("|cff%02x%02x%02x%02x%02x%02x|r", a1*255, a2*255, a3*255, a1*255, a2*255, a3*255)
										end
									end
								elseif v.type == "toggle" then
									if v.map then
										s = tostring(v.map[a1 or false] or NONE)
									else
										s = tostring(MAP_ONOFF[a1 or false] or NONE)
									end
								elseif v.type == "range" then
									if v.isPercent then
										s = tostring(a1 * 100) .. "%"
									else
										s = tostring(a1)
									end
								else
									s = tostring(a1 or NONE)
								end
								if not hidden then
									if disabled then
										local s = string.gsub(s, "|cff%x%x%x%x%x%x(.-)|r", "%1")
										local desc = string.gsub(v.desc or NONE, "|cff%x%x%x%x%x%x(.-)|r", "%1")
										print(string.format("|cffcfcfcf - %s: [%s]|r %s", k, s, desc))
									else
										print(string.format(" - |cffffff7f%s: [|r%s|cffffff7f]|r %s", k, s, v.desc or NONE))
									end
								end
							else
								if not hidden then
									if disabled then
										local desc = string.gsub(v.desc or NONE, "|cff%x%x%x%x%x%x(.-)|r", "%1")
										print(string.format("|cffcfcfcf - %s: %s", k, desc))
									else
										print(string.format(" - |cffffff7f%s:|r %s", k, v.desc or NONE))
									end
								end
							end
						end
					else
						if options.desc then
							desc = options.desc
							print(string.format("|cffffff7f%s:|r %s", USAGE, path), realOptions.name or self)
							print(tostring(options.desc))
						elseif options == realOptions and (self.description or self.notes) then
							print(tostring(self.description or self.notes), realOptions.name or self)
							print(string.format("|cffffff7f%s:|r %s", USAGE, path))
						else
							print(string.format("|cffffff7f%s:|r %s", USAGE, path), realOptions.name or self)
						end
						print(self, NO_OPTIONS_AVAILABLE)
					end
				else
					-- invalid argument
					print(string.format(options.error or IS_NOT_A_VALID_OPTION_FOR, args[1], path), realOptions.name or self)
				end
			end
		end
	end
	
	if not _G.SlashCmdList then
		_G.SlashCmdList = {}
	end
	
	if not name then
		repeat
			name = string.char(math.random(26) + string.byte('A')) .. string.char(math.random(26) + string.byte('A')) .. string.char(math.random(26) + string.byte('A')) .. string.char(math.random(26) + string.byte('A')) .. string.char(math.random(26) + string.byte('A')) .. string.char(math.random(26) + string.byte('A')) .. string.char(math.random(26) + string.byte('A')) .. string.char(math.random(26) + string.byte('A'))
		until not _G.SlashCmdList[name]
	end
	
	local i = 0
	for _,command in ipairs(slashCommands) do
		i = i + 1
		_G["SLASH_"..name..i] = command
		if string.lower(command) ~= command then
			i = i + 1
			_G["SLASH_"..name..i] = string.lower(command)
		end
	end
	_G.SlashCmdList[name] = handler
	if self ~= AceConsole and not self.slashCommand then
		self.slashCommand = slashCommands[1]
	end
	
	if AceEvent then
		if not AceConsole.nextAddon then
			AceConsole.nextAddon = {}
		end
		AceConsole.nextAddon[self] = options
		if not self.playerLogin then
			AceConsole:RegisterEvent("PLAYER_LOGIN", "PLAYER_LOGIN", true)
		end
	end
end

function AceConsole:PLAYER_LOGIN()
	self.playerLogin = true
	for addon, options in pairs(self.nextAddon) do
		local err, position = validateOptionsMethods(addon, options)
		if err then
			if position then
				error(tostring(addon) .. ": AceConsole: " .. position .. ": " .. err)
			else
				error(tostring(addon) .. ": AceConsole: " .. err)
			end
		end
		self.nextAddon[addon] = nil
	end
	
	self:RegisterChatCommand({ "/reload", "/rl", "/reloadui" }, ReloadUI, "RELOAD")
	local tmp
	self:RegisterChatCommand({ "/print" }, function(text)
		RunScript("local function func(...) for k,v in ipairs(arg) do arg[k] = tostring(v) end DEFAULT_CHAT_FRAME:AddMessage(table.concat(arg, ' ')) end func(" .. text .. ")")
	end, "PRINT")
end

local function external(self, major, instance)
	if major == "AceEvent-2.0" then
		AceEvent = instance
		
		AceEvent:embed(self)
	end
end

local function activate(self, oldLib, oldDeactivate)
	self.super.activate(self, oldLib, oldDeactivate)
	
	AceConsole = self
	
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

AceLibrary:Register(AceConsole, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
AceConsole = AceLibrary(MAJOR_VERSION)

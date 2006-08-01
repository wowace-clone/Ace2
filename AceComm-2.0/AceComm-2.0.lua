--[[
Name: AceComm-2.0
Revision: $Rev: 6076 $
Author(s): ckknight (ckknight@gmail.com)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceComm-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceComm-2.0
Description: Mixin to allow for inter-player addon communications.
Dependencies: AceLibrary, AceOO-2.0, AceEvent-2.0
]]

local MAJOR_VERSION = "AceComm-2.0"
local MINOR_VERSION = "$Revision: 6076 $"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0") end

local _G = getfenv(0)

local AceOO = AceLibrary("AceOO-2.0")
local Mixin = AceOO.Mixin
local AceComm = Mixin {
						"SendCommMessage",
						"SendPrioritizedCommMessage",
						"RegisterComm",
						"UnregisterComm",
						"UnregisterAllComms",
						"IsCommRegistered",
						"SetDefaultCommPriority",
						"SetCommPrefix",
					  }
AceComm.hooks = {}

local AceEvent = AceLibrary:HasInstance("AceEvent-2.0") and AceLibrary("AceEvent-2.0")

local new, del
do
	local list = setmetatable({}, {__mode="k"})
	
	function new()
		local t = next(list)
		if t then
			list[t] = nil
		else
			t = {}
		end
		return t
	end
	
	function del(t)
		setmetatable(t, nil)
		for k in pairs(t) do
			t[k] = nil
		end
		table.setn(t, 0)
		list[t] = true
		return nil
	end
end

local byte_a = string.byte('a')
local byte_z = string.byte('z')
local byte_A = string.byte('A')
local byte_Z = string.byte('Z')
local byte_h = string.byte('h')
local byte_deg = string.byte('°')


local Checksum
do
	local SOME_PRIME = 16777213
	function CheckSum(text)
		local counter = 1
		local len = string.len(text)
		for i = 1, len do
				counter = counter + string.byte(text, i) * math.pow(31, len - i)
		end
		counter = math.mod(counter, SOME_PRIME)
		return string.format("%06x", counter)
	end
end

local function GetLatency()
	local _,_,lag = GetNetStats()
	return lag / 1000
end

local function IsInChannel(chan)
	return GetChannelName(chan) ~= 0
end

-- Package a message for transmission
local function Encode(text, drunk)
	text = string.gsub(text, "°", "°±")
	if drunk then
		text = string.gsub(text, "h", "°h")
		-- encode a hidden character in front of all the "h"s and the same hidden character
    end
    text = string.gsub(text, "%z", "°\001") -- \000
    text = string.gsub(text, "\010", "°\011") -- \n
    text = string.gsub(text, "\124", "°\125") -- |
    -- encode assorted prohibited characters
	return text
end

local func
-- Clean a received message
local function Decode(text, drunk)
	if drunk then
		text = string.gsub(text, "([Ss])h", "%1")
		-- find "h"s added to any "s", remove.
	end
	if drunk then
		local _,x = string.find(text, "^.*°")
		text = string.gsub(text, "^(.*)°.-$", "%1")
		-- get rid of " ...hic!"
	end
	if not func then
		func = function(text)
			if text == "h" then
				return "h"
			elseif text == "±" then
				return "°"
			elseif text == "\001" then
				return "\000"
			elseif text == "\011" then
				return "\010"
			elseif text == "\125" then
				return "\124"
			end
		end
	end
    text = string.gsub(text, drunk and "°([h±\001\011\125])" or "°([±\001\011\125])", func)
	-- remove the hidden character and refix the prohibited characters.
    return text
end

local lastChannelJoined

function AceComm.hooks:JoinChannelByName(orig, channel, a,b,c,d,e,f,g,h,i)
	lastChannelJoined = channel
	return orig(channel, a,b,c,d,e,f,g,h,i)
end

local function JoinChannel(channel)
	if not IsInChannel(channel) then
		LeaveChannelByName(channel)
		AceComm:ScheduleEvent(JoinChannelByName, 0, channel)
	end
end

local function LeaveChannel(channel)
	if IsInChannel(channel) then
		LeaveChannelByName(channel)
	end
end

local switches = {}

local function SwitchChannel(former, latter)
	if IsInChannel(former) then
		LeaveChannelByName(former)
		local t = new()
		t.former = former
		t.latter = latter
		switches[t] = true
		return
	end
	if not IsInChannel(latter) then
		JoinChannelByName(latter)
	end
end

local shutdown = false

local zoneCache
local function GetCurrentZoneChannel()
	if not zoneCache then
		zoneCache = "AceCommZone" .. CheckSum(GetRealZoneText())
	end
	return zoneCache
end

local function SupposedToBeInChannel(chan)
	if not string.find(chan, "^AceComm") then
		return true
	elseif shutdown or not AceEvent:IsFullyInitialized() then
		return false
	end
	
	if chan == "AceComm" then
		return AceComm.registry.GLOBAL and next(AceComm.registry.GLOBAL) and true or false
	elseif string.find(chan, "^AceCommZone%x%x%x%x%x%x$") then
		if chan == GetCurrentZoneChannel() then
			return AceComm.registry.ZONE and next(AceComm.registry.ZONE) and true or false
		else
			return false
		end
	else
		return AceComm.registry.CUSTOM and AceComm.registry.CUSTOM[chan] and next(AceComm.registry.CUSTOM[chan]) and true or false
	end
end

local function LeaveAceCommChannels(all)
	if all then
		shutdown = true
	end
	local _,a,_,b,_,c,_,d,_,e,_,f,_,g,_,h,_,i,_,j = GetChannelList()
	local t = new()
	t.n = 0
	table.insert(t, a)
	table.insert(t, b)
	table.insert(t, c)
	table.insert(t, d)
	table.insert(t, e)
	table.insert(t, f)
	table.insert(t, g)
	table.insert(t, h)
	table.insert(t, i)
	table.insert(t, j)
	for _,v in ipairs(t) do
		if v and string.find(v, "^AceComm") then
			if not SupposedToBeInChannel(v) then
				LeaveChannelByName(v)
			end
		end
	end
	t = del(t)
end

local lastRefix = 0
local function RefixAceCommChannelsAndEvents()
	if GetTime() - lastRefix <= 5 then
		AceComm:ScheduleEvent(RefixAceCommChannelsAndEvents, 1)
		return
	end
	lastRefix = GetTime()
	LeaveAceCommChannels(false)
	
	local channel = false
	local whisper = false
	local addon = false
	if SupposedToBeInChannel("AceComm") then
		JoinChannel("AceComm")
		channel = true
	end
	if SupposedToBeInChannel(GetCurrentZoneChannel()) then
		JoinChannel(GetCurrentZoneChannel())
		channel = true
	end
	if AceComm.registry.CUSTOM then
		for k,v in pairs(AceComm.registry.CUSTOM) do
			if next(v) then
				JoinChannel(k)
				channel = true
			end
		end
	end
	if AceComm.registry.WHISPER then
		whisper = true
	end
	if AceComm.registry.GROUP or AceComm.registry.PARTY or AceComm.registry.RAID or AceComm.registry.BATTLEGROUND then
		addon = true
	end
	
	if channel then
		if not AceComm:IsEventRegistered("CHAT_MSG_CHANNEL") then
			AceComm:RegisterEvent("CHAT_MSG_CHANNEL")
		end
	else
		if AceComm:IsEventRegistered("CHAT_MSG_CHANNEL") then
			AceComm:UnregisterEvent("CHAT_MSG_CHANNEL")
		end
	end
	
	if whisper then
		if not AceComm:IsEventRegistered("CHAT_MSG_WHISPER") then
			AceComm:RegisterEvent("CHAT_MSG_WHISPER")
		end
	else
		if AceComm:IsEventRegistered("CHAT_MSG_WHISPER") then
			AceComm:UnregisterEvent("CHAT_MSG_WHISPER")
		end
	end
	
	if addon then
		if not AceComm:IsEventRegistered("CHAT_MSG_ADDON") then
			AceComm:RegisterEvent("CHAT_MSG_ADDON")
		end
	else
		if AceComm:IsEventRegistered("CHAT_MSG_ADDON") then
			AceComm:UnregisterEvent("CHAT_MSG_ADDON")
		end
	end
end


do
	local myFunc = function(k)
		if not IsInChannel(k.latter) then
			JoinChannelByName(k.latter)
		end
		del(k)
		switches[k] = nil
	end
	
	function AceComm:CHAT_MSG_CHANNEL_NOTICE(kind, _, _, deadName, _, _, _, num, channel)
		if kind == "YOU_LEFT" then
			if not string.find(channel, "^AceComm") then
				return
			end
			for k in pairs(switches) do
				if k.former == channel then
					self:ScheduleEvent(myFunc, 0, k)
				end
			end
			if channel == GetCurrentZoneChannel() then
				self:TriggerEvent("AceComm_LeftChannel", "ZONE")
			elseif channel == "AceComm" then
				self:TriggerEvent("AceComm_LeftChannel", "GLOBAL")
			else
				self:TriggerEvent("AceComm_LeftChannel", "CUSTOM", string.sub(channel, 8))
			end
			if string.find(channel, "^AceComm") and SupposedToBeInChannel(channel) then
				self:ScheduleEvent(JoinChannel, 0, channel)
			end
		elseif kind == "YOU_JOINED" then
			if num == 0 then
				if not string.find(deadName, "^AceComm") then
					return
				end
				self:ScheduleEvent(LeaveChannelByName, 0, deadName)
				local t = new()
				t.former = deadName
				t.latter = deadName
				switches[t] = true
			elseif channel == GetCurrentZoneChannel() then
				self:TriggerEvent("AceComm_JoinedChannel", "ZONE")
			elseif channel == "AceComm" then
				self:TriggerEvent("AceComm_JoinedChannel", "GLOBAL")
			else
				self:TriggerEvent("AceComm_JoinedChannel", "CUSTOM", string.sub(channel, 8))
			end
			if num ~= 0 and not SupposedToBeInChannel(channel) then
				LeaveChannel(channel)
			end
		end
	end
end

local Serialize
do
	local recurse
	local function _Serialize(value)
		local kind = type(value)
		if kind == "boolean" then
			if value then
				return "by"
			else
				return "bn"
			end
		elseif not value then
			return "-"
		elseif kind == "number" then
			local v = tostring(value)
			return "#" .. string.char(string.len(v)) .. v
		elseif kind == "string" then
			local len = string.len(value)
			if len <= 127 then
				return "s" .. string.char(len) .. value
			else
				return "S" .. string.char(math.floor(len / 256)) .. string.char(math.mod(len, 256)) .. value
			end
		elseif kind == "function" then
			local v = string.dump(value)
			local len = string.len(v)
			if len <= 127 then
				return "f" .. string.char(len) .. v
			else
				return "F" .. string.char(math.floor(len / 256)) .. string.char(math.mod(len, 256)) .. v
			end
		elseif kind == "table" then
			if recurse[value] then
				for k in pairs(recurse) do
					recurse[k] = nil
				end
				AceComm:error("Cannot serialize a recursive table")
				return
			end
			recurse[value] = true
			local t = new()
			for k,v in pairs(value) do
				table.insert(t, _Serialize(k))
				table.insert(t, _Serialize(v))
			end
			if not notFirst then
				for k in pairs(recurse) do
					recurse[k] = nil
				end
			end
			local s = table.concat(t)
			local len = string.len(s)
			if len <= 127 then
				return "t" .. string.char(len) .. s
			else
				return "T" .. string.char(math.floor(len / 256)) .. string.char(math.mod(len, 256)) .. s
			end
			t = del(t)
		end
	end
	
	function Serialize(value)
		if not recurse then
			recurse = new()
		end
		local chunk = _Serialize(value)
		for k in pairs(recurse) do
			recurse[k] = nil
		end
		return chunk
	end
end

local Deserialize
do
	local byte_b = string.byte('b')
	local byte_nil = string.byte('-')
	local byte_num = string.byte('#')
	local byte_s = string.byte('s')
	local byte_S = string.byte('S')
	local byte_f = string.byte('f')
	local byte_F = string.byte('F')
	local byte_t = string.byte('t')
	local byte_T = string.byte('T')
	
	local function _Deserialize(value, position)
		if not position then
			position = 1
		end
		local x = string.byte(value, position)
		if x == byte_b then
			local v = string.byte(value, position + 1)
			if v == "n" then
				return false, position + 1
			elseif v == "y" then
				return true, position + 1
			else
				error("Improper serialized value provided")
			end
		elseif x == byte_nil then
			return nil, position
		elseif x == byte_s then
			local len = string.byte(value, position + 1)
			return string.sub(value, position + 2, position + 1 + len), position + 1 + len
		elseif x == byte_S then
			local len = string.byte(value, position + 1) * 256 + string.byte(value, position + 2)
			return string.sub(value, position + 3, position + 2 + len), position + 2 + len
		elseif x == byte_num then
			local len = string.byte(value, position + 1)
			return tonumber(string.sub(value, position + 2, position + 1 + len)), position + 1 + len
		elseif x == byte_f then
			local len = string.byte(value, position + 1)
			return loadstring(string.sub(value, position + 2, position + 1 + len)), position + 1 + len
		elseif x == byte_F then
			local len = string.byte(value, position + 1) * 256 + string.byte(value, position + 2)
			return loadstring(string.sub(value, position + 3, position + 2 + len)), position + 2 + len
		elseif x == byte_t or x == byte_T then
			local finish
			local start
			if x == byte_t then
				local len = string.byte(value, position + 1)
				finish = position + 1 + len
				start = position + 2
			else
				local len = string.byte(value, position + 1) * 256 + string.byte(value, position + 2)
				finish = position + 2 + len
				start = position + 3
			end
			local t = new()
			local curr = start -  1
			while curr < finish do
				local key, l = _Deserialize(value, curr + 1)
				local value, m = _Deserialize(value, l + 1)
				curr = m
				t[key] = value
			end
			if type(t.n) ~= "number" then
				local i = 1
				while t[i] ~= nil do
					i = i + 1
				end
				table.setn(t, i - 1)
			end
			return t, finish
		else
			error("Improper serialized value provided")
		end
	end
	
	function Deserialize(value)
		local ret,msg = pcall(_Deserialize, value)
		if ret then
			return msg
		end
	end
end

local function GetCurrentGroupDistribution()
	if MiniMapBattlefieldFrame.status == "active" then
		return "BATTLEGROUND"
	elseif UnitInRaid("player") then
		return "RAID"
	elseif UnitInParty("player") then
		return "PARTY"
	else
		return nil
	end
end

local function IsInDistribution(dist, customChannel)
	if dist == "GROUP" then
		return GetCurrentGroupDistribution() and true or false
	elseif dist == "BATTLEGROUND" then
		return MiniMapBattlefieldFrame.status == "active"
	elseif dist == "RAID" then
		return UnitInRaid("player") == 1
	elseif dist == "PARTY" then
		return UnitInPart("player") == 1
	elseif dist == "GUILD" then
		return IsInGuild() == 1
	elseif dist == "GLOBAL" then
		return IsInChannel("AceComm")
	elseif dist == "ZONE" then
		return IsInChannel(GetCurrentZoneChannel())
	elseif dist == "WHISPER" then
		return true
	elseif dist == "CUSTOM" then
		return IsInChannel(customChannel)
	end
	error("unknown distribution: " .. dist, 2)
end

function AceComm:RegisterComm(prefix, distribution, method, a4)
	AceComm:argCheck(prefix, 2, "string")
	AceComm:argCheck(distribution, 3, "string")
	if distribution ~= "GLOBAL" and distribution ~= "WHISPER" and distribution ~= "PARTY" and distribution ~= "RAID" and distribution ~= "GUILD" and distribution ~= "BATTLEGROUND" and distribution ~= "GROUP" and distribution ~= "ZONE" and distribution ~= "CUSTOM" then
		AceComm:error('Argument #3 to `RegisterComm\' must be either "GLOBAL", "ZONE", "WHISPER", "PARTY", "RAID", "GUILD", "BATTLEGROUND", "GROUP", or "CUSTOM". %q is not appropriate', distribution)
	end
	local customChannel
	if distribution == "CUSTOM" then
		customChannel, method = method, a4
		AceComm:argCheck(customChannel, 4, "string")
		if string.len(customChannel) == 0 then
			AceComm:error('Argument #4 to `RegisterComm\' must be a non-zero-length string.')
		end
	end
	if self == AceComm then
		AceComm:argCheck(method, customChannel and 5 or 4, "function")
		self = method
	else
		AceComm:argCheck(method, customChannel and 5 or 4, "string", "function", "nil")
	end
	if not method then
		method = "OnCommReceive"
	end
	if type(method) == "string" and type(self[method]) ~= "function" then
		AceEvent:error("Cannot register comm %q to method %q, it does not exist", prefix, method)
	end
	
	local registry = AceComm.registry
	if not registry[distribution] then
		registry[distribution] = new()
	end
	if customChannel then
		customChannel = "AceComm" .. customChannel
		if not registry[distribution][customChannel] then
			registry[distribution][customChannel] = new()
		end
		if not registry[distribution][customChannel][prefix] then
			registry[distribution][customChannel][prefix] = new()
		end
		registry[distribution][customChannel][prefix][self] = method
	else
		if not registry[distribution][prefix] then
			registry[distribution][prefix] = new()
		end
		registry[distribution][prefix][self] = method
	end
	
	RefixAceCommChannelsAndEvents()
end

function AceComm:UnregisterComm(prefix, distribution, customChannel)
	AceComm:argCheck(prefix, 2, "string")
	AceComm:argCheck(distribution, 3, "string", "nil")
	if distribution and distribution ~= "GLOBAL" and distribution ~= "WHISPER" and distribution ~= "PARTY" and distribution ~= "RAID" and distribution ~= "GUILD" and distribution ~= "BATTLEGROUND" and distribution ~= "GROUP" and distribution ~= "CUSTOM" then
		AceComm:error('Argument #3 to `UnregisterComm\' must be either nil, "GLOBAL", "WHISPER", "PARTY", "RAID", "GUILD", "BATTLEGROUND", "GROUP", or "CUSTOM". %q is not appropriate', distribution)
	end
	if distribution == "CUSTOM" then
		AceComm:argCheck(customChannel, 3, "string")
		if string.len(customChannel) == 0 then
			AceComm:error('Argument #3 to `UnregisterComm\' must be a non-zero-length string.')
		end
	else
		AceComm:argCheck(customChannel, 3, "nil")
	end
	
	local registry = AceComm.registry
	if not distribution then
		for k,v in pairs(registry) do
			if v[prefix] and v[prefix][self] then
				AceComm.UnregisterComm(self, prefix, k)
			end
		end
		return
	end
	if self == AceComm then
		if distribution == "CUSTOM" then
			error(string.format("Cannot unregister comm %q::%q. Improperly unregistering from AceComm-2.0.", distribution, customChannel), 2)
		else
			error(string.format("Cannot unregister comm %q. Improperly unregistering from AceComm-2.0.", distribution), 2)
		end
	end
	if distribution == "CUSTOM" then
		customChannel = "AceComm" .. customChannel
		if not registry[distribution] or not registry[distribution][customChannel] or not registry[distribution][customChannel][prefix] or not registry[distribution][customChannel][prefix][self] then
			AceComm:error("Cannot unregister comm %q. %q is not registered with it.", distribution, self)
		end
		registry[distribution][customChannel][prefix][self] = nil
		
		if not next(registry[distribution][customChannel][prefix]) then
			registry[distribution][customChannel][prefix] = del(registry[distribution][customChannel][prefix])
		end
		
		if not next(registry[distribution][customChannel]) then
			registry[distribution][customChannel] = del(registry[distribution][customChannel])
		end
	else
		if not registry[distribution] or not registry[distribution][prefix] or not registry[distribution][prefix][self] then
			AceComm:error("Cannot unregister comm %q. %q is not registered with it.", distribution, self)
		end
		registry[distribution][prefix][self] = nil
		
		if not next(registry[distribution][prefix]) then
			registry[distribution][prefix] = del(registry[distribution][prefix])
		end
	end
	
	if not next(registry[distribution]) then
		registry[distribution] = del(registry[distribution])
	end
	
	RefixAceCommChannelsAndEvents()
end

function AceComm:UnregisterAllComms()
	local registry = AceComm.registry
	for k,distribution in pairs(registry) do
		for j,prefix in pairs(distribution) do
			if prefix[self] then
				AceComm.UnregisterComm(self)
			end
		end
	end
end

function AceComm:IsCommRegistered(prefix, distribution, customChannel)
	AceComm:argCheck(prefix, 2, "string")
	AceComm:argCheck(distribution, 3, "string", "nil")
	if distribution and distribution ~= "GLOBAL" and distribution ~= "WHISPER" and distribution ~= "PARTY" and distribution ~= "RAID" and distribution ~= "GUILD" and distribution ~= "BATTLEGROUND" and distribution ~= "GROUP" and distribution ~= "ZONE" and distribution ~= "CUSTOM" then
		AceComm:error('Argument #3 to `IsCommRegistered\' must be either "GLOBAL", "WHISPER", "PARTY", "RAID", "GUILD", "BATTLEGROUND", "GROUP", "ZONE", or "CUSTOM". %q is not appropriate', distribution)
	end
	if distribution == "CUSTOM" then
		AceComm:argCheck(customChannel, 4, "nil", "string")
		if customChannel then
			AceComm:error('Argument #4 to `IsCommRegistered\' must be a non-zero-length string or nil.')
		end
	else
		AceComm:argCheck(customChannel, 4, "nil")
	end
	local registry = AceComm.registry
	if not distribution then
		for k,v in pairs(registry) do
			if distribution == "CUSTOM" then
				for l,u in pairs(v) do
					if u[prefix] and u[prefix][self] then
						return true
					end
				end
			else
				if v[prefix] and v[prefix][self] then
					return true
				end
			end
		end
		return false
	elseif distribution == "CUSTOM" and not customChannel then
		if not registry[destination] then
			return false
		end
		for l,u in pairs(registry[destination]) do
			if u[prefix] and u[prefix][self] then
				return true
			end
		end
		return false
	elseif distribution == "CUSTOM" then
		customChannel = "AceComm" .. customChannel
		return registry[destination] and registry[destination][customChannel] and registry[destination][customChannel][prefix] and registry[destination][customChannel][prefix][self] and true or false
	end
	return registry[destination] and registry[destination][prefix] and registry[destination][prefix][self] and true or false
end

function AceComm:OnEmbedDisable(target)
	self.UnregisterAllComms(target)
end

local id = byte_Z

local function encodedChar(x)
	if x == 10 then
		return "°\011"
	elseif x == 0 then
		return "°\001"
	elseif x == 124 then
		return "°\125"
	elseif x == byte_h then
		return "°h"
	elseif x == byte_deg then
		return "°±"
	end
	return string.char(x)
end

local function SendMessage(prefix, priority, distribution, person, message)
	if distribution == "CUSTOM" then
		person = "AceComm" .. person
	end
	if not IsInDistribution(distribution, person) then
		return false
	end
	if distribution == "GROUP" then
		distribution = GetCurrentGroupDistribution()
		if not distribution then
			return false
		end
	end
	if id == byte_Z then
		id = byte_a
	elseif id == byte_z then
		id = byte_A
	else
		id = id + 1
	end
	local id = string.char(id)
	local drunk = distribution == "GLOBAL" or distribution == "WHISPER" or distribution == "ZONE" or distribution == "CUSTOM"
	prefix = Encode(prefix, drunk)
	message = Serialize(message)
	message = Encode(message, drunk)
	local headerLen = string.len(prefix) + 6
	local messageLen = string.len(message)
	local esses = 0
	if drunk then
		local _,alpha = string.gsub(prefix, "([Ss])", "%1")
		local _,bravo = string.gsub(message, "([Ss])", "%1")
		esses = alpha + bravo
	end
	local max
	if esses > 0 then
		if esses >= (250 - headerLen) then
			max = math.floor((messageLen / (250 - headerLen) + 1)  * 2)
		else
			max = math.floor((messageLen / (250 - headerLen) + 1)  * (esses / (250 - headerLen) + 1))
		end
	else
		max = math.floor(messageLen / (250 - headerLen) + 1)
	end
	if max > 1 then
		local segment = math.floor(messageLen / max + 0.5)
		local last = 0
		local good = true
		for i = 1, max do
			local bit
			if i == max then
				bit = string.sub(message, last + 1)
			else
				local next = segment * i
				if string.byte(message, next) == byte_deg then
					next = next + 1
				end
				bit = string.sub(message, last + 1, next)
				last = next
			end
			if distribution == "WHISPER" then
				bit = "/" .. prefix .. "\t" .. id .. encodedChar(i) .. encodedChar(max) .. "\t" .. bit .. "°"
				ChatThrottleLib:SendChatMessage(priority, prefix, bit, "WHISPER", nil, person)
			elseif distribution == "GLOBAL" or distribution == "ZONE" or distribution == "CUSTOM" then
				bit = prefix .. "\t" .. id .. encodedChar(i) .. encodedChar(max) .. "\t" .. bit .. "°"
				local channel
				if distribution == "GLOBAL" then
					channel = "AceComm"
				elseif distribution == "ZONE" then
					channel = GetCurrentZoneChannel()
				elseif distribution == "CUSTOM" then
					channel = person
				end
				local index = GetChannelName(channel)
				if index and index > 0 then
					ChatThrottleLib:SendChatMessage(priority, prefix, bit, "CHANNEL", nil, index)
				else
					good = false
				end
			else
				bit = id .. encodedChar(i) .. encodedChar(max) .. "\t" .. bit
				ChatThrottleLib:SendAddonMessage(priority, prefix, bit, distribution)
			end
		end
		return good
	else
		if distribution == "WHISPER" then
			message = "/" .. prefix .. "\t" .. id .. string.char(1) .. string.char(1) .. "\t" .. message .. "°"
			ChatThrottleLib:SendChatMessage(priority, prefix, message, "WHISPER", nil, person)
			return true
		elseif distribution == "GLOBAL" or distribution == "ZONE" or distribution == "CUSTOM" then
			message = prefix .. "\t" .. id .. string.char(1) .. string.char(1) .. "\t" .. message .. "°"
			local channel
			if distribution == "GLOBAL" then
				channel = "AceComm"
			elseif distribution == "ZONE" then
				channel = GetCurrentZoneChannel()
			elseif distribution == "CUSTOM" then
				channel = person
			end
			local index = GetChannelName(channel)
			if index and index > 0 then
				ChatThrottleLib:SendChatMessage(priority, prefix, message, "CHANNEL", nil, index)
				return true
			end
		else
			message = id .. string.char(1) .. string.char(1) .. "\t" .. message
			ChatThrottleLib:SendAddonMessage(priority, prefix, message, distribution)
			return true
		end
	end
	return false
end

function AceComm:SendPrioritizedCommMessage(priority, distribution, person, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	AceComm:argCheck(priority, 2, "string")
	if priority ~= "NORMAL" or priority ~= "BULK" or priority ~= "ALERT" then
		AceComm:error('Argument #2 to `SendPrioritizedCommMessage\' must be either "NORMAL", "BULK", or "ALERT"')
	end
	AceComm:argCheck(distribution, 3, "string")
	if distribution == "WHISPER" or distribution == "CUSTOM" then
		AceComm:argCheck(person, 4, "string")
		if string.len(person) == 0 then
			AceComm:error("Argument #4 to `SendPrioritizedCommMessage' must be a non-zero-length string")
		end
	else
		a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20 = person, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19
	end
	if self == AceComm then
		AceComm:error("Cannot send a comm message from AceComm directly.")
	end
	if distribution and distribution ~= "GLOBAL" and distribution ~= "WHISPER" and distribution ~= "PARTY" and distribution ~= "RAID" and distribution ~= "GUILD" and distribution ~= "BATTLEGROUND" and distribution ~= "GROUP" and distribution ~= "ZONE" and distribution ~= "CUSTOM" then
		AceComm:error('Argument #4 to `SendPrioritizedCommMessage\' must be either nil, "GLOBAL", "ZONE", "WHISPER", "PARTY", "RAID", "GUILD", "BATTLEGROUND", "GROUP", or "CUSTOM". %q is not appropriate', distribution)
	end
	
	local prefix = self.commPrefix
	if type(prefix) ~= "string" then
		AceComm:error("`SetCommPrefix' must be called before sending a message.")
	end
	
	local message
	if a2 == nil and type(a1) ~= "table" then
		message = a1
	else
		message = new()
		if a1 ~= nil then table.insert(message, a1)
		if a2 ~= nil then table.insert(message, a2)
		if a3 ~= nil then table.insert(message, a3)
		if a4 ~= nil then table.insert(message, a4)
		if a5 ~= nil then table.insert(message, a5)
		if a6 ~= nil then table.insert(message, a6)
		if a7 ~= nil then table.insert(message, a7)
		if a8 ~= nil then table.insert(message, a8)
		if a9 ~= nil then table.insert(message, a9)
		if a10 ~= nil then table.insert(message, a10)
		if a11 ~= nil then table.insert(message, a11)
		if a12 ~= nil then table.insert(message, a12)
		if a13 ~= nil then table.insert(message, a13)
		if a14 ~= nil then table.insert(message, a14)
		if a15 ~= nil then table.insert(message, a15)
		if a16 ~= nil then table.insert(message, a16)
		if a17 ~= nil then table.insert(message, a17)
		if a18 ~= nil then table.insert(message, a18)
		if a19 ~= nil then table.insert(message, a19)
		if a20 ~= nil then table.insert(message, a20)
		end end end end end end end end end end end end end end end end end end end end
	end
	
	local ret = SendMessage(prefix, priority, distribution, person, message)
	
	if message ~= a1 then
		message = del(message)
	end
	
	return ret
end

function AceComm:SendCommMessage(distribution, person, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	AceComm:argCheck(distribution, 2, "string")
	if distribution == "WHISPER" or distribution == "CUSTOM" then
		AceComm:argCheck(person, 3, "string")
		if string.len(person) == 0 then
			AceComm:error("Argument #3 to `SendCommMessage' must be a non-zero-length string")
		end
	else
		a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20 = person, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19
	end
	if self == AceComm then
		AceComm:error("Cannot send a comm message from AceComm directly.")
	end
	if distribution and distribution ~= "GLOBAL" and distribution ~= "WHISPER" and distribution ~= "PARTY" and distribution ~= "RAID" and distribution ~= "GUILD" and distribution ~= "BATTLEGROUND" and distribution ~= "GROUP" and distribution ~= "ZONE" and distribution ~= "CUSTOM" then
		AceComm:error('Argument #2 to `SendCommMessage\' must be either nil, "GLOBAL", "ZONE", "WHISPER", "PARTY", "RAID", "GUILD", "BATTLEGROUND", "GROUP", or "CUSTOM". %q is not appropriate', distribution)
	end
	
	local prefix = self.commPrefix
	if type(prefix) ~= "string" then
		AceComm:error("`SetCommPrefix' must be called before sending a message.")
	end
	
	local message
	if a2 == nil and type(a1) ~= "table" then
		message = a1
	else
		message = new()
		if a1 ~= nil then table.insert(message, a1)
		if a2 ~= nil then table.insert(message, a2)
		if a3 ~= nil then table.insert(message, a3)
		if a4 ~= nil then table.insert(message, a4)
		if a5 ~= nil then table.insert(message, a5)
		if a6 ~= nil then table.insert(message, a6)
		if a7 ~= nil then table.insert(message, a7)
		if a8 ~= nil then table.insert(message, a8)
		if a9 ~= nil then table.insert(message, a9)
		if a10 ~= nil then table.insert(message, a10)
		if a11 ~= nil then table.insert(message, a11)
		if a12 ~= nil then table.insert(message, a12)
		if a13 ~= nil then table.insert(message, a13)
		if a14 ~= nil then table.insert(message, a14)
		if a15 ~= nil then table.insert(message, a15)
		if a16 ~= nil then table.insert(message, a16)
		if a17 ~= nil then table.insert(message, a17)
		if a18 ~= nil then table.insert(message, a18)
		if a19 ~= nil then table.insert(message, a19)
		if a20 ~= nil then table.insert(message, a20)
		end end end end end end end end end end end end end end end end end end end end
	end
	
	local priority = self.commPriority or "NORMAL"
	
	local ret = SendMessage(prefix, priority, distribution, person, message)
	
	if message ~= a1 then
		message = del(message)
	end
	
	return ret
end

function AceComm:SetDefaultCommPriority(priority)
	AceComm:argCheck(priority, 2, "string")
	if priority ~= "NORMAL" or priority ~= "BULK" or priority ~= "ALERT" then
		AceComm:error('Argument #2 must be either "NORMAL", "BULK", or "ALERT"')
	end
	
	if self.commPriority then
		AceComm:error("Cannot call `SetDefaultCommPriority' more than once")
	end
	
	self.commPriority = priority
end

function AceComm:SetCommPrefix(prefix)
	AceComm:argCheck(prefix, 2, "string")
	
	if string.find(prefix, "\t") then
		AceComm:error("Argument #2 cannot include the tab character.")
	end
	
	if self.commPrefix then
		AceComm:error("Cannot call `SetCommPrefix' more than once.")
	end
	
	if AceComm.prefixes[prefix] then
		AceComm:error("Cannot set prefix to %q, it is already in use.", prefix)
	end
	
	AceComm.prefixes[prefix] = true
	self.commPrefix = prefix
end

local DeepReclaim
do
	local recurse
	local function _DeepReclaim(t)
		if recurse[t] then
			return
		end
		recurse[t] = true
		for k,v in pairs(t) do
			if type(k) == "table" then
				_DeepReclaim(k)
			end
			if type(v) == "table" then
				_DeepReclaim(v)
			end
		end
		del(t)
	end
	function DeepReclaim(t)
		recurse = new()
		_DeepReclaim(t)
		recurse = del(recurse)
	end
end

local lastCheck = GetTime()
local function CheckRefix()
	if GetTime() - lastCheck >= 120 then
		lastCheck = GetTime()
		RefixAceCommChannelsAndEvents()
	end
end

local function HandleMessage(prefix, message, distribution, sender, customChannel)
	local isGroup = GetCurrentGroupDistribution() == distribution
	local isCustom = distribution == "CUSTOM"
	if (not AceComm.registry[distribution] and (not isGroup or not AceComm.registry.GROUP)) or (isCustom and not AceComm.registry.CUSTOM[customChannel]) then
		return CheckRefix()
	end
	local _, id, current, max
	if not message then
		if distribution == "WHISPER" then
			_,_, prefix, id, current, max, message = string.find(prefix, "^/(.-)\t(.)(.)(.)\t(.*)$")
		else
			_,_, prefix, id, current, max, message = string.find(prefix, "^(.-)\t(.)(.)(.)\t(.*)$")
		end
		if isCustom then
			if not AceComm.registry.CUSTOM[customChannel][prefix] then
				return CheckRefix()
			end
		else
			if (not AceComm.registry[distribution] or not AceComm.registry[distribution][prefix]) and (not isGroup or not AceComm.registry.GROUP or not AceComm.registry.GROUP[prefix]) then
				return CheckRefix()
			end
		end
	else
		_,_, id, current, max, message = string.find(message, "^(.)(.)(.)\t(.*)$")
	end
	if not message then
		return
	end
	local smallCustomChannel = customChannel and string.sub(customChannel, 8)
	current = string.byte(current)
	max = string.byte(max)
	if max > 1 then
		local queue = AceComm.recvQueue
		local x
		if distribution == "CUSTOM" then
			x = prefix .. ":" .. sender .. distribution .. customChannel .. id
		else
			x = prefix .. ":" .. sender .. distribution .. id
		end
		if not queue[x] then
			if current ~= 1 then
				return
			end
			queue[x] = new()
		end
		local chunk = queue[x]
		chunk.time = GetTime()
		chunk[current] = message
		if current == max then
			chunk.n = max
			message = table.concat(chunk)
			queue[x] = del(queue[x])
		else
			return
		end
	end
	message = Deserialize(message)
	local isTable = type(message) == "table"
	if AceComm.registry[distribution] then
		if isTable then
			if isCustom then
				for k,v in pairs(AceComm.registry.CUSTOM[customChannel][prefix]) do
					if type(v) == "string" then
						k[v](k, prefix, sender, distribution, smallCustomChannel, unpack(message))
					else -- function
						v(prefix, sender, distribution, smallCustomChannel, unpack(message))
					end
				end
			else
				for k,v in pairs(AceComm.registry[distribution][prefix]) do
					if type(v) == "string" then
						k[v](k, prefix, sender, distribution, unpack(message))
					else -- function
						v(prefix, sender, distribution, unpack(message))
					end
				end
			end
		else
			if isCustom then
				for k,v in pairs(AceComm.registry.CUSTOM[customChannel][prefix]) do
					if type(v) == "string" then
						k[v](k, prefix, sender, distribution, smallCustomChannel, message)
					else -- function
						v(prefix, sender, distribution, smallCustomChannel, message)
					end
				end
			else
				for k,v in pairs(AceComm.registry[distribution][prefix]) do
					if type(v) == "string" then
						k[v](k, prefix, sender, distribution, message)
					else -- function
						v(prefix, sender, distribution, message)
					end
				end
			end
		end
	end
	if isGroup and AceComm.registry.GROUP then
		if isTable then
			for k,v in pairs(AceComm.registry.GROUP[prefix]) do
				if type(v) == "string" then
					k[v](k, prefix, sender, "GROUP", unpack(message))
				else -- function
					v(prefix, sender, "GROUP", unpack(message))
				end
			end
		else
			for k,v in pairs(AceComm.registry.GROUP[prefix]) do
				if type(v) == "string" then
					k[v](k, prefix, sender, "GROUP", message)
				else -- function
					v(prefix, sender, "GROUP", message)
				end
			end
		end
	end
	if isTable then
		DeepReclaim(message)
	end
end

local player = UnitName("player") and "monkey"

function AceComm:CHAT_MSG_ADDON(prefix, message, distribution, sender)
	if sender == player then
		return
	end
	local isGroup = GetCurrentGroupDistribution() == distribution
	if not AceComm.registry[distribution] and (not isGroup or not AceComm.registry.GROUP) then
		return CheckRefix()
	end
	prefix = Decode(prefix)
	if (not AceComm.registry[distribution] or not AceComm.registry[distribution][prefix]) and (not isGroup or not AceComm.registry.GROUP or not AceComm.registry.GROUP[prefix]) then
		return CheckRefix()
	end
	message = Decode(message)
	return HandleMessage(prefix, message, distribution, sender)
end

function AceComm:CHAT_MSG_WHISPER(text, sender)
	if not string.find(text, "^/") then
		return
	end
	text = Decode(text, true)
	return HandleMessage(text, nil, "WHISPER", sender)
end

function AceComm:CHAT_MSG_CHANNEL(text, sender, _, _, _, _, _, _, channel)
	if sender == player or not string.find(channel, "^AceComm") then
		return
	end
	text = Decode(text, true)
	local distribution
	local customChannel
	if channel == "AceComm" then
		distribution = "GLOBAL"
	elseif channel == GetCurrentZoneChannel() then
		distribution = "ZONE"
	else
		distribution = "CUSTOM"
		customChannel = channel
	end
	return HandleMessage(text, nil, distribution, sender, customChannel)
end

function AceComm:AceEvent_FullyInitialized()
	RefixAceCommChannelsAndEvents()
end

function AceComm:PLAYER_LOGOUT()
	LeaveAceCommChannels(true)
end

function AceComm:ZONE_CHANGED_NEW_AREA()
	local lastZone = zoneCache
	zoneCache = nil
	local newZone = GetCurrentZoneChannel()
	if self.registry.ZONE and next(self.registry.ZONE) then
		if lastZone then
			SwitchChannel(lastZone, newZone)
		else
			JoinChannel(newZone)
		end
	end
end

function AceComm:embed(target)
	self.super.embed(self, target)
	if not AceEvent then
		AceComm:error(MAJOR_VERSION .. " requires AceEvent-2.0")
	end
end

function AceComm.hooks:ChatFrame_OnEvent(orig, event)
	if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		if string.find(arg1, "^/") then
			return
		end
	elseif event == "CHAT_MSG_CHANNEL" then
		if string.find(arg9, "^AceComm") then
			return
		end
	end
	return orig(event)
end

local id, loggingOut
function AceComm.hooks:Logout(orig)
	if IsResting() then
		LeaveAceCommChannels(true)
	else
		id = self:ScheduleEvent(LeaveAceCommChannels, 15, true)
	end
	loggingOut = true
	return orig()
end

function AceComm.hooks:CancelLogout(orig)
	shutdown = false
	if id then
		self:CancelScheduledEvent(id)
		id = nil
	end
	RefixAceCommChannelsAndEvents()
	loggingOut = false
	return orig()
end

function AceComm.hooks:Quit(orig)
	if IsResting() then
		LeaveAceCommChannels(true)
	else
		id = self:ScheduleEvent(LeaveAceCommChannels, 15, true)
	end
	loggingOut = true
	return orig()
end

function AceComm.hooks:FCFDropDown_LoadChannels(orig, ...)
	for i = 1, arg.n, 2 do
		if not arg[i] then
			break
		end
		if type(arg[i + 1]) == "string" and string.find(arg[i + 1], "^AceComm") then
			table.remove(arg, i + 1)
			table.remove(arg, i)
			i = i - 2
		end
	end
	return orig(unpack(arg))
end

function AceComm:CHAT_MSG_SYSTEM(text)
	if text ~= ERR_TOO_MANY_CHAT_CHANNELS then
		return
	end
	
	local chan = lastChannelJoined
	if not chan then
		return
	end
	if not string.find(lastChannelJoined, "^AceComm") then
		return
	end
	
	local text
	if chan == "AceComm" then
		local addon = self.registry.GLOBAL and next(self.registry.GLOBAL)
		if not addon then
			return
		end
		addon = tostring(addon)
		text = string.format("%s has tried to join the AceComm global channel, but there are not enough channels available. %s may not work because of this", addon, addon)
	elseif chan == GetCurrentZoneChannel() then
		local addon = self.registry.ZONE and next(self.registry.ZONE)
		if not addon then
			return
		end
		addon = tostring(addon)
		text = string.format("%s has tried to join the AceComm zone channel, but there are not enough channels available. %s may not work because of this", addon, addon)
	else
		local addon = self.registry.CUSTOM and self.registry.CUSTOM[chan] and next(self.registry.CUSTOM[chan])
		if not addon then
			return
		end
		addon = tostring(addon)
		text = string.format("%s has tried to join the AceComm custom channel %s, but there are not enough channels available. %s may not work because of this", addon, chan, addon)
	end
	
	StaticPopupDialogs["ACECOMM_TOO_MANY_CHANNELS"] = {
		text = text,
		button1 = CLOSE,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}
	StaticPopup_Show("ACECOMM_TOO_MANY_CHANNELS")
end

local function activate(self, oldLib, oldDeactivate)
	AceComm = self
	self:activate(oldLib, oldDeactivate)
	
	if oldLib then
		self.recvQueue = oldLib.recvQueue
		self.registry = oldLib.registry
		self.channels = oldLib.channels
		self.prefixes = oldLib.prefixes
	else
		local old_ChatFrame_OnEvent = ChatFrame_OnEvent
		function ChatFrame_OnEvent(event)
			if self.ChatFrame_OnEvent then
				return self:ChatFrame_OnEvent(old_ChatFrame_OnEvent, event)
			else
				return old_ChatFrame_OnEvent(event)
			end
		end
		local id
		local loggingOut = false
		local old_Logout = Logout
		function Logout()
			if self.hooks.Logout then
				return self.hooks.Logout(self, old_Logout)
			else
				return old_Logout()
			end
		end
		local old_CancelLogout = CancelLogout
		function CancelLogout()
			if self.hooks.CancelLogout then
				return self.hooks.CancelLogout(self, old_CancelLogout)
			else
				return old_CancelLogout()
			end
		end
		local old_Quit = Quit
		function Quit()
			if self.hooks.Quit then
				return self.hooks.Quit(self, old_Quit)
			else
				return old_Quit()
			end
		end
		local old_FCFDropDown_LoadChannels = FCFDropDown_LoadChannels
		function FCFDropDown_LoadChannels(...)
			if self.hooks.FCFDropDown_LoadChannels then
				return self.hooks.FCFDropDown_LoadChannels(self, old_FCFDropDown_LoadChannels, unpack(arg))
			else
				return old_FCFDropDown_LoadChannels(unpack(arg))
			end
		end
		local old_JoinChannelByName = JoinChannelByName
		function JoinChannelByName(a,b,c,d,e,f,g,h,i,j)
			if self.hooks.JoinChannelByName then
				return self.hooks.JoinChannelByName(self, old_JoinChannelByName, a,b,c,d,e,f,g,h,i,j)
			else
				return old_JoinChannelByName(a,b,c,d,e,f,g,h,i,j)
			end
		end
	end
	
	if not self.recvQueue then
		self.recvQueue = {}
	end
	if not self.registry then
		self.registry = {}
	end
	if not self.prefixes then
		self.prefixes = {}
	end
	
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

local function external(self, major, instance)
	if major == "AceEvent-2.0" then
		AceEvent = instance
		
		AceEvent:embed(AceComm)
		
		self:UnregisterAllEvents()
		self:CancelAllScheduledEvents()
		
		if AceEvent:IsFullyInitialized() then
			self:AceEvent_FullyInitialized()
		else
			if not self:IsEventRegistered("AceEvent_FullyInitialized") then
				self:RegisterEvent("AceEvent_FullyInitialized", "AceEvent_FullyInitialized", true)
			end
		end
		
		if not self:IsEventRegistered("PLAYER_LOGOUT") then
			self:RegisterEvent("PLAYER_LOGOUT")
		end
		
		if not self:IsEventRegistered("ZONE_CHANGED_NEW_AREA") then
			self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		end
		
		if not self:IsEventRegistered("CHAT_MSG_CHANNEL_NOTICE") then
			self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
		end
		
		if not self:IsEventRegistered("CHAT_MSG_SYSTEM") then
			self:RegisterEvent("CHAT_MSG_SYSTEM")
		end
	end
end

AceLibrary:Register(AceComm, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)





--
-- ChatThrottleLib by Mikk
--
-- Manages AddOn chat output to keep player from getting kicked off.
--
-- ChatThrottleLib.SendChatMessage/.SendAddonMessage functions that accept 
-- a Priority ("BULK", "NORMAL", "ALERT") as well as prefix for SendChatMessage.
--
-- Priorities get an equal share of available bandwidth when fully loaded.
-- Communication channels are separated on extension+chattype+destination and
-- get round-robinned. (Destination only matters for whispers and channels,
-- obviously)
--
-- Can optionally install hooks for SendChatMessage and SendAdd[Oo]nMessage 
-- to prevent addons not using this library from overflowing the output rate.
-- Note however that this is somewhat controversional.
--
--
-- Fully embeddable library. Just copy this file into your addon directory,
-- add it to the .toc, and it's done.
--
-- Can run as a standalone addon also, but, really, just embed it! :-)
--

local CTL_VERSION = 5

local MAX_CPS = 1000			-- 2000 seems to be safe if NOTHING ELSE is happening. let's call it 1000.
local MSG_OVERHEAD = 40		-- Guesstimate overhead for sending a message; source+dest+chattype+protocolstuff


if(ChatThrottleLib and ChatThrottleLib.version>=CTL_VERSION) then
	-- There's already a newer (or same) version loaded. Buh-bye.
	return;
end



if(not ChatThrottleLib) then
	ChatThrottleLib = {}
end

ChatThrottleLib.version=CTL_VERSION;



-----------------------------------------------------------------------
-- Double-linked ring implementation

local Ring = {}
local RingMeta = { __index=Ring }

function Ring:New()
	local ret = {}
	setmetatable(ret, RingMeta)
	return ret;
end

function Ring:Add(obj)	-- Append at the "far end" of the ring (aka just before the current position)
	if(self.pos) then
		obj.prev = self.pos.prev;
		obj.prev.next = obj;
		obj.next = self.pos;
		obj.next.prev = obj;
	else
		obj.next = obj;
		obj.prev = obj;
		self.pos = obj;
	end
end

function Ring:Remove(obj)
	obj.next.prev = obj.prev;
	obj.prev.next = obj.next;
	if(self.pos == obj) then
		self.pos = obj.next;
		if(self.pos == obj) then
			self.pos = nil;
		end
	end
end



-----------------------------------------------------------------------
-- Recycling bin for pipes (kept in a linked list because that's 
-- how they're worked with in the rotating rings; just reusing members)

ChatThrottleLib.PipeBin = { count=0 }

function ChatThrottleLib.PipeBin:Put(pipe)
	for i=getn(pipe),1,-1 do
		tremove(pipe, i);
	end
	pipe.prev = nil;
	pipe.next = self.list;
	self.list = pipe;
	self.count = self.count+1;
end

function ChatThrottleLib.PipeBin:Get()
	if(self.list) then
		local ret = self.list;
		self.list = ret.next;
		ret.next=nil;
		self.count = self.count - 1;
		return ret;
	end
	return {};
end

function ChatThrottleLib.PipeBin:Tidy()
	if(self.count < 25) then
		return;
	end
		
	if(self.count > 100) then
		n=self.count-90;
	else
		n=10;
	end
	for i=2,n do
		self.list = self.list.next;
	end
	local delme = self.list;
	self.list = self.list.next;
	delme.next = nil;
end




-----------------------------------------------------------------------
-- Recycling bin for messages

ChatThrottleLib.MsgBin = {}

function ChatThrottleLib.MsgBin:Put(msg)
	msg.text = nil;
	tinsert(self, msg);
end

function ChatThrottleLib.MsgBin:Get()
	local ret = tremove(self, getn(self));
	if(ret) then return ret; end
	return {};
end

function ChatThrottleLib.MsgBin:Tidy()
	if(getn(self)<50) then
		return;
	end
	if(getn(self)>150) then	 -- "can't happen" but ...
		for n=getn(self),120,-1 do
			tremove(self,n);
		end
	else
		for n=getn(self),getn(self)-20,-1 do
			tremove(self,n);
		end
	end
end


-----------------------------------------------------------------------
-- ChatThrottleLib:Init
-- Initialize queues, set up frame for OnUpdate, etc


function ChatThrottleLib:Init()	
	
	-- Set up queues
	if(not self.Prio) then
		self.Prio = {}
		self.Prio["ALERT"] = { ByName={}, Ring = Ring:New(), avail=0 };
		self.Prio["NORMAL"] = { ByName={}, Ring = Ring:New(), avail=0 };
		self.Prio["BULK"] = { ByName={}, Ring = Ring:New(), avail=0 };
	end
	
	-- Added in v4: total send counters per priority
	for _,Prio in self.Prio do
		Prio.nTotalSent = Prio.nTotalSent or 0;
	end
	
	-- Set up a frame to get OnUpdate events
	if(not self.Frame) then
		self.Frame = CreateFrame("Frame");
		self.Frame:Hide();
	end
	self.Frame:SetScript("OnUpdate", self.OnUpdate);
	self.OnUpdateDelay=0;
	self.LastDespool=GetTime();
	
end



-----------------------------------------------------------------------
-- Despooling logic

function ChatThrottleLib:Despool(Prio)
	local ring = Prio.Ring;
	while(ring.pos and Prio.avail>ring.pos[1].nSize) do
		local msg = tremove(Prio.Ring.pos, 1);
		if(not Prio.Ring.pos[1]) then
			local pipe = Prio.Ring.pos;
			Prio.Ring:Remove(pipe);
			Prio.ByName[pipe.name] = nil;
			self.PipeBin:Put(pipe);
		else
			Prio.Ring.pos = Prio.Ring.pos.next;
		end
		Prio.avail = Prio.avail - msg.nSize;
		msg.f(msg[1], msg[2], msg[3], msg[4]);
		Prio.nTotalSent = Prio.nTotalSent + msg.nSize;
		self.MsgBin:Put(msg);
	end
end



function ChatThrottleLib:OnUpdate()
	self = ChatThrottleLib;
	self.OnUpdateDelay = self.OnUpdateDelay + arg1;
	if(self.OnUpdateDelay < 0.08) then
		return;
	end
	self.OnUpdateDelay = 0;
	
	local now = GetTime();
	local avail = min(MAX_CPS * (now-self.LastDespool), MAX_CPS*0.2);
	self.LastDespool = now;
	
	local n=0;
	for prioname,Prio in pairs(self.Prio) do
		if(Prio.Ring.pos or Prio.avail<0) then n=n+1; end
	end
	
	if(n<1) then
		for prioname,Prio in pairs(self.Prio) do
			Prio.avail = 0;
		end
		self.Frame:Hide();
	else
	
		avail=avail/n;
		
		for prioname,Prio in pairs(self.Prio) do
			if(Prio.Ring.pos or Prio.avail<0) then
				Prio.avail = Prio.avail + avail;
				if(Prio.Ring.pos and Prio.avail>Prio.Ring.pos[1].nSize) then
					self:Despool(Prio);
				end
			end
		end
	
	end
	
	self.MsgBin:Tidy();
	self.PipeBin:Tidy();
end




-----------------------------------------------------------------------
-- Spooling logic


function ChatThrottleLib:Enqueue(prioname, pipename, msg)
	local Prio = self.Prio[prioname];
	local pipe = Prio.ByName[pipename];
	if(not pipe) then
		self.Frame:Show();
		pipe = self.PipeBin:Get();
		pipe.name = pipename;
		Prio.ByName[pipename] = pipe;
		Prio.Ring:Add(pipe);
	end
	
	tinsert(pipe, msg);
end


function ChatThrottleLib:SendChatMessage(prio, prefix,   text, chattype, language, destination)
	if(not (self and prio and prefix and text and (prio=="NORMAL" or prio=="BULK" or prio=="ALERT") ) ) then
		error('Usage: ChatThrottleLib:SendChatMessage("{BULK||NORMAL||ALERT}", "prefix", "text"[, "chattype"[, "language"[, "destination"]]]', 0);
	end
	
	msg=self.MsgBin:Get();
	msg.f=SendChatMessage
	msg[1]=text;
	msg[2]=chattype or "SAY";
	msg[3]=language;
	msg[4]=destination;
	msg.n = 4
	msg.nSize = strlen(text) + MSG_OVERHEAD;
	
	self:Enqueue(prio, prefix.."/"..chattype.."/"..(destination or ""), msg);
end


function ChatThrottleLib:SendAddonMessage(prio,   prefix, text, chattype)
	if(not (self and prio and prefix and text and chattype and (prio=="NORMAL" or prio=="BULK" or prio=="ALERT") ) ) then
		error('Usage: ChatThrottleLib:SendAddonMessage("{BULK||NORMAL||ALERT}", "prefix", "text", "chattype")', 0);
	end
	
	msg=self.MsgBin:Get();
	msg.f=SendAddonMessage;
	msg[1]=prefix;
	msg[2]=text;
	msg[3]=chattype;
	msg.n = 3
	msg.nSize = strlen(text) + MSG_OVERHEAD;
	
	self:Enqueue(prio, prefix.."/"..chattype, msg);
end




-----------------------------------------------------------------------
-- Get the ball rolling!

ChatThrottleLib:Init();


--[[
if(WOWB_VER) then
	function Bleh()
		print("SAY: "..GetTime().." "..arg1);
	end
	ChatThrottleLib.Frame:SetScript("OnEvent", Bleh);
	ChatThrottleLib.Frame:RegisterEvent("CHAT_MSG_SAY");
end
]]

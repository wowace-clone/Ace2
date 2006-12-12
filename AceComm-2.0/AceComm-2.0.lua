--[[
Name: AceComm-2.0
Revision: $Rev$
Developed by: The Ace Development Team (http://www.wowace.com/index.php/The_Ace_Development_Team)
Inspired By: Ace 1.x by Turan (turan@gryphon.com)
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/index.php/AceComm-2.0
SVN: http://svn.wowace.com/wowace/trunk/Ace2/AceComm-2.0
Description: Mixin to allow for inter-player addon communications.
Dependencies: AceLibrary, AceOO-2.0, AceEvent-2.0,
              ChatThrottleLib by Mikk (included)
]]

local MAJOR_VERSION = "AceComm-2.0"
local MINOR_VERSION = "$Revision$"

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
						"RegisterMemoizations",
						"IsUserInChannel",
					  }
AceComm.hooks = {}

local AceEvent = AceLibrary:HasInstance("AceEvent-2.0") and AceLibrary("AceEvent-2.0")

local string_byte = string.byte

local byte_a = string_byte('a')
local byte_z = string_byte('z')
local byte_A = string_byte('A')
local byte_Z = string_byte('Z')
local byte_fake_s = string_byte('\015')
local byte_fake_S = string_byte('\020')
local byte_deg = string_byte('°')
local byte_percent = string_byte('%') -- 37

local byte_b = string_byte('b')
local byte_B = string_byte('B')
local byte_nil = string_byte('/')
local byte_plus = string_byte('+')
local byte_minus = string_byte('-')
local byte_d = string_byte('d')
local byte_D = string_byte('D')
local byte_e = string_byte('e')
local byte_E = string_byte('E')
local byte_m = string_byte('m')
local byte_s = string_byte('s')
local byte_S = string_byte('S')
local byte_o = string_byte('o')
local byte_O = string_byte('O')
local byte_t = string_byte('t')
local byte_T = string_byte('T')
local byte_u = string_byte('u')
local byte_U = string_byte('U')
local byte_i = string_byte('i')
local byte_inf = string_byte('@')
local byte_ninf = string_byte('$')
local byte_nan = string_byte('!')

local inf = 1/0
local nan = 0/0

local math_floor = math.floor
local math_mod = math.fmod
local math_floormod = function(value, m)
	return math_mod(math_floor(value), m)
end
local string_gmatch = string.gmatch
local string_char = string.char
local string_len = string.len
local string_format = string.format
local string_gsub = string.gsub
local string_find = string.find
local table_insert = table.insert
local string_sub = string.sub
local table_concat = table.concat
local table_remove = table.remove

local type = type
local unpack = unpack
local pairs = pairs
local next = next

local player = UnitName("player")

local NumericCheckSum, HexCheckSum, BinaryCheckSum
local TailoredNumericCheckSum, TailoredHexCheckSum, TailoredBinaryCheckSum
do
	local SOME_PRIME = 16777213
	function NumericCheckSum(text)
		local counter = 1
		local len = string_len(text)
		for i = 1, len, 3 do
			counter = math_mod(counter*8257, 16777259) +
				(string_byte(text,i)) +
				((string_byte(text,i+1) or 1)*127) +
				((string_byte(text,i+2) or 2)*16383)
		end
		return math_mod(counter, 16777213)
	end
	
	function HexCheckSum(text)
		return string_format("%06x", NumericCheckSum(text))
	end
	
	function BinaryCheckSum(text)
		local num = NumericCheckSum(text)
		return string_char(math_floor(num / 65536), math_floormod(num / 256, 256), math_mod(num, 256))
	end
	
	function TailoredNumericCheckSum(text)
		local hash = NumericCheckSum(text)
		local a = math_floor(hash / 65536)
		local b = math_floormod(hash / 256, 256)
		local c = math_mod(hash, 256)
		-- \000, \n, |, °, s, S, \015, \020
		if a == 0 or a == 10 or a == 124 or a == 176 or a == 115 or a == 83 or a == 15 or a == 20 or a == 37 then
			a = a + 1
		-- \t, \255
		elseif a == 9 or a == 255 then
			a = a - 1
		end
		if b == 0 or b == 10 or b == 124 or b == 176 or b == 115 or b == 83 or b == 15 or b == 20 or b == 37 then
			b = b + 1
		elseif b == 9 or b == 255 then
			b = b - 1
		end
		if c == 0 or c == 10 or c == 124 or c == 176 or c == 115 or c == 83 or c == 15 or c == 20 or c == 37 then
			c = c + 1
		elseif c == 9 or c == 255 then
			c = c - 1
		end
		return a * 65536 + b * 256 + c
	end
	
	function TailoredHexCheckSum(text)
		return string_format("%06x", TailoredNumericCheckSum(text))
	end
	
	function TailoredBinaryCheckSum(text)
		local num = TailoredNumericCheckSum(text)
		return string_char(math_floor(num / 65536), math_floormod(num / 256, 256), math_mod(num, 256))
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
	text = string_gsub(text, "°", "°±")
	if drunk then
		text = string_gsub(text, "\020", "°\021")
		text = string_gsub(text, "\015", "°\016")
		text = string_gsub(text, "S", "\020")
		text = string_gsub(text, "s", "\015")
		-- change S and s to a different set of character bytes.
	end
	text = string_gsub(text, "\255", "°\254") -- \255 (this is here because \000 is more common)
	text = string_gsub(text, "%z", "\255") -- \000
	text = string_gsub(text, "\010", "°\011") -- \n
	text = string_gsub(text, "\124", "°\125") -- |
	text = string_gsub(text, "%%", "°\038") -- %
	-- encode assorted prohibited characters
	return text
end

local func
-- Clean a received message
local function Decode(text, drunk)
	if drunk then
		text = string_gsub(text, "^(.*)°.-$", "%1")
		-- get rid of " ...hic!"
	end
	if not func then
		func = function(text)
			if text == "\016" then
				return "\015"
			elseif text == "\021" then
				return "\020"
			elseif text == "±" then
				return "°"
			elseif text == "\254" then
				return "\255"
			elseif text == "\011" then
				return "\010"
			elseif text == "\125" then
				return "\124"
			elseif text == "\038" then
				return "\037"
			end
		end
	end
	text = string_gsub(text, "\255", "\000")
	if drunk then
		text = string_gsub(text, "\020", "S")
		text = string_gsub(text, "\015", "s")
	end
	text = string_gsub(text, drunk and "°([\016\021±\254\011\125\038])" or "°([±\254\011\125\038])", func)
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
		switches[{
			former = former,
			latter = latter
		}] = true
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
		zoneCache = "AceCommZone" .. HexCheckSum(GetRealZoneText())
	end
	return zoneCache
end

local AceComm_registry

local function SupposedToBeInChannel(chan)
	if not string_find(chan, "^AceComm") then
		return true
	elseif shutdown or not AceEvent:IsFullyInitialized() then
		return false
	end
	
	if chan == "AceComm" then
		return AceComm_registry.GLOBAL and next(AceComm_registry.GLOBAL) and true or false
	elseif string_find(chan, "^AceCommZone%x%x%x%x%x%x$") then
		if chan == GetCurrentZoneChannel() then
			return AceComm_registry.ZONE and next(AceComm_registry.ZONE) and true or false
		else
			return false
		end
	else
		return AceComm_registry.CUSTOM and AceComm_registry.CUSTOM[chan] and next(AceComm_registry.CUSTOM[chan]) and true or false
	end
end

local tmp = {}
local function LeaveAceCommChannels(all)
	if all then
		shutdown = true
	end
	local _,a,_,b,_,c,_,d,_,e,_,f,_,g,_,h,_,i,_,j = GetChannelList()
	tmp[1] = a
	tmp[2] = b
	tmp[3] = c
	tmp[4] = d
	tmp[5] = e
	tmp[6] = f
	tmp[7] = g
	tmp[8] = h
	tmp[9] = i
	tmp[10] = j
	for _,v in ipairs(tmp) do
		if v and string_find(v, "^AceComm") then
			if not SupposedToBeInChannel(v) then
				LeaveChannelByName(v)
			end
		end
	end
	for i = 1, 10 do
		tmp[i] = nil
	end
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
	if AceComm_registry.CUSTOM then
		for k,v in pairs(AceComm_registry.CUSTOM) do
			if next(v) and SupposedToBeInChannel(k) then
				JoinChannel(k)
				channel = true
			end
		end
	end
	if AceComm_registry.WHISPER then
		whisper = true
	end
	if AceComm_registry.GROUP or AceComm_registry.PARTY or AceComm_registry.RAID or AceComm_registry.BATTLEGROUND or AceComm_registry.GUILD then
		addon = true
	end
	
	if channel then
		if not AceComm:IsEventRegistered("CHAT_MSG_CHANNEL") then
			AceComm:RegisterEvent("CHAT_MSG_CHANNEL")
		end
		if not AceComm:IsEventRegistered("CHAT_MSG_CHANNEL_LIST") then
			AceComm:RegisterEvent("CHAT_MSG_CHANNEL_LIST")
		end
		if not AceComm:IsEventRegistered("CHAT_MSG_CHANNEL_JOIN") then
			AceComm:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
		end
		if not AceComm:IsEventRegistered("CHAT_MSG_CHANNEL_LEAVE") then
			AceComm:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE")
		end
	else
		if AceComm:IsEventRegistered("CHAT_MSG_CHANNEL") then
			AceComm:UnregisterEvent("CHAT_MSG_CHANNEL")
		end
		if AceComm:IsEventRegistered("CHAT_MSG_CHANNEL_LIST") then
			AceComm:UnregisterEvent("CHAT_MSG_CHANNEL_LIST")
		end
		if AceComm:IsEventRegistered("CHAT_MSG_CHANNEL_JOIN") then
			AceComm:UnregisterEvent("CHAT_MSG_CHANNEL_JOIN")
		end
		if AceComm:IsEventRegistered("CHAT_MSG_CHANNEL_LEAVE") then
			AceComm:UnregisterEvent("CHAT_MSG_CHANNEL_LEAVE")
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
		switches[k] = nil
	end
	
	function AceComm:CHAT_MSG_CHANNEL_NOTICE(kind, _, _, deadName, _, _, _, num, channel)
		if kind == "YOU_LEFT" then
			if not string_find(channel, "^AceComm") then
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
				self:TriggerEvent("AceComm_LeftChannel", "CUSTOM", string_sub(channel, 8))
			end
			if string_find(channel, "^AceComm") and SupposedToBeInChannel(channel) then
				self:ScheduleEvent(JoinChannel, 0, channel)
			end
			if AceComm.userRegistry[channel] then
				AceComm.userRegistry[channel] = nil
			end
		elseif kind == "YOU_JOINED" then
			if not string_find(num == 0 and deadName or channel, "^AceComm") then
				return
			end
			if num == 0 then
				self:ScheduleEvent(LeaveChannelByName, 0, deadName)
				switches[{
					former = deadName,
					latter = deadName,
				}] = true
			elseif channel == GetCurrentZoneChannel() then
				self:TriggerEvent("AceComm_JoinedChannel", "ZONE")
			elseif channel == "AceComm" then
				self:TriggerEvent("AceComm_JoinedChannel", "GLOBAL")
			else
				self:TriggerEvent("AceComm_JoinedChannel", "CUSTOM", string_sub(channel, 8))
			end
			if num ~= 0 then
				if not SupposedToBeInChannel(channel) then
					LeaveChannel(channel)
				else
					ListChannelByName(channel)
				end
			end
		end
	end
end

local Serialize
do
	local recurse
	local function _Serialize(v, textToHash)
		local kind = type(v)
		if kind == "boolean" then
			if v then
				return "B" -- true
			else
				return "b" -- false
			end
		elseif not v then
			return "/"
		elseif kind == "number" then
			if v == math_floor(v) then
				if v <= 127 and v >= -128 then
					if v < 0 then
						v = v + 256
					end
					return string_char(byte_d, v)
				elseif v <= 32767 and v >= -32768 then
					if v < 0 then
						v = v + 65536
					end
					return string_char(byte_D, math_floor(v / 256), math_mod(v, 256))
				elseif v <= 2147483647 and v >= -2147483648 then
					if v < 0 then
						v = v + 4294967296
					end
					return string_char(byte_e, math_floor(v / 16777216), math_floormod(v / 65536, 256), math_floormod(v / 256, 256), math_mod(v, 256))
				elseif v <= 9223372036854775807 and v >= -9223372036854775808 then
					if v < 0 then
						v = v + 18446744073709551616
					end
					return string_char(byte_E, math_floor(v / 72057594037927936), math_floormod(v / 281474976710656, 256), math_floormod(v / 1099511627776, 256), math_floormod(v / 4294967296, 256), math_floormod(v / 16777216, 256), math_floormod(v / 65536, 256), math_floormod(v / 256, 256), math_mod(v, 256))
				end
			elseif v == inf then
				return string_char(64 --[[byte_inf]])
			elseif v == -inf then
				return string_char(36 --[[byte_ninf]])
			elseif v ~= v then
				return string_char(33 --[[byte_nan]])
			end
--			do
--				local s = tostring(v)
--				local len = string_len(s)
--				return string_char(byte_plus, len) .. s
--			end
			local sign = v < 0 or v == 0 and tostring(v) == "-0"
			if sign then
				v = -v
			end
			local m, exp = math.frexp(v)
			m = m * 9007199254740992
			local x = exp + 1023
			local b = math_mod(m, 256)
			local c = math_floormod(m / 256, 256)
			m = math_floor(m / 65536)
			m = m + x * 137438953472
			return string_char(sign and byte_minus or byte_plus, math_floormod(m / 1099511627776, 256), math_floormod(m / 4294967296, 256), math_floormod(m / 16777216, 256), math_floormod(m / 65536, 256), math_floormod(m / 256, 256), math_mod(m, 256), c, b)
		elseif kind == "string" then
			local hash = textToHash and textToHash[v]
			if hash then
				return string_char(byte_m, math_floor(hash / 65536), math_floormod(hash / 256, 256), math_mod(hash, 256))
			end
			local _,_,A,B,C,D,E,F,G,H = string_find(v, "^|cff%x%x%x%x%x%x|Hitem:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%-?%d+):(%d+)|h%[.+%]|h|r$")
			if A then
				-- item link
				
				A = A+0 -- convert to number
				B = B+0
				C = C+0
				D = D+0
				E = E+0
				F = F+0
				G = G+0
				H = H+0
				
				-- (1-35000):(1-3093):(1-3093):(1-3093):(1-3093):(?):(-57 to 2164):(0-4294967295)
				
				F = nil -- don't care
				if G < 0 then
					G = G + 65536 -- handle negatives
				end
				
				H = math_mod(H, 65536) -- only lower 16 bits matter
				
				return string_char(byte_i, math_floormod(A / 256, 256), math_mod(A, 256), math_floormod(B / 256, 256), math_mod(B, 256), math_floormod(C / 256, 256), math_mod(C, 256), math_floormod(D / 256, 256), math_mod(D, 256), math_floormod(E / 256, 256), math_mod(E, 256), math_floormod(G / 256, 256), math_mod(G, 256), math_floormod(H / 256, 256), math_mod(H, 256))
			else
				-- normal string
				local len = string_len(v)
				if len <= 255 then
					return string_char(byte_s, len) .. v
				else
					return string_char(byte_S, math_floor(len / 256), math_mod(len, 256)) .. v
				end
			end
		elseif kind == "function" then
			AceComm:error("Cannot serialize a function")
		elseif kind == "table" then
			if recurse[v] then
				for k in pairs(recurse) do
					recurse[k] = nil
				end
				AceComm:error("Cannot serialize a recursive table")
				return
			end
			recurse[v] = true
			if AceOO.inherits(v, AceOO.Class) then
				if not v.class then
					AceComm:error("Cannot serialize an AceOO class, can only serialize objects")
				elseif type(v.Serialize) ~= "function" then
					AceComm:error("Cannot serialize an AceOO object without the `Serialize' method.")
				elseif type(v.class.Deserialize) ~= "function" then
					AceComm:error("Cannot serialize an AceOO object without the `Deserialize' static method.")
				elseif type(v.class.GetLibraryVersion) ~= "function" or not AceLibrary:HasInstance(v.class:GetLibraryVersion()) then
					AceComm:error("Cannot serialize an AceOO object if the class is not registered with AceLibrary.")
				end
				local classHash = TailoredBinaryCheckSum(v.class:GetLibraryVersion())
				local t = { classHash, v:Serialize() }
				for i = 2, #t do
					t[i] = _Serialize(t[i], textToHash)
				end
				if not notFirst then
					for k in pairs(recurse) do
						recurse[k] = nil
					end
				end
				local s = table.concat(t)
				t = nil
				local len = string_len(s)
				if len <= 255 then
					return string_char(byte_o, len) .. s
				else
					return string_char(byte_O, math_floor(len / 256), math_mod(len, 256)) .. s
				end
			end
			local t = {}
			local islist = false
			local n = #v
			if n >= 1 then
				islist = true
				for k,u in pairs(v) do
					if type(k) ~= "number" or k < 1 then
						islist = false
						break
					end
				end
			end
			if islist then
				n = n * 4
				while v[n] == nil do
					n = n - 1
				end
				for i = 1, n do
					t[i] = _Serialize(v[i], textToHash)
				end
			else
				local i = 1
				for k,u in pairs(v) do
					t[i] = _Serialize(k, textToHash)
					t[i+1] = _Serialize(u, textToHash)
					i = i + 2
				end
			end
			if not notFirst then
				for k in pairs(recurse) do
					recurse[k] = nil
				end
			end
			local s = table.concat(t)
			t = nil
			local len = string_len(s)
			if islist then
				if len <= 255 then
					return string_char(byte_u, len) .. s
				else
					return "U" .. string_char(math_floor(len / 256), math_mod(len, 256)) .. s
				end
			else
				if len <= 255 then
					return "t" .. string_char(len) .. s
				else
					return "T" .. string_char(math_floor(len / 256), math_mod(len, 256)) .. s
				end
			end
		end
	end
	
	function Serialize(value, textToHash)
		if not recurse then
			recurse = {}
		end
		local chunk = _Serialize(value, textToHash)
		for k in pairs(recurse) do
			recurse[k] = nil
		end
		return chunk
	end
end

local Deserialize
do
	local tmp = {}
	local function _Deserialize(value, position, hashToText)
		if not position then
			position = 1
		end
		local x = string_byte(value, position)
		if x == byte_b then
			-- false
			return false, position
		elseif x == byte_B then
			-- true
			return true, position
		elseif x == byte_nil then
			-- nil
			return nil, position
		elseif x == byte_i then
			-- 14-byte item link
			local a1 = string_byte(value, position + 1)
			local a2 = string_byte(value, position + 2)
			local b1 = string_byte(value, position + 3)
			local b2 = string_byte(value, position + 4)
			local c1 = string_byte(value, position + 5)
			local c2 = string_byte(value, position + 6)
			local d1 = string_byte(value, position + 7)
			local d2 = string_byte(value, position + 8)
			local e1 = string_byte(value, position + 9)
			local e2 = string_byte(value, position + 10)
			local g1 = string_byte(value, position + 11)
			local g2 = string_byte(value, position + 12)
			local h1 = string_byte(value, position + 13)
			local h2 = string_byte(value, position + 14)
			local A = a1 * 256 + a2
			local B = b1 * 256 + b2
			local C = c1 * 256 + c2
			local D = d1 * 256 + d2
			local E = e1 * 256 + e2
			local G = g1 * 256 + g2
			local H = h1 * 256 + h2
			if G >= 32768 then
				G = G - 65536
			end
			local s = string.format("item:%d:%d:%d:%d:%d:%d:%d:%d", A, B, C, D, E, 0, G, H)
			local _, link = GetItemInfo(s)
			return link, position + 14
		elseif x == byte_m then
			local hash = string_byte(value, position + 1) * 65536 + string_byte(value, position + 2) * 256 + string_byte(value, position + 3)
			return hashToText[hash], position + 3
		elseif x == byte_s then
			-- 0-255-byte string
			local len = string_byte(value, position + 1)
			return string.sub(value, position + 2, position + 1 + len), position + 1 + len
		elseif x == byte_S then
			-- 256-65535-byte string
			local len = string_byte(value, position + 1) * 256 + string_byte(value, position + 2)
			return string.sub(value, position + 3, position + 2 + len), position + 2 + len
		elseif x == 64 --[[byte_inf]] then
			return inf, position
		elseif x == 36 --[[byte_ninf]] then
			return -inf, position
		elseif x == 33 --[[byte_nan]] then
			return nan, position
		elseif x == byte_d then
			-- 1-byte integer
			local a = string_byte(value, position + 1)
			if a >= 128 then
				a = a - 256
			end
			return a, position + 1
		elseif x == byte_D then
			-- 2-byte integer
			local a = string_byte(value, position + 1)
			local b = string_byte(value, position + 2)
			local N = a * 256 + b
			if N >= 32768 then
				N = N - 65536
			end
			return N, position + 2
		elseif x == byte_e then
			-- 4-byte integer
			local a = string_byte(value, position + 1)
			local b = string_byte(value, position + 2)
			local c = string_byte(value, position + 3)
			local d = string_byte(value, position + 4)
			local N = a * 16777216 + b * 65536 + c * 256 + d
			if N >= 2147483648 then
				N = N - 4294967296
			end
			return N, position + 4
		elseif x == byte_E then
			-- 8-byte integer
			local a = string_byte(value, position + 1)
			local b = string_byte(value, position + 2)
			local c = string_byte(value, position + 3)
			local d = string_byte(value, position + 4)
			local e = string_byte(value, position + 5)
			local f = string_byte(value, position + 6)
			local g = string_byte(value, position + 7)
			local h = string_byte(value, position + 8)
			local N = a * 72057594037927936 + b * 281474976710656 + c * 1099511627776 + d * 4294967296 + e * 16777216 + f * 65536 + g * 256 + h
			if N >= 9223372036854775808 then
				N = N - 18446744073709551616
			end
			return N, position + 8
		elseif x == byte_plus or x == byte_minus then
			local a = string_byte(value, position + 1)
			local b = string_byte(value, position + 2)
			local c = string_byte(value, position + 3)
			local d = string_byte(value, position + 4)
			local e = string_byte(value, position + 5)
			local f = string_byte(value, position + 6)
			local g = string_byte(value, position + 7)
			local h = string_byte(value, position + 8)
			local N = a * 1099511627776 + b * 4294967296 + c * 16777216 + d * 65536 + e * 256 + f
			local sign = x
			local x = math.floor(N / 137438953472)
			local m = math_mod(N, 137438953472) * 65536 + g * 256 + h
			local mantissa = m / 9007199254740992
			local exp = x - 1023
			local val = math.ldexp(mantissa, exp)
			if sign == byte_minus then
				return -val, position + 8
			end
			return val, position + 8
		elseif x == byte_u or x == byte_U then
			-- numerically-indexed table
			local finish
			local start
			if x == byte_u then
				local len = string_byte(value, position + 1)
				finish = position + 1 + len
				start = position + 2
			else
				local len = string_byte(value, position + 1) * 256 + string_byte(value, position + 2)
				finish = position + 2 + len
				start = position + 3
			end
			local t = {}
			local n = 0
			local curr = start - 1
			while curr < finish do
				local v
				v, curr = _Deserialize(value, curr + 1, hashToText)
				n = n + 1
				t[n] = v
			end
			return t, finish
		elseif x == byte_o or x == byte_O then
			-- numerically-indexed table
			local finish
			local start
			if x == byte_o then
				local len = string_byte(value, position + 1)
				finish = position + 1 + len
				start = position + 2
			else
				local len = string_byte(value, position + 1) * 256 + string_byte(value, position + 2)
				finish = position + 2 + len
				start = position + 3
			end
			local hash = string_byte(value, start) * 65536 + string_byte(value, start + 1) * 256 + string_byte(value, start + 2)
			local curr = start + 2
			if not AceComm.classes[hash] then
				return nil, finish
			end
			local class = AceComm.classes[hash]
			if type(class.Deserialize) ~= "function" or type(class.prototype.Serialize) ~= "function" then
				return nil, finish
			end
			local n = 0
			while curr < finish do
				local v
				v, curr = _Deserialize(value, curr + 1, hashToText)
				n = n + 1
				tmp[n] = v
			end
			local object = class:Deserialize(unpack(tmp))
			for i = 1, n do
				tmp[i] = nil
			end
			return object, finish
		elseif x == byte_t or x == byte_T then
			-- table
			local finish
			local start
			if x == byte_t then
				local len = string_byte(value, position + 1)
				finish = position + 1 + len
				start = position + 2
			else
				local len = string_byte(value, position + 1) * 256 + string_byte(value, position + 2)
				finish = position + 2 + len
				start = position + 3
			end
			local t = {}
			local curr = start - 1
			while curr < finish do
				local key, l = _Deserialize(value, curr + 1, hashToText)
				local value, m = _Deserialize(value, l + 1, hashToText)
				curr = m
				t[key] = value
			end
			if type(t.n) ~= "number" then
				local i = 1
				while t[i] ~= nil do
					i = i + 1
				end
			end
			return t, finish
		else
			error("Improper serialized value provided")
		end
	end
	
	function Deserialize(value, hashToText)
		local ret,msg = pcall(_Deserialize, value, nil, hashToText)
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
		return UnitInParty("player") == 1
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
		if string_len(customChannel) == 0 then
			AceComm:error('Argument #4 to `RegisterComm\' must be a non-zero-length string.')
		elseif string_find(customChannel, "%s") then
			AceComm:error('Argument #4 to `RegisterComm\' must not have spaces.')
		end
	end
	if self == AceComm then
		AceComm:argCheck(method, customChannel and 5 or 4, "function", "table")
		self = method
	else
		AceComm:argCheck(method, customChannel and 5 or 4, "string", "function", "table", "nil")
	end
	if not method then
		method = "OnCommReceive"
	end
	if type(method) == "string" and type(self[method]) ~= "function" and type(self[method]) ~= "table" then
		AceEvent:error("Cannot register comm %q to method %q, it does not exist", prefix, method)
	end
	
	local registry = AceComm_registry
	if not registry[distribution] then
		registry[distribution] = {}
	end
	if customChannel then
		customChannel = "AceComm" .. customChannel
		if not registry[distribution][customChannel] then
			registry[distribution][customChannel] = {}
		end
		if not registry[distribution][customChannel][prefix] then
			registry[distribution][customChannel][prefix] = {}
		end
		registry[distribution][customChannel][prefix][self] = method
	else
		if not registry[distribution][prefix] then
			registry[distribution][prefix] = {}
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
		if string_len(customChannel) == 0 then
			AceComm:error('Argument #3 to `UnregisterComm\' must be a non-zero-length string.')
		end
	else
		AceComm:argCheck(customChannel, 3, "nil")
	end
	
	local registry = AceComm_registry
	if not distribution then
		for k,v in pairs(registry) do
			if k == "CUSTOM" then
				for l,u in pairs(v) do
					if u[prefix] and u[prefix][self] then
						AceComm.UnregisterComm(self, prefix, k, string.sub(l, 8))
						if not registry[k] then
							break
						end
					end
				end
			else
				if v[prefix] and v[prefix][self] then
					AceComm.UnregisterComm(self, prefix, k)
				end
			end
		end
		return
	end
	if self == AceComm then
		if distribution == "CUSTOM" then
			error(string_format("Cannot unregister comm %q::%q. Improperly unregistering from AceComm-2.0.", distribution, customChannel), 2)
		else
			error(string_format("Cannot unregister comm %q. Improperly unregistering from AceComm-2.0.", distribution), 2)
		end
	end
	if distribution == "CUSTOM" then
		customChannel = "AceComm" .. customChannel
		if not registry[distribution] or not registry[distribution][customChannel] or not registry[distribution][customChannel][prefix] or not registry[distribution][customChannel][prefix][self] then
			AceComm:error("Cannot unregister comm %q. %q is not registered with it.", distribution, self)
		end
		registry[distribution][customChannel][prefix][self] = nil
		
		if not next(registry[distribution][customChannel][prefix]) then
			registry[distribution][customChannel][prefix] = nil
		end
		
		if not next(registry[distribution][customChannel]) then
			registry[distribution][customChannel] = nil
		end
	else
		if not registry[distribution] or not registry[distribution][prefix] or not registry[distribution][prefix][self] then
			AceComm:error("Cannot unregister comm %q. %q is not registered with it.", distribution, self)
		end
		registry[distribution][prefix][self] = nil
		
		if not next(registry[distribution][prefix]) then
			registry[distribution][prefix] = nil
		end
	end
	
	if not next(registry[distribution]) then
		registry[distribution] = nil
	end
	
	RefixAceCommChannelsAndEvents()
end

function AceComm:UnregisterAllComms()
	local registry = AceComm_registry
	for k, distribution in pairs(registry) do
		if k == "CUSTOM" then
			for l, channel in pairs(distribution) do
				local j = next(channel)
				while j ~= nil do
					local prefix = channel[j]
					if prefix[self] then
						AceComm.UnregisterComm(self, j)
						if distribution[l] and registry[k] then
							j = next(channel)
						else
							l = nil
							k = nil
							break
						end
					else
						j = next(channel, j)
					end
				end
				if k == nil then
					break
				end
			end
		else
			local j = next(distribution)
			while j ~= nil do
				local prefix = distribution[j]
				if prefix[self] then
					AceComm.UnregisterComm(self, j)
					if registry[k] then
						j = next(distribution)
					else
						k = nil
						break
					end
				else
					j = next(distribution, j)
				end
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
		if customChannel == "" then
			AceComm:error('Argument #4 to `IsCommRegistered\' must be a non-zero-length string or nil.')
		end
	else
		AceComm:argCheck(customChannel, 4, "nil")
	end
	local registry = AceComm_registry
	if not distribution then
		for k,v in pairs(registry) do
			if k == "CUSTOM" then
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
		if not registry[distribution] then
			return false
		end
		for l,u in pairs(registry[distribution]) do
			if u[prefix] and u[prefix][self] then
				return true
			end
		end
		return false
	elseif distribution == "CUSTOM" then
		customChannel = "AceComm" .. customChannel
		return registry[distribution] and registry[distribution][customChannel] and registry[distribution][customChannel][prefix] and registry[distribution][customChannel][prefix][self] and true or false
	end
	return registry[distribution] and registry[distribution][prefix] and registry[distribution][prefix][self] and true or false
end

function AceComm:OnEmbedDisable(target)
	self.UnregisterAllComms(target)
end

local id = byte_Z

local function encodedChar(x)
	if x == 10 then
		return "°\011"
	elseif x == 0 then
		return "\255"
	elseif x == 255 then
		return "°\254"
	elseif x == 124 then
		return "°\125"
	elseif x == byte_s then
		return "\015"
	elseif x == byte_S then
		return "\020"
	elseif x == 15 then
		return "°\016"
	elseif x == 20 then
		return "°\021"
	elseif x == byte_deg then
		return "°±"
	elseif x == 37 then
		return "°\038"
	end
	return string_char(x)
end

local function soberEncodedChar(x)
	if x == 10 then
		return "°\011"
	elseif x == 0 then
		return "\255"
	elseif x == 255 then
		return "°\254"
	elseif x == 124 then
		return "°\125"
	elseif x == byte_deg then
		return "°±"
	elseif x == 37 then
		return "°\038"
	end
	return string_char(x)
end

local function SendMessage(prefix, priority, distribution, person, message, textToHash)
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
	if id == byte_s or id == byte_S then
		id = id + 1
	end
	local id = string_char(id)
	local drunk = distribution == "GLOBAL" or distribution == "WHISPER" or distribution == "ZONE" or distribution == "CUSTOM"
	prefix = Encode(prefix, drunk)
	message = Serialize(message, textToHash)
	message = Encode(message, drunk)
	local headerLen = string_len(prefix) + 6
	local messageLen = string_len(message)
	if distribution == "WHISPER" then
		AceComm.recentWhispers[string.lower(person)] = GetTime()
	end
	local max = math_floor(messageLen / (250 - headerLen) + 1)
	if max > 1 then
		local segment = math_floor(messageLen / max + 0.5)
		local last = 0
		local good = true
		for i = 1, max do
			local bit
			if i == max then
				bit = string_sub(message, last + 1)
			else
				local next = segment * i
				if string_byte(message, next) == byte_deg then
					next = next + 1
				end
				bit = string_sub(message, last + 1, next)
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
				bit = id .. soberEncodedChar(i) .. soberEncodedChar(max) .. "\t" .. bit
				ChatThrottleLib:SendAddonMessage(priority, prefix, bit, distribution)
			end
		end
		return good
	else
		if distribution == "WHISPER" then
			message = "/" .. prefix .. "\t" .. id .. string_char(1) .. string_char(1) .. "\t" .. message .. "°"
			ChatThrottleLib:SendChatMessage(priority, prefix, message, "WHISPER", nil, person)
			return true
		elseif distribution == "GLOBAL" or distribution == "ZONE" or distribution == "CUSTOM" then
			message = prefix .. "\t" .. id .. string_char(1) .. string_char(1) .. "\t" .. message .. "°"
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
			message = id .. string_char(1) .. string_char(1) .. "\t" .. message
			ChatThrottleLib:SendAddonMessage(priority, prefix, message, distribution)
			return true
		end
	end
	return false
end

local tmp = {}
function AceComm:SendPrioritizedCommMessage(priority, distribution, person, ...)
	AceComm:argCheck(priority, 2, "string")
	if priority ~= "NORMAL" and priority ~= "BULK" and priority ~= "ALERT" then
		AceComm:error('Argument #2 to `SendPrioritizedCommMessage\' must be either "NORMAL", "BULK", or "ALERT"')
	end
	AceComm:argCheck(distribution, 3, "string")
	local includePerson = true
	if distribution == "WHISPER" or distribution == "CUSTOM" then
		includePerson = false
		AceComm:argCheck(person, 4, "string")
		if string_len(person) == 0 then
			AceComm:error("Argument #4 to `SendPrioritizedCommMessage' must be a non-zero-length string")
		end
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
	
	if includePerson and select('#', ...) == 0 and type(person) ~= "table" then
		message = person
	elseif not includePerson and select('#', ...) == 1 and type((...)) ~= "table" then
		message = ...
	else
		message = tmp
		local n = 1
		if includePerson then
			tmp[1] = person
			n = 2
		end
		for i = 1, select('#', ...) do
			tmp[n] = select(i, ...)
			n = n + 1
		end
	end
	
	local ret = SendMessage(AceComm.prefixTextToHash[prefix], priority, distribution, person, message, self.commMemoTextToHash)
	
	if message == tmp then
		local n = #tmp
		for i = 1, n do
			tmp[i] = nil
		end
	end
	
	return ret
end

function AceComm:SendCommMessage(distribution, person, ...)
	AceComm:argCheck(distribution, 2, "string")
	local includePerson = true
	if distribution == "WHISPER" or distribution == "CUSTOM" then
		includePerson = false
		AceComm:argCheck(person, 3, "string")
		if string_len(person) == 0 then
			AceComm:error("Argument #3 to `SendCommMessage' must be a non-zero-length string")
		end
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
	
	if includePerson and select('#', ...) == 0 and type(person) ~= "table" then
		message = person
	elseif not includePerson and select('#', ...) == 1 and type((...)) ~= "table" then
		message = ...
	else
		message = tmp
		local n = 1
		if includePerson then
			tmp[1] = person
			n = 2
		end
		for i = 1, select('#', ...) do
			tmp[n] = select(i, ...)
			n = n + 1
		end
	end
	
	local priority = self.commPriority or "NORMAL"
	
	local ret = SendMessage(AceComm.prefixTextToHash[prefix], priority, distribution, person, message, self.commMemoTextToHash)
	
	if message == tmp then
		local n = #tmp
		for i = 1, n do
			tmp[i] = nil
		end
	end
	
	return ret
end

function AceComm:SetDefaultCommPriority(priority)
	AceComm:argCheck(priority, 2, "string")
	if priority ~= "NORMAL" and priority ~= "BULK" and priority ~= "ALERT" then
		AceComm:error('Argument #2 must be either "NORMAL", "BULK", or "ALERT"')
	end
	
	if self.commPriority then
		AceComm:error("Cannot call `SetDefaultCommPriority' more than once")
	end
	
	self.commPriority = priority
end

function AceComm:SetCommPrefix(prefix)
	AceComm:argCheck(prefix, 2, "string")
	
	if self.commPrefix then
		AceComm:error("Cannot call `SetCommPrefix' more than once.")
	end
	
	if AceComm.prefixes[prefix] then
		AceComm:error("Cannot set prefix to %q, it is already in use.", prefix)
	end
	
	local hash = TailoredBinaryCheckSum(prefix)
	if AceComm.prefixHashToText[hash] then
		AceComm:error("Cannot set prefix to %q, its hash is used by another prefix: %q", prefix, AceComm.prefixHashToText[hash])
	end
	
	AceComm.prefixes[prefix] = true
	self.commPrefix = prefix
	AceComm.prefixHashToText[hash] = prefix
	AceComm.prefixTextToHash[prefix] = hash
end

function AceComm:RegisterMemoizations(values)
	AceComm:argCheck(values, 2, "table")
	for k,v in pairs(values) do
		if type(k) ~= "number" then
			AceComm:error("Bad argument #2 to `RegisterMemoizations'. All keys must be numbers")
		elseif type(v) ~= "string" then
			AceComm:error("Bad argument #2 to `RegisterMemoizations'. All values must be strings")
		end
	end
	if self.commMemoHashToText or self.commMemoTextToHash then
		AceComm:error("You can only call `RegisterMemoizations' once.")
	elseif not self.commPrefix then
		AceComm:error("You can only call `RegisterCommPrefix' before calling `RegisterMemoizations'.")
	elseif AceComm.prefixMemoizations[self.commPrefix] then
		AceComm:error("Another addon with prefix %q has already registered memoizations.", self.commPrefix)
	end
	local hashToText = {}
	local textToHash = {}
	for _,text in ipairs(values) do
		local hash = TailoredNumericCheckSum(text)
		if hashToText[hash] then
			AceComm:error("%q and %q have the same checksum. You must remove one of them for memoization to work properly", hashToText[hash], text)
		else
			textToHash[text] = hash
			hashToText[hash] = text
		end
	end
	values = nil
	self.commMemoHashToText = hashToText
	self.commMemoTextToHash = textToHash
	AceComm.prefixMemoizations[self.commPrefix] = hashToText
end

local lastCheck = GetTime()
local function CheckRefix()
	if GetTime() - lastCheck >= 120 then
		lastCheck = GetTime()
		RefixAceCommChannelsAndEvents()
	end
end

local stack = setmetatable({}, {__mode='k'})
local function HandleMessage(prefix, message, distribution, sender, customChannel)
	local isGroup = GetCurrentGroupDistribution() == distribution
	local isCustom = distribution == "CUSTOM"
	if (not AceComm_registry[distribution] and (not isGroup or not AceComm_registry.GROUP)) or (isCustom and not AceComm_registry.CUSTOM[customChannel]) then
		return CheckRefix()
	end
	local _, id, current, max
	if not message then
		if distribution == "WHISPER" then
			_,_, prefix, id, current, max, message = string_find(prefix, "^/(...)\t(.)(.)(.)\t(.*)$")
		else
			_,_, prefix, id, current, max, message = string_find(prefix, "^(...)\t(.)(.)(.)\t(.*)$")
		end
		prefix = AceComm.prefixHashToText[prefix]
		if not prefix then
			return CheckRefix()
		end
		if isCustom then
			if not AceComm_registry.CUSTOM[customChannel][prefix] then
				return CheckRefix()
			end
		else
			if (not AceComm_registry[distribution] or not AceComm_registry[distribution][prefix]) and (not isGroup or not AceComm_registry.GROUP or not AceComm_registry.GROUP[prefix]) then
				return CheckRefix()
			end
		end
	else
		_,_, id, current, max, message = string_find(message, "^(.)(.)(.)\t(.*)$")
	end
	if not message then
		return
	end
	local smallCustomChannel = customChannel and string_sub(customChannel, 8)
	current = string_byte(current)
	max = string_byte(max)
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
			local t = next(stack) or {}
			stack[t] = nil
			queue[x] = t
		end
		local chunk = queue[x]
		chunk.time = GetTime()
		chunk[current] = message
		if chunk[max] then
			local success
			success, message = pcall(table_concat, chunk)
			if not success then
				return
			end
			local t = queue[x]
			queue[x] = nil
			for k in pairs(t) do
				t[k] = nil
			end
			stack[t] = true
		else
			return
		end
	end
	message = Deserialize(message, AceComm.prefixMemoizations[prefix])
	local isTable = type(message) == "table"
	local n
	if isTable then
		n = #message * 4
		if n < 40 then
			n = 40
		end
		while message[n] == nil do
			n = n - 1
		end
	end
	if AceComm_registry[distribution] then
		if isTable then
			if isCustom then
				if AceComm_registry.CUSTOM[customChannel][prefix] then
					for k,v in pairs(AceComm_registry.CUSTOM[customChannel][prefix]) do
						local type_v = type(v)
						if type_v == "string" then
							local f = k[v]
							if type(f) == "table" then
								local i = 1
								local g = f[message[i]]
								while g do
									if type(g) ~= "table" then -- function
										g(k, prefix, sender, distribution, smallCustomChannel, unpack(message, i+1, n))
										break
									else
										i = i + 1
										g = g[message[i]]
									end
								end
							else -- function
								f(k, prefix, sender, distribution, smallCustomChannel, unpack(message, 1, n))
							end
						elseif type_v == "table" then
							local i = 1
							local g = v[message[i]]
							while g do
								if type(g) ~= "table" then -- function
									g(prefix, sender, distribution, smallCustomChannel, unpack(message, i+1, n))
									break
								else
									i = i + 1
									g = g[message[i]]
								end
							end
						else -- function
							v(prefix, sender, distribution, smallCustomChannel, unpack(message, 1, n))
						end
					end
				end
			else
				if AceComm_registry[distribution][prefix] then
					for k,v in pairs(AceComm_registry[distribution][prefix]) do
						local type_v = type(v)
						if type_v == "string" then
							local f = k[v]
							if type(f) == "table" then
								local i = 1
								local g = f[message[i]]
								while g do
									if type(g) ~= "table" then -- function
										g(k, prefix, sender, distribution, unpack(message, i+1, n))
										break
									else
										i = i + 1
										g = g[message[i]]
									end
								end
							else -- function
								f(k, prefix, sender, distribution, unpack(message, 1, n))
							end
						elseif type_v == "table" then
							local i = 1
							local g = v[message[i]]
							while g do
								if type(g) ~= "table" then -- function
									g(prefix, sender, distribution, unpack(message, i+1, n))
									break
								else
									i = i + 1
									g = g[message[i]]
								end
							end
						else -- function
							v(prefix, sender, distribution, unpack(message, 1, n))
						end
					end
				end
			end
		else
			if isCustom then
				if AceComm_registry.CUSTOM[customChannel][prefix] then
					for k,v in pairs(AceComm_registry.CUSTOM[customChannel][prefix]) do
						local type_v = type(v)
						if type_v == "string" then
							local f = k[v]
							if type(f) == "table" then
								local g = f[message]
								if g and type(g) == "function" then
									g(k, prefix, sender, distribution, smallCustomChannel)
								end
							else -- function
								f(k, prefix, sender, distribution, smallCustomChannel, message)
							end
						elseif type_v == "table" then
							local g = v[message]
							if g and type(g) == "function" then
								g(k, prefix, sender, distribution, smallCustomChannel)
							end
						else -- function
							v(prefix, sender, distribution, smallCustomChannel, message)
						end
					end
				end
			else
				if AceComm_registry[distribution][prefix] then
					for k,v in pairs(AceComm_registry[distribution][prefix]) do
						local type_v = type(v)
						if type_v == "string" then
							local f = k[v]
							if type(f) == "table" then
								local g = f[message]
								if g and type(g) == "function" then
									g(k, prefix, sender, distribution)
								end
							else -- function
								f(k, prefix, sender, distribution, message)
							end
						elseif type_v == "table" then
							local g = v[message]
							if g and type(g) == "function" then
								g(k, prefix, sender, distribution)
							end
						else -- function
							v(prefix, sender, distribution, message)
						end
					end
				end
			end
		end
	end
	if isGroup and AceComm_registry.GROUP and AceComm_registry.GROUP[prefix] then
		if isTable then
			for k,v in pairs(AceComm_registry.GROUP[prefix]) do
				local type_v = type(v)
				if type_v == "string" then
					local f = k[v]
					if type(f) == "table" then
						local i = 1
						local g = f[message[i]]
						while g do
							if type(g) ~= "table" then -- function
								g(k, prefix, sender, "GROUP", unpack(message, i+1, n))
								break
							else
								i = i + 1
								g = g[message[i]]
							end
						end
					else -- function
						f(k, prefix, sender, "GROUP", unpack(message, 1, n))
					end
				elseif type_v == "table" then
					local i = 1
					local g = v[message[i]]
					while g do
						if type(g) ~= "table" then -- function
							g(prefix, sender, "GROUP", unpack(message, i+1, n))
							break
						else
							i = i + 1
							g = g[message[i]]
						end
					end
				else -- function
					v(prefix, sender, "GROUP", unpack(message, 1, n))
				end
			end
		else
			for k,v in pairs(AceComm_registry.GROUP[prefix]) do
				local type_v = type(v)
				if type_v == "string" then
					local f = k[v]
					if type(f) == "table" then
						local g = f[message]
						if g and type(g) == "function" then
							g(k, prefix, sender, "GROUP")
						end
					else -- function
						f(k, prefix, sender, "GROUP", message)
					end
				elseif type_v == "table" then
					local g = v[message]
					if g and type(g) == "function" then
						g(k, prefix, sender, "GROUP")
					end
				else -- function
					v(prefix, sender, "GROUP", message)
				end
			end
		end
	end
end

function AceComm:CHAT_MSG_ADDON(prefix, message, distribution, sender)
	if sender == player then
		return
	end
	prefix = self.prefixHashToText[prefix]
	if not prefix then
		return CheckRefix()
	end
	local isGroup = GetCurrentGroupDistribution() == distribution
	if not AceComm_registry[distribution] and (not isGroup or not AceComm_registry.GROUP) then
		return CheckRefix()
	end
	prefix = Decode(prefix)
	if (not AceComm_registry[distribution] or not AceComm_registry[distribution][prefix]) and (not isGroup or not AceComm_registry.GROUP or not AceComm_registry.GROUP[prefix]) then
		return CheckRefix()
	end
	message = Decode(message)
	return HandleMessage(prefix, message, distribution, sender)
end

function AceComm:CHAT_MSG_WHISPER(text, sender)
	if not string_find(text, "^/") then
		return
	end
	text = Decode(text, true)
	return HandleMessage(text, nil, "WHISPER", sender)
end

function AceComm:CHAT_MSG_CHANNEL(text, sender, _, _, _, _, _, _, channel)
	if sender == player or not string_find(channel, "^AceComm") then
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

function AceComm:IsUserInChannel(userName, distribution, customChannel)
	AceComm:argCheck(userName, 2, "string", "nil")
	if not userName then
		userName = player
	end
	AceComm:argCheck(distribution, 3, "string")
	local channel
	if distribution == "GLOBAL" then
		channel = "AceComm"
	elseif distribution == "ZONE" then
		channel = GetCurrentZoneChannel()
	elseif distribution == "CUSTOM" then
		AceComm:argCheck(customChannel, 4, "string")
		channel = "AceComm" .. customChannel
	else
		AceComm:error('Argument #3 to `IsUserInChannel\' must be "GLOBAL", "CUSTOM", or "ZONE"')
	end
	
	return AceComm.userRegistry[channel] and AceComm.userRegistry[channel][userName] or false
end

function AceComm:CHAT_MSG_CHANNEL_LIST(text, _, _, _, _, _, _, _, channel)
	if not string_find(channel, "^AceComm") then
		return
	end
	
	if not AceComm.userRegistry[channel] then
		AceComm.userRegistry[channel] = {}
	end
	local t = AceComm.userRegistry[channel]
	for k in string_gmatch(text, "[^, @%*#]+") do
		t[k] = true
	end
end

function AceComm:CHAT_MSG_CHANNEL_JOIN(_, user, _, _, _, _, _, _, channel)
	if not string_find(channel, "^AceComm") then
		return
	end
	
	if not AceComm.userRegistry[channel] then
		AceComm.userRegistry[channel] = {}
	end
	local t = AceComm.userRegistry[channel]
	t[user] = true
end

function AceComm:CHAT_MSG_CHANNEL_LEAVE(_, user, _, _, _, _, _, _, channel)
	if not string_find(channel, "^AceComm") then
		return
	end
	
	if not AceComm.userRegistry[channel] then
		AceComm.userRegistry[channel] = {}
	end
	local t = AceComm.userRegistry[channel]
	if t[user] then
		t[user] = nil
	end
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

local recentNotSeen = {}
local notSeenString = '^' .. string_gsub(string_gsub(ERR_CHAT_PLAYER_NOT_FOUND_S, "%%s", "(.-)"), "%%1%$s", "(.-)") .. '$'
local ambiguousString = '^' .. string_gsub(string_gsub(ERR_CHAT_PLAYER_AMBIGUOUS_S, "%%s", "(.-)"), "%%1%$s", "(.-)") .. '$'
function AceComm.hooks:ChatFrame_MessageEventHandler(orig, event)
	if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		if string_find(arg1, "^/") then
			return
		end
	elseif event == "CHAT_MSG_AFK" or event == "CHAT_MSG_DND" then
		local t = self.recentWhispers[string.lower(arg2)]
		if t and GetTime() - t <= 15 then
			return
		end
	elseif event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_CHANNEL_LIST" then
		if string_find(arg9, "^AceComm") then
			return
		end
	elseif event == "CHAT_MSG_SYSTEM" then
		local _,_,player = string_find(arg1, notSeenString)
		if not player then
			_,_,player = string_find(arg1, ambiguousString)
		end
		if player then
			local t = GetTime()
			if recentNotSeen[player] and recentNotSeen[player] > t then
				recentNotSeen[player] = t + 10
				return
			else
				recentNotSeen[player] = t + 10
			end
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
	local arg = { ... }
	for i = 1, #arg, 2 do
		if not arg[i] then
			break
		end
		if type(arg[i + 1]) == "string" and string_find(arg[i + 1], "^AceComm") then
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
	if not string_find(lastChannelJoined, "^AceComm") then
		return
	end
	
	local text
	if chan == "AceComm" then
		local addon = self.registry.GLOBAL and next(AceComm_registry.GLOBAL)
		if not addon then
			return
		end
		addon = tostring(addon)
		text = string_format("%s has tried to join the AceComm global channel, but there are not enough channels available. %s may not work because of this", addon, addon)
	elseif chan == GetCurrentZoneChannel() then
		local addon = AceComm_registry.ZONE and next(AceComm_registry.ZONE)
		if not addon then
			return
		end
		addon = tostring(addon)
		text = string_format("%s has tried to join the AceComm zone channel, but there are not enough channels available. %s may not work because of this", addon, addon)
	else
		local addon = AceComm_registry.CUSTOM and AceComm_registry.CUSTOM[chan] and next(AceComm_registry.CUSTOM[chan])
		if not addon then
			return
		end
		addon = tostring(addon)
		text = string_format("%s has tried to join the AceComm custom channel %s, but there are not enough channels available. %s may not work because of this", addon, chan, addon)
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
	
	if oldLib then
		self.frame = oldLib.frame
		self.frame:UnregisterAllEvents()
		self.recvQueue = oldLib.recvQueue
		self.registry = oldLib.registry
		self.channels = oldLib.channels
		self.prefixes = oldLib.prefixes
		self.classes = oldLib.classes
		self.prefixMemoizations = oldLib.prefixMemoizations
		self.prefixHashToText = oldLib.prefixHashToText
		self.prefixTextToHash = oldLib.prefixTextToHash
		self.recentWhispers = oldLib.recentWhispers
		self.userRegistry = oldLib.userRegistry
	else
		local old_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler
		function ChatFrame_MessageEventHandler(event)
			if self.hooks.ChatFrame_MessageEventHandler then
				return self.hooks.ChatFrame_MessageEventHandler(self, old_ChatFrame_MessageEventHandler, event)
			else
				return old_ChatFrame_MessageEventHandler(event)
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
				return self.hooks.FCFDropDown_LoadChannels(self, old_FCFDropDown_LoadChannels, ...)
			else
				return old_FCFDropDown_LoadChannels(...)
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
	AceComm_registry = self.registry
	if not self.prefixes then
		self.prefixes = {}
	end
	if not self.classes then
		self.classes = {}
	else
		for k in pairs(self.classes) do
			self.classes[k] = nil
		end
	end
	if not self.prefixMemoizations then
		self.prefixMemoizations = {}
	end
	if not self.prefixHashToText then
		self.prefixHashToText = {}
	end
	if not self.prefixTextToHash then
		self.prefixTextToHash = {}
	end
	if not self.recentWhispers then
		self.recentWhispers = {}
	end
	if not self.userRegistry then
		self.userRegistry = {}
	end
	
	SetCVar("spamFilter", 0)
	
	self:activate(oldLib, oldDeactivate)
	
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
			self:RegisterEvent("AceEvent_FullyInitialized", "AceEvent_FullyInitialized", true)
		end
		
		self:RegisterEvent("PLAYER_LOGOUT")
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
		self:RegisterEvent("CHAT_MSG_SYSTEM")
	else
		if AceOO.inherits(instance, AceOO.Class) and not instance.class then
			self.classes[TailoredNumericCheckSum(major)] = instance
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
-- Will install hooks for SendChatMessage and SendAdd[Oo]nMessage to measure
-- bandwidth bypassing the library and use less bandwidth itself.
--
--
-- Fully embeddable library. Just copy this file into your addon directory,
-- add it to the .toc, and it's done.
--
-- Can run as a standalone addon also, but, really, just embed it! :-)
--

local CTL_VERSION = 13

local MAX_CPS = 800			  -- 2000 seems to be safe if NOTHING ELSE is happening. let's call it 800.
local MSG_OVERHEAD = 40		-- Guesstimate overhead for sending a message; source+dest+chattype+protocolstuff

local BURST = 4000				-- WoW's server buffer seems to be about 32KB. 8KB should be safe, but seen disconnects on _some_ servers. Using 4KB now.

local MIN_FPS = 20				-- Reduce output CPS to half (and don't burst) if FPS drops below this value

if(ChatThrottleLib and ChatThrottleLib.version>=CTL_VERSION) then
	-- There's already a newer (or same) version loaded. Buh-bye.
	return;
end



if(not ChatThrottleLib) then
	ChatThrottleLib = {}
end

local ChatThrottleLib = ChatThrottleLib
local strlen = strlen
local setmetatable = setmetatable
local getn = getn
local tremove = tremove
local tinsert = tinsert
local tostring = tostring
local GetTime = GetTime
local format = format

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
	
	-- v4: total send counters per priority
	for _,Prio in pairs(self.Prio) do
		Prio.nTotalSent = Prio.nTotalSent or 0;
	end
	
	self.avail = self.avail or 0;							-- v5
	self.nTotalSent = self.nTotalSent or 0;		-- v5

	
	-- Set up a frame to get OnUpdate events
	if(not self.Frame) then
		self.Frame = CreateFrame("Frame");
		self.Frame:Hide();
	end
	self.Frame.Show = self.Frame.Show; -- cache for speed
	self.Frame.Hide = self.Frame.Hide; -- cache for speed
	self.Frame:SetScript("OnUpdate", self.OnUpdate);
	self.Frame:SetScript("OnEvent", self.OnEvent);	-- v11: Monitor P_E_W so we can throttle hard for a few seconds
	self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	self.OnUpdateDelay=0;
	self.LastAvailUpdate=GetTime();
	self.HardThrottlingBeginTime=GetTime();	-- v11: Throttle hard for a few seconds after startup
	
	-- Hook SendChatMessage and SendAddonMessage so we can measure unpiped traffic and avoid overloads (v7)
	if(not self.ORIG_SendChatMessage) then
		--SendChatMessage
		self.ORIG_SendChatMessage = SendChatMessage;
		SendChatMessage = function(a1,a2,a3,a4) return ChatThrottleLib.Hook_SendChatMessage(a1,a2,a3,a4); end
		--SendAdd[Oo]nMessage
		if(SendAddonMessage or SendAddOnMessage) then -- v10: don't pretend like it doesn't exist if it doesn't!
			self.ORIG_SendAddonMessage = SendAddonMessage or SendAddOnMessage;
			SendAddonMessage = function(a1,a2,a3) return ChatThrottleLib.Hook_SendAddonMessage(a1,a2,a3); end
			if(SendAddOnMessage) then		-- in case Slouken changes his mind...
				SendAddOnMessage = SendAddonMessage;
			end
		end
	end
	self.nBypass = 0;
end


-----------------------------------------------------------------------
-- ChatThrottleLib.Hook_SendChatMessage / .Hook_SendAddonMessage
function ChatThrottleLib.Hook_SendChatMessage(text, chattype, language, destination)
	local self = ChatThrottleLib;
	local size = strlen(tostring(text or "")) + strlen(tostring(chattype or "")) + strlen(tostring(destination or "")) + 40;
	self.avail = self.avail - size;
	self.nBypass = self.nBypass + size;
	return self.ORIG_SendChatMessage(text, chattype, language, destination);
end
function ChatThrottleLib.Hook_SendAddonMessage(prefix, text, chattype)
	local self = ChatThrottleLib;
	local size = strlen(tostring(text or "")) + strlen(tostring(chattype or "")) + strlen(tostring(prefix or "")) + 40;
	self.avail = self.avail - size;
	self.nBypass = self.nBypass + size;
	return self.ORIG_SendAddonMessage(prefix, text, chattype);
end



-----------------------------------------------------------------------
-- ChatThrottleLib:UpdateAvail
-- Update self.avail with how much bandwidth is currently available

function ChatThrottleLib:UpdateAvail()
	local now = GetTime();
	local newavail = MAX_CPS * (now-self.LastAvailUpdate);

	if(now - self.HardThrottlingBeginTime < 5) then
		-- First 5 seconds after startup/zoning: VERY hard clamping to avoid irritating the server rate limiter, it seems very cranky then
		self.avail = min(self.avail + (newavail*0.1), MAX_CPS*0.5);
	elseif(GetFramerate()<MIN_FPS) then		-- GetFrameRate call takes ~0.002 secs
		newavail = newavail * 0.5;
		self.avail = min(MAX_CPS, self.avail + newavail);
		self.bChoking = true;		-- just for stats
	else
		self.avail = min(BURST, self.avail + newavail);
		self.bChoking = false;
	end
	
	self.avail = max(self.avail, 0-(MAX_CPS*2));	-- Can go negative when someone is eating bandwidth past the lib. but we refuse to stay silent for more than 2 seconds; if they can do it, we can.
	self.LastAvailUpdate = now;
	
	return self.avail;
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


function ChatThrottleLib.OnEvent()
	-- v11: We know that the rate limiter is touchy after login. Assume that it's touch after zoning, too.
	self = ChatThrottleLib;
	if(event == "PLAYER_ENTERING_WORLD") then
		self.HardThrottlingBeginTime=GetTime();	-- Throttle hard for a few seconds after zoning
		self.avail = 0;
	end
end


function ChatThrottleLib.OnUpdate()
	self = ChatThrottleLib;
	
	self.OnUpdateDelay = self.OnUpdateDelay + arg1;
	if(self.OnUpdateDelay < 0.08) then
		return;
	end
	self.OnUpdateDelay = 0;
	
	self:UpdateAvail();
	
	if(self.avail<0) then
		return; -- argh. some bastard is spewing stuff past the lib. just bail early to save cpu.
	end

	-- See how many of or priorities have queued messages
	local n=0;
	for prioname,Prio in pairs(self.Prio) do
		if(Prio.Ring.pos or Prio.avail<0) then 
			n=n+1; 
		end
	end
	
	-- Anything queued still?
	if(n<1) then
		-- Nope. Move spillover bandwidth to global availability gauge and clear self.bQueueing
		for prioname,Prio in pairs(self.Prio) do
			self.avail = self.avail + Prio.avail;
			Prio.avail = 0;
		end
		self.bQueueing = false;
		self.Frame:Hide();
		return;
	end
	
	-- There's stuff queued. Hand out available bandwidth to priorities as needed and despool their queues
	local avail= self.avail/n;
	self.avail = 0;
	
	for prioname,Prio in pairs(self.Prio) do
		if(Prio.Ring.pos or Prio.avail<0) then
			Prio.avail = Prio.avail + avail;
			if(Prio.Ring.pos and Prio.avail>Prio.Ring.pos[1].nSize) then
				self:Despool(Prio);
			end
		end
	end

	-- Expire recycled tables if needed	
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
	
	self.bQueueing = true;
end



function ChatThrottleLib:SendChatMessage(prio, prefix,   text, chattype, language, destination)
	if(not (self and prio and text and self.Prio[prio] ) ) then
		error('Usage: ChatThrottleLib:SendChatMessage("{BULK||NORMAL||ALERT}", "prefix" or nil, "text"[, "chattype"[, "language"[, "destination"]]]', 2);
	end
	
	prefix = prefix or tostring(this);		-- each frame gets its own queue if prefix is not given
	
	local nSize = strlen(text) + MSG_OVERHEAD;
	
	-- Check if there's room in the global available bandwidth gauge to send directly
	if(not self.bQueueing and nSize < self:UpdateAvail()) then
		self.avail = self.avail - nSize;
		self.ORIG_SendChatMessage(text, chattype, language, destination);
		self.Prio[prio].nTotalSent = self.Prio[prio].nTotalSent + nSize;
		return;
	end
	
	-- Message needs to be queued
	msg=self.MsgBin:Get();
	msg.f=self.ORIG_SendChatMessage
	msg[1]=text;
	msg[2]=chattype or "SAY";
	msg[3]=language;
	msg[4]=destination;
	msg.n = 4
	msg.nSize = nSize;

	self:Enqueue(prio, format("%s/%s/%s", prefix, chattype, destination or ""), msg);
end


function ChatThrottleLib:SendAddonMessage(prio, prefix, text, chattype)
	if(not (self and prio and prefix and text and chattype and self.Prio[prio] ) ) then
		error('Usage: ChatThrottleLib:SendAddonMessage("{BULK||NORMAL||ALERT}", "prefix", "text", "chattype")', 0);
	end
	
	local nSize = strlen(prefix) + 1 + strlen(text) + MSG_OVERHEAD;
	
	-- Check if there's room in the global available bandwidth gauge to send directly
	if(not self.bQueueing and nSize < self:UpdateAvail()) then
		self.avail = self.avail - nSize;
		self.ORIG_SendAddonMessage(prefix, text, chattype);
		self.Prio[prio].nTotalSent = self.Prio[prio].nTotalSent + nSize;
		return;
	end
	
	-- Message needs to be queued
	msg=self.MsgBin:Get();
	msg.f=self.ORIG_SendAddonMessage;
	msg[1]=prefix;
	msg[2]=text;
	msg[3]=chattype;
	msg.n = 3
	msg.nSize = nSize;
	
	self:Enqueue(prio, format("%s/%s", prefix, chattype), msg);
end




-----------------------------------------------------------------------
-- Get the ball rolling!

ChatThrottleLib:Init();

--[[ WoWBench debugging snippet
if(WOWB_VER) then
	local function SayTimer()
		print("SAY: "..GetTime().." "..arg1);
	end
	ChatThrottleLib.Frame:SetScript("OnEvent", SayTimer);
	ChatThrottleLib.Frame:RegisterEvent("CHAT_MSG_SAY");
end
]]

--[[
Name: AceDebug-2.0
Revision: $Rev$
Author(s): Kaelten (kaelten@gmail.com)
Inspired By: AceDebug 1.x by Turan (<email here>)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceDebug-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceDebug-2.0
Description: Mixin to allow for simple debugging capabilities.
Dependencies: AceLibrary, AceOO-2.0
]]

local MAJOR_VERSION = "AceDebug-2.0"
local MINOR_VERSION = "$Revision$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0") end 

local AceOO = AceLibrary:GetInstance("AceOO-2.0")
local AceDebug = AceOO.Mixin {"Debug", "CustomDebug", "IsDebugging", "SetDebugging"}

local tmp

local print
if DEFAULT_CHAT_FRAME then
	function print(text, r, g, b, frame, delay)
		(frame or DEFAULT_CHAT_FRAME):AddMessage(text, r, g, b, 1, delay or 5)
	end
else
	local _G = getfenv(0)
	function print(text)
		_G.print(text)
	end
end

function AceDebug:CustomDebug(r, g, b, frame, delay, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	if not self.debugging then return end

	local output = string.format("|cff7fff7f(DEBUG) %s:|r", tostring(self))
	
	if string.find(tostring(a1), "%%") then
		output = output .. " " .. string.format(tostring(a1), tostring(a2), tostring(a3), tostring(a4), tostring(a5), tostring(a6), tostring(a7), tostring(a8), tostring(a9), tostring(a10), tostring(a11), tostring(a12), tostring(a13), tostring(a14), tostring(a15), tostring(a16), tostring(a17), tostring(a18), tostring(a19), tostring(a20))
	else
		if not tmp then
			tmp = {}
		end
		
		-- This block dynamically rebuilds the tmp array stopping on the first nil.
		table.insert(tmp, output)
		if a1 ~= nil then table.insert(tmp, tostring(a1))
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
		end	end	end	end	end	end	end	end	end	end	end	end	end	end	end	end	end	end	end	end
		
		output = table.concat(tmp, " ")
		
		for k,v in tmp do
			tmp[k] = nil
		end
		table.setn(tmp, 0)
	end

	print(output, r, g, b, frame or self.debugFrame, delay)
end

function AceDebug:Debug(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	AceDebug.CustomDebug(self, nil, nil, nil, nil, nil, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
end

function AceDebug:IsDebugging() 
	return self.debugging
end

function AceDebug:SetDebugging(debugging)
	self.debugging = debugging
end

AceLibrary:Register(AceDebug, MAJOR_VERSION, MINOR_VERSION, AceDebug.activate)
AceDebug = AceLibrary(MAJOR_VERSION)

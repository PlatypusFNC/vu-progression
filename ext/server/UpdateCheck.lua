require("__shared/Version")
local ParseOffset = require("lib/iso8601")

-- Prints the update check result to console
-- @author Joe91 <https://github.com/Joe91>
---@param p_Result integer
---@param p_UpdateUrl string|nil
---@param p_RemoteVersion string|nil
---@param p_RemoteTimestamp string|nil
local function UpdateFinished(p_Result, p_UpdateUrl, p_RemoteVersion, p_RemoteTimestamp)
	-- Check if the update was successful.
	if p_Result < 0 then
		print('[Update Check] Failed to check for an update.')
		return
	end

	-- Check if there is not an update available and that we are running the latest version.
	if p_Result == 0 then
		print('[Update Check] You are running the latest version.')
		return
	end

	-- Mod is outdated
	if p_Result == 1 then
		if p_RemoteTimestamp ~= nil then
			print('[ + ] A new version for vu-progression was released on ' ..
				os.date('%d-%m-%Y %H:%M', ParseOffset(p_RemoteTimestamp)) .. '!')
		else
			print('[ + ] A new version for vu-progression is available!')
		end

		print('[ + ] Upgrade to ' .. p_RemoteVersion)
		print('[ + ] Download: ' .. p_UpdateUrl)
	end
end

-- Compares external version string against mod's VERSION dictionary
---@param p_ExternalVersion string|nil
local function CompareVersion(p_ExternalVersion)
	local major, minor, patch = p_ExternalVersion:match("^v(%d+)%.(%d+)%.(%d+)$")

	local d_ExtVer = {
		Major = tonumber(major),
		Minor = tonumber(minor),
		Patch = tonumber(patch)
	}

	-- Check for outdated mod
	if d_ExtVer.Major > VERSION.Major
		or d_ExtVer.Minor > VERSION.Minor
		or d_ExtVer.Patch > VERSION.Patch
	then
		return 1
	else
		return 0
	end
end

-- Callback for updateCheck async request.
---@param httpRequest HttpResponse|nil
local function updateCheckCB(httpRequest)
	if httpRequest == nil then
		UpdateFinished(-1, nil, nil, nil)
		return
	end
	-- Parse JSON.
	local s_EndpointJSON = json.decode(httpRequest.body)

	if s_EndpointJSON == nil or s_EndpointJSON['tag_name'] == nil then
		UpdateFinished(-1, nil, nil, nil)
		return
	end

	local s_Result = CompareVersion(s_EndpointJSON['tag_name'])
	
	UpdateFinished(
		s_Result,
		s_EndpointJSON['html_url'],
		s_EndpointJSON['tag_name'],
		s_EndpointJSON['published_at']
	)
end

-- Async check for newer updates.
local function UpdateCheck()
	Net:GetHTTPAsync(VERSION.GithubApiUrl, updateCheckCB)
end

return UpdateCheck

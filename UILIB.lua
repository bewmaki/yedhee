
if type(getgenv) ~= "function" then
	getgenv = function()
		return (typeof(shared) == "table" and shared) or (getfenv and getfenv()) or _G
	end
end

if not game:IsLoaded() then
	game.Loaded:Wait()
end

if not LPH_OBFUSCATED then
	LPH_JIT_MAX = function(...) return ... end
	LPH_NO_VIRTUALIZE = function(f) return f end
	LPH_NO_UPVALUES = function(f) return f end
else
	print = function() end
	warn = function() end
end


local Library = getgenv().Library or {}
if type(Library) == "table" and next(Library) then
	if type(Library.Unload) == "function" then
		pcall(Library.Unload, Library)
	end
	for k in pairs(Library) do
		Library[k] = nil
	end
end
getgenv().Library = Library

local cloneref = cloneref or function(o) return o end
local function safe_cloneref(instance)
	if instance == nil then return nil end
	local ok, cloned = pcall(cloneref, instance)
	if ok and cloned ~= nil then return cloned end
	return instance
end
local function svc(n)
	return safe_cloneref(game:GetService(n))
end

local Players = svc("Players")
local TweenService = svc("TweenService")
local UserInputService = svc("UserInputService")
local RunService = svc("RunService")
local HttpService = svc("HttpService")
local CoreGui = svc("CoreGui")
local Workspace = svc("Workspace")
local TextService = svc("TextService")
local ContextActionService = svc("ContextActionService")
local TeleportService = svc("TeleportService")
local GuiService = svc("GuiService")

local LocalPlayer = safe_cloneref(Players.LocalPlayer)
local platform_ok, current_platform = pcall(function() return UserInputService:GetPlatform() end)
local mobile_platform = platform_ok and (current_platform == Enum.Platform.Android or current_platform == Enum.Platform.IOS)
local IsMobile = getgenv().SolixForceMobile == true
	or mobile_platform
	or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
local Mouse = safe_cloneref(LocalPlayer and LocalPlayer:GetMouse())

local get_mouse_location = LPH_NO_VIRTUALIZE(function()
	return UserInputService:GetMouseLocation()
end)

local FromRGB = Color3.fromRGB
local FromHSV = Color3.fromHSV
local FromHex = Color3.fromHex
local UDim2New = UDim2.new
local UDimNew = UDim.new
local Vector2New = Vector2.new
local RectNew = Rect.new
local CSNew = ColorSequence.new
local CSK = ColorSequenceKeypoint.new
local NSNew = NumberSequence.new
local NSK = NumberSequenceKeypoint.new
local MathFloor = math.floor
local MathClamp = math.clamp
local MathMin = math.min
local MathMax = math.max
local MathAbs = math.abs
local StringFormat = string.format
local StringLower = string.lower
local StringFind = string.find
local StringSub = string.sub
local StringGsub = string.gsub
local TableInsert = table.insert
local TableClear = table.clear
local TableClone = table.clone
local TableConcat = table.concat
local defer = task.defer
local delay = task.delay
local spawn = task.spawn

-- ============================================================================
-- BRANDING — change these to make this your own. Nothing else in the file
-- needs editing to rebrand it: this name is the folder saved under the
-- executor's workspace, and BRAND_WORD_1/BRAND_WORD_2 are the two words shown
-- in the small watermark at the bottom-left of every window.
-- ============================================================================
local BRAND_DIR = "myhub"
local BRAND_WORD_1 = "my"
local BRAND_WORD_2 = "hub"

local GameId = tostring(game.GameId)
local Folders = {
	Directory = BRAND_DIR,
	Assets = BRAND_DIR .. "/Assets",
	Configurations = BRAND_DIR .. "/Configurations",
	Datas = BRAND_DIR .. "/Datas",
	Images = BRAND_DIR .. "/Images",
	Themes = BRAND_DIR .. "/Themes",
}

do
	local list = {
		BRAND_DIR, BRAND_DIR .. "/Datas", BRAND_DIR .. "/Assets", BRAND_DIR .. "/Assets/Fonts",
		BRAND_DIR .. "/Configurations", BRAND_DIR .. "/Images", BRAND_DIR .. "/Themes",
		Folders.Configurations .. "/" .. GameId,
		Folders.Datas .. "/" .. GameId,
	}
	for i = 1, #list do
		if isfolder and not isfolder(list[i]) and makefolder then
			makefolder(list[i])
		end
	end
end

local function GetAutoloadPath()
	return Folders.Configurations .. "/" .. GameId .. "/autoload.json"
end

local function GetAutoloadConfigNamePath()
	return Folders.Configurations .. "/" .. GameId .. "/autoload_config.txt"
end

local function GetAutoloadConfigName()
	local path = GetAutoloadConfigNamePath()
	if isfile and isfile(path) then
		local ok, name = pcall(readfile, path)
		if ok and type(name) == "string" then
			name = StringGsub(StringGsub(name, "^%s+", ""), "%s+$", "")
			if name ~= "" then return name end
		end
	end
	return "none"
end

local function GetAutoloadThemeNamePath()
	return Folders.Themes .. "/autoload_theme.txt"
end

local Themes = {
	Default = {
		Background = FromRGB(14, 13, 18),
		Inline = FromRGB(22, 21, 28),
		Border = FromRGB(42, 40, 52),
		Outline = FromRGB(36, 38, 45),
		Shadow = FromRGB(8, 6, 12),
		Text = FromRGB(242, 240, 248),
		["Inactive Text"] = FromRGB(148, 144, 162),
		Accent = FromRGB(215, 40, 114),
		Element = FromRGB(32, 30, 40),
		Gradient = FromRGB(255, 140, 185),
	},
	Fatality = {
		Background = FromRGB(16, 16, 18), Inline = FromRGB(24, 24, 28), Border = FromRGB(46, 46, 52),
		Outline = FromRGB(36, 38, 45), Shadow = FromRGB(0, 0, 0), Text = FromRGB(245, 245, 245),
		["Inactive Text"] = FromRGB(135, 135, 145), Accent = FromRGB(255, 75, 125),
		Element = FromRGB(30, 30, 34), Gradient = FromRGB(255, 170, 210),
	},
	Primordial = {
		Background = FromRGB(10, 12, 16), Inline = FromRGB(18, 22, 30), Border = FromRGB(36, 44, 58),
		Outline = FromRGB(28, 34, 46), Shadow = FromRGB(0, 0, 0), Text = FromRGB(240, 245, 255),
		["Inactive Text"] = FromRGB(125, 140, 165), Accent = FromRGB(90, 140, 255),
		Element = FromRGB(24, 28, 38), Gradient = FromRGB(180, 205, 255),
	},
	Pandora = {
		Background = FromRGB(14, 10, 20), Inline = FromRGB(24, 18, 34), Border = FromRGB(44, 34, 64),
		Outline = FromRGB(34, 26, 50), Shadow = FromRGB(20, 0, 40), Text = FromRGB(248, 242, 255),
		["Inactive Text"] = FromRGB(150, 140, 180), Accent = FromRGB(170, 85, 255),
		Element = FromRGB(28, 22, 40), Gradient = FromRGB(215, 180, 255),
	},
	Skeet = {
		Background = FromRGB(17, 19, 14), Inline = FromRGB(24, 28, 20), Border = FromRGB(42, 48, 36),
		Outline = FromRGB(32, 38, 28), Shadow = FromRGB(0, 0, 0), Text = FromRGB(242, 245, 238),
		["Inactive Text"] = FromRGB(145, 152, 132), Accent = FromRGB(170, 255, 85),
		Element = FromRGB(30, 34, 26), Gradient = FromRGB(200, 225, 170),
	},
	Rifk = {
		Background = FromRGB(10, 10, 12), Inline = FromRGB(18, 18, 22), Border = FromRGB(36, 36, 42),
		Outline = FromRGB(28, 28, 34), Shadow = FromRGB(0, 0, 0), Text = FromRGB(245, 245, 248),
		["Inactive Text"] = FromRGB(125, 125, 135), Accent = FromRGB(255, 255, 255),
		Element = FromRGB(24, 24, 28), Gradient = FromRGB(185, 185, 190),
	},
}

local Menu = {
	Flags = {},
	Elements = {},
	Classes = {},
	Theme = TableClone(Themes.Default),
	Themes = Themes,
	ThemeItems = {},
	ThemeMap = {},
	Connections = {},
	SearchItems = {},
	GlobalSearchIndex = {},
	OpenFrames = {},
	KeybindEntries = {},
	CurrentContent = nil,
	Silent = 0,
	LoadingConfig = false,
	TweenSettings = { Time = 0.3, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
	AttachOffsets = {
		Colorpicker = { Toggle = { X = -4, Y = 0 }, Checkbox = { X = -4, Y = 0 }, Label = { X = -4, Y = 0 } },
		Hotkey = { Toggle = { X = -4, Y = 0 }, Checkbox = { X = -4, Y = 0 }, Label = { X = -4, Y = 0 } },
	},
	Folders = Folders,
}

Library.Flags = Menu.Flags
Library.Elements = Menu.Elements
Library.Theme = Menu.Theme
Library.Themes = Themes
Library.Folders = Folders
Library.Tween = Menu.TweenSettings
Library.Menu = Menu
Library.Font = Menu.Font

Library.SetFlags = {}
Library.ConfigFlagCallbacks = {}
Library.ConfigCallbackPass = false
Library.ConfigLoadedCallbacks = {}
Library.FlagDefaults = {}
Library.HideRangeSubSliderFlags = {}
Library.ScriptConfigFlags = {}
Library.SettingsConfigFlags = {
	["FloatingButtonPosition"] = true,
	["QuickConfigsPosition"] = true,
	["Auto Save Config"] = true,
	["Safe Mode"] = true,
	["Autoload Configuration"] = true,
	["Autoloads the selected configuration on next load"] = true,
	["Autoload Theme"] = true,
	["Autoload Theme On Execute"] = true,
	["Background Snow"] = true,
	["Background Effect"] = true,
	["Show Watermark"] = true,
	["Show Menu Button"] = true,
	["Show Floating Button"] = true,
	["Show Keybind List"] = true,
	["Show Quick Configs"] = true,
	["Quick Config Slots"] = true,
	["Background Darken"] = true,
	["Background Transparency"] = true,
	["Auto Execute"] = true,
	["Menu Font"] = true,
	["UI Font"] = true,
	["Menu Scale Preset"] = true,
	["Menu Tween Time"] = true,
	["Menu Fade Speed"] = true,
	["Menu Tween Style"] = true,
	["Menu Tween Direction"] = true,
	["Theme Name"] = true,
	["Themes Select"] = true,
	["Themes Preset"] = true,
	["Config Name"] = true,
	["Config Select"] = true,
	["Paste Shared Config"] = true,
	["Pasted Config"] = true,
	["Menu Keybind"] = true,
}
Library.AutoSave = false
Library.AutoloadConfigEnabled = false
Library.AutoloadThemeEnabled = false
Library.AutoloadConfigApplied = false
Library.AutoloadThemeApplied = false
Menu.AutoSave = false
Menu.AutoloadConfig = false
Menu.AutoloadTheme = false

-- Url left blank on purpose: no font is fetched from any third-party server anymore.
-- To enable a font, either put your own .ttf/.otf at <Folders.Assets>/Fonts/<Id>,
-- or set Menu.Fonts["Name"].Url to a URL you control.
Menu.Fonts = {
	["Inter"] = {
		Id = "InterSemibold.ttf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["Tahoma"] = {
		Id = "Tahoma.ttf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["Minecraftia"] = {
		Id = "Minecraftia.ttf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["Silkscreen"] = {
		Id = "Silkscreen.ttf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["ProggyClean"] = {
		Id = "ProggyClean.ttf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["Made Bold"] = {
		Id = "MadeBold.otf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["Cenobyte"] = {
		Id = "cenobyte.ttf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["04B 30"] = {
		Id = "04B_30__.TTF",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["Kiwi Soda"] = {
		Id = "KiwiSoda.ttf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["Malam Poek"] = {
		Id = "Malam Poek.ttf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
	["Starborn"] = {
		Id = "Starborn.ttf",
		Url = "",
		Weight = 200,
		Style = "normal",
	},
}
Library.Fonts = Menu.Fonts
Menu.FontFaces = {}
Menu.FontTextElements = setmetatable({}, { __mode = "k" })
Menu.FontSettings = { Name = "Made Bold", TextSize = 16, SmallTextSize = 12, TitleTextSize = 20 }

do
	local ok, face = pcall(function()
		return Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	end)
	Menu.Font = (ok and face) or Font.fromEnum(Enum.Font.GothamBold)
	Library.Font = Menu.Font
end

local function deep_copy(v)
	if type(v) ~= "table" then return v end
	local c = {}
	for k, e in next, v do c[k] = deep_copy(e) end
	return c
end

local get_thread_identity = getthreadidentity or get_thread_identity or getidentity
local set_thread_identity = setthreadidentity or set_thread_identity or setidentity
local ELEVATED_IDENTITIES = { 8, 7, 2 }

local function run_with_thread_identity(identity, fn, ...)
	if type(fn) ~= "function" then
		return false, "invalid callback"
	end
	local old = (type(get_thread_identity) == "function" and get_thread_identity()) or 2
	if type(set_thread_identity) == "function" then
		pcall(set_thread_identity, tonumber(identity) or 2)
	end
	local packed = table.pack(pcall(fn, ...))
	if type(set_thread_identity) == "function" then
		pcall(set_thread_identity, old)
	end
	return table.unpack(packed, 1, packed.n)
end

local function run_with_elevated_thread_identity(fn, ...)
	local args = table.pack(...)
	for i = 1, #ELEVATED_IDENTITIES do
		local packed = table.pack(run_with_thread_identity(ELEVATED_IDENTITIES[i], function()
			return fn(table.unpack(args, 1, args.n))
		end))
		if packed[1] then
			return table.unpack(packed, 1, packed.n)
		end
	end
	return pcall(fn, table.unpack(args, 1, args.n))
end

local function elevate_callback(callback)
	if type(callback) ~= "function" then return callback end
	return function(...)
		local args = table.pack(...)
		local packed = table.pack(run_with_elevated_thread_identity(function()
			return callback(table.unpack(args, 1, args.n))
		end))
		if packed[1] then
			return table.unpack(packed, 2, packed.n)
		end
	end
end

local function safe_destroy(inst)
	if typeof(inst) ~= "Instance" then return end
	run_with_elevated_thread_identity(function()
		inst:Destroy()
	end)
end

local function safe_set(inst, props)
	if typeof(inst) ~= "Instance" or type(props) ~= "table" then return end
	run_with_elevated_thread_identity(function()
		for k, v in next, props do
			inst[k] = v
		end
	end)
end

local function safe_gui(fn)
	if type(fn) ~= "function" then return end

	if Menu.LoadingConfig == true or Library.ConfigCallbackPass == true then
		local ok = pcall(fn)
		if ok then return end
	end
	run_with_elevated_thread_identity(fn)
end

local function resolve_gui_parent(parent)
	if type(parent) == "table" and parent.Instance ~= nil then
		return parent.Instance
	end
	return parent
end

local function set_instance_parent(inst, parent)
	parent = resolve_gui_parent(parent)
	if typeof(inst) ~= "Instance" or parent == nil then
		return false
	end
	local ok = select(1, run_with_elevated_thread_identity(function()
		inst.Parent = parent
	end))
	if ok then return true end
	local pg = LocalPlayer and LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
	if pg and parent ~= pg then
		ok = select(1, run_with_elevated_thread_identity(function()
			inst.Parent = pg
		end))
	end
	return ok == true
end

local function safe_ui()
	if type(identifyexecutor) == "function" then
		local ok_ex, ex = pcall(identifyexecutor)
		if ok_ex and ex == "Wave" and type(getgenv) == "function" then
			pcall(function()
				getgenv().gethui = function()
					return CoreGui
				end
			end)
		end
	end
	local ok, hui = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if ok and hui then return safe_cloneref(hui) end
	ok, hui = pcall(function()
		return CoreGui
	end)
	if ok and hui then return hui end
	local pg = LocalPlayer and LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
	return pg or LocalPlayer:WaitForChild("PlayerGui")
end

local function tween_info(custom)
	return custom or TweenInfo.new(Menu.TweenSettings.Time, Menu.TweenSettings.Style, Menu.TweenSettings.Direction)
end

local function element_gradient(parent)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = CSNew({ CSK(0, FromRGB(255, 255, 255)), CSK(1, FromRGB(216, 216, 216)) })
	set_instance_parent(g, parent)
	return g
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDimNew(0, r or 5)
	set_instance_parent(c, parent)
	return c
end

local function ui_dual_stroke(parent)
	local outline = Instance.new("UIStroke")
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.LineJoinMode = Enum.LineJoinMode.Miter
	outline.Thickness = 1
	outline.Color = Menu.Theme.Outline
	set_instance_parent(outline, parent)
	Menu:AddToTheme(outline, { Color = "Outline" })

	local border = Instance.new("UIStroke")
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.LineJoinMode = Enum.LineJoinMode.Miter
	border.Thickness = 1
	border.Color = Menu.Theme.Border
	set_instance_parent(border, parent)
	Menu:AddToTheme(border, { Color = "Border" })
	return outline, border
end

local function ui_accent_liner(parent)
	local liner = Instance.new("Frame")
	liner.Position = UDim2New(0, -2, 0, 20)
	liner.Size = UDim2New(1, 4, 0, 1)
	liner.BorderSizePixel = 0
	liner.BackgroundColor3 = Menu.Theme.Accent
	liner.ZIndex = 2
	set_instance_parent(liner, parent)
	Menu:AddToTheme(liner, { BackgroundColor3 = "Accent" })
	return liner
end

local function is_valid_font_bytes(data)
	if type(data) ~= "string" or #data < 12 then return false end
	if StringSub(data, 1, 1) == "<" then return false end
	local sig = StringSub(data, 1, 4)
	return sig == "\0\1\0\0" or sig == "OTTO" or sig == "true" or sig == "wOFF" or sig == "ttcf"
end

local function register_font(name, weight, style, ttf_file, url)
	local fonts_folder = Folders.Assets .. "/Fonts"
	if isfolder and not isfolder(fonts_folder) and makefolder then
		makefolder(fonts_folder)
	end
	local ttf_path = fonts_folder .. "/" .. ttf_file
	if isfile and isfile(ttf_path) then
		local cached = readfile(ttf_path)
		if not is_valid_font_bytes(cached) then
			pcall(delfile, ttf_path)
			pcall(delfile, fonts_folder .. "/" .. name .. ".font")
		end
	end
	if not (isfile and isfile(ttf_path)) then
		-- No network fetch: fonts are local-only now. Drop your own .ttf/.otf
		-- into <Fonts folder>/<ttf_file> (see Folders.Assets .. "/Fonts") to enable one.
		if type(url) ~= "string" or url == "" then return nil end
		local ok, downloaded = pcall(game.HttpGet, game, url)
		if not ok or not is_valid_font_bytes(downloaded) then return nil end
		if writefile then writefile(ttf_path, downloaded) end
	end
	local meta_path = fonts_folder .. "/" .. name .. ".font"
	if isfile and isfile(meta_path) and getcustomasset then
		local ok, asset = pcall(getcustomasset, meta_path)
		if ok and type(asset) == "string" and asset ~= "" then return asset end
	end
	if not getcustomasset then return nil end
	local ok_asset, asset_id = pcall(getcustomasset, ttf_path)
	if not ok_asset then return nil end
	local font_data = {
		name = name,
		faces = {{ name = "Regular", weight = weight, style = style, assetId = asset_id }},
	}
	if writefile then
		if isfile and isfile(meta_path) then pcall(delfile, meta_path) end
		writefile(meta_path, HttpService:JSONEncode(font_data))
	end
	local ok_font, font_asset = pcall(getcustomasset, meta_path)
	if not ok_font then return nil end
	return font_asset
end

function Library:EnsureFontRegistered(font_name)
	if type(font_name) ~= "string" or font_name == "" then return false end
	if Menu.FontFaces[font_name] then return true end
	local data = Menu.Fonts[font_name]
	if type(data) ~= "table" then return false end
	local ok, asset_path = pcall(function()
		return register_font(font_name, data.Weight or 200, data.Style or "normal", data.Id, data.Url)
	end)
	if not ok or not asset_path then return false end
	local face_ok, face = pcall(function()
		return Font.new(asset_path, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	end)
	if face_ok and face then
		Menu.FontFaces[font_name] = face
		return true
	end
	return false
end

function Library:ApplyFont(font_name)
	if font_name and self:EnsureFontRegistered(font_name) then
		Menu.FontSettings.Name = font_name
		Menu.Font = Menu.FontFaces[font_name]
		Library.Font = Menu.Font
	end
	for inst in next, Menu.FontTextElements do
		if inst and inst.Parent then
			pcall(function() inst.FontFace = Menu.Font end)
		end
	end
end

function Library:GetFontNames()
	local names = {}
	for name in next, Menu.Fonts do TableInsert(names, name) end
	table.sort(names)
	return names
end

spawn(function()
	Library:EnsureFontRegistered("Made Bold")
	Library:EnsureFontRegistered("Inter")
	if Menu.FontFaces["Made Bold"] then
		Library:ApplyFont("Made Bold")
	elseif Menu.FontFaces.Inter then
		Library:ApplyFont("Inter")
	end
end)

local Hook = { Events = {} }

local function is_hot_hook_name(name)
	return name == "RenderStepped"
		or name == "Heartbeat"
		or name == "Mouse.Move"
		or name == "InputChanged"
end

function Hook:Add(name, id, cb)
	self:Remove(name, id)
	local signal = name
	if type(name) == "string" then
		if name == "InputBegan" then signal = UserInputService.InputBegan
		elseif name == "InputEnded" then signal = UserInputService.InputEnded
		elseif name == "InputChanged" or name == "Mouse.Move" then signal = UserInputService.InputChanged
		elseif name == "RenderStepped" then signal = RunService.RenderStepped
		elseif name == "Heartbeat" then signal = RunService.Heartbeat
		else return end
	end

	if not is_hot_hook_name(name) then
		cb = elevate_callback(cb)
	end
	local conn
	if name == "Mouse.Move" then
		local handler = cb
		conn = signal:Connect(LPH_NO_VIRTUALIZE(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				handler(input)
			end
		end))
	else
		conn = signal:Connect(cb)
	end
	self.Events[id] = conn
	Menu.Connections[id] = conn
	return conn
end

function Hook:Remove(_, id)
	local c = self.Events[id]
	if c then
		c:Disconnect()
		self.Events[id] = nil
		Menu.Connections[id] = nil
	end
end

function Hook:CallP() end
Menu.Hook = Hook
Library.Hook = Hook

local Config = {
	Flags = Menu.Flags,
	Elements = Menu.Elements,
	FilterKeys = {},
	Filters = {},
	FiltersIndex = 0,
	Order = {},
	OrderIndex = 0,
	Versions = {},
	LastModified = {},
	Active = { Name = "none", IsSaved = false },
	Ignored = {},
	CategoryKeys = {},
}

function Config:Bind(flags, elements)
	self.Flags = flags
	self.Elements = elements
end

function Config:MarkCategory(key)
	self.CategoryKeys[key] = true
	self.Flags[key] = self.Flags[key] or {}
	self.Elements[key] = self.Elements[key] or {}
end

function Config:IsCategoryTable(key)
	return self.CategoryKeys[key] == true
end

function Config:IsIgnored(flag, category)
	if category then
		return self.Ignored[category] and self.Ignored[category][flag] == true
	end
	return self.Ignored[flag] == true
end

function Config:RegisterElement(element, flag, category, ignore)
	if type(flag) ~= "string" or flag == "" or type(element) ~= "table" then return end
	if ignore then
		if category then
			self.Ignored[category] = self.Ignored[category] or {}
			self.Ignored[category][flag] = true
		else
			self.Ignored[flag] = true
		end
	else
		Library:BindElementFlag(flag, function(value, alpha)
			if element.Disabled == true then return end
			local silent = Library.LoadingConfig == true or Menu.LoadingConfig == true
			if element.Class == "Colorpicker" then
				if type(element.Set) == "function" then
					element:Set(value, alpha, silent)
				elseif type(element.SetValue) == "function" then
					if type(value) == "table" and value.Color then
						element:SetValue(value, silent)
					elseif type(value) == "string" or typeof(value) == "Color3" then
						element:SetValue({ Color = value, Alpha = alpha or element.Alpha or 0 }, silent)
					else
						element:SetValue(value, silent)
					end
				end
			elseif type(element.SetValue) == "function" then
				element:SetValue(value, silent)
			elseif type(element.Set) == "function" then
				element:Set(value, silent)
			end
		end, element)
		if element.HideRange == true then
			Library.HideRangeSubSliderFlags[flag] = true
		end
	end
	self.OrderIndex += 1
	self.Order[self.OrderIndex] = { element, flag, category }
	if category then
		self:MarkCategory(category)
		self.Elements[category][flag] = element
		if element.GetValue then self.Flags[category][flag] = element:GetValue() end
	else
		self.Elements[flag] = element
		if element.GetValue then self.Flags[flag] = element:GetValue() end
	end
	Library.Elements[flag] = element
end

function Library:BindElementFlag(flag, setter, element)
	if type(flag) ~= "string" or flag == "" or type(setter) ~= "function" then
		return
	end

	self:RegisterConfigFlag(flag)
	self.SetFlags[flag] = setter

	if type(element) ~= "table" then
		return
	end

	if self.FlagDefaults[flag] == nil then
		if element.Default ~= nil then
			self:RegisterFlagDefault(flag, element.Default)
		elseif element.GetValue then
			local ok, value = pcall(element.GetValue, element)
			if ok and value ~= nil then
				self:RegisterFlagDefault(flag, deep_copy(value))
			end
		elseif element.Value ~= nil then
			self:RegisterFlagDefault(flag, deep_copy(element.Value))
		elseif element.Class == "Colorpicker" and element.Color ~= nil then
			self:RegisterFlagDefault(flag, {
				Color = "#" .. (typeof(element.Color) == "Color3" and element.Color:ToHex() or "FFFFFF"),
				Alpha = element.Alpha or 0,
			})
		end
	end

	if type(element.Callback) == "function" then
		self.ConfigFlagCallbacks[flag] = function()
			if element.Disabled == true then
				return
			end
			if type(element.SyncVisibleChildren) == "function" then
				pcall(element.SyncVisibleChildren, element, element.Value == true)
			end
			if element.Class == "Colorpicker" then
				self:SafeCall(element.Callback, element.Color, element.Alpha)
			elseif element.Class == "Hotkey" then
				self:SafeCall(element.Callback, element.Toggled == true)
			else
				local value = element.Value
				if type(element.GetValue) == "function" then
					local ok, got = pcall(element.GetValue, element)
					if ok then value = got end
				end
				self:SafeCall(element.Callback, value)
			end
		end
	end
end

function Library:BeginSilent()
	self.SilentDepth = (self.SilentDepth or 0) + 1
	Menu.Silent = (Menu.Silent or 0) + 1
end

function Library:EndSilent()
	self.SilentDepth = MathMax(0, (self.SilentDepth or 0) - 1)
	Menu.Silent = MathMax(0, (Menu.Silent or 0) - 1)
end

function Config:FindElement(flag)
	local el = self.Elements[flag]
	if el then return el end
	for category in next, self.CategoryKeys do
		local bucket = self.Elements[category]
		el = bucket and bucket[flag]
		if el then return el, category end
	end
end

function Config:CaptureState()
	local state = { LastModified = os.time(), Flags = {}, Filters = {} }
	for key, value in next, self.Flags do
		if self.FilterKeys[key] then
			continue
		elseif typeof(value) == "table" and self:IsCategoryTable(key) then
			local copy = {}
			for flag, fv in next, value do
				if not self:IsIgnored(flag, key) and Library:IsScriptConfigFlag(flag) then
					copy[flag] = deep_copy(fv)
				end
			end
			state.Flags[key] = copy
		elseif not self:IsIgnored(key) and Library:IsScriptConfigFlag(key) then
			state.Flags[key] = deep_copy(value)
		end
	end
	for i = 1, self.FiltersIndex do
		local f = self.Filters[i]
		state.Filters[f.Flag] = f:CaptureState()
	end
	return state
end

function Config:Save(name)
	if type(name) ~= "string" or name == "" then return false end
	local path = Folders.Configurations .. "/" .. GameId .. "/" .. name .. ".json"
	local ok = writefile and pcall(writefile, path, Library:GetConfig()) == true
	if not ok then return false end
	self.Versions[name] = (self.Versions[name] or 0) + 1
	self.LastModified[name] = os.time()
	self.Active = { Name = name, IsSaved = true }
	return true
end

function Config:Load(name)
	local path = Folders.Configurations .. "/" .. GameId .. "/" .. name .. ".json"
	if not (isfile and isfile(path) and readfile) then return false end
	local ok, content = pcall(readfile, path)
	if not ok or type(content) ~= "string" then return false end
	local success = Library:LoadConfig(content)
	if success then
		self.Active = { Name = name, IsSaved = true }
		self.LastModified[name] = os.time()
	end
	return success == true
end

function Config:GetRelativeTime(name)
	local ts = self.LastModified[name]
	if not ts then return "Never" end
	local d = os.time() - ts
	if d < 60 then return d .. "s ago"
	elseif d < 3600 then return MathFloor(d / 60) .. "m ago"
	elseif d < 86400 then return MathFloor(d / 3600) .. "h ago"
	else return MathFloor(d / 86400) .. "d ago" end
end

Config:Bind(Menu.Flags, Menu.Elements)
Menu.Config = Config
Library.Config = Config

function Library:RegisterConfigFlag(flag)
	if type(flag) ~= "string" or flag == "" then return end
	self.ScriptConfigFlags[flag] = true
end

function Library:IsScriptConfigFlag(flag)
	if type(flag) ~= "string" or flag == "" then return false end
	if self.SettingsConfigFlags[flag] == true then return false end
	if StringFind(flag, "ThemingThing", 1, true) then return false end
	if self.ScriptConfigFlags[flag] == true then return true end
	if type(self.SetFlags[flag]) == "function" then return true end
	if self.Elements and self.Elements[flag] ~= nil then return true end
	return false
end

function Library:FindConfigElement(flag)
	if type(flag) ~= "string" or flag == "" then return nil end
	local element = self.Elements and self.Elements[flag]
	if type(element) == "table" then return element end
	if Config and Config.FindElement then
		element = select(1, Config:FindElement(flag))
		if type(element) == "table" then return element end
	end
	return nil
end

function Library:InvokeElementCallback(element)
	if type(element) ~= "table" then
		return
	end
	if element.Disabled == true then
		return
	end
	local has_callback = type(element.Callback) == "function"
	local has_children = type(element.SyncVisibleChildren) == "function"
		and type(element.VisibleChildren) == "table"
		and #element.VisibleChildren > 0
	if not has_callback and not has_children then
		return
	end
	if has_children then
		pcall(element.SyncVisibleChildren, element, element.Value == true)
	end
	if not has_callback then
		return
	end
	if element.Class == "Colorpicker" then
		self:SafeCall(element.Callback, element.Color, element.Alpha)
	elseif element.Class == "Hotkey" then
		self:SafeCall(element.Callback, element.Toggled == true)
	else
		local value = element.Value
		if type(element.GetValue) == "function" then
			local ok, got = pcall(element.GetValue, element)
			if ok then value = got end
		end
		self:SafeCall(element.Callback, value)
	end
end

function Library:RegisterFlagDefault(flag, default)
	if type(flag) ~= "string" or flag == "" then return end
	self.FlagDefaults[flag] = default
end

function Library:RegisterConfigFlagCallback(flag, callback)
	if type(flag) ~= "string" or flag == "" or type(callback) ~= "function" then return end
	local existing = self.ConfigFlagCallbacks[flag]
	if type(existing) == "function" then
		self.ConfigFlagCallbacks[flag] = function()
			self:SafeCall(existing)
			self:SafeCall(callback)
		end
	else
		self.ConfigFlagCallbacks[flag] = callback
	end
end

function Library:OnConfigLoaded(callback)
	if type(callback) == "function" then
		TableInsert(self.ConfigLoadedCallbacks, callback)
	end
end

Library.RegisterConfigPostLoadSync = Library.OnConfigLoaded

function Library:RoundConfigNumber(number, decimals)
	if type(number) ~= "number" then return number end
	decimals = decimals or 4
	if decimals <= 0 then return MathFloor(number + 0.5) end
	local mult = 10 ^ decimals
	return MathFloor(number * mult + 0.5) / mult
end

function Library:NormalizeKeybindKey(key)
	if key == nil then return "None" end
	if typeof(key) == "EnumItem" then
		if key.EnumType == Enum.UserInputType then
			key = key.Name
		elseif key == Enum.KeyCode.Backspace then
			return "None"
		else
			key = key.Name
		end
	end
	key = tostring(key)

	local bare = string.match(key, "([^%.]+)$")
	if bare and bare ~= "" then key = bare end
	if key == "" or key == "None" or key == "Backspace" or key == "Escape" then
		return "None"
	end

	if key == "M1" or key == "LMB" or key == "LeftClick" then return "MouseButton1" end
	if key == "M2" or key == "RMB" or key == "RightClick" then return "MouseButton2" end
	if key == "M3" or key == "MMB" or key == "MiddleClick" then return "MouseButton3" end
	return key
end

function Library:FormatKeybindDisplay(key)
	key = self:NormalizeKeybindKey(key)
	if key == "None" then return "None" end
	if key == "Click" then return "Click" end
	if key == "MouseButton1" then return "M1" end
	if key == "MouseButton2" then return "M2" end
	if key == "MouseButton3" then return "M3" end
	return key
end

function Library:IsMouseKeybindKey(key)
	key = self:NormalizeKeybindKey(key)
	return key == "MouseButton1" or key == "MouseButton2" or key == "MouseButton3"
end

function Library:CompactConfigValue(value)
	if type(value) == "number" then
		return self:RoundConfigNumber(value, 4)
	end
	if type(value) == "table" and value.Key then
		return { Key = self:NormalizeKeybindKey(value.Key), Mode = value.Mode }
	end
	if type(value) == "table" and value.Color then
		local hex = value.HexValue or value.Color
		if typeof(hex) == "Color3" then hex = hex:ToHex() end
		if type(hex) == "string" and StringSub(hex, 1, 1) == "#" then hex = StringSub(hex, 2) end
		return { Color = "#" .. tostring(hex), Alpha = self:RoundConfigNumber(value.Alpha or 0, 4) }
	end
	if type(value) == "table" and (value.Speed ~= nil or value.Start ~= nil or value["End"] ~= nil or value.End ~= nil) then
		return {
			Speed = self:RoundConfigNumber(value.Speed, 4),
			Start = self:RoundConfigNumber(value.Start, 4),
			["End"] = self:RoundConfigNumber(value["End"] or value.End, 4),
		}
	end
	return value
end

function Library:ConfigValuesEqual(left, right)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	if left.Key or right.Key then
		return self:NormalizeKeybindKey(left.Key) == self:NormalizeKeybindKey(right.Key)
			and tostring(left.Mode or "") == tostring(right.Mode or "")
	end
	if left.Color or right.Color then
		local left_hex = type(left.Color) == "string" and left.Color or (type(left.HexValue) == "string" and left.HexValue or "")
		local right_hex = type(right.Color) == "string" and right.Color or (type(right.HexValue) == "string" and right.HexValue or "")
		if StringSub(left_hex, 1, 1) == "#" then left_hex = StringSub(left_hex, 2) end
		if StringSub(right_hex, 1, 1) == "#" then right_hex = StringSub(right_hex, 2) end
		return StringLower(left_hex) == StringLower(right_hex)
			and self:RoundConfigNumber(left.Alpha or 0, 4) == self:RoundConfigNumber(right.Alpha or 0, 4)
	end
	if left.Speed ~= nil or right.Speed ~= nil or left.Start ~= nil or right.Start ~= nil or left["End"] ~= nil or right["End"] ~= nil then
		return self:RoundConfigNumber(left.Speed, 4) == self:RoundConfigNumber(right.Speed, 4)
			and self:RoundConfigNumber(left.Start, 4) == self:RoundConfigNumber(right.Start, 4)
			and self:RoundConfigNumber(left["End"] or left.End, 4) == self:RoundConfigNumber(right["End"] or right.End, 4)
	end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, left)
	local ok2, encoded2 = pcall(HttpService.JSONEncode, HttpService, right)
	return ok and ok2 and encoded == encoded2
end

function Library:NormalizeLoadedConfigValue(flag, value)
	if type(value) == "number" and type(flag) == "string" and self.HideRangeSubSliderFlags[flag] == true then
		local default_value = self.FlagDefaults[flag]
		return {
			Speed = value,
			Start = type(default_value) == "table" and default_value.Start or 0,
			["End"] = type(default_value) == "table" and (default_value["End"] or default_value.End) or 100,
		}
	end
	if type(value) ~= "table" then return value end
	if type(value.Key) == "string" or typeof(value.Key) == "EnumItem" then
		return {
			Key = self:NormalizeKeybindKey(value.Key),
			Mode = value.Mode,
			Toggled = value.Toggled,
		}
	end
	if type(value.Color) == "string" then
		local color = value.Color
		if StringSub(color, 1, 1) ~= "#" then color = "#" .. color end
		return color, value.Alpha
	end
	if value.Speed ~= nil or value.Start ~= nil or value["End"] ~= nil or value.End ~= nil then
		return {
			Speed = value.Speed,
			Start = value.Start,
			["End"] = value["End"] or value.End,
		}
	end
	return value
end

function Library:StoreRawConfigFlag(flag, value)
	if type(flag) ~= "string" or flag == "" then return end
	if type(value) == "table" and type(value.Color) == "string" then
		local hex = value.Color
		if StringSub(hex, 1, 1) == "#" then hex = StringSub(hex, 2) end
		self.Flags[flag] = {
			Alpha = value.Alpha or 0,
			Color = FromHex("#" .. hex),
			HexValue = hex,
			Flag = flag,
			Transparency = 1 - (value.Alpha or 0),
		}
		return
	end
	self.Flags[flag] = value
end

function Library:ApplyConfigEntry(index, value)
	if index == "FloatingButtonPosition" then
		if self.FloatingButton and type(value) == "table" and type(value.X) == "table" and type(value.Y) == "table" then
			safe_set(self.FloatingButton, {
				Position = UDim2New(value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset),
			})
			Menu.Flags.FloatingButtonPosition = value
			self.FloatingButtonPosition = value
		end
		return true
	end
	if index == "Auto Save Config" and type(value) == "boolean" then
		self.AutoSave = value; Menu.AutoSave = value
		return true
	end
	if index == "Safe Mode" and type(value) == "boolean" then
		self.SafeMode = value; Menu.SafeMode = value
		self:SaveLocalSettings()
		return true
	end
	if (index == "Autoload Configuration" or index == "Autoloads the selected configuration on next load") and type(value) == "boolean" then
		self.AutoloadConfigEnabled = value; Menu.AutoloadConfig = value
		self:SaveLocalSettings()
		return true
	end
	if (index == "Autoload Theme" or index == "Autoload Theme On Execute") and type(value) == "boolean" then
		self.AutoloadThemeEnabled = value; Menu.AutoloadTheme = value
		self:SaveLocalSettings()
		return true
	end
	if index == "Background Snow" and type(value) == "boolean" then
		self:SetBackgroundEffect(value and "Snow" or "None")
		return true
	end
	if index == "Background Effect" and type(value) == "string" then
		self:SetBackgroundEffect(value)
		return true
	end
	if index == "Show Watermark" and type(value) == "boolean" then
		self.ShowWatermark = value; self:SaveLocalSettings()
		return true
	end
	if index == "Show Menu Button" and type(value) == "boolean" then
		self.ShowMenuButton = value; Menu.ShowMenuButton = value; self:SaveLocalSettings()
		return true
	elseif index == "Show Floating Button" and type(value) == "boolean" then
		self.ShowMenuButton = value; Menu.ShowMenuButton = value; self:SaveLocalSettings()
		return true
	end
	if index == "Show Keybind List" and type(value) == "boolean" then
		self.ShowKeybindList = value; self:SaveLocalSettings()
		return true
	end
	if index == "Show Quick Configs" and type(value) == "boolean" then
		self.ShowQuickConfigs = value
		if self.QuickConfigs then
			if self.QuickConfigs.SetVisible then self.QuickConfigs:SetVisible(value)
			elseif self.QuickConfigs.SetVisibility then self.QuickConfigs:SetVisibility(value) end
		end
		self:SaveLocalSettings()
		return true
	end
	if index == "Quick Config Slots" and type(value) == "table" then
		local slots = {}
		local max_n = self.QuickConfigsMax or 4
		if #value > 0 then
			for i = 1, #value do
				if #slots >= max_n then break end
				local n = tostring(value[i])
				if n ~= "" then TableInsert(slots, n) end
			end
		end
		self.QuickConfigSlots = slots
		if self.QuickConfigs and self.QuickConfigs.Refresh then self.QuickConfigs:Refresh() end
		self:SaveLocalSettings()
		return true
	end
	if index == "Background Darken" and type(value) == "boolean" then
		self:SetBackgroundDarkenEnabled(value)
		return true
	end
	if index == "Auto Execute" and type(value) == "boolean" then
		self.AutoExecute = value; Menu.AutoExecute = value; self:SaveLocalSettings()
		return true
	end
	if (index == "Menu Font" or index == "UI Font") and type(value) == "string" then
		if self.SetFont then self:SetFont(value) else self:ApplyFont(value) end
		return true
	end
	if type(index) == "string" and StringSub(index, 1, 6) == "Theme_" then
		local theme_key = StringSub(index, 7)
		if theme_key ~= "" and Menu.Theme[theme_key] ~= nil then
			return self:ApplyConfigEntry(theme_key, value)
		end
	end

	local setter = self.SetFlags[index]
	if type(setter) ~= "function" then

		local element = self:FindConfigElement(index)
		if type(element) == "table" then
			local silent = self.LoadingConfig == true or Menu.LoadingConfig == true
			local normalized, alpha = self:NormalizeLoadedConfigValue(index, value)
			if element.Class == "Colorpicker" then
				if type(element.Set) == "function" then
					element:Set(normalized, alpha, silent)
				elseif type(element.SetValue) == "function" then
					if type(normalized) == "table" and normalized.Color then
						element:SetValue(normalized, silent)
					else
						element:SetValue({ Color = normalized, Alpha = alpha or element.Alpha or 0 }, silent)
					end
				end
			elseif type(element.SetValue) == "function" then
				element:SetValue(normalized, silent)
			elseif type(element.Set) == "function" then
				element:Set(normalized, silent)
			else
				self:StoreRawConfigFlag(index, value)
			end
			return true
		end
		self:StoreRawConfigFlag(index, value)
		return true
	end

	local normalized, alpha = self:NormalizeLoadedConfigValue(index, value)
	if type(normalized) == "string" and type(alpha) == "number" then
		setter(normalized, alpha)
	elseif type(normalized) == "table" and normalized.Key then
		setter(normalized)
	elseif type(normalized) == "table" and normalized.Color then
		setter(normalized.Color, normalized.Alpha)
	else
		setter(normalized)
	end
	return true
end

function Library:FireConfigFlagCallbacks(decoded)
	if type(decoded) ~= "table" then return end
	local ordered = {}
	local settings_flags = self.SettingsConfigFlags
	local elements = self.Elements
	local stored_callbacks = self.ConfigFlagCallbacks
	for index in next, decoded do
		if type(index) == "string" and settings_flags[index] ~= true then
			TableInsert(ordered, index)
		end
	end
	table.sort(ordered, function(left, right)
		local lp = StringFind(left, "_enabled", 1, true) ~= nil and 0 or 1
		local rp = StringFind(right, "_enabled", 1, true) ~= nil and 0 or 1
		if lp ~= rp then return lp < rp end
		return left < right
	end)

	for i = 1, #ordered do
		local flag = ordered[i]
		local element = elements and elements[flag]
		if type(element) ~= "table" then
			element = self:FindConfigElement(flag)
		end
		if type(element) == "table" then
			self:InvokeElementCallback(element)
		else
			local stored = stored_callbacks[flag]
			if type(stored) == "function" then
				self:SafeCall(stored)
			end
		end
	end
end

function Library:FinishConfigLoad(decoded, failed)
	self.LoadingConfig = false
	Menu.LoadingConfig = false
	self.SilentDepth = 0
	Menu.Silent = 0


	self.ConfigCallbackPass = true
	run_with_elevated_thread_identity(function()
		self:FireConfigFlagCallbacks(decoded)
	end)
	self.ConfigCallbackPass = false
	Hook:CallP("Config.Loaded")

	defer(function()
		for i = 1, #self.ConfigLoadedCallbacks do
			self:SafeCall(self.ConfigLoadedCallbacks[i], #(failed or {}) == 0, failed or {})
		end
		if failed and #failed > 0 then
			warn("[UILib] Config loaded with " .. tostring(#failed) .. " warning(s): " .. tostring(failed[1]))
		end
	end)
end

function Library:ShouldSaveAutoload(silent)
	if self.LoadingConfig == true or Menu.LoadingConfig == true then return false end
	if silent == true then return false end
	if type(silent) == "table" and (silent.Silent == true or silent.silent == true) then return false end
	if (self.SilentDepth or 0) > 0 then return false end
	if (Menu.Silent or 0) > 0 then return false end
	return true
end

function Library:GetFolder()
	return Folders.Configurations .. "/" .. GameId .. "/"
end

function Library:GetFolderTheme()
	return Folders.Themes .. "/"
end

function Library:SaveAutoloadIfEnabled()
	if not self.LoadingConfig and not Menu.LoadingConfig and self.AutoSave then
		pcall(function()
			if writefile then writefile(GetAutoloadPath(), self:GetConfig()) end
		end)
	end
end

function Library:RefreshConfigsList(element)
	local list = {}
	if listfiles then
		local ok, files = pcall(listfiles, self:GetFolder())
		if ok and type(files) == "table" then
			for i = 1, #files do
				local file = files[i]
				if StringSub(file, -5) == ".json" then
					local name = StringGsub(StringGsub(file, "^.*[\\/]", ""), "%.json$", "")
					if name ~= "" and name ~= "autoload" then
						TableInsert(list, name)
					end
				end
			end
		end
	end
	if element and element.Refresh then
		element:Refresh(list)
	end
	if self._quick_config_dropdown and self._quick_config_dropdown.Refresh then
		self._quick_config_dropdown:Refresh(list)
	end
	if type(self.QuickConfigSlots) == "table" then
		local valid = {}
		local exist = {}
		for i = 1, #list do
			exist[list[i]] = true
		end
		for i = 1, #self.QuickConfigSlots do
			local n = self.QuickConfigSlots[i]
			if exist[n] then
				TableInsert(valid, n)
			end
		end
		self.QuickConfigSlots = valid
		Menu.Flags["Quick Config Slots"] = valid
		if self._quick_config_dropdown and self._quick_config_dropdown.SetValue then
			self._quick_config_dropdown:SetValue(valid, true)
		end
	end
	if self.QuickConfigs and self.QuickConfigs.Refresh then
		self.QuickConfigs:Refresh()
	end
end

function Library:CheckForThemeAutoLoad()
	if self.AutoloadThemeApplied == true then return end
	if not self.AutoloadThemeEnabled and not Menu.AutoloadTheme then return end
	local theme_name_path = GetAutoloadThemeNamePath()
	if not (isfile and isfile(theme_name_path)) then return end
	local ok, theme_name = pcall(readfile, theme_name_path)
	if not ok or type(theme_name) ~= "string" then return end
	theme_name = StringGsub(StringGsub(theme_name, "^%s+", ""), "%s+$", "")
	if theme_name == "" then return end
	local theme_path = self:GetFolderTheme() .. theme_name .. ".json"
	if not (isfile and isfile(theme_path)) then return end
	local success = self:LoadTheme(readfile(theme_path))
	self.AutoloadThemeApplied = true
	if success then
		self:Notification({ Name = "Success", Description = "Succesfully autoloaded theme: " .. theme_name })
	else
		self:Notification({ Name = "Error", Description = "Failed to autoload theme: " .. theme_name })
	end
end

function Library:CheckForAutoLoad()
	if self.AutoloadConfigApplied == true then return end
	self:CheckForThemeAutoLoad()

	local function notify(success, label, err)
		if success then
			self:Notification({
				Name = "Success",
				Description = label and ("Succesfully autoloaded config: " .. label) or "Succesfully autoloaded config",
			})
		else
			self:Notification({
				Name = "Error",
				Description = label and ("Failed to autoload config: " .. tostring(err)) or ("Failed to load config: " .. tostring(err or "Unknown error")),
			})
		end
	end

	if self.AutoloadConfigEnabled or Menu.AutoloadConfig then
		local config_name = GetAutoloadConfigName()
		if config_name and config_name ~= "" and config_name ~= "none" then
			local config_path = self:GetFolder() .. config_name .. ".json"
			if isfile and isfile(config_path) then
				local success, err = self:LoadConfig(readfile(config_path))
				notify(success, config_name, err)
				self.AutoloadConfigApplied = true
				return
			end
			notify(false, config_name, "Config file not found: " .. config_path)
			self.AutoloadConfigApplied = true
			return
		end
	end

	local autoload_path = GetAutoloadPath()
	if not (isfile and isfile(autoload_path)) then
		self.AutoloadConfigApplied = true
		return
	end
	local content = readfile(autoload_path)
	if content == "" then
		self.AutoloadConfigApplied = true
		return
	end
	local success, err = self:LoadConfig(content)
	notify(success, nil, err)
	self.AutoloadConfigApplied = true
end

local Draw = {}
local UIParent = safe_ui()

function Draw:Create(class, props)
	props = props or {}
	local parent = resolve_gui_parent(props.Parent)
	local theme = props.Theme
	local inst
	local ok, err = run_with_elevated_thread_identity(function()
		inst = Instance.new(class)
		for k, v in next, props do
			if k ~= "Parent" and k ~= "Theme" then
				inst[k] = v
			end
		end
		if parent ~= nil then
			inst.Parent = parent
		end
		if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
			if not props.FontFace then
				inst.FontFace = Menu.Font
			end
		end
		if theme then
			for prop, key in next, theme do
				if type(key) == "string" then
					inst[prop] = Menu.Theme[key] or key
				elseif type(key) == "function" then
					inst[prop] = key()
				else
					inst[prop] = key
				end
			end
		end
	end)
	if not ok then
		error(tostring(err or "Draw:Create failed"), 2)
	end
	if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
		Menu.FontTextElements[inst] = true
	end
	if theme then

		local data = { Item = inst, Properties = theme }
		TableInsert(Menu.ThemeItems, data)
		Menu.ThemeMap[inst] = data
	end
	return inst
end

function Menu:AddToTheme(item, props)
	local data = { Item = item, Properties = props }
	run_with_elevated_thread_identity(function()
		for prop, key in next, props do
			if type(key) == "string" then
				item[prop] = self.Theme[key] or key
			elseif type(key) == "function" then
				item[prop] = key()
			else
				item[prop] = key
			end
		end
	end)
	TableInsert(self.ThemeItems, data)
	self.ThemeMap[item] = data
end

function Menu:ChangeTheme(key, value)
	if value then self.Theme[key] = value end
	Library.Theme = self.Theme
	run_with_elevated_thread_identity(function()
		for i = 1, #self.ThemeItems do
			local data = self.ThemeItems[i]
			local item = data.Item
			if not item or not item.Parent then continue end
			for prop, theme_key in next, data.Properties do
				if type(theme_key) == "string" and self.Theme[theme_key] then
					item[prop] = self.Theme[theme_key]
				elseif type(theme_key) == "function" then
					item[prop] = theme_key()
				end
			end
		end
	end)
end

Library.FadeSpeed = 0.15
Menu.FadeSpeed = Library.FadeSpeed
Menu.TweenMap = {}

function Menu:Tween(inst, info, goal)
	if not inst or type(goal) ~= "table" then return end
	local result
	run_with_elevated_thread_identity(function()
		if Menu.Silent > 0 or Menu.LoadingConfig then
			for k, v in next, goal do inst[k] = v end
			return
		end
		local prev = self.TweenMap[inst]
		if prev then
			pcall(function() prev:Cancel() end)
			self.TweenMap[inst] = nil
		end
		local ok, tw = pcall(TweenService.Create, TweenService, inst, tween_info(info), goal)
		if not ok or not tw then
			for k, v in next, goal do
				pcall(function() inst[k] = v end)
			end
			return
		end
		self.TweenMap[inst] = tw
		tw.Completed:Connect(function()
			if self.TweenMap[inst] == tw then self.TweenMap[inst] = nil end
		end)
		tw:Play()
		result = tw
	end)
	return result
end

function Menu:CloseCurrent()
	local current = self.CurrentContent
	self.CurrentContent = nil
	if current and current.Close then
		run_with_elevated_thread_identity(function()
			current:Close()
		end)
	end
end

function Menu:ShouldFire(silent)
	if silent == true or self.Silent > 0 or self.LoadingConfig then
		return false
	end
	if Library.ShouldSaveAutoload and Library:ShouldSaveAutoload(silent) then
		defer(function()
			Library:SaveAutoloadIfEnabled()
		end)
	end
	return true
end

function Library:ApplyMouseForMenu(is_open)
	if IsMobile then return end
	if Menu.ModalElement then
		Menu.ModalElement.Modal = is_open == true
	end
	if is_open then
		if self._mouse_icon_saved == nil then
			self._mouse_icon_saved = UserInputService.MouseIconEnabled
		end
		UserInputService.MouseIconEnabled = false
		self.WindowOpenState = true
	else
		self.WindowOpenState = false
		if Menu.CursorGui then Menu.CursorGui.Enabled = false end
		if Menu.MouseCursor then Menu.MouseCursor.Visible = false end
		if self._mouse_icon_saved ~= nil then
			local saved = self._mouse_icon_saved
			self._mouse_icon_saved = nil
			UserInputService.MouseIconEnabled = saved
			defer(function()
				if self.WindowOpenState == true then return end
				pcall(function()
					UserInputService.MouseIconEnabled = saved
				end)
			end)
		end
		if self._mouse_free_bound then
			pcall(function() RunService:UnbindFromRenderStep("HubMouseFree") end)
			self._mouse_free_bound = false
		end
	end
end

Menu.Holder = Draw:Create("ScreenGui", {
	Parent = UIParent, Name = "\0", IgnoreGuiInset = true, ResetOnSpawn = false,

	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
})
Menu.ModalElement = Draw:Create("TextButton", {
	Parent = Menu.Holder,
	BackgroundTransparency = 1,
	Size = UDim2New(0, 0, 0, 0),
	Visible = true,
	Text = "",
	Modal = false,
	AutoButtonColor = false,
	Active = false,
	ZIndex = 0,
})
Menu.Overlay = Draw:Create("ScreenGui", {
	Parent = UIParent, Name = "\0", IgnoreGuiInset = true, ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 200,
})
Menu.Other = Draw:Create("ScreenGui", {
	Parent = UIParent, Name = "\0", ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 2,
})
Menu.FloatingButtonHolder = Draw:Create("ScreenGui", {
	Parent = UIParent, Name = "\0", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 3, Enabled = true,
})
Menu.InputBlockGui = Draw:Create("ScreenGui", {
	Parent = UIParent, Name = "\0", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 50, Enabled = false,
})
Menu.InputBlocker = Draw:Create("TextButton", {
	Parent = Menu.InputBlockGui, Size = UDim2New(1, 0, 1, 0),
	BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
	Visible = false, Active = false, ZIndex = 2,
})
if not IsMobile then
	Menu.CursorGui = Draw:Create("ScreenGui", {
		Parent = UIParent, Name = "\0", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 10001, Enabled = false,
	})
	Menu.MouseCursor = Draw:Create("ImageLabel", {
		Parent = Menu.CursorGui, BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2New(0, 0),
		Image = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png",
		Size = UDim2New(0, 64, 0, 64), ScaleType = Enum.ScaleType.Fit, ZIndex = 10001,
		Visible = false, Active = false,
	})
end
Menu.UIScale = Draw:Create("UIScale", { Parent = Menu.Holder, Scale = 1 })
do
	local vp = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2New(1920, 1080)
	Menu.UIScale.Scale = MathFloor(MathClamp(vp.Y / 1000, 0.5, 1.2) * 100 + 0.5) / 100
end

defer(function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if Library.UIScaleNumeric then Library:SetScaleNumeric(Library.UIScaleNumeric) end
	end)
end)

if Menu.MouseCursor then
	Hook:Add("RenderStepped", "MouseCursor", LPH_NO_VIRTUALIZE(function()
		if not Library.WindowOpenState or not Menu.MouseCursor or not Menu.CursorGui then return end
		if not Menu.CursorGui.Enabled then return end
		local hotspot = Library.MouseCursorHotspot or Vector2New(31, 32)
		local mouse = get_mouse_location()
		Menu.MouseCursor.Position = UDim2New(0, mouse.X - hotspot.X, 0, mouse.Y - hotspot.Y)
		Menu.MouseCursor.Visible = true
	end))
end

Menu.NotifHolder = Draw:Create("Frame", {
	Parent = Menu.Holder, Size = UDim2New(0, 0, 1, 0), Position = UDim2New(1, 0, 0, 0),
	AnchorPoint = Vector2New(1, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
})
Draw:Create("UIListLayout", {
	Parent = Menu.NotifHolder, Padding = UDimNew(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder,
})
Draw:Create("UIPadding", {
	Parent = Menu.NotifHolder, PaddingTop = UDimNew(0, 12), PaddingBottom = UDimNew(0, 12),
	PaddingLeft = UDimNew(0, 12), PaddingRight = UDimNew(0, 12),
})

local function get_drag_scale(gui)
	if not gui then return 1 end
	if Menu.Holder and gui:IsDescendantOf(Menu.Holder) then
		return (Menu.UIScale and Menu.UIScale.Scale) or Library.UIScaleNum or 1
	end
	return 1
end

local get_absolute_mouse = LPH_NO_VIRTUALIZE(function()
	return get_mouse_location()
end)

local function make_draggable(frame, on_drag_end)
	if not frame then return end


	local detector
	local ok_det = pcall(function()
		detector = Instance.new("UIDragDetector")
		detector.Parent = frame
	end)
	if ok_det and detector then
		local suppress_drag = false
		local locked_pos = nil

		Library.WindowDragDetector = detector
		Menu.WindowDragDetector = detector

		local function sync_detector_enabled()
			if not detector or not detector.Parent then return end

			if Library.Dragging or Menu.Dragging then return end
			local enable = not Library:IsPointerOverBlockWindowDrag()
			if detector.Enabled ~= enable then
				pcall(function() detector.Enabled = enable end)
			end
		end

		pcall(function()
			detector:AddConstraintFunction(1000, function(proposed_pos, proposed_rot)
				if suppress_drag or Library.BlockWindowDrag == true then
					return UDim2New(0, 0, 0, 0), 0
				end
				return proposed_pos, proposed_rot
			end)
		end)

		detector.DragStart:Connect(function()
			locked_pos = frame.Position
			if Library:IsPointerOverBlockWindowDrag() then
				suppress_drag = true
				Library.Dragging = false
				Menu.Dragging = false
				frame.Position = locked_pos
				return
			end
			suppress_drag = false
			Library.Dragging = true
			Menu.Dragging = true
			local content = Menu.CurrentContent
			if content and type(content.Close) == "function" then
				Menu.DragClosed = content
				pcall(content.Close, content)
			end
		end)

		detector.DragContinue:Connect(function()
			if (suppress_drag or Library.BlockWindowDrag == true) and locked_pos then
				frame.Position = locked_pos
			end
		end)

		detector.DragEnd:Connect(function()
			if (suppress_drag or Library.BlockWindowDrag == true) and locked_pos then
				frame.Position = locked_pos
			end
			suppress_drag = false
			locked_pos = nil
			Library.Dragging = false
			Menu.Dragging = false
			Menu.DragClosed = nil
			sync_detector_enabled()
			if type(on_drag_end) == "function" then
				pcall(on_drag_end)
			end
		end)

		Library:Connect(UserInputService.InputChanged, LPH_NO_VIRTUALIZE(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			sync_detector_enabled()
		end))

		frame:SetAttribute("HasDragDetector", true)
		return detector
	end


	local dragging, drag_start, start_pos, move_c, end_c
	local function stop_drag()
		dragging = false
		drag_start = nil
		start_pos = nil
		Library.Dragging = false
		Menu.Dragging = false
		Menu.DragClosed = nil
		if move_c then pcall(function() move_c:Disconnect() end); move_c = nil end
		if end_c then pcall(function() end_c:Disconnect() end); end_c = nil end
		if type(on_drag_end) == "function" then
			pcall(on_drag_end)
		end
	end

	frame.InputBegan:Connect(function(input)
		if Library.Dragging or Menu.Dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if Library:IsPointerOverBlockWindowDrag(Vector2New(input.Position.X, input.Position.Y)) then
			return
		end
		if dragging then stop_drag() end
		dragging = true
		Library.Dragging = true
		Menu.Dragging = true
		drag_start = Vector2New(input.Position.X, input.Position.Y)
		start_pos = frame.Position
		local content = Menu.CurrentContent
		if content and type(content.Close) == "function" then
			Menu.DragClosed = content
			pcall(content.Close, content)
		end

		move_c = UserInputService.InputChanged:Connect(LPH_NO_VIRTUALIZE(function(move)
			if not dragging or not drag_start or not start_pos then return end
			if move.UserInputType ~= Enum.UserInputType.MouseMovement and move.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local scale = get_drag_scale(frame)
			local delta = (Vector2New(move.Position.X, move.Position.Y) - drag_start) / scale
			frame.Position = UDim2New(
				start_pos.X.Scale,
				start_pos.X.Offset + delta.X,
				start_pos.Y.Scale,
				start_pos.Y.Offset + delta.Y
			)
		end))

		end_c = UserInputService.InputEnded:Connect(function(ended)
			if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
				if dragging then stop_drag() end
			end
		end)
	end)
end

function Library:SetWindowDragEnabled(enabled)
	local detector = self.WindowDragDetector or Menu.WindowDragDetector
	if not detector then return end
	pcall(function()
		detector.Enabled = enabled == true
	end)
end

local function make_resizeable(frame, min_size)
	if not frame then return end
	min_size = min_size or Vector2New(400, 300)

	local size_btn = Draw:Create("TextButton", {
		Parent = frame,
		Position = UDim2New(1, 0, 1, 0),
		AnchorPoint = Vector2New(1, 1),
		Size = UDim2New(0, 16, 0, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 100,
	})


	local grip = Draw:Create("TextLabel", {
		Parent = size_btn,
		Position = UDim2New(1, -1, 1, -1),
		AnchorPoint = Vector2New(1, 1),
		Size = UDim2New(0, 12, 0, 12),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "◢",
		TextColor3 = Menu.Theme.Text,
		TextTransparency = 0.45,
		TextSize = 11,
		FontFace = Menu.Font,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		ZIndex = 101,
		Theme = { TextColor3 = "Text" },
	})

	size_btn.MouseEnter:Connect(function()
		grip.TextTransparency = 0.15
	end)
	size_btn.MouseLeave:Connect(function()
		grip.TextTransparency = 0.45
	end)

	size_btn.MouseButton1Down:Connect(function()
		local start_mouse = Vector2New(Mouse.X, Mouse.Y)
		local start_size = frame.Size
		local start_position = frame.Position
		local parent = frame.Parent
		local parent_size = (parent and parent:IsA("GuiObject") and parent.AbsoluteSize)
			or ((Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2New(1920, 1080))
		local scale = get_drag_scale(frame)

		Hook:Add("RenderStepped", "Menu:Window.Size", LPH_NO_VIRTUALIZE(function()
			if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				Hook:Remove("RenderStepped", "Menu:Window.Size")
				return
			end
			local delta = (Vector2New(Mouse.X, Mouse.Y) - start_mouse) / scale
			local max_x = MathMax(min_size.X, (parent_size.X / scale) - start_position.X.Offset)
			local max_y = MathMax(min_size.Y, (parent_size.Y / scale) - start_position.Y.Offset)
			frame.Size = UDim2New(
				start_size.X.Scale,
				MathClamp(start_size.X.Offset + delta.X, min_size.X, max_x),
				start_size.Y.Scale,
				MathClamp(start_size.Y.Offset + delta.Y, min_size.Y, max_y)
			)
			frame.Position = start_position
		end))
	end)

	return size_btn
end

Library.Draggify = function(self)
	if self and self.Instance then
		make_draggable(self.Instance)
	elseif typeof(self) == "Instance" then
		make_draggable(self)
	end
	return self
end
Library.Dragging = false
Menu.Dragging = false
Library.DraggingSpeed = Library.DraggingSpeed or 0.05
Menu.DragClosed = nil

local InstanceNew = Instance.new
local RGBSequence = ColorSequence.new
local RGBSequenceKeypoint = ColorSequenceKeypoint.new
local UDim2FromOffset = UDim2.fromOffset
local UDim2FromScale = UDim2.fromScale
local Vector3New = Vector3.new
local GuiInset = GuiService:GetGuiInset().Y

local function GetFolders()
	return Library.Folders or Folders
end

local function IsRobloxInstance(Value)
	if Value == nil then
		return false
	end
	if type(typeof) == "function" then
		local ok_type, kind = pcall(typeof, Value)
		if ok_type and kind == "Instance" then
			return true
		end
		if ok_type then
			return false
		end
	end
	if type(Value) == "string" or type(Value) == "number" or type(Value) == "boolean" then
		return false
	end
	local ok, class_name = pcall(function()
		return Value.ClassName
	end)
	return ok and type(class_name) == "string" and class_name ~= ""
end

local function GetWrapperInstance(Wrapper)
	if type(Wrapper) ~= "table" or not Wrapper.Instance then
		return nil
	end
	return Wrapper.Instance
end

local function RunGuiMutation(Function)
	if type(Function) ~= "function" then
		return false
	end
	return select(1, run_with_elevated_thread_identity(Function))
end

Library.RunGuiMutation = function(self, Function)
	return RunGuiMutation(Function)
end
Library.SetInstanceParent = function(self, inst, parent)
	return set_instance_parent(inst, parent)
end
Library.GetWrapperInstance = function(self, Wrapper)
	return GetWrapperInstance(Wrapper)
end
Library.IsRobloxInstance = IsRobloxInstance

Library.ShouldSkipVisualTween = function(self)
	return false
end

Library.ApplyTweenGoals = function(self, InstanceObject, Goal)
	if not InstanceObject or type(Goal) ~= "table" then
		return
	end
	safe_gui(function()
		for Property, Value in next, Goal do
			InstanceObject[Property] = Value
		end
	end)
end

Library.ToRich = function(self, Text, Color)
	return '<font color="rgb('
		.. MathFloor(Color.R * 255)
		.. ", "
		.. MathFloor(Color.G * 255)
		.. ", "
		.. MathFloor(Color.B * 255)
		.. ')">'
		.. Text
		.. "</font>"
end

Library.UnnamedConnections = Library.UnnamedConnections or 0
Library.Connections = Library.Connections or {}
Library.Threads = Library.Threads or {}
Library.ThemeItems = Library.ThemeItems or Menu.ThemeItems
Library.ThemeMap = Library.ThemeMap or Menu.ThemeMap
Library.AllSections = Library.AllSections or {}
Library.OnMainVisibilityChanged = Library.OnMainVisibilityChanged or {}
Library.Pages = Library.Pages or {}
Library.Sections = Library.Sections or {}
Library.Sections.__index = Library.Sections
Library.Pages.__index = Library.Pages

Library.Holder = { Instance = Menu.Holder }
Library.Overlay = { Instance = Menu.Overlay }
Library.Other = { Instance = Menu.Other }

Library.Connect = function(self, Event, Callback, Name)
	self.UnnamedConnections = (self.UnnamedConnections or 0) + 1
	Name = Name or ("connection_number_" .. tostring(self.UnnamedConnections))
	local is_hot = Event == RunService.RenderStepped or Event == RunService.Heartbeat
	if not is_hot then
		Callback = elevate_callback(Callback)
	end
	local connection
	run_with_elevated_thread_identity(function()
		connection = Event:Connect(Callback)
	end)
	local entry = { Event = Event, Callback = Callback, Name = Name, Connection = connection }
	TableInsert(self.Connections, entry)
	Menu.Connections[Name] = connection
	return entry
end

Library.Disconnect = function(self, Name)
	for i = 1, #self.Connections do
		local connection = self.Connections[i]
		if connection and connection.Name == Name then
			if connection.Connection then
				pcall(function()
					connection.Connection:Disconnect()
				end)
			end
			break
		end
	end
	if Menu.Connections[Name] then
		pcall(function()
			Menu.Connections[Name]:Disconnect()
		end)
		Menu.Connections[Name] = nil
	end
end

Library.AddToTheme = function(self, Item, Properties)
	local InstanceObject = (type(Item) == "table" and Item.Instance) or Item
	if not InstanceObject or type(Properties) ~= "table" then
		return
	end
	Menu:AddToTheme(InstanceObject, Properties)
end

Library.ChangeItemTheme = function(self, Item, Properties)
	local InstanceObject = (type(Item) == "table" and Item.Instance) or Item
	if not InstanceObject or type(Properties) ~= "table" then
		return
	end
	local existing = Menu.ThemeMap[InstanceObject]
	if existing then
		existing.Properties = Properties
	end
	Menu:AddToTheme(InstanceObject, Properties)
end

Library.RegisterFontTextElement = function(self, InstanceObject)
	if InstanceObject then
		Menu.FontTextElements[InstanceObject] = true
	end
end

Library.ApplyFontSettings = function(self)
	if type(self.ApplyFont) == "function" then
		pcall(function()
			self:ApplyFont(Menu.FontSettings.Name)
		end)
	end
end

Library.DeferSectionLayoutRefresh = function(self, Section)
	if type(Section) == "table" and type(Section.QueueUpdateLayout) == "function" then
		pcall(Section.QueueUpdateLayout, Section)
	end
end

Library.ApplyElementVisibility = function(self, Element, Bool)
	if type(Element) ~= "table" then return end
	local Visible = Bool == true
	Element.Visible = Visible
	local fw = Element.UI and Element.UI.Framework
	if typeof(fw) ~= "Instance" then return end




	run_with_elevated_thread_identity(function()
		if Visible then
			local saved = Element._VisSaved
			if saved then
				fw.AutomaticSize = saved.AutomaticSize
				fw.Size = saved.Size
				if saved.ClipsDescendants ~= nil then
					fw.ClipsDescendants = saved.ClipsDescendants
				end
				Element._VisSaved = nil
			end
			fw.Visible = true
		else
			if not Element._VisSaved then
				Element._VisSaved = {
					Size = fw.Size,
					AutomaticSize = fw.AutomaticSize,
					ClipsDescendants = fw.ClipsDescendants,
				}
			end
			fw.ClipsDescendants = true
			fw.AutomaticSize = Enum.AutomaticSize.None
			fw.Size = UDim2New(fw.Size.X.Scale, fw.Size.X.Offset, 0, 0)
			fw.Visible = false
		end
	end)

	if Element.Section then
		Library:DeferSectionLayoutRefresh(Element.Section)
	end
end

Library.AttachElementVisibilityApi = function(self, Element, InstanceWrapper)
	if type(Element) ~= "table" then
		return Element
	end
	function Element:SetVisibility(Bool)
		local target = InstanceWrapper and InstanceWrapper.Instance
		if target then
			Library:ApplyElementVisibility(self, Bool)
			if typeof(target) == "Instance" and target ~= (self.UI and self.UI.Framework) then
				run_with_elevated_thread_identity(function()
					target.Visible = self.Visible == true
				end)
			end
		else
			Library:ApplyElementVisibility(self, Bool)
		end
	end
	Element.SetVisible = Element.SetVisibility
	return Element
end

Library.Thread = function(self, Function)
	local thread = task.spawn(Function)
	TableInsert(self.Threads, thread)
	return thread
end

Library.SafeCall = function(self, Function, ...)
	local ok, result = pcall(Function, ...)
	return ok, result
end

local Tween = {}
Tween.__index = Tween
Tween.Create = function(self, Item, Info, Goal, IsRawItem)
	local InstanceObject = IsRawItem and Item or (type(Item) == "table" and Item.Instance or Item)
	Info = Info or TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)
	if Library:ShouldSkipVisualTween() and type(Goal) == "table" then
		Library:ApplyTweenGoals(InstanceObject, Goal)
		return { Tween = nil, Info = Info, Goal = Goal, Item = InstanceObject }
	end
	local ok, tween_inst = pcall(TweenService.Create, TweenService, InstanceObject, Info, Goal)
	if not ok or not tween_inst then
		Library:ApplyTweenGoals(InstanceObject, Goal)
		return { Tween = nil, Info = Info, Goal = Goal, Item = InstanceObject }
	end
	tween_inst:Play()
	return { Tween = tween_inst, Info = Info, Goal = Goal, Item = InstanceObject }
end

local function resolve_column_parent(page, side)
	if not page or type(page.ColumnsData) ~= "table" then
		return nil
	end
	local col = page.ColumnsData[side] or page.ColumnsData[1]
	if type(col) == "table" and col.Instance then
		return col.Instance
	end
	return col
end

local function sections_content_frame(section)
	if type(section) ~= "table" or type(section.Items) ~= "table" then
		return nil
	end
	local content = section.Items["Content"]
	if type(content) == "table" and content.Instance then
		return content.Instance
	end
	return content
end

local function sections_make_element(section, class_name, style, data)
	local frame = sections_content_frame(section)
	if not frame then
		return nil
	end
	data = data or {}
	if data.Title == nil then
		data.Title = data.Name or data.name or class_name
	end
	data.Name = data.Name or data.Title
	local class = Menu.Classes[class_name]
	if not class or type(class.new) ~= "function" then
		return nil
	end
	local config = { ContentFrame = frame, Category = section.Category }
	if style then
		config.Style = style
	end
	return class.new(config, data)
end

Library.Sections.Toggle = function(self, Data)
	return sections_make_element(self, "Checkbox", "Toggle", Data)
end
Library.Sections.Checkbox = function(self, Data)
	return sections_make_element(self, "Checkbox", "Checkbox", Data)
end
Library.Sections.Slider = function(self, Data)
	return sections_make_element(self, "Slider", nil, Data)
end
Library.Sections.Dropdown = function(self, Data)
	return sections_make_element(self, "Dropdown", nil, Data)
end
Library.Sections.Label = function(self, Name, Description)
	local data = type(Name) == "table" and Name or { Title = Name, Name = Name, Description = Description }
	return sections_make_element(self, "Label", nil, data)
end
Library.Sections.Button = function(self, Data)
	return sections_make_element(self, "Button", nil, Data)
end
Library.Sections.Textbox = function(self, Data)
	return sections_make_element(self, "Textbox", nil, Data)
end

function Library:EnsureFolders()
	local roots = {
		BRAND_DIR, BRAND_DIR .. "/Datas", BRAND_DIR .. "/Assets", BRAND_DIR .. "/Assets/Fonts",
		BRAND_DIR .. "/Configurations", BRAND_DIR .. "/Images", BRAND_DIR .. "/Themes",
	}
	for i = 1, #roots do
		local path = roots[i]
		if isfolder and not isfolder(path) and makefolder then
			pcall(makefolder, path)
		end
	end
end

-- Restored to the original Solix Hub logo for this branded copy.
-- Set Library.LogoUrl to "" (and Library.LogoFallback to your own
-- rbxassetid://) if you want to go back to no third-party fetch at all.
Library.LogoUrl = "https://solixhub.com/solix-logo.png"
Library.LogoFallback = "rbxassetid://137698471325689"

function Library:GetLogoAsset()
	if type(self._logo_asset) == "string" and self._logo_asset ~= "" then
		return self._logo_asset
	end
	if type(self.LogoUrl) ~= "string" or self.LogoUrl == "" then
		return self.LogoFallback
	end
	if type(getcustomasset) ~= "function" or type(writefile) ~= "function" then
		return self.LogoFallback
	end
	self:EnsureFolders()
	local file_path = GetFolders().Images .. "/logo.png"
	if type(isfile) ~= "function" or not isfile(file_path) then
		local content = self:HttpGetImageTextbox(self.LogoUrl)
		if type(content) ~= "string" or content == "" then
			return self.LogoFallback
		end
		if pcall(writefile, file_path, content) ~= true then
			return self.LogoFallback
		end
	end
	local ok, asset_id = pcall(getcustomasset, file_path)
	if ok and type(asset_id) == "string" and asset_id ~= "" then
		self._logo_asset = asset_id
		return asset_id
	end
	return self.LogoFallback
end

function Library:ApplyLogoImage(inst)
	if not inst then return end
	spawn(function()
		local asset = self:GetLogoAsset()
		if type(asset) ~= "string" or asset == "" then return end
		local props = { Image = asset }
		if asset ~= self.LogoFallback then
			props.ImageColor3 = FromRGB(255, 255, 255)
		end
		safe_set(inst, props)
	end)
end

Library.TrimImageTextboxInput = function(_, value)
	if type(value) ~= "string" then return "" end
	return StringGsub(StringGsub(value, "^%s+", ""), "%s+$", "")
end

Library.GetImageTextboxUrlPath = function(_, url)
	if type(url) ~= "string" then return "" end
	local path = url:match("^https?://[^/%?]+(.*)$") or url
	path = path:match("^([^%?#]+)") or path
	return StringLower(path)
end

Library.GetImageTextboxUrlExtension = function(_, url)
	local path = Library:GetImageTextboxUrlPath(url)
	if path:match("%.webp") then return "webp" end
	if path:match("%.jpe?g") then return "jpg" end
	if path:match("%.png") then return "png" end
	return "png"
end

Library.HttpGetImageTextbox = function(_, url)
	if type(url) ~= "string" or url == "" then return nil, "empty url" end
	local ok, content = run_with_thread_identity(8, function()
		if type(game.HttpGet) == "function" then
			local success, body = pcall(function() return game:HttpGet(url) end)
			if success and type(body) == "string" and body ~= "" then return body end
		end
		local req = (type(syn) == "table" and syn.request) or request or http_request or (type(http) == "table" and http.request)
		if req then
			local success, body = pcall(function()
				local response = req({ Url = url, Method = "GET" })
				return type(response) == "table" and response.Body or nil
			end)
			if success and type(body) == "string" and body ~= "" then return body end
		end
		return nil
	end)
	if ok and type(content) == "string" and content ~= "" then return content end
	return nil, "http get failed"
end

Library.WriteImageTextboxWorkspaceAsset = function(_, content, extension, cache_key)
	if type(content) ~= "string" or content == "" then return nil end
	if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then return nil end
	Library:EnsureFolders()
	extension = type(extension) == "string" and extension ~= "" and extension or "png"
	local hash = 0
	local hash_source = type(cache_key) == "string" and cache_key or content
	for index = 1, #hash_source do
		hash = (hash * 31 + string.byte(hash_source, index)) % 2147483647
	end
	local file_path = GetFolders().Images .. "/preview_" .. tostring(hash) .. "." .. extension
	if type(isfile) ~= "function" or not isfile(file_path) then
		local ok_write = pcall(writefile, file_path, content)
		if ok_write ~= true then return nil end
	end
	local ok_asset, asset_id = pcall(getcustomasset, file_path)
	if ok_asset ~= true or type(asset_id) ~= "string" or asset_id == "" then return nil end
	return asset_id
end

Library.IsValidImageTextboxInput = function(_, value)
	local trimmed = Library:TrimImageTextboxInput(value)
	if trimmed == "" then return false end
	if trimmed:match("^%d+$") then return true end
	if trimmed:match("^rbxassetid://%d+") then return true end
	if trimmed:match("roblox%.com") and trimmed:match("%d+") then return true end
	if StringLower(trimmed):match("^https?://") then return true end
	return false
end

Library.ResolveImageTextboxPreview = function(_, value)
	local trimmed = Library:TrimImageTextboxInput(value)
	if not Library:IsValidImageTextboxInput(trimmed) then return nil end

	local numeric_id = trimmed:match("^(%d+)$") or trimmed:match("^rbxassetid://(%d+)")
	if numeric_id then return "rbxassetid://" .. numeric_id end

	if trimmed:match("roblox%.com") then
		local catalog_id = trimmed:match("(%d+)")
		if catalog_id then return "rbxassetid://" .. catalog_id end
	end

	local lowered = StringLower(trimmed)
	if not lowered:match("^https?://") then return nil end

	local content = Library:HttpGetImageTextbox(trimmed)
	if type(content) ~= "string" or content == "" then return nil end
	return Library:WriteImageTextboxWorkspaceAsset(content, Library:GetImageTextboxUrlExtension(trimmed), trimmed)
end

Library.Sections.ImageTextbox = function(self, Data)
	return sections_make_element(self, "ImageTextbox", nil, Data)
end
Library.Sections.SubSlider = function(self, Data)
	return sections_make_element(self, "SubSlider", nil, Data)
end

local function ResolveSectionSide(Data)
	Data = Data or {}
	local side = tonumber(Data.Side or Data.side or 1) or 1
	if side == 0 then
		return 0
	end
	if side == 2 then
		return 2
	end
	return 1
end

local Instances = {}
Instances.__index = Instances

Instances.Create = function(self, Class, Properties)
	local Success, Result = pcall(function()
		local NewItem = {
			Instance = InstanceNew(Class),
			Properties = Properties,
			Class = Class,
		}
		setmetatable(NewItem, Instances)
		for Property, Value in next, NewItem.Properties do
			if Property == "Parent" then
				set_instance_parent(NewItem.Instance, Value)
			else
				pcall(function()
					NewItem.Instance[Property] = Value
				end)
			end
		end
		if Class == "TextLabel" or Class == "TextButton" or Class == "TextBox" then
			pcall(function()
				NewItem.Instance.AutoLocalize = false
			end)
			Menu.FontTextElements[NewItem.Instance] = true
			if not Properties.FontFace then
				pcall(function()
					NewItem.Instance.FontFace = Menu.Font
				end)
			end
		end
		return NewItem
	end)
	if Success and Result then
		return Result
	end
	return { Instance = nil, Properties = Properties or {}, Class = Class, _Protected = true }
end

Instances.SetParent = function(self, Parent)
	if self.Instance then
		set_instance_parent(self.Instance, Parent)
	end
	return self
end

Instances.AddToTheme = function(self, Properties)
	if self.Instance then
		Library:AddToTheme(self, Properties)
	end
	return self
end

Instances.ChangeItemTheme = function(self, Properties)
	if self.Instance then
		Library:ChangeItemTheme(self, Properties)
	end
	return self
end

Instances.Connect = function(self, Event, Callback, Name)
	if not self.Instance or not self.Instance[Event] then
		return
	end
	local event_name = Event
	if IsMobile and (Event == "MouseButton1Down" or Event == "MouseButton1Click") then
		event_name = "TouchTap"
	end
	if not self.Instance[event_name] then
		event_name = Event
	end
	return Library:Connect(self.Instance[event_name], Callback, Name)
end

Instances.Set = function(self, Property, Value)
	if not self.Instance then
		return self
	end
	run_with_elevated_thread_identity(function()
		self.Instance[Property] = Value
	end)
	return self
end

Instances.Tween = function(self, Info, Goal)
	if not self.Instance then
		return
	end
	if Library:ShouldSkipVisualTween() and type(Goal) == "table" then
		Library:ApplyTweenGoals(self.Instance, Goal)
		return
	end
	return Tween:Create(self, Info, Goal)
end

Instances.Clean = function(self)
	if self.Instance then
		safe_destroy(self.Instance)
		self.Instance = nil
	end
end

Instances.MakeDraggable = function(self)
	if not self.Instance then
		return self
	end
	make_draggable(self.Instance)
	return self
end

Instances.MakeResizeable = function(self, minimum)
	if not self.Instance then
		return self
	end
	make_resizeable(self.Instance, minimum)
	return self
end

Instances.OnHover = function(self, Function)
	if not self.Instance then
		return
	end
	return Library:Connect(self.Instance.MouseEnter, Function)
end

Instances.OnHoverLeave = function(self, Function)
	if not self.Instance then
		return
	end
	return Library:Connect(self.Instance.MouseLeave, Function)
end

function Menu:Attach(element, class_name, parameters)
	parameters = parameters or {}
	local class = self.Classes[class_name]
	if not class then return end

	element.Attachments = element.Attachments or {}
	element.AttachmentsIndex = (element.AttachmentsIndex or 0) + 1

	local parent = element.UI and element.UI.SubElements
	if not parent then return end

	local attachment
	local ok, err = run_with_elevated_thread_identity(function()
		attachment = class.new({
			ContentFrame = parent,
			Host = element,
			ZIndex = (element.ZIndex or 2) + 1,
			Category = element.Category,
		}, parameters)
	end)
	if not ok then
		error(tostring(err or "Attach failed"), 2)
	end

	attachment.Host = element
	element.Attachments[element.AttachmentsIndex] = attachment
	return attachment
end

local function data_flag(data)
	if type(data) ~= "table" then return nil end
	local f = data.Flag or data.flag
	if type(f) == "string" and f ~= "" then return f end
	return nil
end

local function data_name(data, fallback)
	return (data and (data.Name or data.name or data.Title)) or fallback or "Element"
end

do
	local Window = {}
	Window.__index = Window

	function Window.new(parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Window)
		self.Class = "Window"
		self.Name = parameters.Name or parameters.name or "Window"
		self.GameName = parameters.Game or parameters.game or ""
		self.Premium = parameters.Premium == true or parameters.premium == true
		self.Pages = {}
		self.PagesIndex = 0
		self.IsOpen = false
		self.Visible = true
		self.UI = {}
		self.CurrentPage = nil

		if self.GameName == "" then
			local after = string.match(self.Name, "|%s*(.+)$")
			if after then
				self.GameName = string.match(after, "^(.-)%s+Premium%s*$") or after
			end
		end

		self:Draw()
		self:Connections()
		return self
	end

	function Window:Draw()
		local UI = self.UI
		local h = IsMobile and MathFloor(526 * 0.85) or 526

		UI.MainFrame = Draw:Create("Frame", {
			Parent = Menu.Holder,
			Size = UDim2New(0, 770, 0, h),
			Position = UDim2New(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2New(0.5, 0.5),
			BackgroundColor3 = Menu.Theme.Background,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 2,
			Theme = { BackgroundColor3 = "Background" },
		})
		corner(UI.MainFrame, 5)
		UI.DragDetector = make_draggable(UI.MainFrame)
		UI.SizeFrame = make_resizeable(UI.MainFrame, Vector2New(500, 350))

		UI.Shadow = Draw:Create("ImageLabel", {
			Parent = UI.MainFrame,
			Size = UDim2New(1, 55, 1, 55),
			Position = UDim2New(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2New(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://112971167999062",
			ImageColor3 = Menu.Theme.Shadow,
			ImageTransparency = 0.56,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = RectNew(Vector2New(112, 112), Vector2New(147, 147)),
			SliceScale = 0.6,
			ZIndex = -1,
			Theme = { ImageColor3 = "Shadow" },
		})

		UI.Logo = Draw:Create("ImageLabel", {
			Parent = UI.MainFrame,
			Size = UDim2New(0, 18, 0, 18),
			Position = UDim2New(0, 9, 0, 7),
			BackgroundTransparency = 1,
			Image = "",
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 4,
		})

		UI.Title = Draw:Create("TextLabel", {
			Parent = UI.MainFrame,
			Size = UDim2New(0, 0, 0, 15),
			Position = UDim2New(0, 32, 0, 8),
			BackgroundTransparency = 1,
			Text = self.Name,
			TextColor3 = Menu.Theme.Text,
			TextSize = 14,
			FontFace = Menu.Font,
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = 4,
			Theme = { TextColor3 = "Text" },
		})
		Library:ApplyLogoImage(UI.Logo)

		UI.Pages = Draw:Create("ScrollingFrame", {
			Parent = UI.MainFrame,
			Size = UDim2New(0, 150, 1, -30),
			Position = UDim2New(0, 0, 0, 30),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2New(0, 0, 0, 0),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Menu.Theme.Accent,
			TopImage = "rbxassetid://136419474381965",
			MidImage = "rbxassetid://136419474381965",
			BottomImage = "rbxassetid://136419474381965",
			ZIndex = 2,
			Theme = { ScrollBarImageColor3 = "Accent" },
		})
		Draw:Create("UIListLayout", { Parent = UI.Pages, Padding = UDimNew(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
		Draw:Create("UIPadding", { Parent = UI.Pages, PaddingLeft = UDimNew(0, 8), PaddingRight = UDimNew(0, 8) })

		UI.Close = Draw:Create("ImageButton", {
			Parent = UI.MainFrame,
			Size = UDim2New(0, 23, 0, 23),
			Position = UDim2New(1, -12, 0, 5),
			AnchorPoint = Vector2New(1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://76001605964586",
			ScaleType = Enum.ScaleType.Fit,
			AutoButtonColor = false,
			ZIndex = 2,
		})

		UI.Content = Draw:Create("Frame", {
			Parent = UI.MainFrame,
			Size = UDim2New(1, -171, 1, -38),
			Position = UDim2New(0, 163, 0, 30),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
		})

		UI.Search = Draw:Create("Frame", {
			Parent = UI.Content,
			Size = UDim2New(1, 0, 0, 35),
			BackgroundColor3 = Menu.Theme.Inline,
			BorderSizePixel = 0,
			ZIndex = 2,
			Theme = { BackgroundColor3 = "Inline" },
		})
		corner(UI.Search, 5)
		Draw:Create("ImageLabel", {
			Parent = UI.Search, Size = UDim2New(0, 20, 0, 20),
			Position = UDim2New(0, 8, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundTransparency = 1, Image = "rbxassetid://71924825350727",
			ImageTransparency = 0.4, ScaleType = Enum.ScaleType.Fit, ZIndex = 2,
		})
		UI.SearchInput = Draw:Create("TextBox", {
			Parent = UI.Search, Size = UDim2New(1, -43, 0, 15),
			Position = UDim2New(0, 35, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundTransparency = 1, Text = "", TextColor3 = Menu.Theme.Text,
			TextSize = 14, FontFace = Menu.Font, TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderText = "Search..", PlaceholderColor3 = Menu.Theme["Inactive Text"],
			ClearTextOnFocus = false, ZIndex = 2,
			Theme = { TextColor3 = "Text", PlaceholderColor3 = "Inactive Text" },
		})

		UI.SearchResults = Draw:Create("Frame", {
			Parent = UI.Content,
			Size = UDim2New(1, 0, 0, 0),
			Position = UDim2New(0, 0, 0, 39),
			BackgroundColor3 = Menu.Theme.Element,
			BorderSizePixel = 0,
			Visible = false,
			ClipsDescendants = true,
			ZIndex = 80,
			Theme = { BackgroundColor3 = "Element" },
		})
		corner(UI.SearchResults, 5)
		ui_dual_stroke(UI.SearchResults)
		UI.SearchResultsList = Draw:Create("ScrollingFrame", {
			Parent = UI.SearchResults,
			Size = UDim2New(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2New(0, 0, 0, 0),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Menu.Theme.Accent,
			ZIndex = 81,
			TopImage = "rbxassetid://128693616966482",
			MidImage = "rbxassetid://128693616966482",
			BottomImage = "rbxassetid://128693616966482",
			Theme = { ScrollBarImageColor3 = "Accent" },
		})
		Draw:Create("UIListLayout", {
			Parent = UI.SearchResultsList, Padding = UDimNew(0, 2), SortOrder = Enum.SortOrder.LayoutOrder,
		})
		Draw:Create("UIPadding", {
			Parent = UI.SearchResultsList,
			PaddingTop = UDimNew(0, 4), PaddingBottom = UDimNew(0, 4),
			PaddingLeft = UDimNew(0, 4), PaddingRight = UDimNew(0, 4),
		})

		Draw:Create("Frame", {
			Parent = UI.MainFrame, Size = UDim2New(0, 1, 1, -30),
			Position = UDim2New(0, 152, 0, 30), BackgroundColor3 = Menu.Theme.Border,
			BorderSizePixel = 0, ZIndex = 2, Theme = { BackgroundColor3 = "Border" },
		})

		UI.PagesContent = Draw:Create("Frame", {
			Parent = UI.Content, Size = UDim2New(1, 0, 1, -43),
			Position = UDim2New(0, 0, 0, 43), BackgroundTransparency = 1, ZIndex = 2,
		})

		local footer = Draw:Create("Frame", {
			Parent = UI.MainFrame, AnchorPoint = Vector2New(0, 1),
			Position = UDim2New(0, 9, 1, -6), AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 4,
		})
		Draw:Create("UIListLayout", { Parent = footer, Padding = UDimNew(0, 1), SortOrder = Enum.SortOrder.LayoutOrder })
		local brand_row = Draw:Create("Frame", {
			Parent = footer, AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, ZIndex = 4,
		})
		Draw:Create("UIListLayout", {
			Parent = brand_row, FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
		})
		Draw:Create("TextLabel", {
			Parent = brand_row, AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1,
			Text = BRAND_WORD_1, TextColor3 = FromRGB(255, 255, 255), TextSize = 14, FontFace = Menu.Font, ZIndex = 4,
		})
		Draw:Create("TextLabel", {
			Parent = brand_row, AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1,
			Text = BRAND_WORD_2, TextColor3 = Menu.Theme.Accent, TextSize = 14, FontFace = Menu.Font, ZIndex = 4,
			Theme = { TextColor3 = "Accent" },
		})
		local subtitle = self.Premium and ((self.GameName ~= "" and self.GameName .. " Premium") or "Premium") or self.GameName
		UI.Subtitle = Draw:Create("TextLabel", {
			Parent = footer, AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1,
			Text = subtitle, TextColor3 = Menu.Theme["Inactive Text"], TextSize = 12, FontFace = Menu.Font,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
			Theme = { TextColor3 = "Inactive Text" },
		})
	end

	function Window:HideSearchResults()
		local ui = self.UI
		if ui.SearchResults then
			ui.SearchResults.Visible = false
		end
		if ui.SearchResultsList then
			local children = ui.SearchResultsList:GetChildren()
			for i = 1, #children do
				local child = children[i]
				if child.Name == "SearchResultRow" then
					safe_destroy(child)
				end
			end
		end
	end

	function Window:RestoreSearchVisibility()
		local page = self.CurrentPage
		if not page then return end
		local index = Menu.GlobalSearchIndex
		for i = 1, #index do
			local e = index[i]
			if e.Page == page and e.Frame then

				if e.Element and e.Element.Visible == false then
					continue
				end
				if e.Element and type(e.Element.SetVisible) == "function" then
					pcall(e.Element.SetVisible, e.Element, true)
				else
					e.Frame.Visible = true
				end
			end
		end
	end

	function Window:UpdateSearchResults(query)
		local ui = self.UI
		local list = ui.SearchResultsList
		local panel = ui.SearchResults
		if not list or not panel then return end

		local children = list:GetChildren()
		for i = 1, #children do
			local child = children[i]
			if child.Name == "SearchResultRow" then
				safe_destroy(child)
			end
		end

		if query == "" then
			panel.Visible = false
			self:RestoreSearchVisibility()
			return
		end

		local index = Menu.GlobalSearchIndex
		local count = 0
		local SEARCH_RESULT_CAP = 12
		local SEARCH_RESULT_ROW_H = 42

		for i = 1, #index do
			if count >= SEARCH_RESULT_CAP then break end
			local e = index[i]
			local key = e.SearchKey or e.NameLower or StringLower(e.Name or "")
			if StringFind(key, query, 1, true) == nil then continue end
			count += 1

			local row = Draw:Create("TextButton", {
				Parent = list,
				Name = "SearchResultRow",
				Size = UDim2New(1, -4, 0, SEARCH_RESULT_ROW_H),
				BackgroundColor3 = Menu.Theme.Inline,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 82,
				Theme = { BackgroundColor3 = "Inline" },
			})
			corner(row, 5)
			Draw:Create("TextLabel", {
				Parent = row,
				Size = UDim2New(1, -16, 0, 16),
				Position = UDim2New(0, 8, 0, 5),
				BackgroundTransparency = 1,
				Text = e.Name or "",
				TextColor3 = Menu.Theme.Text,
				TextSize = 14,
				FontFace = Menu.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 83,
				Theme = { TextColor3 = "Text" },
			})
			Draw:Create("TextLabel", {
				Parent = row,
				Size = UDim2New(1, -16, 0, 14),
				Position = UDim2New(0, 8, 0, 23),
				BackgroundTransparency = 1,
				Text = e.PathLabel or "",
				TextColor3 = Menu.Theme["Inactive Text"],
				TextSize = 12,
				FontFace = Menu.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 83,
				Theme = { TextColor3 = "Inactive Text" },
			})

			row.MouseEnter:Connect(function()
				Menu:Tween(row, nil, { BackgroundTransparency = 0 })
			end)
			row.MouseLeave:Connect(function()
				Menu:Tween(row, nil, { BackgroundTransparency = 1 })
			end)
			row.MouseButton1Down:Connect(function()
				self._search_picking = true
				self:JumpToSearchResult(e)
				ui.SearchInput.Text = ""
				self:HideSearchResults()
				self._search_picking = false
			end)
		end

		if count == 0 then
			panel.Visible = false
			return
		end

		local visible = MathMin(count, 6)
		panel.Size = UDim2New(1, 0, 0, visible * SEARCH_RESULT_ROW_H + MathMax(0, visible - 1) * 2 + 8)
		panel.Visible = true
	end

	function Window:PulseSearchTarget(frame)
		if not frame or not frame.Parent then return end
		if self._search_pulse and self._search_pulse.Parent then
			safe_destroy(self._search_pulse)
		end
		self._search_pulse = nil
		local pulse = Draw:Create("Frame", {
			Parent = frame,
			Size = UDim2New(1, 0, 1, 0),
			BackgroundColor3 = Menu.Theme.Accent,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			ZIndex = (frame.ZIndex or 2) + 8,
		})
		corner(pulse, 5)
		self._search_pulse = pulse
		local tw = Menu:Tween(pulse, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		if tw then
			tw.Completed:Connect(function()
				if self._search_pulse == pulse then
					self._search_pulse = nil
				end
				safe_destroy(pulse)
			end)
		else
			delay(0.5, function()
				if self._search_pulse == pulse then
					self._search_pulse = nil
				end
				safe_destroy(pulse)
			end)
		end
	end

	function Window:JumpToSearchResult(entry)
		if not entry or not entry.Page then return end
		entry.Page:Open()
		if entry.SubPage then
			entry.SubPage:Open()
		end
		if entry.Section and entry.Section.Collapsed and entry.Section.SetCollapsed then
			entry.Section:SetCollapsed(false)
		end
		local frame = entry.Frame
		if not frame then return end
		defer(function()
			if not frame.Parent then return end
			RunService.Heartbeat:Wait()
			if not frame.Parent then return end
			local scroll = frame
			while scroll do
				if scroll:IsA("ScrollingFrame") then break end
				scroll = scroll.Parent
			end
			if scroll and scroll:IsA("ScrollingFrame") then
				local rel = frame.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
				scroll.CanvasPosition = Vector2New(scroll.CanvasPosition.X, MathMax(0, rel - 8))
			end
			self:PulseSearchTarget(frame)
		end)
	end

	function Window:Connections()
		self.UI.Close.MouseButton1Down:Connect(function()
			Library:ConfirmDialog({
				Message = "Are you sure?",
				OnConfirm = function()
					Library:Unload()
				end,
			})
		end)
		Hook:Add("InputBegan", "Window.Toggle", function(input, gp)
			if gp then return end
			local key = Menu.MenuKeybind or "RightControl"
			local pressed
			if input.UserInputType == Enum.UserInputType.Keyboard then
				pressed = input.KeyCode.Name
			else
				pressed = input.UserInputType.Name
			end
			if pressed == key or (key == "RightControl" and (pressed == "RightControl" or pressed == "Insert")) then
				self:SetOpen(not self.IsOpen)
			end
		end)
		Hook:Add("InputEnded", "Menu:ClearDragClosed", function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				Menu.DragClosed = nil
			end
		end)
		self.UI.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
			self:UpdateSearchResults(StringLower(self.UI.SearchInput.Text))
		end)
		self.UI.SearchInput.Focused:Connect(function()
			local q = StringLower(self.UI.SearchInput.Text)
			if q ~= "" then
				self:UpdateSearchResults(q)
			end
		end)
		self.UI.SearchInput.FocusLost:Connect(function()
			delay(0.12, function()
				if self._search_picking then return end
				if not self.UI.SearchInput or self.UI.SearchInput:IsFocused() then return end
				self:HideSearchResults()
			end)
		end)
	end

	function Window:SetOpen(bool)
		bool = bool == true
		local effective = bool and self.Visible
		if self.IsOpen == bool and not self._fade_busy then
			self.UI.MainFrame.Visible = effective
			if self.UI.DragDetector then
				self.UI.DragDetector.Enabled = effective
			end
			Library.WindowOpenState = effective
			Library:ApplyMouseForMenu(effective)
			if Library.ApplyWindowInputState then
				Library:ApplyWindowInputState(effective)
			end
			return
		end

		self.IsOpen = bool
		Library.WindowOpenState = effective
		Library:ApplyMouseForMenu(effective)
		if Library.ApplyWindowInputState then
			Library:ApplyWindowInputState(effective)
		end
		Menu:CloseCurrent()
		if not effective then
			self:HideSearchResults()
		end

		local main = self.UI.MainFrame
		main.Visible = effective
		if self.UI.DragDetector then
			self.UI.DragDetector.Enabled = effective
		end
		self._fade_busy = false
	end

	function Window:SetVisible(bool)
		self.Visible = bool ~= false
		if self.IsOpen then
			self:SetOpen(true)
		else
			self.UI.MainFrame.Visible = false
			Library.WindowOpenState = false
			Library:ApplyMouseForMenu(false)
			if Library.ApplyWindowInputState then
				Library:ApplyWindowInputState(false)
			end
		end
	end

	function Window:CreatePage(parameters)
		return Menu.Classes.Page.new(self, parameters)
	end

	function Window:Init()
		if not self.IsOpen then self:SetOpen(true) end
	end

	function Window:Destroy()
		if self.UI.MainFrame then safe_destroy(self.UI.MainFrame) end
	end

	Menu.Classes.Window = Window
end

do
	local Page = {}
	Page.__index = Page

	function Page.new(window, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Page)
		self.Class = "Page"
		self.Window = window
		self.Name = parameters.Name or parameters.name or "Page"
		self.UI = {}
		self.Sections = {}
		self.SectionsIndex = 0
		self.SubPages = {}
		self.SubPagesIndex = 0
		self.ColumnsData = {}
		self.Active = false

		Menu.SearchItems[self] = {}
		self:Draw()
		self:Connections()

		window.PagesIndex += 1
		window.Pages[window.PagesIndex] = self
		if window.PagesIndex == 1 then self:Open() end
		return self
	end

	function Page:Draw()
		local UI = self.UI
		local win = self.Window.UI

		UI.Tab = Draw:Create("TextButton", {
			Parent = win.Pages, Size = UDim2New(1, 0, 0, 35),
			BackgroundColor3 = Menu.Theme.Inline, BackgroundTransparency = 1,
			BorderSizePixel = 0, Text = "", AutoButtonColor = false, ClipsDescendants = true, ZIndex = 2,
			Theme = { BackgroundColor3 = "Inline" },
		})
		corner(UI.Tab, 5)

		UI.Liner = Draw:Create("Frame", {
			Parent = UI.Tab, Size = UDim2New(0, 6, 0, 0),
			Position = UDim2New(0, -3, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundColor3 = Menu.Theme.Accent, BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 3, Theme = { BackgroundColor3 = "Accent" },
		})
		corner(UI.Liner, 1)
		UI.Liner:FindFirstChildOfClass("UICorner").CornerRadius = UDimNew(1, 0)

		UI.Label = Draw:Create("TextLabel", {
			Parent = UI.Tab, Size = UDim2New(0, 0, 0, 15),
			Position = UDim2New(0, 4, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundTransparency = 1, Text = self.Name, TextColor3 = Menu.Theme.Text,
			TextSize = 14, FontFace = Menu.Font, TextTransparency = 0.4,
			AutomaticSize = Enum.AutomaticSize.X, ZIndex = 2, Theme = { TextColor3 = "Text" },
		})

		UI.Content = Draw:Create("Frame", {
			Parent = win.PagesContent, Size = UDim2New(1, 0, 1, 0),
			BackgroundTransparency = 1, Visible = false, ClipsDescendants = true, ZIndex = 2,
		})

		UI.Columns = Draw:Create("Frame", {
			Parent = UI.Content, Size = UDim2New(1, 0, 1, 0),
			BackgroundTransparency = 1, ZIndex = 1,
		})

		local function col(pos, size)
			local sf = Draw:Create("ScrollingFrame", {
				Parent = UI.Columns, Size = size, Position = pos,
				BackgroundTransparency = 1, BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2New(0, 0, 0, 0),
				ScrollBarThickness = 3, ScrollBarImageColor3 = Menu.Theme.Accent,
				TopImage = "rbxassetid://128693616966482", MidImage = "rbxassetid://128693616966482",
				BottomImage = "rbxassetid://128693616966482", ZIndex = 2,
				Theme = { ScrollBarImageColor3 = "Accent" },
			})
			Draw:Create("UIListLayout", { Parent = sf, Padding = UDimNew(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
			Draw:Create("UIPadding", { Parent = sf, PaddingRight = UDimNew(0, 10), PaddingBottom = UDimNew(0, 24) })
			return sf
		end

		self.ColumnsData[1] = col(UDim2New(0, 0, 0, 0), UDim2New(0.5, -4, 1, 0))
		self.ColumnsData[2] = col(UDim2New(0.5, 4, 0, 0), UDim2New(0.5, -4, 1, 0))
		self.ColumnsData[0] = col(UDim2New(0, 0, 0, 0), UDim2New(1, 0, 1, 0))
		self.ColumnsData[0].Visible = false
	end

	function Page:Connections()
		self.UI.Tab.MouseButton1Down:Connect(function()
			self:Open()
		end)
	end

	function Page:Open()
		local win = self.Window
		if win.CurrentPage and win.CurrentPage ~= self then
			win.CurrentPage:Close()
		end
		win.CurrentPage = self
		self.Active = true
		self.UI.Content.Visible = true
		Menu:Tween(self.UI.Tab, nil, { BackgroundTransparency = 0 })
		Menu:Tween(self.UI.Liner, nil, { BackgroundTransparency = 0, Size = UDim2New(0, 6, 1, -20) })
		Menu:Tween(self.UI.Label, nil, { TextTransparency = 0, Position = UDim2New(0, 12, 0.5, 0) })
	end

	function Page:Close()
		self.Active = false
		self.UI.Content.Visible = false
		Menu:Tween(self.UI.Tab, nil, { BackgroundTransparency = 1 })
		Menu:Tween(self.UI.Liner, nil, { BackgroundTransparency = 1, Size = UDim2New(0, 6, 0, 0) })
		Menu:Tween(self.UI.Label, nil, { TextTransparency = 0.4, Position = UDim2New(0, 4, 0.5, 0) })
	end

	function Page:CreateSection(parameters)
		return Menu.Classes.Section.new(self, parameters)
	end

	function Page:CreateSubPage(parameters)
		return Menu.Classes.SubPage.new(self, parameters)
	end

	Menu.Classes.Page = Page
end

do
	local SubPage = {}
	SubPage.__index = SubPage

	local SUBTAB_HEIGHT = 30
	local SUBTAB_PAD_H = 14
	local SUBTAB_LINER_INSET = 8
	local SUBPAGE_BAR_HEIGHT = 34
	local SUBPAGE_CONTENT_GAP = 4

	function SubPage.new(page, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, SubPage)
		self.Class = "SubPage"
		self.Page = page
		self.Window = page.Window
		self.Name = parameters.Name or parameters.name or "Tab"
		self.UI = {}
		self.ColumnsData = {}
		self.Active = false
		Menu.SearchItems[self] = Menu.SearchItems[self] or {}

		if not page.UI.SubBar then
			page.UI.SubBar = Draw:Create("ScrollingFrame", {
				Parent = page.UI.Content, Size = UDim2New(1, -16, 0, SUBPAGE_BAR_HEIGHT),
				Position = UDim2New(0, 8, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2New(0, 0, 0, 0),
				ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 2,
				ScrollBarImageColor3 = Menu.Theme.Accent, ClipsDescendants = true,
				TopImage = "rbxassetid://128693616966482", MidImage = "rbxassetid://128693616966482",
				BottomImage = "rbxassetid://128693616966482", ZIndex = 10,
				Theme = { ScrollBarImageColor3 = "Accent" },
			})
			Draw:Create("UIListLayout", {
				Parent = page.UI.SubBar, FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDimNew(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			})
			Draw:Create("UIPadding", {
				Parent = page.UI.SubBar, PaddingTop = UDimNew(0, 4),
				PaddingLeft = UDimNew(0, 2), PaddingRight = UDimNew(0, 2),
			})
			local top = SUBPAGE_BAR_HEIGHT + SUBPAGE_CONTENT_GAP

			page.UI.Columns.Position = UDim2New(0, 0, 0, top)
			page.UI.Columns.Size = UDim2New(1, 0, 1, -top)
			page.UI.SubHolder = Draw:Create("Frame", {
				Parent = page.UI.Content, Size = UDim2New(1, 0, 1, -top),
				Position = UDim2New(0, 0, 0, top), BackgroundTransparency = 1,
				ClipsDescendants = true, Visible = false, ZIndex = 1,
			})
		end

		local UI = self.UI
		UI.Tab = Draw:Create("Frame", {
			Parent = page.UI.SubBar, Size = UDim2New(0, 0, 0, SUBTAB_HEIGHT),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
			ClipsDescendants = false, ZIndex = 11,
		})
		Draw:Create("UIPadding", {
			Parent = UI.Tab, PaddingLeft = UDimNew(0, SUBTAB_PAD_H), PaddingRight = UDimNew(0, SUBTAB_PAD_H),
		})

		Draw:Create("TextLabel", {
			Parent = UI.Tab, Size = UDim2New(0, 0, 0, 15),
			Position = UDim2New(0, 0, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundTransparency = 1, Text = self.Name, TextSize = 13, FontFace = Menu.Font,
			TextTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, ZIndex = 0,
		})
		UI.TabBg = Draw:Create("Frame", {
			Parent = UI.Tab, Size = UDim2New(1, 0, 1, 0),
			BackgroundColor3 = Menu.Theme.Inline, BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 11, Theme = { BackgroundColor3 = "Inline" },
		})
		corner(UI.TabBg, 5)
		UI.TabLiner = Draw:Create("Frame", {
			Parent = UI.Tab, Size = UDim2New(1, -SUBTAB_LINER_INSET * 2, 0, 0),
			Position = UDim2New(0, SUBTAB_LINER_INSET, 0, 0),
			BackgroundColor3 = Menu.Theme.Accent, BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 24, Theme = { BackgroundColor3 = "Accent" },
		})
		corner(UI.TabLiner, 2)
		UI.TabText = Draw:Create("TextLabel", {
			Parent = UI.Tab, Size = UDim2New(1, 0, 0, 15),
			Position = UDim2New(0, 0, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundTransparency = 1, Text = self.Name, TextColor3 = Menu.Theme.Text,
			TextSize = 13, FontFace = Menu.Font, TextTransparency = 0.4,
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 25,
			Theme = { TextColor3 = "Text" },
		})
		UI.TabHit = Draw:Create("TextButton", {
			Parent = UI.Tab, Size = UDim2New(1, 0, 1, 0),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 26,
		})

		UI.Content = Draw:Create("Frame", {
			Parent = page.UI.SubHolder, Size = UDim2New(1, 0, 1, 0),
			BackgroundTransparency = 1, Visible = false, ClipsDescendants = true, ZIndex = 1,
		})

		local function col(pos, size)
			local sf = Draw:Create("ScrollingFrame", {
				Parent = UI.Content, Size = size, Position = pos,
				BackgroundTransparency = 1, BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2New(0, 0, 0, 0),
				ScrollBarThickness = 2, ScrollBarImageColor3 = Menu.Theme.Accent, ZIndex = 2,
				Theme = { ScrollBarImageColor3 = "Accent" },
			})
			Draw:Create("UIListLayout", { Parent = sf, Padding = UDimNew(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
			Draw:Create("UIPadding", { Parent = sf, PaddingRight = UDimNew(0, 10), PaddingBottom = UDimNew(0, 24) })
			return sf
		end
		self.ColumnsData[1] = col(UDim2New(0, 0, 0, 0), UDim2New(0.5, -4, 1, 0))
		self.ColumnsData[2] = col(UDim2New(0.5, 4, 0, 0), UDim2New(0.5, -4, 1, 0))
		self.ColumnsData[0] = col(UDim2New(0, 0, 0, 0), UDim2New(1, 0, 1, 0))
		self.ColumnsData[0].Visible = false

		UI.TabHit.MouseButton1Down:Connect(function()
			if not self.Active then self:Open() end
		end)

		page.SubPagesIndex += 1
		page.SubPages[page.SubPagesIndex] = self

		if page.SubPagesIndex == 1 and (page.SectionsIndex or 0) == 0 then
			self:Open()
		end
		return self
	end

	function SubPage:Open()
		local page = self.Page
		for i = 1, page.SubPagesIndex do
			local sp = page.SubPages[i]
			if sp ~= self and sp.Active then sp:Close() end
		end
		self.Active = true
		page.ActiveSubPage = self
		if page.UI.Columns then page.UI.Columns.Visible = false end
		if page.UI.SubHolder then page.UI.SubHolder.Visible = true end
		self.UI.Content.Visible = true
		self.UI.Tab.ZIndex = 20
		self.UI.TabBg.ZIndex = 20
		Menu:Tween(self.UI.TabBg, nil, { BackgroundTransparency = 0 })
		Menu:Tween(self.UI.TabLiner, nil, {
			BackgroundTransparency = 0,
			Size = UDim2New(1, -SUBTAB_LINER_INSET * 2, 0, 3),
		})
		Menu:Tween(self.UI.TabText, nil, { TextTransparency = 0 })

		local bar = page.UI.SubBar
		local tab = self.UI.Tab
		if bar and bar:IsA("ScrollingFrame") and tab then
			defer(function()
				if not tab.Parent or not bar.Parent then return end
				local left = tab.AbsolutePosition.X - bar.AbsolutePosition.X + bar.CanvasPosition.X
				local right = left + tab.AbsoluteSize.X
				local view = bar.AbsoluteWindowSize.X
				local pos = bar.CanvasPosition.X
				if left < pos then
					bar.CanvasPosition = Vector2New(MathMax(0, left - 6), 0)
				elseif right > pos + view then
					bar.CanvasPosition = Vector2New(MathMax(0, right - view + 6), 0)
				end
			end)
		end
	end

	function SubPage:Close()
		self.Active = false
		self.UI.Content.Visible = false
		if self.Page.ActiveSubPage == self then self.Page.ActiveSubPage = nil end

		local page = self.Page
		local any = false
		for i = 1, page.SubPagesIndex do
			if page.SubPages[i].Active then any = true; break end
		end
		if not any then
			if page.UI.SubHolder then page.UI.SubHolder.Visible = false end
			if page.UI.Columns then page.UI.Columns.Visible = true end
		end
		self.UI.Tab.ZIndex = 11
		self.UI.TabBg.ZIndex = 11
		Menu:Tween(self.UI.TabBg, nil, { BackgroundTransparency = 1 })
		Menu:Tween(self.UI.TabLiner, nil, {
			BackgroundTransparency = 1,
			Size = UDim2New(1, -SUBTAB_LINER_INSET * 2, 0, 0),
		})
		Menu:Tween(self.UI.TabText, nil, { TextTransparency = 0.4 })
	end

	function SubPage:Turn(bool)
		if bool then self:Open() else self:Close() end
	end

	function SubPage:CreateSection(parameters)
		return Menu.Classes.Section.new(self, parameters)
	end

	Menu.Classes.SubPage = SubPage
end

do
	local Section = {}
	Section.__index = Section

	function Section.new(page, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Section)
		self.Class = "Section"
		self.Page = page
		self.Window = page.Window
		self.Name = parameters.Name or parameters.name or "Section"
		self.Side = tonumber(parameters.Side or parameters.side or 1) or 1
		if self.Side < 0 then self.Side = 0 end
		if self.Side > 2 then self.Side = 2 end

		-- Side = 0 (full width) shares its column with the two-column layout,
		-- but that column starts Visible = false (only CreateServersPage used to
		-- flip it on manually). Without this, any Side = 0 section rendered into
		-- an invisible column and the tab looked empty. Switch the page over to
		-- whichever layout its most recently added section actually uses.
		local cols = page.ColumnsData
		if cols then
			if self.Side == 0 then
				if cols[1] then cols[1].Visible = false end
				if cols[2] then cols[2].Visible = false end
				if cols[0] then cols[0].Visible = true end
			else
				if cols[0] then cols[0].Visible = false end
				if cols[1] then cols[1].Visible = true end
				if cols[2] then cols[2].Visible = true end
			end
		end

		self.Collapsed = parameters.Collapsed ~= false
		self.UI = {}
		self.Elements = {}
		self.ElementsIndex = 0
		self.LayoutQueued = false
		self.Category = parameters.Category

		self:Draw()
		self:Connections()
		self:SetCollapsed(self.Collapsed)

		page.SectionsIndex = (page.SectionsIndex or 0) + 1
		return self
	end

	function Section:Draw()
		local UI = self.UI
		local col = self.Page.ColumnsData[self.Side] or self.Page.ColumnsData[1]

		UI.Section = Draw:Create("Frame", {
			Parent = col, Size = UDim2New(1, 0, 0, 28),
			BackgroundColor3 = Menu.Theme.Inline, BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
			Theme = { BackgroundColor3 = "Inline" },
		})
		corner(UI.Section, 5)

		UI.Header = Draw:Create("TextButton", {
			Parent = UI.Section, Size = UDim2New(1, 0, 0, 28),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3,
		})
		UI.Title = Draw:Create("TextLabel", {
			Parent = UI.Header, Size = UDim2New(0, 0, 0, 15), Position = UDim2New(0, 8, 0, 7),
			BackgroundTransparency = 1, Text = self.Name, TextColor3 = Menu.Theme.Text,
			TextSize = 14, FontFace = Menu.Font, AutomaticSize = Enum.AutomaticSize.X, ZIndex = 3,
			Theme = { TextColor3 = "Text" },
		})
		UI.Indicator = Draw:Create("ImageLabel", {
			Parent = UI.Header, Size = UDim2New(0, 23, 0, 23),
			Position = UDim2New(1, -15, 0.5, 0), AnchorPoint = Vector2New(0.5, 0.5),
			BackgroundTransparency = 1, Image = "rbxassetid://126603363478667",
			ImageColor3 = Menu.Theme.Text, ScaleType = Enum.ScaleType.Fit, ZIndex = 3,
			Theme = { ImageColor3 = "Text" },
		})
		UI.Line = Draw:Create("Frame", {
			Parent = UI.Section, Size = UDim2New(1, -16, 0, 1), Position = UDim2New(0, 8, 0, 28),
			BackgroundColor3 = Menu.Theme.Border, BorderSizePixel = 0, ZIndex = 3,
			Theme = { BackgroundColor3 = "Border" },
		})
		UI.ContentHolder = Draw:Create("Frame", {
			Parent = UI.Section, Size = UDim2New(1, -16, 0, 0), Position = UDim2New(0, 8, 0, 32),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 3,
		})
		UI.ContentFrame = Draw:Create("Frame", {
			Parent = UI.ContentHolder, Size = UDim2New(1, 0, 0, 0),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 3,
		})
		Draw:Create("UIPadding", {
			Parent = UI.ContentFrame, PaddingTop = UDimNew(0, 6), PaddingBottom = UDimNew(0, 6),
		})
		UI.ListLayout = Draw:Create("UIListLayout", {
			Parent = UI.ContentFrame, Padding = UDimNew(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		})
	end

	function Section:Repaint()
		self.UI.Section.BackgroundTransparency = 0
		self.UI.Section.BackgroundColor3 = Menu.Theme.Inline
	end

	function Section:Connections()
		self.UI.Header.MouseButton1Down:Connect(function()
			self:SetCollapsed(not self.Collapsed)
		end)
	end

	function Section:QueueUpdateLayout()
		if self.LayoutQueued then return end
		self.LayoutQueued = true
		defer(function()
			self.LayoutQueued = false
			self:Repaint()


			local cf = self.UI and self.UI.ContentFrame
			local ch = self.UI and self.UI.ContentHolder
			if cf and cf.AutomaticSize == Enum.AutomaticSize.Y then
				cf.Size = UDim2New(1, 0, 0, 0)
			end
			if ch and not self.Collapsed and ch.AutomaticSize == Enum.AutomaticSize.Y then
				ch.Size = UDim2New(1, -16, 0, 0)
			end
			local layout = self.UI and self.UI.ListLayout
			if layout then
				local _ = layout.AbsoluteContentSize
			end
		end)
	end

	function Section:SetCollapsed(bool)
		self.Collapsed = bool == true
		self.UI.Line.Visible = not self.Collapsed
		self:Repaint()
		local key = self.Collapsed and "Text" or "Accent"
		if Menu.ThemeMap[self.UI.Indicator] then
			Menu.ThemeMap[self.UI.Indicator].Properties.ImageColor3 = key
		end
		if self.Collapsed then
			Menu:Tween(self.UI.Indicator, nil, { Rotation = 0, ImageColor3 = Menu.Theme[key] })
			self.UI.ContentFrame.Visible = false
			self.UI.ContentHolder.AutomaticSize = Enum.AutomaticSize.None
			self.UI.ContentHolder.Size = UDim2New(1, -16, 0, 0)
		else
			Menu:Tween(self.UI.Indicator, nil, { Rotation = 90, ImageColor3 = Menu.Theme[key] })
			self.UI.ContentFrame.Visible = true
			self.UI.ContentHolder.AutomaticSize = Enum.AutomaticSize.Y
			self.UI.ContentHolder.Size = UDim2New(1, -16, 0, 0)
		end
		self:QueueUpdateLayout()
	end

	function Section:Push(element)
		element.Section = self
		element.Visible = true
		element.Category = self.Category
		self.ElementsIndex += 1
		self.Elements[self.ElementsIndex] = element
		self:QueueUpdateLayout()
		local owner = self.Page
		local search = Menu.SearchItems[owner]
		if search and element.UI and element.UI.Framework then
			local name = element.Title or element.Name or ""
			local is_sub = owner.Class == "SubPage"
			local page = is_sub and owner.Page or owner
			local subpage = is_sub and owner or nil
			local page_name = page and page.Name or ""
			local sub_name = subpage and subpage.Name or ""
			local path_label = page_name
			if sub_name ~= "" then
				path_label = page_name .. " > " .. sub_name
			end
			local entry = {
				Frame = element.UI.Framework,
				Element = element,
				Name = name,
				NameLower = StringLower(name),
				Section = self,
				Page = page,
				SubPage = subpage,
				PathLabel = path_label,
				SearchKey = StringLower(path_label .. " " .. name),
			}
			TableInsert(search, entry)
			TableInsert(Menu.GlobalSearchIndex, entry)
		end
		if element.Premium or (element.Callback and Library:IsPremiumPlaceholder(element.Callback)) then
			Library:ApplyPremiumVisual(element)
		end
		return element
	end

	function Section:CreateCheckbox(parameters)
		return self:Push(Menu.Classes.Checkbox.new({ ContentFrame = self.UI.ContentFrame, Category = self.Category, Style = "Checkbox" }, parameters))
	end
	function Section:CreateToggle(parameters)
		return self:Push(Menu.Classes.Checkbox.new({ ContentFrame = self.UI.ContentFrame, Category = self.Category, Style = "Toggle" }, parameters))
	end
	function Section:CreateDropdown(parameters)
		return self:Push(Menu.Classes.Dropdown.new({ ContentFrame = self.UI.ContentFrame, Category = self.Category }, parameters))
	end
	function Section:CreateSlider(parameters)
		return self:Push(Menu.Classes.Slider.new({ ContentFrame = self.UI.ContentFrame, Category = self.Category }, parameters))
	end
	function Section:CreateLabel(parameters)
		return self:Push(Menu.Classes.Label.new({ ContentFrame = self.UI.ContentFrame, Category = self.Category }, parameters))
	end
	function Section:CreateButton(parameters)
		return self:Push(Menu.Classes.Button.new({ ContentFrame = self.UI.ContentFrame, Category = self.Category }, parameters))
	end
	function Section:CreateTextbox(parameters)
		return self:Push(Menu.Classes.Textbox.new({ ContentFrame = self.UI.ContentFrame, Category = self.Category }, parameters))
	end
	function Section:CreateImageTextbox(parameters)
		return self:Push(Menu.Classes.ImageTextbox.new({ ContentFrame = self.UI.ContentFrame, Category = self.Category }, parameters))
	end
	function Section:CreateSubSlider(parameters)
		return self:Push(Menu.Classes.SubSlider.new({ ContentFrame = self.UI.ContentFrame, Category = self.Category }, parameters))
	end

	Menu.Classes.Section = Section
end

do
	local Checkbox = {}
	Checkbox.__index = Checkbox

	function Checkbox.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Checkbox)
		local style = config.Style or "Toggle"
		self.Class = style == "Checkbox" and "Checkbox" or "Toggle"
		self.Style = style
		self.Title = parameters.Title or parameters.Name or parameters.name or "Toggle"
		self.Description = parameters.Description or parameters.description
		self.Value = parameters.Value or parameters.Default or parameters.default or false
		self.Callback = parameters.Callback or parameters.callback or function() end
		self.Flag = parameters.Flag or parameters.flag
		self.ZIndex = 2
		self.Height = 22
		self.Visible = true
		self.Disabled = false
		self.VisibleChildren = {}
		self.UI = {}
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category
		self.Changed = { Fire = function() end }

		self:Draw()
		self:Connections()
		self:SetValue(self.Value, true)

		if self.Flag then
			Config:RegisterElement(self, self.Flag, self.Category, parameters.IgnoreConfig)
		end
		local tip = parameters.Tooltip or parameters.tooltip
		if tip and self.UI.Framework then
			Library:BindTooltip(self.UI.Framework, tip)
			self._premium_tip_bound = true
		end
		if Library:IsPremiumElement(parameters) then
			Library:ApplyPremiumVisual(self)
		end
		return self
	end

	function Checkbox:Draw()
		local UI = self.UI
		local has_desc = self.Description ~= nil and self.Description ~= ""

		UI.Framework = Draw:Create("TextButton", {
			Parent = self.ContentFrame,
			Size = has_desc and UDim2New(1, 0, 0, 0) or UDim2New(1, 0, 0, 22),
			BackgroundTransparency = 1,
			AutomaticSize = has_desc and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
			Text = "", AutoButtonColor = false, BorderSizePixel = 0,
			ClipsDescendants = true, ZIndex = 2,
		})

		UI.Text = Draw:Create("TextLabel", {
			Parent = UI.Framework,
			Size = UDim2New(1, -96, has_desc and 0 or 1, 0),
			Position = has_desc and UDim2New(0, 0, 0, 0) or UDim2New(0, 0, 0.5, 0),
			AnchorPoint = has_desc and Vector2New(0, 0) or Vector2New(0, 0.5),
			BackgroundTransparency = 1, Text = self.Title, TextColor3 = Menu.Theme.Text,
			TextSize = 16, FontFace = Menu.Font, TextTransparency = 0.4,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			AutomaticSize = has_desc and Enum.AutomaticSize.Y or Enum.AutomaticSize.None, ZIndex = 2,
			Theme = { TextColor3 = "Text" },
		})

		if self.Style == "Toggle" then
			UI.Indicator = Draw:Create("TextButton", {
				Parent = UI.Framework, Size = UDim2New(0, 40, 0, 22),
				Position = UDim2New(1, 0, 0.5, 0), AnchorPoint = Vector2New(1, 0.5),
				BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, Text = "",
				AutoButtonColor = false, ZIndex = 6, Theme = { BackgroundColor3 = "Element" },
			})
			local c = Instance.new("UICorner")
			c.CornerRadius = UDimNew(1, 0)
			set_instance_parent(c, UI.Indicator)
			element_gradient(UI.Indicator)
			UI.Circle = Draw:Create("Frame", {
				Parent = UI.Indicator, Size = UDim2New(0, 16, 0, 16),
				Position = UDim2New(0, 3, 0, 3), BackgroundTransparency = 0.4,
				BorderSizePixel = 0, Active = false, ZIndex = 6,
			})
			local cc = Instance.new("UICorner")
			cc.CornerRadius = UDimNew(1, 0)
			set_instance_parent(cc, UI.Circle)
			UI.SubElements = Draw:Create("Frame", {
				Parent = UI.Framework, Size = UDim2New(0, 0, 0, 0),
				Position = UDim2New(1, -48, 0.5, 0), AnchorPoint = Vector2New(1, 0.5),
				BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
				Active = false, ZIndex = 3,
			})
		else
			UI.Indicator = Draw:Create("TextButton", {
				Parent = UI.Framework, Size = UDim2New(0, 22, 0, 22),
				Position = UDim2New(1, 0, 0.5, 0), AnchorPoint = Vector2New(1, 0.5),
				BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, Text = "",
				AutoButtonColor = false, ZIndex = 6, Theme = { BackgroundColor3 = "Element" },
			})
			corner(UI.Indicator, 5)
			element_gradient(UI.Indicator)
			UI.Check = Draw:Create("ImageLabel", {
				Parent = UI.Indicator, Size = UDim2New(1, -2, 1, -2),
				Position = UDim2New(0.5, 0, 0.5, 0), AnchorPoint = Vector2New(0.5, 0.5),
				BackgroundTransparency = 1, Image = "rbxassetid://116339777575852",
				ImageColor3 = FromRGB(0, 0, 0), ImageTransparency = 1,
				ScaleType = Enum.ScaleType.Fit, Active = false, ZIndex = 6,
			})
			UI.SubElements = Draw:Create("Frame", {
				Parent = UI.Framework, Size = UDim2New(0, 0, 0, 0),
				Position = UDim2New(1, -30, 0.5, 0), AnchorPoint = Vector2New(1, 0.5),
				BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY,
				Active = false, ZIndex = 3,
			})
		end

		Draw:Create("UIListLayout", {
			Parent = UI.SubElements, Padding = UDimNew(0, self.Style == "Toggle" and 2 or 8),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
		})
		Draw:Create("UISizeConstraint", {
			Parent = UI.SubElements,
			MinSize = Vector2New(0, 22),
			MaxSize = Vector2New(1e5, 22),
		})

		if has_desc then
			Draw:Create("TextLabel", {
				Parent = UI.Framework, Size = UDim2New(1, -96, 0, 0), Position = UDim2New(0, 0, 0, 18),
				BackgroundTransparency = 1, Text = self.Description, TextColor3 = Menu.Theme.Text,
				TextSize = 12, FontFace = Menu.Font, TextTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
			})
		end
	end

	function Checkbox:Connections()
		local last_toggle_at = 0
		local function on_toggle()
			if self.Disabled or self.PremiumLocked then
				Library:GuardPremiumInteract(self)
				return
			end


			local now = os.clock()
			if now - last_toggle_at < 0.04 then return end
			last_toggle_at = now
			local ok, err = pcall(self.SetValue, self, not self.Value)
			if not ok then warn("[UILib Toggle]", err) end
		end
		run_with_elevated_thread_identity(function()
			if self.UI.Framework then
				self.UI.Framework.Active = true
				self.UI.Framework.AutoButtonColor = false
			end
			if self.UI.Indicator then
				self.UI.Indicator.Active = true
				self.UI.Indicator.AutoButtonColor = false
			end
			local function bind(gui)
				if not gui then return end
				gui.InputBegan:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					on_toggle()
				end)
			end
			bind(self.UI.Framework)
			bind(self.UI.Indicator)
		end)
	end

	function Checkbox:GetValue()
		return self.Value
	end

	function Checkbox:SetDisabled(bool)
		if self.PremiumLocked and bool ~= true then
			bool = true
		end
		self.Disabled = bool == true
		local text_t = self.Disabled and 0.6 or (self.Value and 0 or 0.4)
		local circle_t = self.Disabled and 0.6 or (self.Value and 0 or 0.4)
		local ind_t = self.Disabled and 0.6 or 0
		if self.UI.Text then Menu:Tween(self.UI.Text, nil, { TextTransparency = text_t }) end
		if self.UI.Circle then Menu:Tween(self.UI.Circle, nil, { BackgroundTransparency = circle_t }) end
		if self.UI.Indicator then Menu:Tween(self.UI.Indicator, nil, { BackgroundTransparency = ind_t }) end
		if self.UI.Check and self.Disabled then
			Menu:Tween(self.UI.Check, nil, { ImageTransparency = MathMax(self.UI.Check.ImageTransparency, 0.6) })
		end
	end

	function Checkbox:RegisterVisibleChildren(children)
		self.VisibleChildren = type(children) == "table" and children or {}
		return self
	end

	function Checkbox:SyncVisibleChildren(visible)
		if type(self.VisibleChildren) ~= "table" or #self.VisibleChildren == 0 then return end
		for i = 1, #self.VisibleChildren do
			local child = self.VisibleChildren[i]
			if type(child) == "table" then
				if type(child.SetVisible) == "function" then pcall(child.SetVisible, child, visible == true)
				elseif type(child.SetVisibility) == "function" then pcall(child.SetVisibility, child, visible == true) end
			end
		end
		if self.Section and self.Section.QueueUpdateLayout then self.Section:QueueUpdateLayout() end
	end

	function Checkbox:SetValue(value, silent)
		if self.PremiumLocked then
			value = false
			silent = true
		end
		self.Value = value == true
		if self.Flag then Menu.Flags[self.Flag] = self.Value end

		local key = self.Value and "Accent" or "Element"
		local accent = Menu.Theme[key] or Menu.Theme.Element
		local text_t = self.Disabled and 0.6 or (self.Value and 0 or 0.4)
		local circle_t = self.Disabled and 0.6 or (self.Value and 0 or 0.4)
		local check_t = self.Value and 0 or 1

		local circle_pos = self.Value and UDim2New(0, 21, 0, 3) or UDim2New(0, 3, 0, 3)
		local ind_t = self.Disabled and 0.6 or 0
		local animate = silent ~= true and Menu.LoadingConfig ~= true and (Menu.Silent or 0) <= 0
		local tween_time = (Menu.TweenSettings and Menu.TweenSettings.Time or 0.15) + 0.2

		if Menu.ThemeMap[self.UI.Indicator] then
			Menu.ThemeMap[self.UI.Indicator].Properties.BackgroundColor3 = key
		end

		self._VisualGen = (self._VisualGen or 0) + 1
		local gen = self._VisualGen

		local function apply_visual()
			if gen ~= self._VisualGen then return end
			safe_gui(function()
				if self.UI.Text then
					self.UI.Text.TextTransparency = text_t
				end
				if self.UI.Indicator then
					self.UI.Indicator.BackgroundColor3 = accent
					self.UI.Indicator.BackgroundTransparency = ind_t
				end
				if self.Style == "Toggle" then
					if self.UI.Circle then
						self.UI.Circle.AnchorPoint = Vector2New(0, 0)
						self.UI.Circle.Position = circle_pos
						self.UI.Circle.BackgroundTransparency = circle_t
					end
				elseif self.UI.Check then
					self.UI.Check.ImageTransparency = check_t
				end
			end)
		end

		if not animate then
			apply_visual()
		else
			if self.UI.Text then
				Menu:Tween(self.UI.Text, nil, { TextTransparency = text_t })
			end
			if self.UI.Indicator then
				Menu:Tween(self.UI.Indicator, nil, {
					BackgroundColor3 = accent,
					BackgroundTransparency = ind_t,
				})
			end
			local main_tw
			if self.Style == "Toggle" and self.UI.Circle then
				safe_gui(function()
					local c = self.UI.Circle
					c.AnchorPoint = Vector2New(0, 0)

					if c.Position.X.Scale ~= 0 then
						c.Position = self.Value and UDim2New(0, 3, 0, 3) or UDim2New(0, 23, 0, 3)
					end
				end)
				main_tw = Menu:Tween(self.UI.Circle, TweenInfo.new(tween_time, Enum.EasingStyle.Quart, Menu.TweenSettings.Direction), {
					Position = circle_pos,
					BackgroundTransparency = circle_t,
				})
			elseif self.UI.Check then
				main_tw = Menu:Tween(self.UI.Check, nil, { ImageTransparency = check_t })
			end

			if main_tw then
				main_tw.Completed:Connect(function()
					apply_visual()
				end)
			end
			task.delay(tween_time + 0.05, apply_visual)
		end


		if Menu.LoadingConfig ~= true and type(self.SyncVisibleChildren) == "function" then
			self:SyncVisibleChildren(self.Value)
		end

		if Menu:ShouldFire(silent) and type(self.Callback) == "function" then
			Library:SafeCall(self.Callback, self.Value)
		end
	end

	function Checkbox:SetVisible(bool)
		Library:ApplyElementVisibility(self, bool)
	end
	Checkbox.SetVisibility = Checkbox.SetVisible

	function Checkbox:CreateColorpicker(parameters)
		return Menu:Attach(self, "Colorpicker", parameters)
	end
	function Checkbox:CreateHotkey(parameters)
		return Menu:Attach(self, "Hotkey", parameters)
	end

	function Checkbox:Colorpicker(data) return self:CreateColorpicker(data) end
	function Checkbox:Keybind(data) return self:CreateHotkey(data) end
	function Checkbox:Hotkey(data) return self:CreateHotkey(data) end
	Checkbox.Set = Checkbox.SetValue
	Checkbox.Get = Checkbox.GetValue

	Menu.Classes.Checkbox = Checkbox
end

do
	local Slider = {}
	Slider.__index = Slider

	local function slider_frac_places(n)
		local s = StringFormat("%.12f", MathAbs(tonumber(n) or 0)):gsub("0+$", ""):gsub("%.$", "")
		local dot = string.find(s, ".", 1, true)
		return dot and MathClamp(#s - dot, 0, 8) or 0
	end


	local function slider_resolve_increment(parameters, min, max)
		local raw = parameters.Increment or parameters.increment or parameters.Step or parameters.step
		if raw == nil then raw = parameters.Decimals or parameters.decimals end
		raw = tonumber(raw)
		if raw == nil then
			local r = max - min
			return r <= 1 and 0.01 or (r <= 10 and 0.1 or 1)
		end
		if raw == 0 then return 1 end
		if raw < 0 then return 10 ^ (-raw) end
		return raw
	end

	local function slider_snap(value, min, max, increment, places)
		value = MathClamp(tonumber(value) or min, min, max)
		if not increment or increment <= 0 then return value end
		value = min + MathFloor((value - min) / increment + 0.5) * increment
		local mult = 10 ^ (places or 0)
		value = MathFloor(value * mult + 0.5) / mult
		return MathClamp(value, min, max)
	end

	function Slider.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Slider)
		self.Class = "Slider"
		self.Title = parameters.Title or parameters.Name or parameters.name or "Slider"
		self.Min = parameters.Min or parameters.min or 0
		self.Max = parameters.Max or parameters.max or 100
		self.Increment = slider_resolve_increment(parameters, self.Min, self.Max)
		self.Decimals = MathMax(slider_frac_places(self.Increment), slider_frac_places(self.Min))
		self.Suffix = parameters.Suffix or parameters.suffix or ""
		self.Compact = parameters.Compact ~= false
		self.Value = parameters.Value or parameters.Default or parameters.default or self.Min
		self.Callback = parameters.Callback or parameters.callback or function() end
		self.Flag = parameters.Flag or parameters.flag
		self.Height = self.Compact and 22 or 30
		self.Visible = true
		self.UI = {}
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category

		self:Draw()
		self:Connections()
		self:SetValue(self.Value, true)
		if self.Flag then Config:RegisterElement(self, self.Flag, self.Category, parameters.IgnoreConfig) end
		if Library:IsPremiumElement(parameters) then
			Library:ApplyPremiumVisual(self)
		end
		return self
	end

	function Slider:Draw()
		local UI = self.UI
		UI.Framework = Draw:Create("Frame", {
			Parent = self.ContentFrame, Size = UDim2New(1, 0, 0, 0),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
		})
		Draw:Create("UIListLayout", { Parent = UI.Framework, Padding = UDimNew(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })

		UI.Text = Draw:Create("TextLabel", {
			Parent = UI.Framework, Size = UDim2New(1, 0, 0, 16), BackgroundTransparency = 1,
			Text = self.Title, TextColor3 = Menu.Theme.Text, TextSize = 16, FontFace = Menu.Font,
			TextXAlignment = Enum.TextXAlignment.Left, Visible = not self.Compact, ZIndex = 4,
			Theme = { TextColor3 = "Text" },
		})
		if self.Compact then UI.Text.Size = UDim2New(1, 0, 0, 0) end

		UI.Row = Draw:Create("Frame", {
			Parent = UI.Framework, Size = UDim2New(1, 0, 0, self.Compact and 22 or 16),
			BackgroundTransparency = 1, ZIndex = 2,
		})
		Draw:Create("UIListLayout", {
			Parent = UI.Row, FillDirection = Enum.FillDirection.Horizontal, Padding = UDimNew(0, 5),
			VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
		})

		UI.Track = Draw:Create("TextButton", {
			Parent = UI.Row, Size = UDim2New(1, -60, 1, 0), BackgroundColor3 = Menu.Theme.Element,
			BorderSizePixel = 0, Text = "", ClipsDescendants = true, AutoButtonColor = false,
			ZIndex = 2, LayoutOrder = 0, Theme = { BackgroundColor3 = "Element" },
		})
		corner(UI.Track, 5)
		element_gradient(UI.Track)
		local flex = Instance.new("UIFlexItem"); flex.FlexMode = Enum.UIFlexMode.Fill; set_instance_parent(flex, UI.Track)

		UI.Fill = Draw:Create("Frame", {
			Parent = UI.Track, Size = UDim2New(0, 0, 1, 0), BackgroundColor3 = Menu.Theme.Accent,
			BorderSizePixel = 0, ZIndex = 2, Theme = { BackgroundColor3 = "Accent" },
		})
		corner(UI.Fill, 5)
		local fg = Instance.new("UIGradient"); fg.Rotation = 90
		fg.Color = CSNew({ CSK(0, FromRGB(255, 255, 255)), CSK(1, FromRGB(163, 163, 163)) })
		set_instance_parent(fg, UI.Fill)

		UI.Drag = Draw:Create("Frame", {
			Parent = UI.Fill, Size = UDim2New(0, 7, 1, 0),
			Position = UDim2New(1, 0, 0.5, 0), AnchorPoint = Vector2New(1, 0.5),
			BorderSizePixel = 0, ZIndex = 5,
		})
		corner(UI.Drag, 5)

		if self.Compact then
			UI.TrackLabel = Draw:Create("TextLabel", {
				Parent = UI.Track, Size = UDim2New(1, -12, 1, 0), BackgroundTransparency = 1,
				Text = self.Title, TextColor3 = Menu.Theme.Text, TextSize = 16, FontFace = Menu.Font,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
				Theme = { TextColor3 = "Text" },
			})
			Draw:Create("UIPadding", { Parent = UI.TrackLabel, PaddingLeft = UDimNew(0, 8), PaddingRight = UDimNew(0, 10) })
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 1; stroke.Color = FromRGB(0, 0, 0); stroke.Transparency = 0.35
			set_instance_parent(stroke, UI.TrackLabel)
		end

		UI.ValueBg = Draw:Create("Frame", {
			Parent = UI.Row, Size = UDim2New(0, 55, 1, 0), BackgroundColor3 = Menu.Theme.Element,
			BorderSizePixel = 0, ZIndex = 3, LayoutOrder = 1, Theme = { BackgroundColor3 = "Element" },
		})
		corner(UI.ValueBg, 5)
		UI.ValueBox = Draw:Create("TextBox", {
			Parent = UI.ValueBg, Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 1,
			Text = "", TextColor3 = Menu.Theme.Text, TextSize = 14, FontFace = Menu.Font,
			ClearTextOnFocus = false, ZIndex = 4, Theme = { TextColor3 = "Text" },
		})
	end

	function Slider:Connections()
		local handle = LPH_NO_VIRTUALIZE(function(input)
			if self.PremiumLocked or self.Disabled then return end
			local abs = self.UI.Track
			local x = MathClamp((input.Position.X - abs.AbsolutePosition.X) / MathMax(abs.AbsoluteSize.X, 1), 0, 1)
			self:SetValue(self.Min + (self.Max - self.Min) * x)
		end)

		self.UI.Track.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if Library:GuardPremiumInteract(self) or self.Disabled then return end
			handle(input)
			local mid, eid = "Slider.Move." .. tostring(self), "Slider.End." .. tostring(self)
			Hook:Add("Mouse.Move", mid, LPH_NO_VIRTUALIZE(function(inp) handle(inp) end))
			Hook:Add("InputEnded", eid, function(inp)
				if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
				Hook:Remove("Mouse.Move", mid)
				Hook:Remove("InputEnded", eid)
			end)
		end)

		self.UI.ValueBox.FocusLost:Connect(function()
			if Library:GuardPremiumInteract(self) or self.Disabled then
				self:SetValue(self.Value, true)
				return
			end
			local n = tonumber(self.UI.ValueBox.Text)
			if n then self:SetValue(n) else self:SetValue(self.Value, true) end
		end)
	end

	function Slider:GetValue() return self.Value end

	function Slider:SetValue(value, silent)
		if self.PremiumLocked then
			if not silent then return end
		end
		value = slider_snap(value, self.Min, self.Max, self.Increment, self.Decimals)
		self.Value = value
		if self.Flag then Menu.Flags[self.Flag] = value end
		local pct = (self.Max == self.Min) and 0 or ((value - self.Min) / (self.Max - self.Min))
		local text
		if self.Decimals <= 0 then
			text = StringFormat("%d", MathFloor(value + 0.5))
		else
			text = StringFormat("%." .. tostring(self.Decimals) .. "f", value)
			local dot = string.find(text, ".", 1, true)
			if dot then
				local frac = text:sub(dot + 1):gsub("0+$", "")
				text = frac == "" and text:sub(1, dot - 1) or (text:sub(1, dot) .. frac)
			end
		end
		safe_gui(function()
			self.UI.Fill.Size = UDim2New(pct, 0, 1, 0)
			self.UI.ValueBox.Text = text .. self.Suffix
			if self.Compact and self.UI.TrackLabel then
				self.UI.TrackLabel.Text = self.Title .. ": " .. text .. self.Suffix
			end
		end)
		if Menu:ShouldFire(silent) then Library:SafeCall(self.Callback, value) end
	end

	function Slider:SetVisible(bool)
		Library:ApplyElementVisibility(self, bool)
	end
	Slider.SetVisibility = Slider.SetVisible
	Slider.Set = Slider.SetValue
	Slider.Get = Slider.GetValue
	Menu.Classes.Slider = Slider
end

do
	local Dropdown = {}
	Dropdown.__index = Dropdown

	local HEADER_HEIGHT = 40
	local FOOTER_HEIGHT = 0
	local OPTION_HEIGHT = 25
	local OPTION_PADDING = 5
	local HOLDER_PADDING = 8
	local DROPDOWN_HEIGHT_CAP = 240

	local function dropdown_option_data(name, premium)
		local data = { Name = name, Selected = false, Premium = premium == true }
		function data:Toggle(_state) end
		return data
	end

	local function dropdown_parse_item(item)
		if type(item) == "table" then
			local name = item.Name or item.name or item.Value or item.value or item[1]
			if name == nil then return nil, false end
			return tostring(name), item.Premium == true or item.premium == true or item.Locked == true or item.locked == true
		end
		if item == nil then return nil, false end
		return tostring(item), false
	end

	local function dropdown_add_option(self, item)
		local name, premium = dropdown_parse_item(item)
		if not name or name == "" or name == "nil" then return nil end
		local existing = self.Options[name]
		if existing then
			if premium then existing.Premium = true end
			return name
		end
		self.OptionsIndex += 1
		self.OptionsOrder[self.OptionsIndex] = name
		self.Options[name] = dropdown_option_data(name, premium)
		return name
	end

	local function dropdown_is_premium_option(self, name)
		local data = self.Options[tostring(name)]
		return data ~= nil and data.Premium == true
	end

	local function dropdown_strip_premium_selection(self, value)
		if self.Multi then
			local out = {}
			if type(value) ~= "table" then
				if value ~= nil and not dropdown_is_premium_option(self, value) then
					out[1] = tostring(value)
				end
				return out
			end
			if #value > 0 then
				for i = 1, #value do
					local name = tostring(value[i])
					if name ~= "" and name ~= "nil" and not dropdown_is_premium_option(self, name) then
						out[#out + 1] = name
					end
				end
				return out
			end
			for k, v in next, value do
				if v == true and type(k) == "string" and not dropdown_is_premium_option(self, k) then
					out[#out + 1] = k
				elseif type(v) == "string" and not dropdown_is_premium_option(self, v) then
					out[#out + 1] = v
				end
			end
			return out
		end
		if type(value) == "table" then value = value[1] end
		if value == nil then return nil end
		value = tostring(value)
		if dropdown_is_premium_option(self, value) then return nil end
		return value
	end

	local function dropdown_sync_selected(self)
		for i = 1, self.OptionsIndex do
			local name = self.OptionsOrder[i]
			local data = self.Options[name]
			if data then
				if self.Multi then
					data.Selected = self.Value[name] == true
				else
					data.Selected = self.Value == name
				end
			end
		end
	end

	function Dropdown.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Dropdown)
		self.Class = "Dropdown"
		self.Title = parameters.Title or parameters.Name or parameters.name or "Dropdown"
		self.Description = parameters.Description or parameters.description
		self.Multi = parameters.Multi or parameters.multi or false
		self.Max = tonumber(parameters.Max or parameters.max)
		self.Options = {}
		self.OptionsOrder = {}
		self.OptionsIndex = 0
		self.Callback = parameters.Callback or parameters.callback or function() end
		self.Flag = parameters.Flag or parameters.flag
		self.Height = 40
		self.Visible = true
		self.IsOpen = false
		self.UI = {}
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category
		self.Value = self.Multi and {} or nil
		self.OptionButtons = {}

		local items = parameters.Items or parameters.items or { "One", "Two", "Three" }
		for i = 1, #items do
			dropdown_add_option(self, items[i])
		end

		local def = parameters.Value or parameters.Default or parameters.default
		if self.Multi then
			self.Value = {}
			if type(def) == "table" then
				if #def > 0 then
					for i = 1, #def do self.Value[tostring(def[i])] = true end
				else
					for k, v in next, def do
						if v == true and type(k) == "string" then
							self.Value[k] = true
						elseif type(v) == "string" then
							self.Value[v] = true
						end
					end
				end
			elseif def ~= nil then
				self.Value[tostring(def)] = true
			end
		else
			if type(def) == "table" then def = def[1] end
			self.Value = def ~= nil and tostring(def) or nil
		end

		self:Draw()
		self:Connections()
		self:SetValue(self.Multi and self:GetValue() or self.Value, true)
		if self.Flag then Config:RegisterElement(self, self.Flag, self.Category, parameters.IgnoreConfig) end
		if Library:IsPremiumElement(parameters) then
			Library:ApplyPremiumVisual(self)
		end
		return self
	end

	function Dropdown:Draw()
		local UI = self.UI
		UI.Framework = Draw:Create("Frame", {
			Parent = self.ContentFrame, Size = UDim2New(1, 0, 0, 0),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
		})
		Draw:Create("UIListLayout", { Parent = UI.Framework, Padding = UDimNew(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
		Draw:Create("UIPadding", { Parent = UI.Framework, PaddingTop = UDimNew(0, 0), PaddingBottom = UDimNew(0, 0) })

		UI.Text = Draw:Create("TextLabel", {
			Parent = UI.Framework, Size = UDim2New(1, 0, 0, 16), BackgroundTransparency = 1,
			Text = self.Title, TextColor3 = Menu.Theme.Text, TextSize = 16, FontFace = Menu.Font,
			TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 4,
			Theme = { TextColor3 = "Text" },
		})
		if self.Description and self.Description ~= "" then
			Draw:Create("TextLabel", {
				Parent = UI.Framework, Size = UDim2New(1, 0, 0, 0), BackgroundTransparency = 1,
				Text = self.Description, TextColor3 = Menu.Theme.Text, TextSize = 12, FontFace = Menu.Font,
				TextTransparency = 0.5, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2, Theme = { TextColor3 = "Text" },
			})
		end

		UI.Holder = Draw:Create("TextButton", {
			Parent = UI.Framework, Size = UDim2New(1, 0, 0, 25), BackgroundColor3 = Menu.Theme.Element,
			BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 2,
			Theme = { BackgroundColor3 = "Element" },
		})
		corner(UI.Holder, 5)
		element_gradient(UI.Holder)

		UI.Value = Draw:Create("TextLabel", {
			Parent = UI.Holder, Size = UDim2New(1, -25, 0, 16),
			Position = UDim2New(0, 8, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundTransparency = 1, Text = "...", TextColor3 = Menu.Theme.Text,
			TextSize = 16, FontFace = Menu.Font, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
			Theme = { TextColor3 = "Text" },
		})
		Draw:Create("UIGradient", {
			Parent = UI.Value,
			Transparency = NSNew({ NSK(0, 0), NSK(0.676, 0), NSK(1, 1) }),
		})
		UI.Arrow = Draw:Create("ImageLabel", {
			Parent = UI.Holder, Size = UDim2New(0, 23, 0, 23),
			Position = UDim2New(1, -13, 0.5, 0), AnchorPoint = Vector2New(0.5, 0.5),
			BackgroundTransparency = 1, Image = "rbxassetid://126603363478667",
			ImageColor3 = Menu.Theme.Text, ScaleType = Enum.ScaleType.Fit, ZIndex = 2,
			Theme = { ImageColor3 = "Text" },
		})
	end

	function Dropdown:Display()
		if self.Multi then
			local parts = {}
			for i = 1, self.OptionsIndex do
				local opt = self.OptionsOrder[i]
				if self.Value[opt] then TableInsert(parts, opt) end
			end
			return #parts > 0 and TableConcat(parts, ", ") or "..."
		end
		return self.Value and tostring(self.Value) or "..."
	end

	function Dropdown:GetValue()
		if self.Multi then
			local out = {}
			for i = 1, self.OptionsIndex do
				local opt = self.OptionsOrder[i]
				if self.Value[opt] then TableInsert(out, opt) end
			end
			return out
		end
		return self.Value
	end

	function Dropdown:SetValue(value, silent)
		if not silent then
			if self.Multi then
				local blocked = false
				if type(value) == "table" then
					if #value > 0 then
						for i = 1, #value do
							if dropdown_is_premium_option(self, value[i]) then blocked = true break end
						end
					else
						for k, v in next, value do
							if v == true and dropdown_is_premium_option(self, k) then blocked = true break end
							if type(v) == "string" and dropdown_is_premium_option(self, v) then blocked = true break end
						end
					end
				elseif value ~= nil and dropdown_is_premium_option(self, value) then
					blocked = true
				end
				if blocked then
					value = dropdown_strip_premium_selection(self, value)
				end
			else
				local check = value
				if type(check) == "table" then check = check[1] end
				if check ~= nil and dropdown_is_premium_option(self, check) then
					return
				end
			end
		else
			value = dropdown_strip_premium_selection(self, value)
		end

		if self.Multi then
			self.Value = {}
			if type(value) == "table" then
				local added = 0
				local max_n = self.Max
				if #value > 0 then
					for i = 1, #value do
						if max_n and added >= max_n then break end
						local name = tostring(value[i])
						if name ~= "" and name ~= "nil" and not dropdown_is_premium_option(self, name) then
							self.Value[name] = true
							added += 1
						end
					end
				else
					for k, v in next, value do
						if max_n and added >= max_n then break end
						if v == true and type(k) == "string" and k ~= "" and not dropdown_is_premium_option(self, k) then
							self.Value[k] = true
							added += 1
						elseif type(v) == "string" and v ~= "" and not dropdown_is_premium_option(self, v) then
							self.Value[v] = true
							added += 1
						end
					end
				end
			elseif value ~= nil then
				local name = tostring(value)
				if not dropdown_is_premium_option(self, name) then
					self.Value[name] = true
				end
			end
			dropdown_sync_selected(self)
			if self.Flag then Menu.Flags[self.Flag] = self:GetValue() end
		else
			if type(value) == "table" then value = value[1] end
			self.Value = value ~= nil and tostring(value) or nil
			if self.Value and dropdown_is_premium_option(self, self.Value) then
				self.Value = nil
			end
			dropdown_sync_selected(self)
			if self.Flag then Menu.Flags[self.Flag] = self.Value end
		end
		if self.UI.Value then
			local display = self:Display()
			safe_set(self.UI.Value, { Text = display })
		end
		if Menu:ShouldFire(silent) then self.Callback(self:GetValue()) end
	end

	function Dropdown:Close()
		if not self.IsOpen then return end
		self.IsOpen = false
		if Menu.CurrentContent == self then Menu.CurrentContent = nil end
		if self._pos_conn then
			pcall(function() self._pos_conn:Disconnect() end)
			self._pos_conn = nil
		end
		if self._size_conn then
			pcall(function() self._size_conn:Disconnect() end)
			self._size_conn = nil
		end
		run_with_elevated_thread_identity(function()
			if self.OpenUI then safe_destroy(self.OpenUI); self.OpenUI = nil end
			if self.Blocker then safe_destroy(self.Blocker); self.Blocker = nil end
			self.OptionButtons = {}
			if Menu.ThemeMap[self.UI.Arrow] then
				Menu.ThemeMap[self.UI.Arrow].Properties.ImageColor3 = "Text"
			end
			Menu:Tween(self.UI.Arrow, nil, { Rotation = 0, ImageColor3 = Menu.Theme.Text })
		end)
	end

	function Dropdown:Open()
		if Library:GuardPremiumInteract(self) or self.Disabled then return end
		run_with_elevated_thread_identity(function()
			if self.OptionsIndex == 0 then return end
			Menu:CloseCurrent()
			Menu.CurrentContent = self
			self.IsOpen = true
			if Menu.ThemeMap[self.UI.Arrow] then
				Menu.ThemeMap[self.UI.Arrow].Properties.ImageColor3 = "Accent"
			end
			Menu:Tween(self.UI.Arrow, nil, { Rotation = 90, ImageColor3 = Menu.Theme.Accent })
		end)
		if not self.IsOpen then return end

		local holder = self.UI.Holder
		local size = holder.AbsoluteSize
		local visible = MathMin(self.OptionsIndex, 8)
		local list_h = visible * OPTION_HEIGHT + MathMax(0, visible - 1) * OPTION_PADDING + HOLDER_PADDING
		list_h = MathMin(list_h, DROPDOWN_HEIGHT_CAP - HEADER_HEIGHT - FOOTER_HEIGHT)
		local total_h = HEADER_HEIGHT + list_h + FOOTER_HEIGHT

		local blocker = Draw:Create("TextButton", {
			Parent = Menu.Overlay, Size = UDim2New(1, 0, 1, 0),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 240,
		})
		self.Blocker = blocker

		local fw = Draw:Create("TextButton", {
			Parent = Menu.Overlay,
			Size = UDim2New(0, size.X, 0, total_h),
			Position = UDim2New(0, 0, 0, 0),
			BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0,
			Text = "", AutoButtonColor = false, ClipsDescendants = true, ZIndex = 250,
			Theme = { BackgroundColor3 = "Element" },
		})
		corner(fw, 5)
		ui_dual_stroke(fw)
		self.OpenUI = fw

		local search = Draw:Create("Frame", {
			Parent = fw, Size = UDim2New(1, -16, 0, 30), Position = UDim2New(0, 8, 0, 8),
			BackgroundColor3 = Menu.Theme.Inline, BorderSizePixel = 0, ZIndex = 251,
			Theme = { BackgroundColor3 = "Inline" },
		})
		corner(search, 5)
		Draw:Create("ImageLabel", {
			Parent = search, Size = UDim2New(0, 20, 0, 20),
			Position = UDim2New(0, 8, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundTransparency = 1, Image = "rbxassetid://71924825350727",
			ImageTransparency = 0.4, ScaleType = Enum.ScaleType.Fit, ZIndex = 252,
		})
		local input = Draw:Create("TextBox", {
			Parent = search, Size = UDim2New(1, -43, 0, 16),
			Position = UDim2New(0, 35, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundTransparency = 1, Text = "", PlaceholderText = "Search..",
			TextColor3 = Menu.Theme.Text, PlaceholderColor3 = Menu.Theme["Inactive Text"],
			TextSize = 16, FontFace = Menu.Font, TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false, ZIndex = 252,
			Theme = { TextColor3 = "Text", PlaceholderColor3 = "Inactive Text" },
		})

		local scroll = Draw:Create("ScrollingFrame", {
			Parent = fw, Size = UDim2New(1, -16, 0, list_h), Position = UDim2New(0, 8, 0, HEADER_HEIGHT),
			BackgroundTransparency = 1, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2New(0, 0, 0, 0), ScrollBarThickness = IsMobile and 6 or 3,
			ScrollBarImageColor3 = Menu.Theme.Accent, ZIndex = 251,
			Active = true, ScrollingEnabled = true, Selectable = false,
			TopImage = "rbxassetid://128693616966482", MidImage = "rbxassetid://128693616966482",
			BottomImage = "rbxassetid://128693616966482",
			Theme = { ScrollBarImageColor3 = "Accent" },
		})
		Draw:Create("UIListLayout", { Parent = scroll, Padding = UDimNew(0, OPTION_PADDING), SortOrder = Enum.SortOrder.LayoutOrder })
		Draw:Create("UIPadding", {
			Parent = scroll, PaddingTop = UDimNew(0, 5), PaddingBottom = UDimNew(0, 5),
			PaddingLeft = UDimNew(0, 0), PaddingRight = UDimNew(0, 0),
		})

		local function set_option_visual(btn, label, active)
			if active then
				btn.BackgroundTransparency = 0
				label.TextTransparency = 0
				label.Position = UDim2New(0, 8, 0, 0)
			else
				btn.BackgroundTransparency = 1
				label.TextTransparency = 0.4
				label.Position = UDim2New(0, 4, 0, 0)
			end
		end

		local TAP_MOVE_PX = IsMobile and 14 or 8

		for i = 1, self.OptionsIndex do
			local opt = self.OptionsOrder[i]
			local data = self.Options[opt]
			local is_premium_opt = data and data.Premium == true
			local chosen = self.Multi and self.Value[opt] == true or self.Value == opt
			local btn = Draw:Create("TextButton", {
				Parent = scroll, Size = UDim2New(1, 0, 0, OPTION_HEIGHT),
				BackgroundColor3 = Menu.Theme.Inline, BackgroundTransparency = 1,
				BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 252,
				Theme = { BackgroundColor3 = "Inline" },
			})
			corner(btn, 5)
			local label = Draw:Create("TextLabel", {
				Parent = btn, Size = UDim2New(1, -15, 1, 0), Position = UDim2New(0, 4, 0, 0),
				BackgroundTransparency = 1,
				Text = is_premium_opt and (opt .. " (Premium)") or opt,
				TextColor3 = is_premium_opt and Menu.Theme.Accent or Menu.Theme.Text,
				TextSize = 16, FontFace = Menu.Font, TextTransparency = 0.4,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 253,
				Theme = { TextColor3 = is_premium_opt and "Accent" or "Text" },
			})
			set_option_visual(btn, label, chosen and not is_premium_opt)
			self.OptionButtons[i] = { Button = btn, Label = label, Name = opt, Premium = is_premium_opt }

			local function select_option()
				if is_premium_opt then
					Library:NotifyPremiumFeature()
					return
				end
				if self.Multi then
					local next_state = not self.Value[opt]
					if next_state and self.Max then
						local count = 0
						for j = 1, self.OptionsIndex do
							if self.Value[self.OptionsOrder[j]] then count += 1 end
						end
						if count >= self.Max then return end
					end
					self.Value[opt] = next_state
					if data then
						data.Selected = self.Value[opt] == true
						if type(data.Toggle) == "function" then
							pcall(data.Toggle, data, self.Value[opt] and "Active" or "Inactive")
						end
					end
					set_option_visual(btn, label, self.Value[opt] == true)
					self:SetValue(self:GetValue(), false)
				else
					self:SetValue(opt, false)
					self:Close()
				end
			end


			local press_pos, press_canvas
			btn.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				press_pos = Vector2New(input.Position.X, input.Position.Y)
				press_canvas = scroll.CanvasPosition
			end)
			btn.InputEnded:Connect(elevate_callback(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				if not press_pos then return end
				local release = Vector2New(input.Position.X, input.Position.Y)
				local moved = (release - press_pos).Magnitude
				local scrolled = (scroll.CanvasPosition - press_canvas).Magnitude
				press_pos = nil
				press_canvas = nil
				if moved > TAP_MOVE_PX or scrolled > 2 then return end
				select_option()
			end))
		end

		input:GetPropertyChangedSignal("Text"):Connect(elevate_callback(function()
			local q = StringLower(input.Text)
			for i = 1, #self.OptionButtons do
				local e = self.OptionButtons[i]
				e.Button.Visible = q == "" or StringFind(StringLower(e.Name), q, 1, true) ~= nil
			end
		end))

		blocker.MouseButton1Down:Connect(elevate_callback(function() self:Close() end))
		fw.MouseButton1Down:Connect(function() end)

		local function sync_pos()
			if not self.IsOpen or not fw or not fw.Parent then return end
			local a = holder.AbsolutePosition
			local s = holder.AbsoluteSize
			local vp = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2New(1920, 1080)
			local y = a.Y + s.Y + 1
			if y + total_h > vp.Y - 8 then y = MathMax(8, a.Y - total_h - 1) end
			local x = a.X
			if x + s.X > vp.X - 8 then x = MathMax(8, vp.X - s.X - 8) end
			fw.Position = UDim2New(0, x, 0, y)
			fw.Size = UDim2New(0, s.X, 0, total_h)
		end
		sync_pos()
		self._pos_conn = holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(sync_pos)
		self._size_conn = holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync_pos)
	end

	function Dropdown:Connections()
		self.UI.Holder.MouseButton1Down:Connect(function()
			if Library:GuardPremiumInteract(self) or self.Disabled then return end
			if self.IsOpen then self:Close() else self:Open() end
		end)
	end

	function Dropdown:Refresh(list)
		TableClear(self.Options)
		TableClear(self.OptionsOrder)
		self.OptionsIndex = 0
		list = list or {}
		for i = 1, #list do
			dropdown_add_option(self, list[i])
		end
		if self.Multi then
			local keep = {}
			for name in next, self.Value do
				if self.Options[name] then keep[name] = true end
			end
			self.Value = keep
		elseif self.Value and not self.Options[self.Value] then
			self.Value = nil
		end
		dropdown_sync_selected(self)
		if self.UI.Value then
			safe_set(self.UI.Value, { Text = self:Display() })
		end
		if self.IsOpen then self:Close() end
	end

	function Dropdown:Add(opt)
		dropdown_add_option(self, opt)
	end

	function Dropdown:Remove(opt)
		opt = tostring(opt)
		if not self.Options[opt] then return end
		self.Options[opt] = nil
		local order, idx = {}, 0
		for i = 1, self.OptionsIndex do
			local name = self.OptionsOrder[i]
			if name ~= opt then
				idx += 1
				order[idx] = name
			end
		end
		self.OptionsOrder = order
		self.OptionsIndex = idx
		if self.Multi then
			self.Value[opt] = nil
		elseif self.Value == opt then
			self.Value = nil
		end
		dropdown_sync_selected(self)
		if self.UI.Value then
			safe_set(self.UI.Value, { Text = self:Display() })
		end
		if self.IsOpen then self:Close() end
	end

	function Dropdown:SetVisible(bool)
		Library:ApplyElementVisibility(self, bool)
	end
	Dropdown.SetVisibility = Dropdown.SetVisible
	Dropdown.Set = Dropdown.SetValue
	Dropdown.Get = Dropdown.GetValue
	Dropdown.SetOpen = function(self, bool) if bool then self:Open() else self:Close() end end
	Menu.Classes.Dropdown = Dropdown
end

do
	local Label = {}
	Label.__index = Label

	function Label.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Label)
		self.Class = "Label"
		self.Title = parameters.Title or parameters.Name or parameters.name or parameters.Text or "Label"
		self.Description = parameters.Description or parameters.description
		self.DescriptionColor = parameters.DescriptionColor or parameters.description_color
		self.Height = 18
		self.Visible = true
		self.UI = {}
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category
		self:Draw()
		local tip = parameters.Tooltip or parameters.tooltip
		if tip and self.UI.Framework then
			Library:BindTooltip(self.UI.Framework, tip)
			self._premium_tip_bound = true
		end
		if Library:IsPremiumElement(parameters) then
			Library:ApplyPremiumVisual(self)
		end
		return self
	end

	function Label:Draw()
		local UI = self.UI
		local has_desc = self.Description ~= nil and self.Description ~= ""
		UI.Framework = Draw:Create("Frame", {
			Parent = self.ContentFrame, Size = UDim2New(1, 0, 0, 0),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
		})
		-- Title and Description live in their own vertically-stacked holder so the
		-- description can never render on top of the title (it used to: both were
		-- direct children of Framework at Position (0,0) with nothing stacking them).
		UI.TextHolder = Draw:Create("Frame", {
			Parent = UI.Framework, Size = UDim2New(1, -50, 0, 0),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
		})
		Draw:Create("UIListLayout", {
			Parent = UI.TextHolder, SortOrder = Enum.SortOrder.LayoutOrder,
		})
		UI.Text = Draw:Create("TextLabel", {
			Parent = UI.TextHolder, Size = UDim2New(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = self.Title, TextColor3 = Menu.Theme.Text,
			TextSize = 16, FontFace = Menu.Font, TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true, ZIndex = 2, Theme = { TextColor3 = "Text" },
		})
		if has_desc then
			local desc_color = self.DescriptionColor or Menu.Theme.Text
			UI.Description = Draw:Create("TextLabel", {
				Parent = UI.TextHolder, Size = UDim2New(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1, Text = self.Description, TextColor3 = desc_color,
				TextSize = 12, FontFace = Menu.Font, TextTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 2,
			})
			if not self.DescriptionColor then
				Menu:AddToTheme(UI.Description, { TextColor3 = "Text" })
			end
		end
		UI.SubElements = Draw:Create("Frame", {
			Parent = UI.Framework, Size = UDim2New(0, 0, 0, 0),
			Position = UDim2New(1, 0, 0, 0), AnchorPoint = Vector2New(1, 0),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, ZIndex = 3,
		})
		Draw:Create("UIListLayout", {
			Parent = UI.SubElements, FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDimNew(0, 2),
		})
	end

	function Label:SetText(t)
		self.Title = t
		safe_set(self.UI.Text, { Text = t })
	end
	function Label:SetTextColor(Color)
		if not self.UI.Text then return end
		if type(Color) == "table" then
			Color = FromRGB(Color[1], Color[2], Color[3])
		elseif type(Color) == "string" then
			Color = FromHex(Color)
		end
		safe_set(self.UI.Text, { TextColor3 = Color })
	end
	function Label:SetValue() end
	function Label:GetValue() return self.Title end
	function Label:CreateColorpicker(p) return Menu:Attach(self, "Colorpicker", p) end
	function Label:CreateHotkey(p) return Menu:Attach(self, "Hotkey", p) end
	function Label:Colorpicker(d) return self:CreateColorpicker(d) end
	function Label:Keybind(d) return self:CreateHotkey(d) end
	function Label:Hotkey(d) return self:CreateHotkey(d) end
	function Label:SetVisible(bool)
		Library:ApplyElementVisibility(self, bool)
	end
	Label.SetVisibility = Label.SetVisible
	Menu.Classes.Label = Label
end

do
	local Button = {}
	Button.__index = Button

	function Button.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Button)
		self.Class = "Button"
		self.Height = 22
		self.Visible = true
		self.UI = {}
		self.Buttons = {}
		self.ButtonsIndex = 0
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category
		self:Draw()
		local name = parameters.Name or parameters.name or parameters.Title
		if name ~= nil and name ~= "" then
			self:Add(tostring(name), parameters.Callback or parameters.callback)
		end
		return self
	end

	function Button:Draw()


		self.UI.Framework = Draw:Create("Frame", {
			Parent = self.ContentFrame, Size = UDim2New(1, 0, 0, 22),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
		})
		Draw:Create("UIListLayout", {
			Parent = self.UI.Framework, FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDimNew(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
		})
	end

	function Button:SetVisible(bool)
		Library:ApplyElementVisibility(self, bool)
	end
	Button.SetVisibility = Button.SetVisible

	function Button:Add(name, callback)
		self.ButtonsIndex += 1
		local btn
		run_with_elevated_thread_identity(function()
			btn = Draw:Create("TextButton", {
				Parent = self.UI.Framework, Size = UDim2New(1, 0, 0, 22),
				BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, Text = "",
				AutoButtonColor = false, ZIndex = 2, Theme = { BackgroundColor3 = "Element" },
			})
			corner(btn, 5)
			element_gradient(btn)
			Draw:Create("TextLabel", {
				Parent = btn, Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 1,
				Text = name or "Button", TextColor3 = Menu.Theme.Text, TextSize = 16,
				FontFace = Menu.Font, ZIndex = 2, Theme = { TextColor3 = "Text" },
			})
			btn.MouseButton1Down:Connect(function()
				Menu:Tween(btn, TweenInfo.new(0.1), { BackgroundColor3 = Menu.Theme.Accent })
				delay(0.1, function()
					Menu:Tween(btn, nil, { BackgroundColor3 = Menu.Theme.Element })
				end)
				if callback then callback() end
			end)
		end)
		self.Buttons[self.ButtonsIndex] = btn
		if self.Section and self.Section.QueueUpdateLayout then
			self.Section:QueueUpdateLayout()
		end
		return self
	end

	function Button:SetValue() end
	function Button:GetValue() end
	Menu.Classes.Button = Button
end

do
	local Textbox = {}
	Textbox.__index = Textbox

	function Textbox.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Textbox)
		self.Class = "Textbox"
		self.Title = parameters.Title or parameters.Name or parameters.name or "Textbox"
		self.Description = parameters.Description or parameters.description
		self.Placeholder = parameters.Placeholder or parameters.placeholder or ""
		self.Finished = parameters.Finished or parameters.finished or false
		self.Value = tostring(parameters.Value or parameters.Default or parameters.default or "")
		self.Callback = parameters.Callback or parameters.callback or function() end
		self.Flag = parameters.Flag or parameters.flag
		self.Height = 48
		self.Visible = true
		self.UI = {}
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category
		self:Draw()
		self:Connections()
		self:SetValue(self.Value, true)
		if self.Flag then Config:RegisterElement(self, self.Flag, self.Category, parameters.IgnoreConfig) end
		if Library:IsPremiumElement(parameters) then
			Library:ApplyPremiumVisual(self)
		end
		return self
	end

	function Textbox:Draw()
		local UI = self.UI
		UI.Framework = Draw:Create("Frame", {
			Parent = self.ContentFrame, Size = UDim2New(1, 0, 0, 0),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
		})
		Draw:Create("UIListLayout", { Parent = UI.Framework, Padding = UDimNew(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
		Draw:Create("TextLabel", {
			Parent = UI.Framework, Size = UDim2New(1, 0, 0, 16), BackgroundTransparency = 1,
			Text = self.Title, TextColor3 = Menu.Theme.Text, TextSize = 16, FontFace = Menu.Font,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Theme = { TextColor3 = "Text" },
		})
		if self.Description and self.Description ~= "" then
			Draw:Create("TextLabel", {
				Parent = UI.Framework, Size = UDim2New(1, 0, 0, 0), BackgroundTransparency = 1,
				Text = self.Description, TextColor3 = Menu.Theme.Text, TextSize = 12, FontFace = Menu.Font,
				TextTransparency = 0.5, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2, Theme = { TextColor3 = "Text" },
			})
		end
		UI.Input = Draw:Create("TextBox", {
			Parent = UI.Framework, Size = UDim2New(1, 0, 0, 28), BackgroundColor3 = Menu.Theme.Element,
			BorderSizePixel = 0, Text = "", PlaceholderText = self.Placeholder,
			TextColor3 = Menu.Theme.Text, PlaceholderColor3 = Menu.Theme["Inactive Text"],
			TextSize = 16, FontFace = Menu.Font, ClearTextOnFocus = false, ZIndex = 2,
			TextXAlignment = Enum.TextXAlignment.Left,
			Theme = { BackgroundColor3 = "Element", TextColor3 = "Text", PlaceholderColor3 = "Inactive Text" },
		})
		corner(UI.Input, 5)
		element_gradient(UI.Input)
		Draw:Create("UIPadding", { Parent = UI.Input, PaddingLeft = UDimNew(0, 8), PaddingRight = UDimNew(0, 8) })
	end

	function Textbox:Connections()
		if self.Finished then
			self.UI.Input.FocusLost:Connect(function()
				if Library:GuardPremiumInteract(self) or self.Disabled then
					safe_set(self.UI.Input, { Text = self.Value })
					return
				end
				self:SetValue(self.UI.Input.Text)
			end)
		else
			self.UI.Input:GetPropertyChangedSignal("Text"):Connect(function()
				if Library:GuardPremiumInteract(self) or self.Disabled then
					safe_set(self.UI.Input, { Text = self.Value })
					return
				end
				self:SetValue(self.UI.Input.Text)
			end)
		end
	end

	function Textbox:GetValue() return self.Value end
	function Textbox:SetValue(value, silent)
		if self.PremiumLocked then
			if not silent then
				safe_set(self.UI.Input, { Text = self.Value })
				return
			end
		end
		self.Value = tostring(value or "")
		safe_set(self.UI.Input, { Text = self.Value })
		if self.Flag then Menu.Flags[self.Flag] = self.Value end
		if Menu:ShouldFire(silent) then self.Callback(self.Value) end
	end
	function Textbox:SetDisabled(bool)
		if self.PremiumLocked and bool ~= true then
			bool = true
		end
		self.Disabled = bool == true
		pcall(function() self.UI.Input.TextEditable = not self.Disabled end)
	end
	function Textbox:SetVisible(bool)
		Library:ApplyElementVisibility(self, bool)
	end
	Textbox.SetVisibility = Textbox.SetVisible
	Textbox.Set = Textbox.SetValue
	Textbox.Get = Textbox.GetValue
	Menu.Classes.Textbox = Textbox
end

do
	local ImageTextbox = {}
	ImageTextbox.__index = ImageTextbox

	function ImageTextbox.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, ImageTextbox)
		self.Class = "ImageTextbox"
		self.Title = parameters.Title or parameters.Name or parameters.name or "Image"
		self.Description = parameters.Description or parameters.description
		self.Placeholder = parameters.Placeholder or parameters.placeholder or "url or rbxassetid"
		self.Finished = parameters.Finished ~= false
		self.Preview = parameters.Preview ~= false
		self.PreviewHeight = parameters.PreviewHeight or parameters.preview_height or 140
		self.Value = tostring(parameters.Value or parameters.Default or parameters.default or "")
		self.Callback = parameters.Callback or parameters.callback or function() end
		self.Flag = parameters.Flag or parameters.flag
		self.Height = self.Preview and (48 + self.PreviewHeight) or 48
		self.Visible = true
		self.Disabled = false
		self.PreviewToken = 0
		self.UI = {}
		self.Items = {}
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category
		self:Draw()
		self:Connections()
		self:SetValue(self.Value, true)
		if self.Flag then Config:RegisterElement(self, self.Flag, self.Category, parameters.IgnoreConfig) end
		if Library:IsPremiumElement(parameters) then
			Library:ApplyPremiumVisual(self)
		end
		return self
	end

	function ImageTextbox:Draw()
		local UI = self.UI
		UI.Framework = Draw:Create("Frame", {
			Parent = self.ContentFrame, Size = UDim2New(1, 0, 0, 0),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
		})
		Draw:Create("UIListLayout", { Parent = UI.Framework, Padding = UDimNew(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
		UI.Text = Draw:Create("TextLabel", {
			Parent = UI.Framework, Size = UDim2New(1, 0, 0, 0), BackgroundTransparency = 1,
			Text = self.Title, TextColor3 = Menu.Theme.Text, TextSize = 16, FontFace = Menu.Font,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 4, Theme = { TextColor3 = "Text" },
		})
		if self.Description and self.Description ~= "" then
			Draw:Create("TextLabel", {
				Parent = UI.Framework, Size = UDim2New(1, 0, 0, 0), BackgroundTransparency = 1,
				Text = self.Description, TextColor3 = Menu.Theme.Text, TextSize = 12, FontFace = Menu.Font,
				TextTransparency = 0.5, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2, Theme = { TextColor3 = "Text" },
			})
		end
		UI.Bg = Draw:Create("Frame", {
			Parent = UI.Framework, Size = UDim2New(1, 0, 0, 25), BackgroundColor3 = Menu.Theme.Element,
			BorderSizePixel = 0, ZIndex = 2, Theme = { BackgroundColor3 = "Element" },
		})
		corner(UI.Bg, 5)
		element_gradient(UI.Bg)
		UI.Input = Draw:Create("TextBox", {
			Parent = UI.Bg, Size = UDim2New(1, -16, 1, 0), Position = UDim2New(0, 8, 0, 0),
			BackgroundTransparency = 1, Text = "", PlaceholderText = self.Placeholder,
			TextColor3 = Menu.Theme.Text, PlaceholderColor3 = Menu.Theme["Inactive Text"],
			TextSize = 16, FontFace = Menu.Font, ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2,
			Theme = { TextColor3 = "Text", PlaceholderColor3 = "Inactive Text" },
		})
		if self.Preview then
			UI.PreviewBg = Draw:Create("Frame", {
				Parent = UI.Framework, Size = UDim2New(1, 0, 0, 0),
				BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, ClipsDescendants = true,
				Visible = false, ZIndex = 2, Theme = { BackgroundColor3 = "Element" },
			})
			corner(UI.PreviewBg, 5)
			UI.PreviewImage = Draw:Create("ImageLabel", {
				Parent = UI.PreviewBg, Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 1,
				Image = "", ImageTransparency = 1, ScaleType = Enum.ScaleType.Crop, ZIndex = 3,
			})
			UI.PreviewLabel = Draw:Create("TextLabel", {
				Parent = UI.PreviewBg, Size = UDim2New(1, -8, 1, 0), Position = UDim2New(0, 4, 0, 0),
				BackgroundTransparency = 1, Text = "image preview", TextColor3 = Menu.Theme["Inactive Text"],
				TextSize = 12, FontFace = Menu.Font, Visible = false, ZIndex = 3,
				Theme = { TextColor3 = "Inactive Text" },
			})
		end


		self.Items = {
			Input = { Instance = UI.Input },
			Background = { Instance = UI.Bg },
			Text = { Instance = UI.Text },
			PreviewBackground = UI.PreviewBg and { Instance = UI.PreviewBg } or nil,
			PreviewImage = UI.PreviewImage and { Instance = UI.PreviewImage } or nil,
			PreviewPlaceholder = UI.PreviewLabel and { Instance = UI.PreviewLabel } or nil,
		}
	end

	function ImageTextbox:_SetPreviewPlaceholder(text, visible)
		if not self.Preview or not self.UI.PreviewLabel then return end
		safe_gui(function()
			self.UI.PreviewLabel.Text = text or "image preview"
			self.UI.PreviewLabel.Visible = visible == true
		end)
	end

	function ImageTextbox:_SetPreviewCollapsed(collapsed)
		if not self.Preview or not self.UI.PreviewBg then return end
		safe_gui(function()
			if collapsed then
				self.UI.PreviewBg.Visible = false
				self.UI.PreviewBg.Size = UDim2New(1, 0, 0, 0)
			else
				self.UI.PreviewBg.Visible = true
				self.UI.PreviewBg.Size = UDim2New(1, 0, 0, self.PreviewHeight)
			end
		end)
		if self.Section then self.Section:QueueUpdateLayout() end
	end

	function ImageTextbox:_ClearPreview()
		if not self.Preview then return end
		safe_gui(function()
			self.UI.PreviewImage.Image = ""
			self.UI.PreviewImage.ImageTransparency = 1
		end)
		self:_SetPreviewPlaceholder("image preview", false)
		self:_SetPreviewCollapsed(true)
	end

	function ImageTextbox:_ApplyPreviewImage(image_id)
		if not self.Preview or type(image_id) ~= "string" or image_id == "" then return end
		self:_SetPreviewCollapsed(false)
		safe_gui(function()
			self.UI.PreviewImage.Image = image_id
			self.UI.PreviewImage.ImageTransparency = 0
		end)
		self:_SetPreviewPlaceholder(nil, false)
	end

	function ImageTextbox:UpdatePreview(value)
		if not self.Preview then return end
		local string_value = Library:TrimImageTextboxInput(value)
		if not Library:IsValidImageTextboxInput(string_value) then
			self:_ClearPreview()
			return
		end

		self.PreviewToken = self.PreviewToken + 1
		local preview_token = self.PreviewToken
		local numeric_id = string_value:match("^(%d+)$") or string_value:match("^rbxassetid://(%d+)")
		if numeric_id then
			self:_ApplyPreviewImage("rbxassetid://" .. numeric_id)
			return
		end

		self:_SetPreviewCollapsed(false)
		self:_SetPreviewPlaceholder("loading...", true)
		safe_gui(function()
			self.UI.PreviewImage.ImageTransparency = 1
		end)
		task.spawn(function()
			local image_id = Library:ResolveImageTextboxPreview(string_value)
			if self.PreviewToken ~= preview_token then return end
			if type(image_id) == "string" and image_id ~= "" then
				self:_ApplyPreviewImage(image_id)
			else
				safe_gui(function()
					self.UI.PreviewImage.Image = ""
					self.UI.PreviewImage.ImageTransparency = 1
				end)
				self:_SetPreviewPlaceholder("failed to load", true)
				self:_SetPreviewCollapsed(false)
			end
		end)
	end

	function ImageTextbox:Connections()
		if self.Finished then
			self.UI.Input.FocusLost:Connect(function()
				if Library:GuardPremiumInteract(self) or self.Disabled then
					safe_set(self.UI.Input, { Text = self.Value })
					return
				end
				self:SetValue(self.UI.Input.Text)
			end)
		else
			self.UI.Input:GetPropertyChangedSignal("Text"):Connect(function()
				if Library:GuardPremiumInteract(self) or self.Disabled then
					safe_set(self.UI.Input, { Text = self.Value })
					return
				end
				self:SetValue(self.UI.Input.Text)
			end)
		end
	end

	function ImageTextbox:GetValue()
		return self.Value
	end

	function ImageTextbox:IsValid(value)
		return Library:IsValidImageTextboxInput(value or self.Value)
	end

	function ImageTextbox:SetDisabled(bool)
		if self.PremiumLocked and bool ~= true then
			bool = true
		end
		self.Disabled = bool == true
		local text_t = self.Disabled and 0.6 or 0
		if self.UI.Text then Menu:Tween(self.UI.Text, nil, { TextTransparency = text_t }) end
		if self.UI.Bg then Menu:Tween(self.UI.Bg, nil, { BackgroundTransparency = text_t }) end
		if self.UI.Input then
			Menu:Tween(self.UI.Input, nil, { TextTransparency = text_t })
			pcall(function() self.UI.Input.TextEditable = not self.Disabled end)
		end
		if self.UI.PreviewBg then Menu:Tween(self.UI.PreviewBg, nil, { BackgroundTransparency = text_t }) end
		if self.UI.PreviewImage then Menu:Tween(self.UI.PreviewImage, nil, { ImageTransparency = MathMax(self.UI.PreviewImage.ImageTransparency, text_t) }) end
		if self.UI.PreviewLabel then Menu:Tween(self.UI.PreviewLabel, nil, { TextTransparency = text_t }) end
	end

	function ImageTextbox:SetValue(value, silent)
		if self.PremiumLocked then
			if not silent then
				safe_set(self.UI.Input, { Text = self.Value })
				return
			end
		end
		if self.Disabled then return end
		self.Value = tostring(value or "")
		if self.UI.Input.Text ~= self.Value then
			safe_set(self.UI.Input, { Text = self.Value })
		end
		if self.Flag then Menu.Flags[self.Flag] = self.Value end
		self:UpdatePreview(self.Value)
		if Menu:ShouldFire(silent) then
			Library:SafeCall(self.Callback, self.Value, Library:IsValidImageTextboxInput(self.Value))
		end
	end

	function ImageTextbox:SetVisible(bool)
		Library:ApplyElementVisibility(self, bool)
	end
	ImageTextbox.SetVisibility = ImageTextbox.SetVisible
	ImageTextbox.Set = ImageTextbox.SetValue
	ImageTextbox.Get = ImageTextbox.GetValue
	Menu.Classes.ImageTextbox = ImageTextbox
end

do
	local Colorpicker = {}
	Colorpicker.__index = Colorpicker


	local CP = IsMobile and {
		W = 310, H = 430, Pad = 11, BarH = 26, FooterH = 28, AnimH = 52,
		PaletteInset = 175, HueOff = 140, AlphaOff = 105, RgbOff = 70, Dragger = 7,
	} or {
		W = 219, H = 310, Pad = 8, BarH = 18, FooterH = 25, AnimH = 47,
		PaletteInset = 153, HueOff = 118, AlphaOff = 91, RgbOff = 55, Dragger = 4,
	}

	local ANIM_OPTS = { "Rainbow", "Breathing" }

	if Menu.ColorpickerPopup then
		local old = Menu.ColorpickerPopup.UI
		if old then
			pcall(function() if old.Window then old.Window:Destroy() end end)
			pcall(function() if old.Blocker then old.Blocker:Destroy() end end)
			pcall(function() if old.AnimHolder then old.AnimHolder:Destroy() end end)
		end
		Menu.ColorpickerPopup = nil
	end

	local function ensure_popup()
		if Menu.ColorpickerPopup then return Menu.ColorpickerPopup end

		local popup = {
			IsOpen = false, Target = nil, AnimOpen = false,
			SlidingPalette = false, SlidingHue = false, SlidingAlpha = false,
			UI = {}, AnimOptions = {},
		}

		local blocker = Draw:Create("TextButton", {
			Parent = Menu.Overlay, Size = UDim2New(1, 0, 1, 0),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			Visible = false, ZIndex = 290,
		})

		local win = Draw:Create("TextButton", {
			Parent = Menu.Overlay, Size = UDim2New(0, CP.W, 0, CP.H),
			BackgroundColor3 = Menu.Theme.Background, BackgroundTransparency = 0.3,
			BorderSizePixel = 0, Text = "", AutoButtonColor = false,
			Visible = false, ClipsDescendants = false, ZIndex = 300,
			Theme = { BackgroundColor3 = "Background" },
		})
		corner(win, 5)
		ui_dual_stroke(win)

		local palette = Draw:Create("TextButton", {
			Parent = win, Size = UDim2New(1, -(CP.Pad * 2), 1, -CP.PaletteInset),
			Position = UDim2New(0, CP.Pad, 0, CP.Pad),
			BackgroundColor3 = FromRGB(255, 0, 0), BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, ZIndex = 301,
		})
		corner(palette, 5)
		local sat = Draw:Create("Frame", {
			Parent = palette, Size = UDim2New(1, 0, 1, 0),
			BackgroundColor3 = FromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 301,
		})
		corner(sat, 5)
		Draw:Create("UIGradient", {
			Parent = sat, Transparency = NSNew({ NSK(0, 0), NSK(1, 1) }),
		})
		local val = Draw:Create("Frame", {
			Parent = palette, Size = UDim2New(1, 0, 1, 0),
			BackgroundColor3 = FromRGB(0, 0, 0), BorderSizePixel = 0, ZIndex = 302,
		})
		corner(val, 5)
		Draw:Create("UIGradient", {
			Parent = val, Rotation = 90, Transparency = NSNew({ NSK(0, 1), NSK(1, 0) }),
		})
		local pal_drag = Draw:Create("Frame", {
			Parent = palette, Size = UDim2New(0, CP.Dragger, 0, CP.Dragger),
			BackgroundColor3 = FromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 304,
			AnchorPoint = Vector2New(0.5, 0.5),
		})
		corner(pal_drag, 99)
		Draw:Create("UIStroke", { Parent = pal_drag, Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })

		local hue = Draw:Create("TextButton", {
			Parent = win, Size = UDim2New(1, -(CP.Pad * 2), 0, CP.BarH),
			Position = UDim2New(0, CP.Pad, 1, -CP.HueOff), AnchorPoint = Vector2New(0, 1),
			BackgroundColor3 = FromRGB(255, 255, 255), BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, ZIndex = 301,
		})
		corner(hue, 5)
		Draw:Create("UIGradient", {
			Parent = hue,
			Color = CSNew({
				CSK(0, FromRGB(255, 0, 0)), CSK(0.17, FromRGB(255, 255, 0)), CSK(0.33, FromRGB(0, 255, 0)),
				CSK(0.5, FromRGB(0, 255, 255)), CSK(0.67, FromRGB(0, 0, 255)), CSK(0.83, FromRGB(255, 0, 255)),
				CSK(1, FromRGB(255, 0, 0)),
			}),
		})
		local hue_drag = Draw:Create("Frame", {
			Parent = hue, Size = UDim2New(0, 3, 1, -8),
			Position = UDim2New(0, 12, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundColor3 = FromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 304,
		})
		corner(hue_drag, 99)
		Draw:Create("UIStroke", { Parent = hue_drag, Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })

		local alpha = Draw:Create("TextButton", {
			Parent = win, Size = UDim2New(1, -(CP.Pad * 2), 0, CP.BarH),
			Position = UDim2New(0, CP.Pad, 1, -CP.AlphaOff), AnchorPoint = Vector2New(0, 1),
			BackgroundColor3 = FromRGB(255, 215, 160), BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, ZIndex = 301,
		})
		corner(alpha, 5)
		local checkers = Draw:Create("Frame", {
			Parent = alpha, Size = UDim2New(1, 0, 1, 0),
			BackgroundColor3 = FromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 301,
		})
		corner(checkers, 5)
		Draw:Create("UIGradient", {
			Parent = checkers, Transparency = NSNew({ NSK(0, 1), NSK(0.37, 0.5), NSK(1, 0) }),
		})
		local alpha_drag = Draw:Create("Frame", {
			Parent = alpha, Size = UDim2New(0, 3, 1, -8),
			Position = UDim2New(0, 3, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundColor3 = FromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 305,
		})
		corner(alpha_drag, 99)
		Draw:Create("UIStroke", { Parent = alpha_drag, Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })

		local footer = Draw:Create("Frame", {
			Parent = win, Size = UDim2New(1, -(CP.Pad * 2), 0, CP.FooterH),
			Position = UDim2New(0, CP.Pad, 1, -CP.RgbOff), AnchorPoint = Vector2New(0, 1),
			BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, ZIndex = 301,
			Theme = { BackgroundColor3 = "Element" },
		})
		corner(footer, 5)
		element_gradient(footer)
		local rgb_input = Draw:Create("TextBox", {
			Parent = footer, Size = UDim2New(1, -16, 1, 0), Position = UDim2New(0, 8, 0, 0),
			BackgroundTransparency = 1, Text = "", PlaceholderText = "Enter RGB..",
			TextColor3 = Menu.Theme.Text, PlaceholderColor3 = Menu.Theme["Inactive Text"],
			TextSize = 14, FontFace = Menu.Font, TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false, ZIndex = 302,
			Theme = { TextColor3 = "Text", PlaceholderColor3 = "Inactive Text" },
		})

		local anim_row = Draw:Create("Frame", {
			Parent = win, Size = UDim2New(1, -(CP.Pad * 2), 0, CP.AnimH),
			Position = UDim2New(0, CP.Pad, 1, -CP.Pad), AnchorPoint = Vector2New(0, 1),
			BackgroundTransparency = 1, ZIndex = 301,
		})
		Draw:Create("TextLabel", {
			Parent = anim_row, Size = UDim2New(0, 0, 0, 15), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1, Text = "animations", TextColor3 = Menu.Theme.Text,
			TextSize = 14, FontFace = Menu.Font, ZIndex = 302, Theme = { TextColor3 = "Text" },
		})
		local anim_btn = Draw:Create("TextButton", {
			Parent = anim_row, Size = UDim2New(1, 0, 0, CP.FooterH),
			Position = UDim2New(0, 0, 1, 0), AnchorPoint = Vector2New(0, 1),
			BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, ZIndex = 302, Theme = { BackgroundColor3 = "Element" },
		})
		corner(anim_btn, 5)
		element_gradient(anim_btn)
		local anim_val = Draw:Create("TextLabel", {
			Parent = anim_btn, Size = UDim2New(1, -28, 0, 15),
			Position = UDim2New(0, 8, 0.5, 0), AnchorPoint = Vector2New(0, 0.5),
			BackgroundTransparency = 1, Text = "None", TextColor3 = Menu.Theme.Text,
			TextSize = 14, FontFace = Menu.Font, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 303,
			Theme = { TextColor3 = "Text" },
		})
		Draw:Create("ImageLabel", {
			Parent = anim_btn, Size = UDim2New(0, 20, 0, 20),
			Position = UDim2New(1, -3, 0.5, 0), AnchorPoint = Vector2New(1, 0.5),
			BackgroundTransparency = 1, Image = "rbxassetid://126603363478667",
			ImageColor3 = Menu.Theme.Accent, ScaleType = Enum.ScaleType.Fit, ZIndex = 303,
			Theme = { ImageColor3 = "Accent" },
		})


		local anim_holder = Draw:Create("TextButton", {
			Parent = anim_row, Size = UDim2New(1, 0, 0, 0),
			Position = UDim2New(0, 0, 1, 5), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Menu.Theme.Inline, BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, Visible = false, ZIndex = 320,
			Theme = { BackgroundColor3 = "Inline" },
		})
		corner(anim_holder, 5)
		ui_dual_stroke(anim_holder)
		element_gradient(anim_holder)
		Draw:Create("UIListLayout", { Parent = anim_holder, Padding = UDimNew(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
		Draw:Create("UIPadding", {
			Parent = anim_holder, PaddingTop = UDimNew(0, 8), PaddingBottom = UDimNew(0, 8),
			PaddingLeft = UDimNew(0, 8), PaddingRight = UDimNew(0, 8),
		})

		popup.UI.Blocker = blocker
		popup.UI.Window = win
		popup.UI.Palette = palette
		popup.UI.PalDrag = pal_drag
		popup.UI.Alpha = alpha
		popup.UI.AlphaDrag = alpha_drag
		popup.UI.Hue = hue
		popup.UI.HueDrag = hue_drag
		popup.UI.RGB = rgb_input
		popup.UI.AnimVal = anim_val
		popup.UI.AnimHolder = anim_holder
		popup.UI.AnimBtn = anim_btn

		local function sync_visual(from_alpha)
			local t = popup.Target
			if not t then return end
			run_with_elevated_thread_identity(function()
				pal_drag.Position = UDim2New(MathClamp(t.Saturation, 0, 1), 0, MathClamp(1 - t.ValueV, 0, 1), 0)
				hue_drag.Position = UDim2New(MathClamp(t.Hue, 0, 1), 0, 0.5, 0)
				alpha_drag.Position = UDim2New(MathClamp(t.Alpha, 0, 1), 0, 0.5, 0)
				palette.BackgroundColor3 = FromHSV(t.Hue, 1, 1)
				if not from_alpha then alpha.BackgroundColor3 = t.Color end
				rgb_input.Text = StringFormat("%d, %d, %d", MathFloor(t.Color.R * 255), MathFloor(t.Color.G * 255), MathFloor(t.Color.B * 255))
				local parts = {}
				for i = 1, #ANIM_OPTS do
					if t.AnimValue[ANIM_OPTS[i]] then TableInsert(parts, ANIM_OPTS[i]) end
				end
				anim_val.Text = #parts > 0 and TableConcat(parts, ", ") or "None"
			end)
		end

		local cp_mouse = LPH_NO_VIRTUALIZE(function(input)
			if input then
				local ok, pos = pcall(function()
					return input.Position
				end)
				if ok and pos then
					return Vector2New(pos.X, pos.Y)
				end
			end
			return get_absolute_mouse()
		end)

		local slide_palette = LPH_NO_VIRTUALIZE(function(input)
			local t = popup.Target
			if not t or not popup.SlidingPalette then return end
			local m = cp_mouse(input)
			local slide_x, slide_y
			local ok = select(1, run_with_elevated_thread_identity(function()
				local p, s = palette.AbsolutePosition, palette.AbsoluteSize
				if s.X <= 0 or s.Y <= 0 then return end
				slide_x = MathClamp((m.X - p.X) / s.X, 0, 1)
				slide_y = MathClamp((m.Y - p.Y) / s.Y, 0, 1)
				pal_drag.Position = UDim2New(slide_x, 0, slide_y, 0)
			end))
			if not ok or slide_x == nil then return end
			t.Saturation = slide_x
			t.ValueV = 1 - slide_y
			t:Update(false)
		end)
		local slide_hue = LPH_NO_VIRTUALIZE(function(input)
			local t = popup.Target
			if not t or not popup.SlidingHue then return end
			local m = cp_mouse(input)
			local slide_x
			local ok = select(1, run_with_elevated_thread_identity(function()
				local p, s = hue.AbsolutePosition, hue.AbsoluteSize
				if s.X <= 0 then return end
				slide_x = MathClamp((m.X - p.X) / s.X, 0, 1)
				hue_drag.Position = UDim2New(slide_x, 0, 0.5, 0)
			end))
			if not ok or slide_x == nil then return end
			t.Hue = slide_x
			t:Update(false)
		end)
		local slide_alpha = LPH_NO_VIRTUALIZE(function(input)
			local t = popup.Target
			if not t or not popup.SlidingAlpha then return end
			local m = cp_mouse(input)
			local slide_x
			local ok = select(1, run_with_elevated_thread_identity(function()
				local p, s = alpha.AbsolutePosition, alpha.AbsoluteSize
				if s.X <= 0 then return end
				slide_x = MathClamp((m.X - p.X) / s.X, 0, 1)
				alpha_drag.Position = UDim2New(slide_x, 0, 0.5, 0)
			end))
			if not ok or slide_x == nil then return end
			t.Alpha = slide_x
			t:Update(true)
		end)

		local function bind_slide(btn, flag, fn)
			btn.InputBegan:Connect(elevate_callback(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				popup[flag] = true
				fn(input)
				local mid = "CP." .. flag
				Hook:Add("Mouse.Move", mid, LPH_NO_VIRTUALIZE(function(move_input)
					fn(move_input)
				end))
				Hook:Add("InputEnded", mid .. ".End", function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						popup[flag] = false
						Hook:Remove(nil, mid); Hook:Remove(nil, mid .. ".End")
					end
				end)
			end))
		end
		bind_slide(palette, "SlidingPalette", slide_palette)
		bind_slide(hue, "SlidingHue", slide_hue)
		bind_slide(alpha, "SlidingAlpha", slide_alpha)

		rgb_input.FocusLost:Connect(function()
			local t = popup.Target
			if not t then return end
			local cleaned = StringGsub(rgb_input.Text, "%s+", "")
			local r, g, b = cleaned:match("^(%d+),(%d+),(%d+)$")
			if not r then return end
			t:SetValue(FromRGB(MathClamp(tonumber(r), 0, 255), MathClamp(tonumber(g), 0, 255), MathClamp(tonumber(b), 0, 255)), false)
			sync_visual(false)
		end)

		local function refresh_anim_options()
			local children = anim_holder:GetChildren()
			for i = 1, #children do
				local c = children[i]
				if c:IsA("TextButton") then safe_destroy(c) end
			end
			local t = popup.Target
			for i = 1, #ANIM_OPTS do
				local name = ANIM_OPTS[i]
				local on = t and t.AnimValue[name] == true
				local btn = Draw:Create("TextButton", {
					Parent = anim_holder, Size = UDim2New(1, 0, 0, CP.FooterH),
					BackgroundColor3 = Menu.Theme.Inline, BackgroundTransparency = on and 0 or 1,
					BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 321,
					Theme = { BackgroundColor3 = "Inline" },
				})
				corner(btn, 5)
				Draw:Create("TextLabel", {
					Parent = btn, Size = UDim2New(1, -15, 1, 0),
					Position = UDim2New(0, on and 8 or 4, 0, 0), BackgroundTransparency = 1,
					Text = name, TextColor3 = Menu.Theme.Text, TextSize = 14, FontFace = Menu.Font,
					TextTransparency = on and 0 or 0.4, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 322,
					Theme = { TextColor3 = "Text" },
				})
				btn.MouseButton1Down:Connect(function()
					if not popup.Target then return end
					popup.Target.AnimValue[name] = not popup.Target.AnimValue[name]
					popup.Target:StartAnims()
					sync_visual(false)
					refresh_anim_options()
				end)
			end
		end

		anim_btn.MouseButton1Down:Connect(function()
			popup.AnimOpen = not popup.AnimOpen
			anim_holder.Visible = popup.AnimOpen
			if popup.AnimOpen then refresh_anim_options() end
		end)

		blocker.MouseButton1Down:Connect(function()
			if popup.Target then popup.Target:Close() end
		end)
		win.MouseButton1Down:Connect(function() end)

		function popup:BindTo(target)
			self.Target = target
			sync_visual(false)
		end

		function popup:Open(btn, target)
			run_with_elevated_thread_identity(function()
				self:BindTo(target)
				self.IsOpen = true
				blocker.Visible = true
				win.Visible = true
				anim_holder.Visible = false
				self.AnimOpen = false
				local abs = btn.AbsolutePosition
				local size = btn.AbsoluteSize
				local vp = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2New(1920, 1080)
				local x = abs.X + size.X + 6
				local y = abs.Y
				if x + CP.W > vp.X - 8 then
					x = abs.X - CP.W - 6
				end
				if x < 8 then x = 8 end
				if y + CP.H > vp.Y - 8 then
					y = MathMax(8, vp.Y - CP.H - 8)
				end
				if y < 8 then y = 8 end
				win.Position = UDim2New(0, x, 0, y)
				win.Size = UDim2New(0, CP.W, 0, CP.H)
			end)
		end

		function popup:Close()
			run_with_elevated_thread_identity(function()
				self.IsOpen = false
				self.Target = nil
				self.AnimOpen = false
				blocker.Visible = false
				win.Visible = false
				anim_holder.Visible = false
			end)
			Hook:Remove(nil, "CP.SlidingPalette"); Hook:Remove(nil, "CP.SlidingPalette.End")
			Hook:Remove(nil, "CP.SlidingHue"); Hook:Remove(nil, "CP.SlidingHue.End")
			Hook:Remove(nil, "CP.SlidingAlpha"); Hook:Remove(nil, "CP.SlidingAlpha.End")
		end

		Menu.ColorpickerPopup = popup
		return popup
	end

	function Colorpicker.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Colorpicker)
		self.Class = "Colorpicker"
		self.UI = {}
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category
		self.Flag = parameters.Flag or parameters.flag
		self.Callback = parameters.Callback or parameters.callback or function() end
		self.Alpha = type(parameters.Alpha) == "number" and parameters.Alpha or 0
		self.Hue, self.Saturation, self.ValueV = 0, 0, 1
		self.Color = FromRGB(255, 255, 255)
		self.DefaultColor = self.Color
		self.DefaultAlpha = self.Alpha
		self.IsOpen = false
		self.AnimValue = {}
		self._RainbowRunning = false
		self._BreathingRunning = false

		local sw = IsMobile and 18 or 15
		self.UI.Framework = Draw:Create("TextButton", {
			Parent = self.ContentFrame, Size = UDim2New(0, sw, 0, sw),
			BackgroundColor3 = FromRGB(255, 215, 160), BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, ZIndex = 2,
		})
		corner(self.UI.Framework, 5)
		self.UI.Gradient = Draw:Create("UIGradient", {
			Parent = self.UI.Framework, Rotation = 90,
			Color = CSNew({ CSK(0, FromRGB(255, 255, 255)), CSK(1, FromRGB(216, 216, 216)) }),
		})

		local def = parameters.Default or parameters.default or parameters.Color or FromRGB(255, 255, 255)
		self:SetValue(def, true)
		self.DefaultColor = self.Color
		self.DefaultAlpha = self.Alpha

		self.UI.Framework.MouseButton1Down:Connect(function()
			if Library:GuardPremiumInteract(self) or self.Disabled then return end
			local popup = ensure_popup()
			if self.IsOpen and popup.Target == self then
				self:Close()
				return
			end
			Menu:CloseCurrent()
			self.IsOpen = true
			Menu.CurrentContent = self
			popup:Open(self.UI.Framework, self)
		end)

		if self.Flag then Config:RegisterElement(self, self.Flag, self.Category, parameters.IgnoreConfig) end
		if Library:IsPremiumElement(parameters) then
			Library:ApplyPremiumVisual(self)
		end
		return self
	end

	function Colorpicker:StartAnims()
		if self.AnimValue.Rainbow and not self._RainbowRunning then
			self._RainbowRunning = true
			local saved = self.Color
			spawn(LPH_NO_VIRTUALIZE(function()
				while self._RainbowRunning and self.AnimValue.Rainbow do
					self.Hue = (tick() * 0.21) % 1
					self:Update(true)
					task.wait(0.03)
				end
				self._RainbowRunning = false
				if not self.AnimValue.Rainbow then self:SetValue(saved, true) end
			end))
		elseif not self.AnimValue.Rainbow then
			self._RainbowRunning = false
		end
		if self.AnimValue.Breathing and not self._BreathingRunning then
			self._BreathingRunning = true
			spawn(LPH_NO_VIRTUALIZE(function()
				while self._BreathingRunning and self.AnimValue.Breathing do
					self.Alpha = MathAbs(math.sin(tick() * 0.55))
					self:Update(true)
					task.wait(0.03)
				end
				self._BreathingRunning = false
			end))
		elseif not self.AnimValue.Breathing then
			self._BreathingRunning = false
		end
	end

	function Colorpicker:Update(silent)
		self.Color = FromHSV(self.Hue, self.Saturation, self.ValueV)
		run_with_elevated_thread_identity(function()
			self.UI.Framework.BackgroundColor3 = self.Color
			local popup = Menu.ColorpickerPopup
			if popup and popup.Target == self and popup.IsOpen then
				local ui = popup.UI
				ui.Palette.BackgroundColor3 = FromHSV(self.Hue, 1, 1)
				ui.Alpha.BackgroundColor3 = self.Color
				if ui.PalDrag then
					ui.PalDrag.Position = UDim2New(MathClamp(self.Saturation, 0, 1), 0, MathClamp(1 - self.ValueV, 0, 1), 0)
				end
				if ui.HueDrag then
					ui.HueDrag.Position = UDim2New(MathClamp(self.Hue, 0, 1), 0, 0.5, 0)
				end
				if ui.AlphaDrag then
					ui.AlphaDrag.Position = UDim2New(MathClamp(self.Alpha, 0, 1), 0, 0.5, 0)
				end
				if ui.RGB then
					ui.RGB.Text = StringFormat("%d, %d, %d", MathFloor(self.Color.R * 255), MathFloor(self.Color.G * 255), MathFloor(self.Color.B * 255))
				end
			end
		end)
		if self.Flag then
			Menu.Flags[self.Flag] = {
				Color = self.Color, Alpha = self.Alpha, HexValue = self.Color:ToHex(),
				Transparency = 1 - self.Alpha,
			}
		end
		if Menu:ShouldFire(silent) then self.Callback(self.Color, self.Alpha) end
	end

	function Colorpicker:Open()
		local popup = ensure_popup()
		if self.IsOpen and popup.Target == self then return end
		Menu:CloseCurrent()
		self.IsOpen = true
		Menu.CurrentContent = self
		popup:Open(self.UI.Framework, self)
	end

	function Colorpicker:Close()
		self.IsOpen = false
		if Menu.CurrentContent == self then Menu.CurrentContent = nil end
		if Menu.ColorpickerPopup then Menu.ColorpickerPopup:Close() end
	end

	function Colorpicker:GetValue()
		return { Color = self.Color, Alpha = self.Alpha, HexValue = self.Color:ToHex(), Transparency = 1 - self.Alpha }
	end

	function Colorpicker:SetValue(color, silent)
		if self.PremiumLocked then
			if not silent then return end
		end
		if type(color) == "table" and color.Color then
			self.Alpha = color.Alpha or color.Transparency or self.Alpha
			color = color.Color
		end
		if type(color) == "string" then
			if StringSub(color, 1, 1) ~= "#" then color = "#" .. color end
			color = FromHex(color)
		elseif type(color) == "table" and color[1] then
			color = FromRGB(color[1], color[2], color[3])
		end
		if typeof(color) == "Color3" then
			self.Hue, self.Saturation, self.ValueV = color:ToHSV()
			self.Color = color
		end
		self:Update(silent == true)
		local popup = Menu.ColorpickerPopup
		if self.IsOpen and popup and popup.Target == self then
			popup:BindTo(self)
		end
	end

	function Colorpicker:Set(color, alpha, silent)
		if type(alpha) == "number" then self.Alpha = alpha end
		if type(silent) ~= "boolean" and type(alpha) == "boolean" then silent = alpha end
		self:SetValue(color, silent)
	end

	Colorpicker.SetColor = Colorpicker.SetValue
	Menu.Classes.Colorpicker = Colorpicker
end

do
	local Hotkey = {}
	Hotkey.__index = Hotkey

	function Hotkey.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, Hotkey)
		self.Class = "Hotkey"
		self.Height = 0
		self.UI = {}
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category
		self.Flag = parameters.Flag or parameters.flag
		self.Mode = parameters.Mode or parameters.mode or "Toggle"
		self.Key = "None"
		self.Toggled = false
		self.Picking = false
		self.Callback = parameters.Callback or parameters.callback or function() end
		self.DisplayName = parameters.Name or parameters.name
			or (config.Host and (config.Host.Title or config.Host.Name))
			or "Keybind"

		local function sync_flag()
			if not self.Flag then return end
			Menu.Flags[self.Flag] = {
				Key = self.Key,
				Mode = self.Mode,
				Toggled = self.Toggled == true,
			}
		end

		local function key_label()
			return Library:FormatKeybindDisplay(self.Key)
		end

		local function refresh_label()
			run_with_elevated_thread_identity(function()
				self.UI.Framework.Text = "[" .. key_label() .. "]"
			end)
		end
		self._RefreshLabel = refresh_label

		local function press(bool)
			if self.Mode == "Toggle" or self.Mode == "Click" then
				self.Toggled = not self.Toggled
			elseif self.Mode == "Hold" then
				self.Toggled = bool == true
			elseif self.Mode == "Always" then
				self.Toggled = true
			end
			sync_flag()
			if Menu:ShouldFire(false) then
				self.Callback(self.Toggled)
			end
			if self._UpdateList then self:_UpdateList() end
		end
		self.Press = press
		self._SyncFlag = sync_flag

		self.UI.Framework = Draw:Create("TextButton", {
			Parent = self.ContentFrame, Size = UDim2New(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, Text = "[None]",
			TextColor3 = Menu.Theme.Text, TextSize = 16, FontFace = Menu.Font, 			AutoButtonColor = false, ZIndex = 2,
			Theme = { BackgroundColor3 = "Element", TextColor3 = "Text" },
		})
		corner(self.UI.Framework, 4)
		Draw:Create("UIPadding", {
			Parent = self.UI.Framework,
			PaddingLeft = UDimNew(0, 6), PaddingRight = UDimNew(0, 6),
		})
		local size_c = Instance.new("UISizeConstraint")
		size_c.MinSize = Vector2New(32, 18)
		size_c.MaxSize = Vector2New(1e5, 18)
		set_instance_parent(size_c, self.UI.Framework)

		local def = parameters.Default or parameters.default
		if def then self:SetValue(def, true) end
		self.ShowInList = parameters.ShowInList ~= false
		sync_flag()
		refresh_label()

		local id = "Hotkey." .. tostring(self.Flag or math.random())

		local function start_picking()
			if self.Picking then return end
			self.Picking = true
			self.UI.Framework.Text = "[...]"

			local ignore_until = os.clock() + 0.2
			local conn
			conn = UserInputService.InputBegan:Connect(elevate_callback(function(input, gp)
				if os.clock() < ignore_until then return end
				local key
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if gp then return end
					key = input.KeyCode.Name
				elseif input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.MouseButton2
					or input.UserInputType == Enum.UserInputType.MouseButton3 then

					key = input.UserInputType.Name
				end
				if key then
					if key == "Escape" or key == "Backspace" then key = "None" end
					self:SetValue({ Key = key, Mode = self.Mode }, false)
					self.Picking = false
					conn:Disconnect()
				end
			end))
		end


		self.UI.Framework.MouseButton1Down:Connect(elevate_callback(function()
			if Library:GuardPremiumInteract(self) or self.Disabled then return end
			if self.Picking then return end
			if self.Mode ~= "Click" then
				start_picking()
				return
			end

			if self.Key == "None" then
				start_picking()
				return
			end
			local down_at = os.clock()
			local holding = true
			local started_pick = false
			local up_conn
			up_conn = UserInputService.InputEnded:Connect(elevate_callback(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				holding = false
				up_conn:Disconnect()
				if started_pick or self.Picking then return end
				if os.clock() - down_at < 0.35 then
					press()
				end
			end))
			task.delay(0.35, function()
				if holding and not self.Picking then
					started_pick = true
					pcall(function() up_conn:Disconnect() end)
					start_picking()
				end
			end)
		end))

		self.UI.Framework.MouseButton2Click:Connect(elevate_callback(function()
			if Library:GuardPremiumInteract(self) or self.Disabled then return end
			if self.Picking then return end
			if self.IsOpen then
				self:Close()
			else
				self:OpenModePopup()
			end
		end))

		local function resolve_key(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				return input.KeyCode.Name
			end
			local name = input.UserInputType.Name
			if name == "MouseButton1" or name == "MouseButton2" or name == "MouseButton3" then
				return name
			end
			return nil
		end
		Hook:Add("InputBegan", id, function(input, gp)
			if self.PremiumLocked or self.Disabled then return end
			if self.Picking or self.Key == "None" then return end
			if resolve_key(input) ~= self.Key then return end
			if gp and not Library:IsMouseKeybindKey(self.Key) then return end
			if self.Mode == "Toggle" or self.Mode == "Click" then
				press()
			elseif self.Mode == "Hold" then
				press(true)
			elseif self.Mode == "Always" then
				press(true)
			end
		end)
		Hook:Add("InputEnded", id .. ".End", function(input, gp)
			if self.Mode == "Click" or self.Key == "None" then return end
			if resolve_key(input) ~= self.Key then return end
			if gp and not Library:IsMouseKeybindKey(self.Key) then return end
			if self.Mode == "Hold" then
				press(false)
			elseif self.Mode == "Always" then
				press(true)
			end
		end)

		if self.Flag then Config:RegisterElement(self, self.Flag, self.Category, parameters.IgnoreConfig) end
		TableInsert(Menu.KeybindEntries, self)

		function self:_UpdateList()
			if not self.KeyListItem then return end
			run_with_elevated_thread_identity(function()
				self.KeyListItem:Set("[" .. key_label() .. "]", self.DisplayName, self.Mode)
				if self.ShowInList == false then
					self.KeyListItem:SetVis(false)
					self.KeyListItem:SetStatus(false)
					return
				end
				self.KeyListItem:SetVis(true)
				if self.Mode == "Always" then
					self.KeyListItem:SetStatus(true)
				else
					self.KeyListItem:SetStatus(self.Toggled == true)
				end
			end)
		end
		if Library.KeyList and Library.KeyList.Add then
			self.KeyListItem = Library.KeyList:Add("[" .. key_label() .. "]", self.DisplayName, self.Mode)
			self:_UpdateList()
		end
		return self
	end

	function Hotkey:OpenModePopup()
		Menu:CloseCurrent()
		run_with_elevated_thread_identity(function()
			if self.ModeUI then safe_destroy(self.ModeUI); self.ModeUI = nil end
			if self.ModeBlocker then safe_destroy(self.ModeBlocker); self.ModeBlocker = nil end
		end)

		local abs = self.UI.Framework.AbsolutePosition
		local size = self.UI.Framework.AbsoluteSize
		local blocker = Draw:Create("TextButton", {
			Parent = Menu.Overlay, Size = UDim2New(1, 0, 1, 0),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 280,
		})
		local modes = { "Hold", "Toggle", "Always", "Click" }
		local row_h = 26
		local win_h = 14 + (#modes * (row_h + 4)) + 28
		local win = Draw:Create("Frame", {
			Parent = Menu.Overlay, Size = UDim2New(0, 168, 0, win_h),
			Position = UDim2New(0, abs.X, 0, abs.Y + size.Y + 8),
			BackgroundColor3 = Menu.Theme.Background, BorderSizePixel = 0, ZIndex = 290,
			Theme = { BackgroundColor3 = "Background" },
		})
		ui_dual_stroke(win)
		Draw:Create("Frame", {
			Parent = win, Size = UDim2New(1, 0, 0, 1), BorderSizePixel = 0,
			BackgroundColor3 = Menu.Theme.Accent, ZIndex = 291, Theme = { BackgroundColor3 = "Accent" },
		})

		local mode_buttons = {}
		local function paint_modes()
			for i = 1, #mode_buttons do
				local b = mode_buttons[i]
				local on = b.Mode == self.Mode
				b.Btn.BackgroundColor3 = on and Menu.Theme.Accent or Menu.Theme.Element
				b.Label.TextColor3 = on and FromRGB(255, 255, 255) or Menu.Theme.Text
			end
		end

		local function set_mode(mode)
			self.Mode = mode
			if mode == "Always" then
				self.Toggled = true
			end
			if self._RefreshLabel then self:_RefreshLabel() end
			if self._SyncFlag then self._SyncFlag() end
			if Menu:ShouldFire(false) then
				self.Callback(self.Toggled)
			end
			if self._UpdateList then self:_UpdateList() end
			paint_modes()
		end

		for i = 1, #modes do
			local mode = modes[i]
			local y = 8 + (i - 1) * (row_h + 4)
			local mode_btn = Draw:Create("TextButton", {
				Parent = win, Size = UDim2New(1, -16, 0, row_h), Position = UDim2New(0, 8, 0, y),
				BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, Text = "",
				AutoButtonColor = false, ZIndex = 291, Theme = { BackgroundColor3 = "Element" },
			})
			corner(mode_btn, 5)
			element_gradient(mode_btn)
			local mode_label = Draw:Create("TextLabel", {
				Parent = mode_btn, Size = UDim2New(1, -12, 1, 0), Position = UDim2New(0, 8, 0, 0),
				BackgroundTransparency = 1, Text = mode, TextColor3 = Menu.Theme.Text,
				TextSize = 14, FontFace = Menu.Font, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 292,
				Theme = { TextColor3 = "Text" },
			})
			mode_buttons[i] = { Mode = mode, Btn = mode_btn, Label = mode_label }
			mode_btn.MouseButton1Down:Connect(function()
				set_mode(mode)
			end)
		end
		paint_modes()

		local show = Draw:Create("TextButton", {
			Parent = win, Size = UDim2New(1, -16, 0, 18), Position = UDim2New(0, 8, 1, -26),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 291,
		})
		local box = Draw:Create("Frame", {
			Parent = show, Size = UDim2New(0, 12, 0, 12), Position = UDim2New(0, 0, 0.5, 0),
			AnchorPoint = Vector2New(0, 0.5), BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, ZIndex = 292,
			Theme = { BackgroundColor3 = "Element" },
		})
		corner(box, 3)
		local fill = Draw:Create("Frame", {
			Parent = box, Size = self.ShowInList and UDim2New(1, 0, 1, 0) or UDim2New(0, 0, 0, 0),
			BackgroundColor3 = Menu.Theme.Accent, BorderSizePixel = 0, BackgroundTransparency = self.ShowInList and 0 or 1, ZIndex = 293,
			Theme = { BackgroundColor3 = "Accent" },
		})
		corner(fill, 3)
		Draw:Create("TextLabel", {
			Parent = show, Size = UDim2New(1, -20, 1, 0), Position = UDim2New(0, 18, 0, 0),
			BackgroundTransparency = 1, Text = "Show In Keybinds List", TextColor3 = Menu.Theme.Text,
			TextSize = 13, FontFace = Menu.Font, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 292,
			Theme = { TextColor3 = "Text" },
		})
		show.MouseButton1Down:Connect(elevate_callback(function()
			self.ShowInList = not self.ShowInList
			fill.Size = self.ShowInList and UDim2New(1, 0, 1, 0) or UDim2New(0, 0, 0, 0)
			fill.BackgroundTransparency = self.ShowInList and 0 or 1
			if self._UpdateList then self:_UpdateList() end
		end))

		self.ModeUI = win
		self.ModeBlocker = blocker
		self.IsOpen = true
		Menu.CurrentContent = self
		blocker.MouseButton1Down:Connect(elevate_callback(function() self:Close() end))
	end

	function Hotkey:Close()
		self.IsOpen = false
		if Menu.CurrentContent == self then Menu.CurrentContent = nil end
		run_with_elevated_thread_identity(function()
			if self.ModeUI then safe_destroy(self.ModeUI); self.ModeUI = nil end
			if self.ModeBlocker then safe_destroy(self.ModeBlocker); self.ModeBlocker = nil end
		end)
	end

	function Hotkey:GetValue()
		return { Key = self.Key, Mode = self.Mode, Toggled = self.Toggled == true }
	end

	function Hotkey:SetValue(value, silent)
		if typeof(value) == "EnumItem" then
			self.Key = Library:NormalizeKeybindKey(value)
		elseif type(value) == "table" then
			self.Key = Library:NormalizeKeybindKey(value.Key)
			if type(value.Mode) == "string" and value.Mode ~= "" then
				self.Mode = value.Mode
			end
			if type(value.Toggled) == "boolean" then
				self.Toggled = value.Toggled
			elseif self.Mode == "Always" then
				self.Toggled = true
			end
		else
			self.Key = Library:NormalizeKeybindKey(value)
		end
		if self.Mode == "Always" then self.Toggled = true end
		if self._RefreshLabel then
			self:_RefreshLabel()
		else
			local label = Library:FormatKeybindDisplay(self.Key)
			run_with_elevated_thread_identity(function()
				self.UI.Framework.Text = "[" .. label .. "]"
			end)
		end
		if self._SyncFlag then self._SyncFlag()
		elseif self.Flag then
			Menu.Flags[self.Flag] = { Key = self.Key, Mode = self.Mode, Toggled = self.Toggled == true }
		end
		if self._UpdateList then self:_UpdateList() end
		if silent ~= true and Menu:ShouldFire(silent) then
			self.Callback(self.Toggled)
		end
	end
	Hotkey.Set = Hotkey.SetValue
	Hotkey.Get = Hotkey.GetValue
	Menu.Classes.Hotkey = Hotkey
end

do
	local SubSlider = {}
	SubSlider.__index = SubSlider

	local TRACK_HEIGHT = 22
	local BLOCK_GAP = 4
	local RANGE_GAP = 6
	local MAX_ENTRIES = 4

	local function resolve_increment(decimals, min, max)
		decimals = tonumber(decimals)
		if decimals == nil then
			local r = (max or 0) - (min or 0)
			return r <= 1 and 0.01 or (r <= 10 and 0.1 or 1)
		end
		if decimals == 0 then return 1 end
		if decimals < 0 then return 10 ^ (-decimals) end
		return decimals
	end

	local function places_from_increment(increment)
		local s = StringFormat("%.12f", MathAbs(tonumber(increment) or 1)):gsub("0+$", ""):gsub("%.$", "")
		local dot = string.find(s, ".", 1, true)
		return dot and MathClamp(#s - dot, 0, 8) or 0
	end

	local function resolve_places(decimals, min, max)
		return places_from_increment(resolve_increment(decimals, min, max))
	end

	local function snap_value(value, min, max, places, increment)
		value = MathClamp(tonumber(value) or min, min, max)
		increment = tonumber(increment)
		if not increment or increment <= 0 then
			increment = 10 ^ -(tonumber(places) or 0)
		end
		value = min + MathFloor((value - min) / increment + 0.5) * increment
		local mult = 10 ^ (tonumber(places) or 0)
		return MathClamp(MathFloor(value * mult + 0.5) / mult, min, max)
	end

	local function format_places(value, places)
		value = tonumber(value) or 0
		if places <= 0 then
			return StringFormat("%d", MathFloor(value + 0.5))
		end
		local text = StringFormat("%." .. tostring(places) .. "f", value)
		local dot = string.find(text, ".", 1, true)
		if not dot then return text end
		local frac = text:sub(dot + 1):gsub("0+$", "")
		if frac == "" then return text:sub(1, dot - 1) end
		return text:sub(1, dot) .. frac
	end

	local function make_track(parent, layout_order, size)
		local track = Draw:Create("TextButton", {
			Parent = parent, Size = size or UDim2New(1, 0, 0, TRACK_HEIGHT),
			BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, ClipsDescendants = true, ZIndex = 2, LayoutOrder = layout_order or 0,
			Theme = { BackgroundColor3 = "Element" },
		})
		corner(track, 5)
		local accent = Draw:Create("Frame", {
			Parent = track, Size = UDim2New(0, 0, 1, 0),
			BackgroundColor3 = Menu.Theme.Accent, BorderSizePixel = 0, ZIndex = 3,
			Theme = { BackgroundColor3 = "Accent" },
		})
		corner(accent, 5)
		local label = Draw:Create("TextLabel", {
			Parent = track, Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 1,
			Text = "", TextColor3 = Menu.Theme.Text, TextSize = 16, FontFace = Menu.Font,
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
			Theme = { TextColor3 = "Text" },
		})
		Draw:Create("UIStroke", {
			Parent = label, Thickness = 1, Color = FromRGB(0, 0, 0), Transparency = 0.35,
		})
		return { Track = track, Accent = accent, Label = label }
	end

	function SubSlider.new(config, parameters)
		parameters = parameters or {}
		local self = setmetatable({}, SubSlider)
		self.Class = "SubSlider"
		self.Title = parameters.Title or parameters.Name or parameters.name
		self.Compact = parameters.Compact == true or parameters.compact == true
		self.Callback = parameters.Callback or parameters.callback or function() end
		self.Flag = parameters.Flag or parameters.flag
		self.Entries = {}
		self.EntriesIndex = 0
		self.Visible = true
		self.UI = {}
		self.ContentFrame = config.ContentFrame
		self.Category = config.Category
		self.SlidingEntry = nil
		self.SlidingKind = nil
		self:Draw()
		return self
	end

	function SubSlider:Draw()
		local UI = self.UI
		UI.Framework = Draw:Create("Frame", {
			Parent = self.ContentFrame, Size = UDim2New(1, 0, 0, 0),
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
		})
		Draw:Create("UIListLayout", {
			Parent = UI.Framework, Padding = UDimNew(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
		})
		if self.Title and self.Title ~= "" then
			Draw:Create("TextLabel", {
				Parent = UI.Framework, Size = UDim2New(1, 0, 0, 16), BackgroundTransparency = 1,
				Text = self.Title, TextColor3 = Menu.Theme.Text, TextSize = 16, FontFace = Menu.Font,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Theme = { TextColor3 = "Text" },
			})
		end

		UI.Row = Draw:Create("Frame", {
			Parent = UI.Framework,
			Size = UDim2New(1, 0, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
		})
		Draw:Create("UIListLayout", {
			Parent = UI.Row, Padding = UDimNew(0, BLOCK_GAP), SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		})
	end

	function SubSlider:RelayoutEntries()
		local n = self.EntriesIndex
		if n < 1 then return end
		local offset = -MathFloor(((BLOCK_GAP * (n - 1)) / n) + 0.5)
		local size = UDim2New(1 / n, offset, 0, 0)
		for i = 1, n do
			local e = self.Entries[i]
			local block = e and e.Items and e.Items.Block
			if block then
				block.Size = size
				block.AutomaticSize = Enum.AutomaticSize.Y
			end
		end
	end

	function SubSlider:Add(entry)
		if self.EntriesIndex >= MAX_ENTRIES then return self end
		entry = entry or {}
		self.EntriesIndex += 1

		local speed_min = entry.SpeedMin or entry.Min or entry.min or 0
		local speed_max = entry.SpeedMax or entry.Max or entry.max or 10
		local start_min = entry.StartMin or 0
		local start_max = entry.StartMax or 100
		local end_min = entry.EndMin or 0
		local end_max = entry.EndMax or 100
		local speed_inc = resolve_increment(entry.SpeedDecimals or entry.Decimals or entry.Increment or 0.01, speed_min, speed_max)
		local range_inc = resolve_increment(entry.RangeDecimals ~= nil and entry.RangeDecimals or 0, start_min, start_max)
		local speed_places = places_from_increment(speed_inc)
		local range_places = places_from_increment(range_inc)

		local e = {
			Name = entry.Name or entry.name or "value",
			Flag = entry.Flag or entry.flag or (self.Flag and (self.Flag .. "_" .. self.EntriesIndex)) or nil,
			HideRange = entry.HideRange == true or entry.hide_range == true,
			Speed = entry.SpeedDefault or entry.Default or entry.default or 1,
			Start = entry.StartDefault or entry.start_default or 0,
			["End"] = entry.EndDefault or entry.end_default or 100,
			SpeedMin = speed_min,
			SpeedMax = speed_max,
			StartMin = start_min,
			StartMax = start_max,
			EndMin = end_min,
			EndMax = end_max,
			SpeedIncrement = speed_inc,
			RangeIncrement = range_inc,
			SpeedPlaces = speed_places,
			RangePlaces = range_places,
			SpeedSuffix = entry.SpeedSuffix or entry.Suffix or "",
			StartSuffix = entry.StartSuffix or entry.RangeSuffix or "%",
			EndSuffix = entry.EndSuffix or entry.RangeSuffix or "%",
			Callback = entry.Callback or entry.callback or function() end,
			Items = {},
		}

		local block = Draw:Create("Frame", {
			Parent = self.UI.Row,
			Size = UDim2New(1, 0, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
		})
		Draw:Create("UIListLayout", {
			Parent = block, Padding = UDimNew(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
		})
		e.Items.Block = block

		local speed = make_track(block, 0, UDim2New(1, 0, 0, TRACK_HEIGHT))
		e.Items.SpeedAccent = speed.Accent
		e.Items.SpeedLabel = speed.Label
		e.Items.SpeedButton = speed.Track

		if not e.HideRange then
			local range = Draw:Create("Frame", {
				Parent = block, Size = UDim2New(1, 0, 0, TRACK_HEIGHT),
				BackgroundTransparency = 1, ZIndex = 2, LayoutOrder = 1,
			})
			Draw:Create("UIListLayout", {
				Parent = range, Padding = UDimNew(0, RANGE_GAP), SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
			})
			local half = UDim2New(0.5, -RANGE_GAP / 2, 1, 0)
			local start_t = make_track(range, 0, half)
			local end_t = make_track(range, 1, half)
			e.Items.StartAccent = start_t.Accent
			e.Items.StartLabel = start_t.Label
			e.Items.StartButton = start_t.Track
			e.Items.EndAccent = end_t.Accent
			e.Items.EndLabel = end_t.Label
			e.Items.EndButton = end_t.Track
		end

		local function refresh(skip_tween)
			local a = MathClamp((e.Speed - e.SpeedMin) / MathMax(e.SpeedMax - e.SpeedMin, 1e-6), 0, 1)
			local speed_size = UDim2New(a, 0, 1, 0)
			local speed_text = StringFormat("%s: %s%s", e.Name, format_places(e.Speed, e.SpeedPlaces), e.SpeedSuffix)
			local start_size, end_size, start_text, end_text
			if not e.HideRange then
				local sa = MathClamp((e.Start - e.StartMin) / MathMax(e.StartMax - e.StartMin, 1e-6), 0, 1)
				local ea = MathClamp((e["End"] - e.EndMin) / MathMax(e.EndMax - e.EndMin, 1e-6), 0, 1)
				start_size = UDim2New(sa, 0, 1, 0)
				end_size = UDim2New(ea, 0, 1, 0)
				start_text = StringFormat("start: %s%s", format_places(e.Start, e.RangePlaces), e.StartSuffix)
				end_text = StringFormat("end: %s%s", format_places(e["End"], e.RangePlaces), e.EndSuffix)
			end
			safe_gui(function()
				if skip_tween then e.Items.SpeedAccent.Size = speed_size
				else Menu:Tween(e.Items.SpeedAccent, nil, { Size = speed_size }) end
				e.Items.SpeedLabel.Text = speed_text
				if not e.HideRange then
					if skip_tween then
						e.Items.StartAccent.Size = start_size
						e.Items.EndAccent.Size = end_size
					else
						Menu:Tween(e.Items.StartAccent, nil, { Size = start_size })
						Menu:Tween(e.Items.EndAccent, nil, { Size = end_size })
					end
					e.Items.StartLabel.Text = start_text
					e.Items.EndLabel.Text = end_text
				end
			end)
			if e.Flag then
				Menu.Flags[e.Flag] = { Speed = e.Speed, Start = e.Start, ["End"] = e["End"] }
			end
		end

		local function fire(silent)
			refresh(silent == true or Menu.LoadingConfig == true or (Menu.Silent or 0) > 0)
			if Menu:ShouldFire(silent) then
				e.Callback(e.Speed, e.Start, e["End"])
				self.Callback({ Speed = e.Speed, Start = e.Start, ["End"] = e["End"] })
			end
		end

		function e:Set(value, silent)
			if type(value) == "table" then
				if value.Speed ~= nil then e.Speed = snap_value(value.Speed, e.SpeedMin, e.SpeedMax, e.SpeedPlaces, e.SpeedIncrement) end
				if value.Start ~= nil then e.Start = snap_value(value.Start, e.StartMin, e.StartMax, e.RangePlaces, e.RangeIncrement) end
				if value["End"] ~= nil or value.End ~= nil then
					e["End"] = snap_value(value["End"] or value.End, e.EndMin, e.EndMax, e.RangePlaces, e.RangeIncrement)
				end
			elseif type(value) == "number" then
				e.Speed = snap_value(value, e.SpeedMin, e.SpeedMax, e.SpeedPlaces, e.SpeedIncrement)
			end
			fire(silent)
		end
		function e:Get() return e.Speed, e.Start, e["End"] end
		function e:GetValue() return { Speed = e.Speed, Start = e.Start, ["End"] = e["End"] } end
		function e:SetValue(value, silent) e:Set(value, silent) end

		local from_input = LPH_NO_VIRTUALIZE(function(kind)
			local btn = (kind == "Speed" and e.Items.SpeedButton)
				or (kind == "Start" and e.Items.StartButton) or e.Items.EndButton
			if not btn then return end
			local mouse = get_absolute_mouse()
			local alpha = MathClamp((mouse.X - btn.AbsolutePosition.X) / MathMax(btn.AbsoluteSize.X, 1), 0, 1)
			if kind == "Speed" then
				e.Speed = snap_value(e.SpeedMin + alpha * (e.SpeedMax - e.SpeedMin), e.SpeedMin, e.SpeedMax, e.SpeedPlaces, e.SpeedIncrement)
			elseif kind == "Start" then
				e.Start = snap_value(e.StartMin + alpha * (e.StartMax - e.StartMin), e.StartMin, e.StartMax, e.RangePlaces, e.RangeIncrement)
			else
				e["End"] = snap_value(e.EndMin + alpha * (e.EndMax - e.EndMin), e.EndMin, e.EndMax, e.RangePlaces, e.RangeIncrement)
			end
			fire(false)
		end)

		local function bind(btn, kind)
			if not btn then return end
			btn.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				self.SlidingEntry = e
				self.SlidingKind = kind
				from_input(kind)
				local mid = "SubSlider." .. tostring(e) .. "." .. kind
				Hook:Add("Mouse.Move", mid, LPH_NO_VIRTUALIZE(function()
					if self.SlidingEntry == e and self.SlidingKind == kind then from_input(kind) end
				end))
				Hook:Add("InputEnded", mid .. ".End", function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						self.SlidingEntry = nil
						self.SlidingKind = nil
						Hook:Remove(nil, mid)
						Hook:Remove(nil, mid .. ".End")
					end
				end)
			end)
		end
		bind(e.Items.SpeedButton, "Speed")
		bind(e.Items.StartButton, "Start")
		bind(e.Items.EndButton, "End")

		e:Set({ Speed = e.Speed, Start = e.Start, ["End"] = e["End"] }, true)
		if e.Flag then Config:RegisterElement(e, e.Flag, self.Category, entry.IgnoreConfig) end
		self.Entries[self.EntriesIndex] = e
		self:RelayoutEntries()
		return self
	end

	function SubSlider:GetValue()
		local out = {}
		for i = 1, self.EntriesIndex do
			local e = self.Entries[i]
			out[i] = { Speed = e.Speed, Start = e.Start, ["End"] = e["End"], Name = e.Name }
		end
		return out
	end

	function SubSlider:SetValue(value, silent)
		if type(value) ~= "table" then return end
		if value.Speed ~= nil and self.Entries[1] then
			self.Entries[1]:Set(value, silent)
			return
		end
		for i = 1, self.EntriesIndex do
			if type(value[i]) == "table" then self.Entries[i]:Set(value[i], silent) end
		end
	end

	SubSlider.Set = SubSlider.SetValue
	SubSlider.Get = SubSlider.GetValue
	function SubSlider:SetVisible(bool)
		Library:ApplyElementVisibility(self, bool)
	end
	SubSlider.SetVisibility = SubSlider.SetVisible
	Menu.Classes.SubSlider = SubSlider
end

Menu.ParticleMode = "None"
Menu.ParticlesEnabled = false

function Library:ClearBackgroundParticles()
	if Menu._particle_folder then
		pcall(function() Menu._particle_folder:ClearAllChildren() end)
	end
	local fx = self.BackgroundEffects
	if fx and fx.ParticleHolder then
		pcall(function() fx.ParticleHolder:ClearAllChildren() end)
	end
end

function Library:SetBackgroundEffect(mode)
	mode = mode or "None"
	Menu.ParticleMode = mode
	Menu.ParticlesEnabled = mode ~= "None"
	self.BackgroundEffect = mode

	Hook:Remove(nil, "Particles")
	self:ClearBackgroundParticles()
	if self.BackgroundEffects then
		self.BackgroundEffects.IsParticleActive = false
	end
	if not Menu.ParticlesEnabled then
		self:SetBackgroundEffectsVisible(self.WindowOpenState == true, true)
		return
	end

	self:SetupBackgroundEffects()
	local folder = self.BackgroundEffects and self.BackgroundEffects.ParticleHolder
	if not folder then
		if not Menu._particle_folder then
			Menu._particle_folder = Draw:Create("Frame", {
				Parent = Menu.Holder, Size = UDim2New(1, 0, 1, 0),
				BackgroundTransparency = 1, ZIndex = 0,
			})
		end
		folder = Menu._particle_folder
	else
		Menu._particle_folder = folder
	end

	local acc = 0
	Hook:Add("Heartbeat", "Particles", LPH_NO_VIRTUALIZE(function(dt)
		if Library.WindowOpenState ~= true or not Menu.ParticlesEnabled then return end
		local fx = Library.BackgroundEffects
		if fx then fx.IsParticleActive = true end
		acc += dt
		if acc < 0.12 then return end
		acc = 0
		local holder = (fx and fx.ParticleHolder) or folder
		if not holder or not holder.Parent then return end
		local vp = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2New(1920, 1080)
		local flake = Instance.new("Frame")
		flake.Size = UDim2New(0, mode == "Rain" and 2 or 3, 0, mode == "Rain" and 8 or 3)
		flake.Position = UDim2New(0, math.random(0, vp.X), 0, -10)
		flake.BackgroundColor3 = FromRGB(255, 255, 255)
		flake.BackgroundTransparency = 0.35
		flake.BorderSizePixel = 0
		flake.Parent = holder
		local fall = TweenService:Create(flake, TweenInfo.new(mode == "Rain" and 1.1 or 3.2, Enum.EasingStyle.Linear), {
			Position = UDim2New(0, flake.Position.X.Offset + (mode == "Snow" and math.random(-40, 40) or 0), 0, vp.Y + 20),
			BackgroundTransparency = 1,
		})
		fall:Play()
		fall.Completed:Connect(function()
			if flake and flake.Parent then flake:Destroy() end
		end)
	end))

	self:SetBackgroundEffectsVisible(self.WindowOpenState == true, true)
end

function Library:SafeCall(fn, ...)
	if type(fn) ~= "function" then return end
	local args = table.pack(...)
	local ok, err = pcall(function()
		return fn(table.unpack(args, 1, args.n))
	end)
	if not ok then
		local msg = tostring(err)

		if not StringFind(msg, "lacking capability Plugin", 1, true) then
			warn("[UILib]", err)
		end
	end
end

-- No default purchase URL: set Library.PremiumUrl yourself if you want the
-- "premium locked" affordance to point somewhere (e.g. your own site/Discord).
Library.PremiumUrl = Library.PremiumUrl or ""
Library.FreemiumMode = Library.FreemiumMode == true
local PremiumPlaceholders = setmetatable({}, { __mode = "k" })

function Library:OpenPurchasePrompt()
	local url = self.PremiumUrl
	if type(url) ~= "string" or url == "" then return end
	if setclipboard then
		pcall(setclipboard, url)
	elseif toclipboard then
		pcall(toclipboard, url)
	end
end

function Library:NotifyPremiumFeature()
	self:Notification({
		Name = "Premium Feature",
		Description = "This is a premium feature.",
	})
	self:OpenPurchasePrompt()
end

function Library:GuardPremiumInteract(element)
	if not element or element.PremiumLocked ~= true then return false end
	self:NotifyPremiumFeature()
	return true
end

function Library:IsPremiumPlaceholder(callback)
	return type(callback) == "function" and PremiumPlaceholders[callback] == true
end

function Library:IsPremiumElement(parameters)
	if type(parameters) ~= "table" then return false end
	if parameters.Premium == true or parameters.premium == true or parameters.Locked == true then
		return true
	end
	return self:IsPremiumPlaceholder(parameters.Callback or parameters.callback)
end

function Library:ApplyPremiumVisual(element)

	if not element or element.Class == "Hotkey" then
		return
	end
	if type(element.UI) ~= "table" then
		element.Premium = true
		element.PremiumLocked = true
		element.Disabled = true
		return
	end

	local ui = element.UI
	element.Premium = true
	element.PremiumLocked = true

	local function append_premium_label(text)
		text = tostring(text or "")
		if text == "" then return text end
		if StringFind(text, "(Premium)", 1, true) then return text end
		return text .. " (Premium)"
	end

	if type(element.Title) == "string" and element.Title ~= "" then
		element.Title = append_premium_label(element.Title)
	end
	if ui.Text then
		ui.Text.Text = append_premium_label(ui.Text.Text)
	end
	if ui.TrackLabel then
		local track = tostring(ui.TrackLabel.Text or "")
		local sep = StringFind(track, ":", 1, true)
		if sep then
			local name = StringSub(track, 1, sep - 1)
			local rest = StringSub(track, sep)
			ui.TrackLabel.Text = append_premium_label(name) .. rest
		else
			ui.TrackLabel.Text = append_premium_label(track)
		end
	end

	if type(element.SetDisabled) == "function" then
		element:SetDisabled(true)
	else
		element.Disabled = true
	end

	if ui.ValueBox then
		pcall(function() ui.ValueBox.TextEditable = false end)
	end
	if ui.Input then
		pcall(function() ui.Input.TextEditable = false end)
	end

	if type(element.SetValue) == "function" and (element.Class == "Toggle" or element.Class == "Checkbox") then
		element:SetValue(false, true)
	end

	if element.Class == "Colorpicker" then
		return
	end

	if ui.Framework and not element._premium_tip_bound then
		element._premium_tip_bound = true
		Library:BindTooltip(ui.Framework, "Premium feature")
	end
end

function Library.PlaceholderElement()
	local fn = function()
	end
	PremiumPlaceholders[fn] = true
	return fn
end
Library.placeholder_element = Library.PlaceholderElement

function Library:GetConfig()
	local config = {}
	local flags = self.Flags or Menu.Flags
	self:SafeCall(function()
		for index, value in next, flags do
			if self:IsScriptConfigFlag(index) ~= true then
				continue
			end

			local compact
			if type(value) == "table" and value.Key then
				compact = { Key = tostring(value.Key), Mode = value.Mode }
			elseif type(value) == "table" and value.Color then
				local hex = value.HexValue or value.Color
				if typeof(hex) == "Color3" then hex = hex:ToHex() end
				if type(hex) == "string" and StringSub(hex, 1, 1) == "#" then hex = StringSub(hex, 2) end
				compact = {
					Color = "#" .. tostring(hex),
					Alpha = self:RoundConfigNumber(value.Alpha or 0, 4),
				}
			elseif self.HideRangeSubSliderFlags[index] == true and type(value) == "table" and value.Speed ~= nil then
				local default_value = self.FlagDefaults[index]
				local default_start = type(default_value) == "table" and default_value.Start or 0
				local default_end = type(default_value) == "table" and (default_value["End"] or default_value.End) or 100
				local current_start = value.Start
				local current_end = value["End"] or value.End
				if self:RoundConfigNumber(current_start or 0, 4) == self:RoundConfigNumber(default_start, 4)
					and self:RoundConfigNumber(current_end or 100, 4) == self:RoundConfigNumber(default_end, 4) then
					compact = self:RoundConfigNumber(value.Speed, 4)
				else
					compact = self:CompactConfigValue(value)
				end
			else
				compact = self:CompactConfigValue(value)
			end

			local default_value = self.FlagDefaults[index]
			if default_value ~= nil then
				local default_compact = self:CompactConfigValue(default_value)
				if type(compact) == "number" and type(default_compact) == "table" and default_compact.Speed ~= nil then
					if self:RoundConfigNumber(compact, 4) == self:RoundConfigNumber(default_compact.Speed, 4) then
						continue
					end
				elseif self:ConfigValuesEqual(compact, default_compact) then
					continue
				end
			end

			config[index] = compact
		end
	end)
	return HttpService:JSONEncode(config)
end

function Library:LoadConfig(str)
	local decoded
	if type(str) == "table" then
		decoded = str
	else
		local ok, result = pcall(HttpService.JSONDecode, HttpService, str)
		if not ok or type(result) ~= "table" then
			return false, tostring(result)
		end
		decoded = result
	end

	if type(decoded.Flags) == "table" then
		decoded = decoded.Flags
	end

	self:BeginSilent()
	self.LoadingConfig = true
	Menu.LoadingConfig = true

	local failed = {}
	local set_flags = self.SetFlags
	local settings_flags = self.SettingsConfigFlags
	local script_flags = self.ScriptConfigFlags
	local elements = self.Elements

	run_with_elevated_thread_identity(function()
		for index, value in next, decoded do
			if type(index) ~= "string" then
				continue
			end
			local should_apply = settings_flags[index] == true
				or script_flags[index] == true
				or type(set_flags[index]) == "function"
				or (elements and elements[index] ~= nil)
				or self:IsScriptConfigFlag(index)
				or self:FindConfigElement(index) ~= nil
			if not should_apply then
				continue
			end
			local apply_ok, apply_err = pcall(self.ApplyConfigEntry, self, index, value)
			if not apply_ok then
				TableInsert(failed, tostring(index) .. ": " .. tostring(apply_err))
			end
		end
	end)

	self:FinishConfigLoad(decoded, failed)
	return true
end

function Library:GetTheme()
	local out = {}
	for k, v in next, Menu.Theme do
		out[k] = { Color = "#" .. v:ToHex(), Alpha = 0 }
	end
	return HttpService:JSONEncode(out)
end

function Library:LoadTheme(str)
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, str)
	if not ok or type(decoded) ~= "table" then return false end
	for k, v in next, decoded do
		if type(v) == "table" and v.Color then
			local c = v.Color
			if type(c) == "string" then
				if StringSub(c, 1, 1) ~= "#" then c = "#" .. c end
				Menu.Theme[k] = FromHex(c)
			end
		elseif typeof(v) == "Color3" then
			Menu.Theme[k] = v
		end
	end
	Menu:ChangeTheme()
	return true
end

function Library:ChangeTheme(key, value)
	Menu:ChangeTheme(key, value)
end

function Library:BindTooltip(gui, text)
	if not gui or text == nil or text == "" then return end
	local tip
	local function show()
		if tip then tip:Destroy() end
		local m = get_mouse_location()
		tip = Draw:Create("Frame", {
			Parent = Menu.Holder, AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2New(0, m.X + 12, 0, m.Y - 22),
			BackgroundColor3 = Menu.Theme.Background, BorderSizePixel = 0, ZIndex = 450,
			Theme = { BackgroundColor3 = "Background" },
		})
		corner(tip, 4)
		Draw:Create("UIPadding", {
			Parent = tip, PaddingTop = UDimNew(0, 4), PaddingBottom = UDimNew(0, 4),
			PaddingLeft = UDimNew(0, 6), PaddingRight = UDimNew(0, 6),
		})
		Draw:Create("TextLabel", {
			Parent = tip, AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1,
			Text = tostring(text), TextColor3 = Menu.Theme.Text, TextSize = 12, FontFace = Menu.Font,
			ZIndex = 451, Theme = { TextColor3 = "Text" },
		})
	end
	local function hide()
		if tip then tip:Destroy(); tip = nil end
	end
	gui.MouseEnter:Connect(show)
	gui.MouseLeave:Connect(hide)
end

function Library:Notification(data)
	data = data or {}
	task.wait()
	Menu.NotifLayoutOrder = (Menu.NotifLayoutOrder or 0) + 1

	local title = data.Title or data.Name or data.name or ""
	local desc = data.Description or data.description or data.Text or data.text or ""
	local duration = data.Duration or data.duration or data.Time or data.time or 5
	local accent = data.Color or data.color or Menu.Theme.Accent

	local pad_h, pad_v, gap, bar_gap, bar_h = 10, 8, 4, 6, 3
	local accent_w, accent_gap = 3, 8
	local max_w, min_w = 300, 160
	local title_size = Menu.FontSettings.TextSize or 14
	local desc_size = Menu.FontSettings.SmallTextSize or 12

	local function text_size(text, font_size, width)
		return TextService:GetTextSize(text, font_size, Enum.Font.Gotham, Vector2New(width > 0 and width or 10000, 10000))
	end

	local text_w = max_w - pad_h * 2 - accent_w - accent_gap
	local title_sz = title ~= "" and text_size(title, title_size, text_w) or Vector2New(0, 0)
	local desc_sz = desc ~= "" and text_size(desc, desc_size, text_w) or Vector2New(0, 0)
	local title_h = title ~= "" and MathMax(MathFloor(title_sz.Y + 0.5), title_size + 2) or 0
	local desc_h = desc ~= "" and MathMax(MathFloor(desc_sz.Y + 0.5), desc_size + 2) or 0
	local has_desc = desc ~= "" and desc_h > 0

	local content_w = MathMin(
		MathMax(MathFloor(title_sz.X + 0.5), MathFloor(desc_sz.X + 0.5), min_w - pad_h * 2 - accent_w - accent_gap)
			+ pad_h * 2 + accent_w + accent_gap,
		max_w
	)
	local body_h = title_h + (has_desc and (gap + desc_h) or 0)
	local size_y = pad_v * 2 + body_h + bar_gap + bar_h

	local fade_info = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local bar_info = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	local notif = Draw:Create("Frame", {
		Parent = Menu.NotifHolder, BackgroundColor3 = Menu.Theme.Inline,
		BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
		LayoutOrder = Menu.NotifLayoutOrder, Size = UDim2New(0, 0, 0, size_y), ZIndex = 50,
		Theme = { BackgroundColor3 = "Inline" },
	})
	corner(notif, 5)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Menu.Theme.Border
	stroke.Thickness = 1
	stroke.Transparency = 0.45
	stroke.Parent = notif
	Menu:AddToTheme(stroke, { Color = "Border" })
	Draw:Create("UIPadding", {
		Parent = notif, PaddingLeft = UDimNew(0, pad_h), PaddingRight = UDimNew(0, pad_h),
		PaddingTop = UDimNew(0, pad_v), PaddingBottom = UDimNew(0, pad_v),
	})
	Draw:Create("UIListLayout", {
		Parent = notif, Padding = UDimNew(0, bar_gap), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})

	local body = Draw:Create("Frame", {
		Parent = notif, Size = UDim2New(1, 0, 0, body_h), BackgroundTransparency = 1,
		BorderSizePixel = 0, LayoutOrder = 1, ZIndex = 51,
	})
	Draw:Create("UIListLayout", {
		Parent = body, Padding = UDimNew(0, accent_gap), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})

	local accent_bar = Draw:Create("Frame", {
		Parent = body, Size = UDim2New(0, accent_w, 1, 0), BackgroundColor3 = accent,
		BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1, ZIndex = 51,
	})
	corner(accent_bar, 2)

	local content = Draw:Create("Frame", {
		Parent = body, Size = UDim2New(1, -(accent_w + accent_gap), 0, body_h),
		BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 2, ZIndex = 51,
	})
	Draw:Create("UIListLayout", {
		Parent = content, Padding = UDimNew(0, gap), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})

	local title_lbl, desc_lbl
	if title ~= "" then
		title_lbl = Draw:Create("TextLabel", {
			Parent = content, Size = UDim2New(1, 0, 0, title_h), BackgroundTransparency = 1,
			Text = title, TextColor3 = Menu.Theme.Text, TextSize = title_size, FontFace = Menu.Font,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
			TextWrapped = true, TextTransparency = 1, LayoutOrder = 1, ZIndex = 51,
			Theme = { TextColor3 = "Text" },
		})
	end
	if has_desc then
		desc_lbl = Draw:Create("TextLabel", {
			Parent = content, Size = UDim2New(1, 0, 0, desc_h), BackgroundTransparency = 1,
			Text = desc, TextColor3 = Menu.Theme["Inactive Text"], TextSize = desc_size, FontFace = Menu.Font,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true, TextTransparency = 1, LayoutOrder = 2, ZIndex = 51,
			Theme = { TextColor3 = "Inactive Text" },
		})
	end

	local duration_bg = Draw:Create("Frame", {
		Parent = notif, Size = UDim2New(1, 0, 0, bar_h), BackgroundColor3 = Menu.Theme.Element,
		BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
		LayoutOrder = 2, ZIndex = 51, Theme = { BackgroundColor3 = "Element" },
	})
	corner(duration_bg, 2)
	local progress = Draw:Create("Frame", {
		Parent = duration_bg, Size = UDim2New(1, 0, 1, 0), BackgroundColor3 = accent,
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 52,
	})
	corner(progress, 2)

	task.spawn(function()
		Menu:Tween(notif, fade_info, { BackgroundTransparency = 0, Size = UDim2New(0, content_w, 0, size_y) })
		Menu:Tween(duration_bg, fade_info, { BackgroundTransparency = 0 })
		Menu:Tween(accent_bar, fade_info, { BackgroundTransparency = 0 })
		if title_lbl then Menu:Tween(title_lbl, fade_info, { TextTransparency = 0 }) end
		if desc_lbl then Menu:Tween(desc_lbl, fade_info, { TextTransparency = 0 }) end
		progress.Size = UDim2New(1, 0, 1, 0)

		Menu:Tween(progress, fade_info, { BackgroundTransparency = 0 })
		TweenService:Create(progress, bar_info, { Size = UDim2New(0, 0, 1, 0) }):Play()

		task.wait(duration + 0.15)
		if not notif.Parent then return end
		Menu:Tween(notif, fade_info, { BackgroundTransparency = 1, Size = UDim2New(0, 0, 0, size_y) })
		Menu:Tween(duration_bg, fade_info, { BackgroundTransparency = 1 })
		Menu:Tween(accent_bar, fade_info, { BackgroundTransparency = 1 })
		Menu:Tween(progress, fade_info, { BackgroundTransparency = 1 })
		if title_lbl then Menu:Tween(title_lbl, fade_info, { TextTransparency = 1 }) end
		if desc_lbl then Menu:Tween(desc_lbl, fade_info, { TextTransparency = 1 }) end
		task.wait(0.4)
		if notif then notif:Destroy() end
	end)
end

function Library:ConfirmDialog(data)
	data = data or {}
	if self._confirm_dialog_open then return end
	self._confirm_dialog_open = true

	local message = data.Message or data.message or "Are you sure?"
	local yes_text = data.Yes or data.yes or "Yes"
	local no_text = data.No or data.no or "No"
	local on_confirm = data.OnConfirm or data.on_confirm
	local on_cancel = data.OnCancel or data.on_cancel

	local overlay = Draw:Create("Frame", {
		Parent = Menu.Holder or Menu.Overlay, Size = UDim2New(1, 0, 1, 0),
		BackgroundColor3 = FromRGB(0, 0, 0), BackgroundTransparency = 0.45,
		BorderSizePixel = 0, ZIndex = 500,
	})
	local dialog = Draw:Create("Frame", {
		Parent = overlay, Size = UDim2New(0, 280, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2New(0.5, 0, 0.5, 0), AnchorPoint = Vector2New(0.5, 0.5),
		BackgroundColor3 = Menu.Theme.Background, BorderSizePixel = 0, ZIndex = 501,
		Theme = { BackgroundColor3 = "Background" },
	})
	corner(dialog, 6)
	ui_dual_stroke(dialog)
	Draw:Create("Frame", {
		Parent = dialog, Size = UDim2New(1, 0, 0, 1), BorderSizePixel = 0,
		BackgroundColor3 = Menu.Theme.Accent, ZIndex = 502, Theme = { BackgroundColor3 = "Accent" },
	})
	Draw:Create("UIPadding", {
		Parent = dialog, PaddingTop = UDimNew(0, 14), PaddingBottom = UDimNew(0, 12),
		PaddingLeft = UDimNew(0, 14), PaddingRight = UDimNew(0, 14),
	})
	Draw:Create("UIListLayout", {
		Parent = dialog, Padding = UDimNew(0, 12), SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Draw:Create("TextLabel", {
		Parent = dialog, LayoutOrder = 1, Size = UDim2New(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Text = message, TextColor3 = Menu.Theme.Text, TextSize = 14, FontFace = Menu.Font,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 502,
		Theme = { TextColor3 = "Text" },
	})

	local row = Draw:Create("Frame", {
		Parent = dialog, LayoutOrder = 2, Size = UDim2New(1, 0, 0, 24),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 502,
	})
	Draw:Create("UIListLayout", {
		Parent = row, Padding = UDimNew(0, 8),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local function close()
		self._confirm_dialog_open = false
		if overlay then overlay:Destroy() end
	end

	local function mk(text, order, cb)
		local b = Draw:Create("TextButton", {
			Parent = row, LayoutOrder = order, Size = UDim2New(1, 0, 0, 24),
			BackgroundColor3 = Menu.Theme.Element, BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, ZIndex = 502, Theme = { BackgroundColor3 = "Element" },
		})
		corner(b, 5)
		element_gradient(b)
		Draw:Create("TextLabel", {
			Parent = b, Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 1,
			Text = text, TextColor3 = Menu.Theme.Text, TextSize = 14, FontFace = Menu.Font, ZIndex = 503,
			Theme = { TextColor3 = "Text" },
		})
		b.MouseButton1Down:Connect(function()
			close()
			if cb then pcall(cb) end
		end)
	end

	mk(yes_text, 1, on_confirm)
	mk(no_text, 2, on_cancel)
end

local function create_hud_panel(opts)
	opts = opts or {}
	local parent = (Library.Holder and Library.Holder.Instance) or Menu.Holder
	local panel = {
		Visible = opts.Visible ~= false,
		Name = opts.Name or "Panel",
	}

	local root = Instances:Create("Frame", {
		Name = "\0",
		Parent = parent,
		AnchorPoint = opts.AnchorPoint or Vector2New(0, 0.5),
		Position = opts.Position or UDim2New(0, 10, 0.5, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Library.Theme["Background"],
		ZIndex = opts.ZIndex or 10,
		Visible = panel.Visible,
	}):AddToTheme({ BackgroundColor3 = "Background" })
	if type(opts.OnDragEnd) == "function" then
		make_draggable(root.Instance, opts.OnDragEnd)
	else
		root:MakeDraggable()
	end

	Instances:Create("UIStroke", {
		Parent = root.Instance,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter,
		Color = Library.Theme["Outline"],
	}):AddToTheme({ Color = "Outline" })

	Instances:Create("UIStroke", {
		Parent = root.Instance,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter,
		Color = Library.Theme["Border"],
		BorderOffset = UDimNew(0, 1),
	}):AddToTheme({ Color = "Border" })

	Instances:Create("UIPadding", {
		Parent = root.Instance,
		PaddingTop = UDimNew(0, 5),
		PaddingBottom = UDimNew(0, 5),
		PaddingLeft = UDimNew(0, 8),
		PaddingRight = UDimNew(0, 8),
	})

	local title = Instances:Create("TextLabel", {
		Name = "\0",
		Parent = root.Instance,
		Text = opts.Title or "",
		RichText = opts.RichText == true,
		BackgroundTransparency = 1,
		Size = UDim2New(0, 0, 0, 15),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		TextColor3 = Library.Theme["Text"],
		TextSize = Menu.FontSettings.TextSize or 14,
		FontFace = Library.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = (opts.ZIndex or 10) + 1,
	}):AddToTheme({ TextColor3 = "Text" })

	local liner = Instances:Create("Frame", {
		Name = "\0",
		Parent = root.Instance,
		Position = UDim2New(0, -2, 0, 20),
		Size = UDim2New(1, 4, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Library.Theme["Accent"],
		ZIndex = (opts.ZIndex or 10) + 1,
	}):AddToTheme({ BackgroundColor3 = "Accent" })

	local content = Instances:Create("Frame", {
		Name = "\0",
		Parent = root.Instance,
		BackgroundTransparency = 1,
		Position = UDim2New(0, 0, 0, 24),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = (opts.ZIndex or 10) + 1,
	})

	Instances:Create("UIListLayout", {
		Parent = content.Instance,
		Padding = UDimNew(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	panel.Root = root
	panel.TitleLabel = title
	panel.Content = content
	panel.Liner = liner
	panel.Items = {
		[panel.Name] = root,
		Text = title,
		Content = content,
		AccentLiner = liner,
	}

	function panel:SetVisibility(bool)
		self.Visible = bool == true
		root.Instance.Visible = self.Visible
	end
	function panel:SetVisible(bool)
		self:SetVisibility(bool)
	end
	function panel:SetText(text)
		title.Instance.Text = tostring(text or "")
	end
	function panel:SetTransparency()
		if type(Library.BackgroundTransparency) == "number" then
			root.Instance.BackgroundTransparency = Library.BackgroundTransparency
		end
	end
	function panel:SetCenter()
		local abs = root.Instance.AbsolutePosition
		task.wait()
		root.Instance.AnchorPoint = Vector2New(0, 0)
		root.Instance.Position = UDim2New(0, abs.X, 0, abs.Y + GuiService:GetGuiInset().Y)
	end
	function panel:Center()
		self:SetCenter()
	end

	return panel
end

Library.Watermark = function(self, NameOrOptions)
	local Data = type(NameOrOptions) == "table" and NameOrOptions or { Name = NameOrOptions }
	local BrandName = Data.Name or Data.name or "My Hub"

	local Dynamic = Data.Dynamic ~= false
	local DynamicOptions = Data.Options or Data.options or { "fps", "ping", "time" }

	local StatsService = svc("Stats")
	local WatermarkPath = GetFolders().Datas .. "/watermark.json"

	local function ColorToRgbStr(Color)
		return string.format(
			"rgb(%d,%d,%d)",
			MathFloor(Color.R * 255 + 0.5),
			MathFloor(Color.G * 255 + 0.5),
			MathFloor(Color.B * 255 + 0.5)
		)
	end

	local function FormatBrandRichText(Text)
		if not Text or Text == "" then
			return ""
		end
		if string.find(Text, "<font", 1, true) then
			return Text
		end
		local Lower = string.lower(Text)
		local HubIndex = string.find(Lower, "hub", 1, true)
		if HubIndex then
			local AccentColor = ColorToRgbStr(Library.Theme["Accent"])
			local Before = Text:sub(1, HubIndex - 1)
			local HubPart = Text:sub(HubIndex, HubIndex + 2)
			local After = Text:sub(HubIndex + 3)
			return Before .. '<font color="' .. AccentColor .. '">' .. HubPart .. "</font>" .. After
		end
		return Text
	end

	local function GetTime12h()
		local Time = os.date("*t")
		local Hour = Time.hour % 12
		if Hour == 0 then Hour = 12 end
		return string.format("%d:%02d %s", Hour, Time.min, Time.hour >= 12 and "PM" or "AM")
	end

	local function GetPing()
		local Success, Ping = pcall(function()
			return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		if Success and Ping then return MathFloor(Ping) end
		Success, Ping = pcall(function()
			return StatsService.PerformanceStats.Ping:GetValue()
		end)
		if Success and Ping then return MathFloor(Ping) end
		return 0
	end

	local Watermark = {
		CustomText = nil,
		Dynamic = Dynamic,
		DynamicOptions = DynamicOptions,
		BrandName = BrandName,
		IsVisible = false,
	}

	local shell = create_hud_panel({
		Name = "Watermark",
		Title = "",
		RichText = true,
		AnchorPoint = Vector2New(0.5, 0),
		Position = UDim2New(0.5, 0, 0, 12),
		ZIndex = 10,
		Visible = false,
	})
	local Items = shell.Items
	Items["Watermark"] = shell.Root
	Items["Text"] = shell.TitleLabel

	Items["Stats"] = Instances:Create("TextLabel", {
		Name = "\0",
		Parent = shell.Content.Instance,
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2New(0, 0, 0, 14),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		TextColor3 = Library.Theme["Inactive Text"] or Library.Theme["Text"],
		TextSize = Menu.FontSettings.SmallTextSize or 12,
		FontFace = Library.Font,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		ZIndex = 11,
	}):AddToTheme({ TextColor3 = "Inactive Text" })

	do
		local content_layout = shell.Content.Instance:FindFirstChildOfClass("UIListLayout")
		if content_layout then
			content_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		end
		Items["Text"].Instance.TextXAlignment = Enum.TextXAlignment.Center
	end

	local TargetFPS, TargetPing = 0, 0
	local DisplayFPS, DisplayPing = 0, 0
	local LastSample = os.clock()
	local LastSave = os.clock()
	local LastUpdate = os.clock()

	local RenderFuncs = {
		fps = function()
			return MathFloor(DisplayFPS) .. " fps"
		end,
		ping = function()
			return MathFloor(DisplayPing) .. " ms"
		end,
		time = function()
			return GetTime12h()
		end,
	}

	local DEFAULT_WATERMARK_Y = 12

	local function ApplyDefaultTopCenter()
		local Frame = Items["Watermark"].Instance
		Frame.AnchorPoint = Vector2New(0.5, 0)
		Frame.Position = UDim2New(0.5, 0, 0, DEFAULT_WATERMARK_Y)
	end

	local function SavePosition()
		if not writefile then return end
		pcall(function()
			local Frame = Items["Watermark"].Instance
			writefile(WatermarkPath, HttpService:JSONEncode({
				X = Frame.AbsolutePosition.X,
				Y = Frame.AbsolutePosition.Y,
				AnchorX = Frame.AnchorPoint.X,
				AnchorY = Frame.AnchorPoint.Y,
				ScaleX = Frame.Position.X.Scale,
				OffsetX = Frame.Position.X.Offset,
				ScaleY = Frame.Position.Y.Scale,
				OffsetY = Frame.Position.Y.Offset,
			}))
		end)
	end

	local function LoadPosition()
		if not readfile or not isfile or not isfile(WatermarkPath) then
			ApplyDefaultTopCenter()
			return false
		end
		local loaded = false
		pcall(function()
			local Saved = HttpService:JSONDecode(readfile(WatermarkPath))
			if type(Saved) ~= "table" then
				ApplyDefaultTopCenter()
				return
			end

			if type(Saved.ScaleX) == "number" then
				Items["Watermark"].Instance.AnchorPoint = Vector2New(
					tonumber(Saved.AnchorX) or 0.5,
					tonumber(Saved.AnchorY) or 0
				)
				Items["Watermark"].Instance.Position = UDim2New(
					tonumber(Saved.ScaleX) or 0.5,
					tonumber(Saved.OffsetX) or 0,
					tonumber(Saved.ScaleY) or 0,
					tonumber(Saved.OffsetY) or DEFAULT_WATERMARK_Y
				)
				loaded = true
				return
			end

			if type(Saved.X) == "number" and type(Saved.Y) == "number" then

				if Saved.X == 0 and (Saved.Y == 12 or Saved.Y == 42) then
					ApplyDefaultTopCenter()
					loaded = true
					return
				end
				Items["Watermark"].Instance.AnchorPoint = Vector2New(0, 0)
				Items["Watermark"].Instance.Position = UDim2New(0, Saved.X, 0, Saved.Y)
				loaded = true
				return
			end
			ApplyDefaultTopCenter()
		end)
		if not loaded then
			ApplyDefaultTopCenter()
		end
		return loaded
	end

	local function BuildDynamicText()
		local Parts = {}
		for i = 1, #Watermark.DynamicOptions do
			local OptionName = Watermark.DynamicOptions[i]
			local Render = RenderFuncs[OptionName]
			if Render then TableInsert(Parts, Render()) end
		end
		if #Parts == 0 then return "" end
		return TableConcat(Parts, "  ·  ")
	end

	local function SyncCenteredWidths()
		local title_lbl = Items["Text"].Instance
		local stats_lbl = Items["Stats"].Instance
		local title_w = title_lbl.TextBounds.X
		local stats_w = (stats_lbl.Visible and stats_lbl.TextBounds.X) or 0
		local width = MathMax(title_w, stats_w)
		if width < 1 then return end
		title_lbl.AutomaticSize = Enum.AutomaticSize.None
		title_lbl.Size = UDim2New(0, width, 0, 15)
		title_lbl.TextXAlignment = Enum.TextXAlignment.Center
		stats_lbl.AutomaticSize = Enum.AutomaticSize.None
		stats_lbl.Size = UDim2New(0, width, 0, 14)
		stats_lbl.TextXAlignment = Enum.TextXAlignment.Center
	end

	local function RefreshLabel()
		local TitleText = Watermark.CustomText or FormatBrandRichText(Watermark.BrandName)
		if Watermark.CustomText and not string.find(Watermark.CustomText, "<font", 1, true) then
			TitleText = FormatBrandRichText(Watermark.CustomText)
		end
		Items["Text"].Instance.Text = TitleText

		local StatsText = Watermark.Dynamic and BuildDynamicText() or ""
		local ShowStats = StatsText ~= ""
		Items["Stats"].Instance.Text = StatsText
		Items["Stats"].Instance.Visible = ShowStats
		Items["Content"].Instance.Visible = ShowStats
		task.defer(SyncCenteredWidths)
	end

	function Watermark:SetText(Text)
		Watermark.CustomText = Text and tostring(Text) or nil
		RefreshLabel()
	end

	local function ClampWatermarkPosition()
		local Frame = Items["Watermark"] and Items["Watermark"].Instance
		local Camera = Workspace.CurrentCamera
		if not Frame or not Camera then return end
		local Viewport = Camera.ViewportSize
		local Size = Frame.AbsoluteSize
		local Pos = Frame.AbsolutePosition
		local Inset = GuiService:GetGuiInset().Y
		local max_x = MathMax(0, Viewport.X - Size.X)
		local max_y = MathMax(0, Viewport.Y - Size.Y - Inset)
		local X = MathClamp(Pos.X, 0, max_x)
		local Y = MathClamp(Pos.Y, 0, max_y)


		if Frame.AnchorPoint.X == 0.5 and Frame.Position.X.Scale == 0.5 and Frame.Position.X.Offset == 0 then
			Frame.AnchorPoint = Vector2New(0.5, 0)
			Frame.Position = UDim2New(0.5, 0, 0, Y)
			return
		end

		Frame.AnchorPoint = Vector2New(0, 0)
		Frame.Position = UDim2New(0, X, 0, Y)
	end

	function Watermark:SetVisibility(Bool)
		local Visible = Bool == true
		Watermark.IsVisible = Visible
		if Items["Watermark"] and Items["Watermark"].Instance then
			Items["Watermark"].Instance.Visible = Visible
			if Visible then
				ClampWatermarkPosition()
				RefreshLabel()
			end
		end
	end
	function Watermark:SetVisible(Bool)
		self:SetVisibility(Bool)
	end

	function Watermark:SetTransparency()
		if type(Library.BackgroundTransparency) == "number" then
			Items["Watermark"].Instance.BackgroundTransparency = Library.BackgroundTransparency
		end
	end

	function Watermark:SetDynamic(Enabled, Options)
		Watermark.Dynamic = Enabled == true
		if Options then Watermark.DynamicOptions = Options end
		RefreshLabel()
	end

	function Watermark:SetCenter()
		ApplyDefaultTopCenter()
		SavePosition()
	end

	RefreshLabel()
	LoadPosition()
	Watermark:SetVisibility(self.ShowWatermark == true)
	Watermark:SetTransparency()

	Library:Connect(RunService.RenderStepped, LPH_NO_VIRTUALIZE(function(DeltaTime)
		if not Items["Watermark"].Instance.Visible then return end
		local Now = os.clock()
		local Step = Now - LastUpdate
		if Step < 0.1 then return end
		LastUpdate = Now
		if Now - LastSample > 0.25 then
			LastSample = Now
			TargetFPS = MathFloor(1 / math.max(DeltaTime, 1e-6))
			TargetPing = GetPing()
		end
		local LerpAlpha = math.min(1, Step * 8)
		DisplayFPS = DisplayFPS + (TargetFPS - DisplayFPS) * LerpAlpha
		DisplayPing = DisplayPing + (TargetPing - DisplayPing) * LerpAlpha
		if Watermark.Dynamic then RefreshLabel() end
		if Now - LastSave > 0.85 then
			LastSave = Now
			SavePosition()
		end
	end))

	Library.WatermarkGui = Items["Watermark"]
	Library.WatermarkInstance = Watermark
	Library.WatermarkObject = Watermark
	pcall(function() Library:ApplyFontSettings() end)
	return Watermark
end

function Library:KeybindList(name)
	name = name or "Keybinds"
	local shell = create_hud_panel({
		Name = "KeybindList",
		Title = name,
		AnchorPoint = Vector2New(0, 0.5),
		Position = UDim2New(0, 10, 0.5, 0),
		ZIndex = 10,
		Visible = Library.ShowKeybindList == true,
	})

	local list = {
		Frame = shell.Root.Instance,
		Items = shell.Items,
		Visible = shell.Visible,
	}

	function list:SetVisibility(bool)
		shell:SetVisibility(bool)
		self.Visible = shell.Visible
	end
	function list:SetVisible(bool) self:SetVisibility(bool) end
	function list:SetText(text) shell:SetText(text) end
	function list:SetTransparency() shell:SetTransparency() end
	function list:SetCenter() shell:SetCenter() end
	function list:Center() self:SetCenter() end
	function list:Resize() end

	function list:Add(key, bind_name, mode)
		local can_show = true
		local active = false
		local row = Instances:Create("TextLabel", {
			Name = "\0",
			Parent = shell.Content.Instance,
			Size = UDim2New(0, 0, 0, 14),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Text = "",
			TextColor3 = Library.Theme["Text"],
			TextTransparency = 0.35,
			TextSize = Menu.FontSettings.SmallTextSize or 12,
			FontFace = Library.Font,
			Visible = false,
			ZIndex = 12,
		}):AddToTheme({ TextColor3 = "Text" })

		local function paint()
			run_with_elevated_thread_identity(function()
				local k = tostring(key or "")
				local n = tostring(bind_name or "")
				local m = tostring(mode or "")
				row.Instance.Text = k .. "  ·  " .. n .. "  ·  " .. m
				row.Instance.TextTransparency = active and 0 or 0.35
			end)
		end
		paint()

		local entry = { Instance = row.Instance }
		function entry:Set(k, n, m)
			key, bind_name, mode = k, n, m
			paint()
		end
		function entry:SetStatus(bool)
			active = bool == true
			paint()
			run_with_elevated_thread_identity(function()
				row.Instance.Visible = can_show and active
			end)
		end
		function entry:SetVis(bool)
			can_show = bool == true
			run_with_elevated_thread_identity(function()
				if not can_show then
					row.Instance.Visible = false
				elseif active then
					row.Instance.Visible = true
				end
			end)
		end
		return entry
	end

	function list:SyncEntries()
		for i = 1, #Menu.KeybindEntries do
			local kb = Menu.KeybindEntries[i]
			if kb and not kb.KeyListItem then
				kb.KeyListItem = self:Add(kb.Key, kb.DisplayName, kb.Mode)
				if kb._UpdateList then kb:_UpdateList() end
			elseif kb and kb._UpdateList then
				kb:_UpdateList()
			end
		end
	end

	list:SetVisibility(Library.ShowKeybindList == true)
	list:SetTransparency()
	Library.KeyList = list
	list:SyncEntries()
	return list
end

function Library:CreateQuickConfigs()
	if self.QuickConfigs then
		return self.QuickConfigs
	end

	local max_slots = self.QuickConfigsMax or 4
	local default_pos = UDim2New(0, 10, 0, 120)
	local saved = self.QuickConfigsPosition or Menu.Flags.QuickConfigsPosition
	if type(saved) == "table" and saved.X and saved.Y then
		default_pos = UDim2New(saved.X.Scale or 0, saved.X.Offset or 10, saved.Y.Scale or 0, saved.Y.Offset or 120)
	end

	local function save_pos()
		local panel = self.QuickConfigs
		if not panel or not panel.Frame then return end
		local p = panel.Frame.Position
		local saved_pos = {
			X = { Scale = p.X.Scale, Offset = p.X.Offset },
			Y = { Scale = p.Y.Scale, Offset = p.Y.Offset },
		}
		self.QuickConfigsPosition = saved_pos
		Menu.Flags.QuickConfigsPosition = saved_pos
		self:SaveLocalSettings()
	end

	local shell = create_hud_panel({
		Name = "QuickConfigs",
		Title = "Quick Configs",
		AnchorPoint = Vector2New(0, 0),
		Position = default_pos,
		ZIndex = 10,
		Visible = self.ShowQuickConfigs == true,
		OnDragEnd = save_pos,
	})

	do
		local layout = shell.Content.Instance:FindFirstChildOfClass("UIListLayout")
		if layout then
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.Padding = UDimNew(0, 0)
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		end
	end

	local rows = {}
	local panel = {
		Frame = shell.Root.Instance,
		Items = shell.Items,
		Visible = shell.Visible,
	}

	function panel:SetVisibility(bool)
		shell:SetVisibility(bool)
		self.Visible = shell.Visible
	end
	function panel:SetVisible(bool)
		self:SetVisibility(bool)
	end
	function panel:SetTransparency()
		shell:SetTransparency()
	end

	function panel:Refresh()
		local content = shell.Content.Instance
		for i = 1, #rows do
			safe_destroy(rows[i])
			rows[i] = nil
		end
		TableClear(rows)

		local slots = Library.QuickConfigSlots
		if type(slots) ~= "table" then return end
		local shown = 0
		for i = 1, #slots do
			if shown >= max_slots then break end
			local name = slots[i]
			if type(name) ~= "string" or name == "" then continue end
			shown += 1

			if shown > 1 then
				local sep = Instances:Create("TextLabel", {
					Name = "\0",
					Parent = content,
					Size = UDim2New(0, 0, 0, 14),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Text = "  ·  ",
					TextColor3 = Library.Theme["Text"],
					TextTransparency = 0.35,
					TextSize = Menu.FontSettings.SmallTextSize or 12,
					FontFace = Library.Font,
					ZIndex = 12,
				}):AddToTheme({ TextColor3 = "Text" })
				TableInsert(rows, sep.Instance)
			end

			local row = Instances:Create("TextButton", {
				Name = "\0",
				Parent = content,
				Size = UDim2New(0, 0, 0, 14),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = name,
				TextColor3 = Library.Theme["Text"],
				TextTransparency = 0.35,
				TextSize = Menu.FontSettings.SmallTextSize or 12,
				FontFace = Library.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				ZIndex = 12,
			}):AddToTheme({ TextColor3 = "Text" })

			row.Instance.MouseEnter:Connect(function()
				Menu:Tween(row.Instance, nil, { TextTransparency = 0 })
			end)
			row.Instance.MouseLeave:Connect(function()
				Menu:Tween(row.Instance, nil, { TextTransparency = 0.35 })
			end)
			row.Instance.MouseButton1Click:Connect(function()
				local path = Library:GetFolder() .. name .. ".json"
				if not (isfile and isfile(path)) then
					Library:Notification({ Name = "Error", Description = "Failed to find config: " .. name })
					return
				end
				local success, err = Library:LoadConfig(readfile(path))
				if success then
					Library:Notification({ Name = "Success", Description = "Succesfully loaded config: " .. name })
				else
					Library:Notification({ Name = "Error", Description = "Failed to load config: " .. name .. " " .. tostring(err) })
				end
			end)

			TableInsert(rows, row.Instance)
		end
	end

	panel:SetVisibility(self.ShowQuickConfigs == true)
	panel:SetTransparency()
	panel:Refresh()
	self.QuickConfigs = panel
	return panel
end

function Library:SpectatorList(name)
	name = name or "Spectators"
	local shell = create_hud_panel({
		Name = "SpectatorList",
		Title = name,
		AnchorPoint = Vector2New(1, 0.5),
		Position = UDim2New(1, -10, 0.5, 0),
		ZIndex = 10,
		Visible = false,
	})

	local list = {
		Frame = shell.Root.Instance,
		Items = shell.Items,
		Visible = shell.Visible,
		_entries = {},
		_entries_index = 0,
	}

	function list:SetVisibility(bool)
		shell:SetVisibility(bool)
		self.Visible = shell.Visible
	end
	function list:SetVisible(bool) self:SetVisibility(bool) end
	function list:SetText(text) shell:SetText(text) end
	function list:SetTransparency() shell:SetTransparency() end
	function list:SetCenter() shell:SetCenter() end
	function list:Center() self:SetCenter() end

	local function format_value(v)
		local t = type(v)
		if t == "number" then
			if v == MathFloor(v) then return tostring(MathFloor(v)) end
			return string.format("%.2f", v)
		elseif t == "boolean" then
			return v and "true" or "false"
		end
		return tostring(v)
	end

	local function build_data_text(data)
		if type(data) ~= "table" then return "" end
		local parts = {}
		for k, v in next, data do
			if type(k) == "string" then
				TableInsert(parts, tostring(k) .. ": " .. format_value(v))
			end
		end
		table.sort(parts)
		return TableConcat(parts, "  ·  ")
	end

	local function avatar_url(user_id)
		return "https://www.roblox.com/headshot-thumbnail/image?userId="
			.. tostring(user_id)
			.. "&width=48&height=48&format=png"
	end

	function list:Add(config)
		config = config or {}
		local player = config.Player or config.player
		local title = config.Title or config.title
		local data = {}
		if type(config.Data) == "table" then
			for k, v in next, config.Data do data[k] = v end
		elseif type(config.data) == "table" then
			for k, v in next, config.data do data[k] = v end
		end

		if not title and player and typeof(player) == "Instance" and player:IsA("Player") then
			title = player.DisplayName or player.Name
		end
		title = tostring(title or "Spectator")

		local row = Instances:Create("Frame", {
			Name = "\0",
			Parent = shell.Content.Instance,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2New(0, 0, 0, 0),
			ZIndex = 12,
		})

		local header = Instances:Create("Frame", {
			Name = "\0",
			Parent = row.Instance,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2New(0, 0, 0, 16),
			ZIndex = 12,
		})
		Instances:Create("UIListLayout", {
			Parent = header.Instance,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDimNew(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		local avatar
		if player and typeof(player) == "Instance" and player:IsA("Player") then
			avatar = Instances:Create("ImageLabel", {
				Name = "\0",
				Parent = header.Instance,
				Size = UDim2New(0, 14, 0, 14),
				BackgroundTransparency = 1,
				Image = avatar_url(player.UserId),
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
				ZIndex = 13,
			})
			Instances:Create("UICorner", {
				Parent = avatar.Instance,
				CornerRadius = UDimNew(1, 0),
			})
		end

		local title_lbl = Instances:Create("TextLabel", {
			Name = "\0",
			Parent = header.Instance,
			BackgroundTransparency = 1,
			Size = UDim2New(0, 0, 0, 14),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = title,
			TextColor3 = Library.Theme["Text"],
			TextSize = Menu.FontSettings.SmallTextSize or 12,
			FontFace = Library.Font,
			LayoutOrder = 2,
			ZIndex = 13,
		}):AddToTheme({ TextColor3 = "Text" })

		local data_lbl = Instances:Create("TextLabel", {
			Name = "\0",
			Parent = row.Instance,
			BackgroundTransparency = 1,
			Size = UDim2New(0, 0, 0, 12),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = build_data_text(data),
			TextColor3 = Library.Theme["Inactive Text"] or Library.Theme["Text"],
			TextSize = 11,
			FontFace = Library.Font,
			Visible = next(data) ~= nil,
			ZIndex = 12,
			LayoutOrder = 2,
		}):AddToTheme({ TextColor3 = "Inactive Text" })

		Instances:Create("UIListLayout", {
			Parent = row.Instance,
			Padding = UDimNew(0, 1),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
		})
		header.Instance.LayoutOrder = 1

		local entry = {
			Player = player,
			Title = title,
			Data = data,
			_row = row,
			_title = title_lbl,
			_data = data_lbl,
			_avatar = avatar,
			_alive = true,
		}

		local function refresh()
			if not entry._alive then return end
			title_lbl.Instance.Text = entry.Title
			local text = build_data_text(entry.Data)
			data_lbl.Instance.Text = text
			data_lbl.Instance.Visible = text ~= ""
		end

		function entry:Update(payload)
			payload = payload or {}
			if payload.Title ~= nil or payload.title ~= nil then
				self.Title = tostring(payload.Title or payload.title)
			end
			if payload.Player ~= nil then self.Player = payload.Player end
			local incoming = payload.Data or payload.data
			if type(incoming) == "table" then

				local next_data = {}
				for k, v in next, incoming do next_data[k] = v end
				self.Data = next_data
			end
			refresh()
		end

		function entry:SetData(key, value)
			if type(key) ~= "string" then return end
			self.Data[key] = value
			refresh()
		end

		function entry:RemoveData(key)
			if type(key) ~= "string" then return end
			self.Data[key] = nil
			refresh()
		end

		function entry:SetVisible(bool)
			if not self._alive then return end
			row.Instance.Visible = bool == true
		end

		function entry:Destroy()
			if not self._alive then return end
			self._alive = false
			if row and row.Instance then row.Instance:Destroy() end
			for i = 1, list._entries_index do
				if list._entries[i] == self then
					list._entries[i] = nil
					break
				end
			end
		end

		self._entries_index += 1
		self._entries[self._entries_index] = entry

		if player and typeof(player) == "Instance" and player:IsA("Player") then
			local conn
			conn = Players.PlayerRemoving:Connect(function(left)
				if left == player and entry._alive then
					entry:Destroy()
					if conn then conn:Disconnect() end
				end
			end)
			entry._leave_conn = conn
		end

		refresh()
		return entry
	end

	function list:Remove(target)
		if type(target) == "table" and target.Destroy then
			target:Destroy()
			return
		end
		if typeof(target) == "Instance" and target:IsA("Player") then
			for i = 1, self._entries_index do
				local e = self._entries[i]
				if e and e.Player == target then
					e:Destroy()
				end
			end
		end
	end

	function list:Clear()
		for i = 1, self._entries_index do
			local e = self._entries[i]
			if e and e.Destroy then e:Destroy() end
		end
		self._entries = {}
		self._entries_index = 0
	end

	list:SetVisibility(false)
	list:SetTransparency()
	Library.SpectatorListObject = list
	Library.SpectatorListInstance = list
	return list
end

function Library:Unload()
	self._confirm_dialog_open = false
	Library:ApplyMouseForMenu(false)
	if Library.ApplyWindowInputState then Library:ApplyWindowInputState(false) end
	if Library.SetExternalGuisBlocked then Library:SetExternalGuisBlocked(false) end
	Library:SetBackgroundEffect("None")
	if Library.BackgroundEffects and Library.BackgroundEffects.BlurEffect then
		pcall(function() Library.BackgroundEffects.BlurEffect:Destroy() end)
	end
	pcall(function()
		ContextActionService:UnbindAction(Library.InputBlockAction or "HubInputBlock")
		ContextActionService:UnbindAction((Library.InputBlockAction or "HubInputBlock") .. "_MOUSE")
	end)
	for id, conn in next, Menu.Connections do
		pcall(function() conn:Disconnect() end)
		Menu.Connections[id] = nil
	end
	for id, conn in next, Hook.Events do
		pcall(function() conn:Disconnect() end)
		Hook.Events[id] = nil
	end
	if Menu.Holder then Menu.Holder:Destroy() end
	if Menu.Overlay then Menu.Overlay:Destroy() end
	if Menu.Other then Menu.Other:Destroy() end
	if Menu.FloatingButtonHolder then Menu.FloatingButtonHolder:Destroy() end
	if Menu.InputBlockGui then Menu.InputBlockGui:Destroy() end
	if Menu.CursorGui then Menu.CursorGui:Destroy() end
	Menu._particle_folder = nil
	Menu.FloatingButton = nil
	Library.FloatingButton = nil
	Library.BackgroundEffects = nil
	TableClear(Menu.Flags)
	TableClear(Menu.Elements)
	TableClear(Menu.ThemeItems)
	TableClear(Menu.SearchItems)
	TableClear(Menu.GlobalSearchIndex)
	Library.QuickConfigs = nil
	Library._quick_config_dropdown = nil
	Library._config_dropdown = nil
	if getgenv().Library == Library then getgenv().Library = nil end
end

function Library:RefreshThemeList(dropdown)
	if not dropdown or not dropdown.Refresh then return end
	local list = {}
	for name in next, Themes do TableInsert(list, name) end
	if listfiles and isfolder and isfolder(Folders.Themes) then
		local files = listfiles(Folders.Themes)
		for i = 1, #files do
			local f = files[i]
			if StringSub(f, -5) == ".json" then
				local n = StringGsub(StringGsub(f, "^.*[\\/]", ""), "%.json$", "")
				local found = false
				for j = 1, #list do
					if list[j] == n then found = true; break end
				end
				if not found then TableInsert(list, n) end
			end
		end
	end
	table.sort(list)
	dropdown:Refresh(list)
end

function Library:CreateSettingsPage(window, watermark, keybind_list)
	local page = window:Page({ Name = "Settings" })
	local menu_tab = page:SubPage({ Name = "Menu" })
	local themes = page:SubPage({ Name = "Themes" })
	local configs = page:SubPage({ Name = "Configs" })


	local general_sec = menu_tab:Section({ Name = "General", Side = 1, Collapsed = false })
	local appearance_sec = menu_tab:Section({ Name = "Appearance", Side = 2, Collapsed = false })

	general_sec:Button():Add("Unload", function()
		Library:ConfirmDialog({ Message = "Unload UI?", OnConfirm = function() Library:Unload() end })
	end)
	general_sec:Button():Add("Reset Positions", function()
		if Library.ResetPositions then Library:ResetPositions() end
	end)
	general_sec:Label("Menu Keybind"):Hotkey({
		Flag = "Menu Keybind", Default = Enum.KeyCode.RightControl, Mode = "Toggle",
		Callback = function()
			local v = Menu.Flags["Menu Keybind"]
			if type(v) == "table" and v.Key then
				Menu.MenuKeybind = Library:NormalizeKeybindKey(v.Key)
			end
		end,
	})
	general_sec:Dropdown({
		Name = "Menu Scale Preset", Flag = "Menu Scale Preset",
		Items = { "Very Small", "Small", "Medium", "Large", "Bigger", "Massive" },
		Default = Library.MenuScalePreset or "Medium",
		Callback = function(v)
			local scale_map = {
				["Very Small"] = 1200, Small = 1100, Medium = 1000,
				Large = 800, Bigger = 600, Massive = 500,
			}
			Library.MenuScalePreset = v
			if Library.SetScaleNumeric then Library:SetScaleNumeric(scale_map[v] or 1000)
			else
				local vp = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2New(1920, 1080)
				Menu.UIScale.Scale = MathClamp(vp.Y / (scale_map[v] or 1000), 0.4, 2)
			end
			Library:SaveLocalSettings()
		end,
	})
	general_sec:Toggle({
		Name = "Safe Mode", Flag = "Safe Mode", Default = Library.SafeMode == true,
		Callback = function(v)
			Menu.SafeMode = v == true
			Library.SafeMode = v == true
			Library:SaveLocalSettings()
			if v and window and window.SetOpen then
				window:SetOpen(false)
				if Menu.FloatingButtonHolder then
					Menu.FloatingButtonHolder.Enabled = Library.ShowMenuButton ~= false
				end
			end
		end,
	})
	general_sec:Toggle({
		Name = "Auto Execute", Flag = "Auto Execute",
		Default = Library.AutoExecute == true,
		Callback = function(v)
			Library.AutoExecute = v == true
			Menu.AutoExecute = v == true
			Library:SaveLocalSettings()
			-- No hardcoded loader here anymore: this used to silently re-fetch and
			-- re-run the original author's entire hub (incl. its own separate
			-- key/license gate) via queueonteleport on every teleport. Set
			-- Library.AutoExecuteScript to a Lua source string you control
			-- (e.g. 'loadstring(readfile("ExampleUI.lua"))()') if you want this
			-- feature back, pointed at your own code.
			if v and not getgenv().auto_execute then
				getgenv().auto_execute = true
				task.wait(0.3)
				pcall(function()
					if queueonteleport and type(Library.AutoExecuteScript) == "string" and Library.AutoExecuteScript ~= "" then
						queueonteleport(Library.AutoExecuteScript)
					end
				end)
			end
		end,
	})
	general_sec:Toggle({
		Name = "Auto Save Config", Flag = "Auto Save Config", Default = Library.AutoSave == true,
		Callback = function(v) Menu.AutoSave = v == true; Library.AutoSave = v == true end,
	})

	appearance_sec:Toggle({
		Name = "Show Watermark", Flag = "Show Watermark", Default = Library.ShowWatermark == true,
		Callback = function(v)
			Library.ShowWatermark = v == true
			local wm = watermark or Library.WatermarkObject or Library.WatermarkInstance
			if wm and wm.SetVisible then wm:SetVisible(v)
			elseif wm and wm.SetVisibility then wm:SetVisibility(v) end
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Toggle({
		Name = "Show Keybind List", Flag = "Show Keybind List", Default = Library.ShowKeybindList == true,
		Callback = function(v)
			Library.ShowKeybindList = v == true
			local kb = keybind_list or Library.KeyList
			if kb and kb.SetVisible then kb:SetVisible(v)
			elseif kb and kb.SetVisibility then kb:SetVisibility(v) end
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Toggle({
		Name = "Show Quick Configs", Flag = "Show Quick Configs", Default = Library.ShowQuickConfigs == true,
		Callback = function(v)
			Library.ShowQuickConfigs = v == true
			if not Library.QuickConfigs and Library.CreateQuickConfigs then
				Library:CreateQuickConfigs()
			end
			local qc = Library.QuickConfigs
			if qc and qc.SetVisible then qc:SetVisible(v)
			elseif qc and qc.SetVisibility then qc:SetVisibility(v) end
			if qc and qc.SetTransparency then qc:SetTransparency() end
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Toggle({
		Name = "Show Menu Button", Flag = "Show Menu Button", Default = Library.ShowMenuButton ~= false,
		Callback = function(v)
			Library.ShowMenuButton = v == true
			Menu.ShowMenuButton = v == true
			if Menu.FloatingButtonHolder then Menu.FloatingButtonHolder.Enabled = v == true end
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Slider({
		Name = "Background Transparency", Flag = "Background Transparency",
		Min = 0, Max = 1, Decimals = 0.01, Default = Library.BackgroundTransparency or 0.3, Compact = true,
		Callback = function(v)
			Library.BackgroundTransparency = v
			if window and window.SetTransparency then window:SetTransparency(v) end
			local wm = watermark or Library.WatermarkObject or Library.WatermarkInstance
			if wm and wm.SetTransparency then wm:SetTransparency() end
			local kb = keybind_list or Library.KeyList
			if kb and kb.SetTransparency then kb:SetTransparency() end
			local qc = Library.QuickConfigs
			if qc and qc.SetTransparency then qc:SetTransparency() end
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Toggle({
		Name = "Background Darken", Flag = "Background Darken", Default = Library.BackgroundDarkenEnabled ~= false,
		Callback = function(v)
			if Library.SetBackgroundDarkenEnabled then Library:SetBackgroundDarkenEnabled(v)
			else Library.BackgroundDarkenEnabled = v == true end
		end,
	})
	appearance_sec:Dropdown({
		Name = "Background Effect", Flag = "Background Effect",
		Items = { "None", "Snow", "Rain" }, Default = Menu.ParticleMode or "None",
		Callback = function(v)
			Library:SetBackgroundEffect(v)
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Slider({
		Name = "Menu Tween Time", Flag = "Menu Tween Time",
		Min = 0, Max = 5, Decimals = 0.01, Default = Menu.TweenSettings.Time, Compact = true,
		Callback = function(v)
			Menu.TweenSettings.Time = v; Library.Tween.Time = v
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Slider({
		Name = "Menu Fade Speed", Flag = "Menu Fade Speed",
		Min = 0, Max = 1, Decimals = 0.01, Default = Library.FadeSpeed or 0.15, Compact = true,
		Callback = function(v)
			Library.FadeSpeed = v
			Menu.FadeSpeed = v
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Dropdown({
		Name = "Menu Tween Style", Flag = "Menu Tween Style",
		Items = { "Linear", "Sine", "Quad", "Cubic", "Quart", "Quint", "Exponential", "Circular", "Back", "Elastic", "Bounce" },
		Default = "Quad",
		Callback = function(v)
			local style = Enum.EasingStyle[v]
			if style then Menu.TweenSettings.Style = style; Library.Tween.Style = style end
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Dropdown({
		Name = "Menu Tween Direction", Flag = "Menu Tween Direction",
		Items = { "In", "Out", "InOut" }, Default = "Out",
		Callback = function(v)
			local dir = Enum.EasingDirection[v]
			if dir then Menu.TweenSettings.Direction = dir; Library.Tween.Direction = dir end
			Library:SaveLocalSettings()
		end,
	})
	appearance_sec:Dropdown({
		Name = "Menu Font", Flag = "Menu Font", Items = Library:GetFontNames(), Default = Menu.FontSettings.Name,
		Callback = function(v) Library:ApplyFont(v); Library:SaveLocalSettings() end,
	})


	local colors_sec = themes:Section({ Name = "Colors", Side = 1, Collapsed = false })
	local manage_sec = themes:Section({ Name = "Manage", Side = 2, Collapsed = false })
	local theme_pickers = {}

	for key, value in next, Menu.Theme do
		theme_pickers[key] = colors_sec:Label(key):Colorpicker({
			Flag = key,
			Default = value,
			Callback = function(c)
				Menu.Theme[key] = c
				Menu:ChangeTheme(key, c)
			end,
		})
	end

	local theme_folder = Folders.Themes
	if makefolder and not (isfolder and isfolder(theme_folder)) then pcall(makefolder, theme_folder) end

	local selected_theme, theme_name

	local preset_names = {}
	for name in next, Themes do TableInsert(preset_names, name) end
	table.sort(preset_names)
	manage_sec:Dropdown({
		Name = "Themes Preset", Flag = "Themes Preset", Items = preset_names, Default = "Default",
		Callback = function(v)
			local data = Themes[v]
			if not data then return end
			for k in next, Menu.Theme do
				if data[k] then
					Menu.Theme[k] = data[k]
					Menu:ChangeTheme(k, data[k])
					if theme_pickers[k] and theme_pickers[k].Set then theme_pickers[k]:Set(data[k], true) end
				end
			end
		end,
	})

	local theme_drop = manage_sec:Dropdown({
		Name = "Themes Select", Flag = "Themes Select", Items = {}, Default = "Default",
		Callback = function(v) selected_theme = v end,
	})
	Library._theme_dropdown = theme_drop
	Library:RefreshThemeList(theme_drop)

	manage_sec:Textbox({
		Name = "Theme Name", Flag = "Theme Name", Placeholder = "Theme Name...", Finished = true,
		Callback = function(v) theme_name = v end,
	})
	manage_sec:Button()
		:Add("Load", function()
			if not selected_theme then return end
			if Themes[selected_theme] then
				Menu.Theme = TableClone(Themes[selected_theme])
				Library.Theme = Menu.Theme
				Menu:ChangeTheme()
				for k, picker in next, theme_pickers do
					if Menu.Theme[k] and picker.Set then picker:Set(Menu.Theme[k], true) end
				end
				Library:Notification({ Name = "Success", Description = "Loaded preset: " .. selected_theme })
				return
			end
			local path = theme_folder .. "/" .. selected_theme .. ".json"
			if isfile and isfile(path) and Library:LoadTheme(readfile(path)) then
				for k, picker in next, theme_pickers do
					if Menu.Theme[k] and picker.Set then picker:Set(Menu.Theme[k], true) end
				end
				Library:Notification({ Name = "Success", Description = "Loaded: " .. selected_theme })
			end
		end)
		:Add("Save", function()
			if not selected_theme or not writefile then return end
			writefile(theme_folder .. "/" .. selected_theme .. ".json", Library:GetTheme())
			Library:Notification({ Name = "Success", Description = "Saved: " .. selected_theme })
		end)
	manage_sec:Button()
		:Add("Create", function()
			if not theme_name or theme_name == "" then return end
			if writefile then
				writefile(theme_folder .. "/" .. theme_name .. ".json", Library:GetTheme())
				Library:RefreshThemeList(theme_drop)
				Library:Notification({ Name = "Success", Description = "Created theme: " .. theme_name })
			end
		end)
		:Add("Delete", function()
			if not selected_theme then return end
			local path = theme_folder .. "/" .. selected_theme .. ".json"
			if isfile and isfile(path) then pcall(delfile, path) end
			Library:RefreshThemeList(theme_drop)
			Library:Notification({ Name = "Success", Description = "Deleted: " .. tostring(selected_theme) })
		end)
	manage_sec:Button():Add("Refresh", function() Library:RefreshThemeList(theme_drop) end)
	manage_sec:Toggle({
		Name = "Autoload Theme", Flag = "Autoload Theme",
		Default = Library.AutoloadThemeEnabled == true or Menu.AutoloadTheme == true,
		Callback = function(v)
			Menu.AutoloadTheme = v == true
			Library.AutoloadThemeEnabled = v == true
			Library:SaveLocalSettings()
			if v and selected_theme and writefile then
				writefile(theme_folder .. "/autoload_theme.txt", selected_theme)
			elseif not v and isfile and isfile(theme_folder .. "/autoload_theme.txt") then
				pcall(delfile, theme_folder .. "/autoload_theme.txt")
			end
		end,
	})


	local cfg_sec = configs:Section({ Name = "Script Config", Side = 1, Collapsed = false })
	local server_sec = configs:Section({ Name = "Server Options", Side = 2, Collapsed = false })
	local data_sec = configs:Section({ Name = "Data", Side = 2, Collapsed = false })

	local cfg_folder = Library:GetFolder()
	local autoload_name_path = GetAutoloadConfigNamePath()
	local selected, name, pasted = nil, nil, ""

	local function sanitize_name(n)
		if type(n) ~= "string" then return "" end
		n = StringGsub(n, '[%?%*:|<>/"\\]', "")
		return StringGsub(StringGsub(n, "^%s+", ""), "%s+$", "")
	end

	local function try_write_config_file(path, content)
		if type(writefile) ~= "function" or type(path) ~= "string" or path == "" then return false end
		return pcall(writefile, path, content) == true
	end

	local drop = cfg_sec:Dropdown({
		Name = "Config Select", Flag = "Config Select",
		Items = {},
		Callback = function(v) selected = v end,
	})
	Library._config_dropdown = drop

	local quick_drop = cfg_sec:Dropdown({
		Name = "Quick Config Slots", Flag = "Quick Config Slots",
		Items = {},
		Multi = true,
		Max = Library.QuickConfigsMax or 4,
		Default = Library.QuickConfigSlots or {},
		Callback = function(v)
			local slots = {}
			if type(v) == "table" then
				local max_n = Library.QuickConfigsMax or 4
				for i = 1, #v do
					if #slots >= max_n then break end
					local n = tostring(v[i])
					if n ~= "" then TableInsert(slots, n) end
				end
			end
			Library.QuickConfigSlots = slots
			Menu.Flags["Quick Config Slots"] = slots
			if Library.QuickConfigs and Library.QuickConfigs.Refresh then
				Library.QuickConfigs:Refresh()
			end
			Library:SaveLocalSettings()
		end,
	})
	Library._quick_config_dropdown = quick_drop

	cfg_sec:Toggle({
		Name = "Autoload Configuration",
		Flag = "Autoload Configuration",
		Default = Library.AutoloadConfigEnabled == true or Menu.AutoloadConfig == true,
		Callback = function(v)
			Menu.AutoloadConfig = v == true
			Library.AutoloadConfigEnabled = v == true
			Library:SaveLocalSettings()
		end,
	})

	cfg_sec:Textbox({
		Name = "Config Name", Flag = "Config Name",
		Placeholder = "Config Name...", Finished = false,
		Callback = function(v) name = v end,
	})

	local function notify_ok(msg)
		Library:Notification({ Name = "Success", Description = msg })
	end
	local function notify_err(msg)
		Library:Notification({ Name = "Error", Description = msg })
	end

	local autoload_label
	local function refresh_autoload_label()
		if autoload_label and autoload_label.SetText then
			autoload_label:SetText("Current autoload config: " .. GetAutoloadConfigName())
		end
	end

	cfg_sec:Button()
		:Add("Create", function()
			local safe = sanitize_name(name)
			if safe == "" then notify_err("Invalid config name (empty)"); return end
			if try_write_config_file(cfg_folder .. safe .. ".json", Library:GetConfig()) then
				Library:RefreshConfigsList(drop)
				notify_ok("Succesfully created config: " .. safe)
			else
				notify_err("Failed to create config")
			end
		end)
		:Add("Delete", function()
			if not selected then notify_err("Please select a config first"); return end
			local path = cfg_folder .. selected .. ".json"
			local ok, err = pcall(function()
				if isfile and isfile(path) then delfile(path) end
			end)
			if ok then
				Library:RefreshConfigsList(drop)
				notify_ok("Succesfully deleted config: " .. tostring(selected))
			else
				notify_err("Failed to delete config: " .. tostring(selected) .. " " .. tostring(err))
			end
		end)

	cfg_sec:Button()
		:Add("Load", function()
			if not selected then notify_err("Please select a config first"); return end
			local path = cfg_folder .. selected .. ".json"
			if not (isfile and isfile(path)) then notify_err("Failed to find config: " .. tostring(selected)); return end
			local success, err = Library:LoadConfig(readfile(path))
			if success then notify_ok("Succesfully loaded config: " .. selected)
			else notify_err("Failed to load config: " .. tostring(selected) .. " " .. tostring(err)) end
		end)
		:Add("Save", function()
			if not selected then notify_err("Please select a config first"); return end
			local path = cfg_folder .. selected .. ".json"
			if not (isfile and isfile(path)) then notify_err("Failed to find config: " .. tostring(selected)); return end
			local ok, err = pcall(function() writefile(path, Library:GetConfig()) end)
			if ok then notify_ok("Succesfully saved config: " .. selected)
			else notify_err("Failed to save config: " .. tostring(selected) .. " " .. tostring(err)) end
		end)

	cfg_sec:Button():Add("Refresh", function()
		Library:RefreshConfigsList(drop)
	end)

	cfg_sec:Button()
		:Add("Set Autoload", function()
			if not selected or selected == "" then notify_err("Please select a config first"); return end
			local ok, err = pcall(function()
				writefile(autoload_name_path, selected)
			end)
			if ok then
				Menu.AutoloadConfig = true
				Library.AutoloadConfigEnabled = true
				Library:SaveLocalSettings()
				refresh_autoload_label()
				notify_ok("Set " .. selected .. " to auto load")
			else
				notify_err("Failed to set autoload: " .. tostring(err))
			end
		end)
		:Add("Remove Autoload", function()
			local ok, err = pcall(function()
				if isfile and isfile(autoload_name_path) then delfile(autoload_name_path) end
			end)
			if ok then
				refresh_autoload_label()
				notify_ok("Succesfully removed autoload")
			else
				notify_err("Failed to remove autoload: " .. tostring(err))
			end
		end)

	autoload_label = cfg_sec:Label("Current autoload config: " .. GetAutoloadConfigName())

	cfg_sec:Textbox({
		Name = "Paste Shared Config", Flag = "Paste Shared Config",
		Placeholder = "Paste Config Here...", Finished = true,
		Callback = function(v) pasted = v end,
	})

	cfg_sec:Button()
		:Add("Share Config", function()
			local raw = Library:GetConfig()
			local cleaned = StringGsub(raw, "https://discord%.com/api/webhooks/%d+/%S+", "")
			local ok, err = run_with_elevated_thread_identity(function()
				if setclipboard then setclipboard(cleaned) else error("setclipboard unavailable") end
			end)
			if ok then notify_ok("Config copied to clipboard (webhooks removed)")
			else notify_err("Failed to copy config: " .. tostring(err)) end
		end)
		:Add("Import Pasted", function()
			if not pasted or pasted == "" then notify_err("No config pasted"); return end
			local cleaned = StringGsub(pasted, "https://discord%.com/api/webhooks/%d+/%S+", "")
			local success, err = Library:LoadConfig(cleaned)
			if success then notify_ok("Succesfully imported config (webhooks removed)")
			else notify_err("Failed to import config: " .. tostring(err)) end
		end)

	Library:RefreshConfigsList(drop)
	if quick_drop and quick_drop.SetValue then
		quick_drop:SetValue(Library.QuickConfigSlots or {}, true)
	end

	local function notify_server(msg, color)
		Library:Notification({ Name = "Server Options", Description = msg, Color = color })
	end
	local function copy_clip(text)
		if setclipboard then setclipboard(tostring(text)) end
	end

	server_sec:Button()
		:Add("Rejoin", function()
			pcall(function()
				LocalPlayer:Kick("")
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end)
			notify_server("Rejoining...")
		end)
		:Add("Server Hop", function()
			local servers = {}
			local ok, body = pcall(function()
				if type(game.HttpGet) == "function" then
					return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
				end
			end)
			if ok and type(body) == "string" then
				local dec_ok, data = pcall(HttpService.JSONDecode, HttpService, body)
				if dec_ok and type(data) == "table" and type(data.data) == "table" then
					local rows = data.data
					for i = 1, #rows do
						local s = rows[i]
						if s.id ~= game.JobId and s.playing < s.maxPlayers then TableInsert(servers, s.id) end
					end
				end
			end
			pcall(function()
				LocalPlayer:Kick("")
				if #servers > 0 then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
					notify_server("Server hopping...")
				else
					TeleportService:Teleport(game.PlaceId, LocalPlayer)
					notify_server("No servers found, joining a new server", FromRGB(255, 200, 100))
				end
			end)
		end)

	server_sec:Button()
		:Add("Copy Place ID", function() copy_clip(game.PlaceId); notify_server("Place ID copied") end)
		:Add("Copy Game ID", function() copy_clip(game.GameId); notify_server("Game ID copied") end)

	server_sec:Button()
		:Add("Copy Job ID", function() copy_clip(game.JobId); notify_server("Job ID copied") end)
		:Add("Copy Join Code", function()
			copy_clip('cloneref(game:GetService("TeleportService"):TeleportToPlaceInstance(' .. game.PlaceId .. ', "' .. game.JobId .. '"))')
			notify_server("Join code copied")
		end)

	data_sec:Button():Add("Delete All Local Data", function()
		local roots = { BRAND_DIR .. "/Configurations", BRAND_DIR .. "/Themes", BRAND_DIR .. "/Datas", BRAND_DIR .. "/Assets", BRAND_DIR .. "/Images" }
		for i = 1, #roots do
			local root = roots[i]
			if isfolder and isfolder(root) and delfolder then pcall(delfolder, root) end
		end
		Library:Notification({ Name = "Data", Description = "Deleted local folders (configs, themes, settings, assets)" })
	end)

	if Library.FinalizeMenuSettings then
		Library:FinalizeMenuSettings(watermark, keybind_list, window)
	end

	return page
end

Library.DisplayOrders = {
	Holder = 100,
	HolderOpen = 1000,
	Overlay = 200,
	OverlayOpen = 1100,
	FloatingButton = 3,
	FloatingButtonOpen = 10000,
	Cursor = 10001,
	InputBlock = 50,
}

Library.SafeMode = Library.SafeMode == true
Library.ShowMenuButton = Library.ShowMenuButton ~= false
Library.ShowWatermark = Library.ShowWatermark == true
Library.ShowKeybindList = Library.ShowKeybindList == true
Library.ShowQuickConfigs = Library.ShowQuickConfigs == true
Library.QuickConfigSlots = Library.QuickConfigSlots or {}
Library.QuickConfigsMax = 4
Library.AutoExecute = Library.AutoExecute == true
Library.BackgroundDarkenEnabled = Library.BackgroundDarkenEnabled ~= false
Library.BackgroundTransparency = type(Library.BackgroundTransparency) == "number" and Library.BackgroundTransparency or 0.3
Library.MenuScalePreset = Library.MenuScalePreset or (IsMobile and "Massive" or "Medium")
Library.ExternalGuiStates = Library.ExternalGuiStates or {}
Library.InputBlockAction = "HubInputBlock"
Library.MouseCursorImage = Library.MouseCursorImage or "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png"
Library.MouseCursorImageFallback = Library.MouseCursorImageFallback or "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
Library.MouseCursorSize = Library.MouseCursorSize or 64
Library.MouseCursorHotspot = Library.MouseCursorHotspot or Vector2New(31, 32)
Library.UIScaleNumeric = Library.UIScaleNumeric or 1000
Library.UIScaleScreenPercent = Library.UIScaleScreenPercent or 0.7
Library.Pages = Library.Pages or {}

Menu.SafeMode = Library.SafeMode
Menu.ShowMenuButton = Library.ShowMenuButton
Menu.AutoExecute = Library.AutoExecute
Menu.BackgroundDarkenEnabled = Library.BackgroundDarkenEnabled

local SCALE_PRESETS = {
	["Very Small"] = 1200, Small = 1100, Medium = 1000,
	Large = 800, Bigger = 600, Massive = 500,
}

local function local_settings_path()
	return Folders.Datas .. "/" .. GameId .. "/settings.json"
end

function Library:SetScaleNumeric(value)
	value = MathClamp(tonumber(value) or 1000, 300, 1400)
	self.UIScaleNumeric = value
	self.UIScaleScreenPercent = value / 1400
	local vp = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2New(1920, 1080)
	local scale = MathFloor(MathClamp(vp.Y / value, 0.3, 3) * 100 + 0.5) / 100
	if Menu.UIScale then Menu.UIScale.Scale = scale end
	self.UIScaleNum = scale
end

function Library:SetScaleFromScreenPercent(percent)
	percent = MathClamp(tonumber(percent) or 0.7, 0.2, 1)
	self.UIScaleScreenPercent = percent
	local vp = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2New(1920, 1080)
	local scale = MathFloor(MathClamp(math.min(vp.X, vp.Y) / 1000 * percent / 0.7, 0.5, 1.2) * 100 + 0.5) / 100
	if Menu.UIScale then Menu.UIScale.Scale = scale end
	self.UIScaleNum = scale
end

function Library:GetHubGuiRoots()
	local roots = {}
	if Menu.Holder then TableInsert(roots, Menu.Holder) end
	if Menu.Overlay then TableInsert(roots, Menu.Overlay) end
	if Menu.Other then TableInsert(roots, Menu.Other) end
	if Menu.FloatingButtonHolder then TableInsert(roots, Menu.FloatingButtonHolder) end
	if Menu.InputBlockGui then TableInsert(roots, Menu.InputBlockGui) end
	if Menu.CursorGui then TableInsert(roots, Menu.CursorGui) end
	return roots
end

function Library:GetHubScreenGuis()
	local map = {}
	local roots = self:GetHubGuiRoots()
	for i = 1, #roots do map[roots[i]] = true end
	return map
end

function Library:IsHubGuiObject(object)
	if not object then return false end
	local roots = self:GetHubGuiRoots()
	for i = 1, #roots do
		local root = roots[i]
		if object == root or object:IsDescendantOf(root) then return true end
	end
	return false
end

Library.IsPointerOverHubGui = LPH_NO_VIRTUALIZE(function(self, position)
	local mouse = position or get_mouse_location()
	local objects = nil
	local ok, listed = pcall(function()
		return GuiService:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
	end)
	if ok and type(listed) == "table" then objects = listed end
	if type(objects) ~= "table" then return false end
	for i = 1, #objects do
		if self:IsHubGuiObject(objects[i]) then return true end
	end
	return false
end)

Library.IsPointerOverBlockWindowDrag = LPH_NO_VIRTUALIZE(function(self, position)
	if self.BlockWindowDrag == true then return true end
	local mouse = position or get_mouse_location()
	local ok, objects = pcall(function()
		return GuiService:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
	end)
	if not ok or type(objects) ~= "table" then return false end
	for i = 1, #objects do
		local object = objects[i]
		while object and object ~= game do
			if object:GetAttribute("BlockWindowDrag") == true then
				return true
			end
			object = object.Parent
			if typeof(object) ~= "Instance" then break end
			if object:IsA("LayerCollector") or object:IsA("PlayerGui") then break end
		end
	end
	return false
end)

function Library:SetExternalGuisBlocked(_bool)

	if self.ExternalGuiStates then
		for gui, was in next, self.ExternalGuiStates do
			if gui and gui.Parent and was then gui.Enabled = true end
		end
		self.ExternalGuiStates = {}
	end
end

function Library:SetupBackgroundEffects()
	if self.BackgroundEffects then return end
	if not Menu.InputBlockGui then return end

	local camera = Workspace.CurrentCamera
	local vp = (camera and camera.ViewportSize) or Vector2New(1920, 1080)

	local bg = Draw:Create("Frame", {
		Parent = Menu.InputBlockGui, BackgroundColor3 = FromRGB(0, 0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2New(0, vp.X, 0, vp.Y), Visible = false, Active = false, ZIndex = 0,
	})
	local particles = Draw:Create("Frame", {
		Parent = bg, BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2New(1, 0, 1, 0), ClipsDescendants = true, ZIndex = 0,
	})
	local blur = Instance.new("BlurEffect")
	blur.Name = "\0"
	blur.Size = 0
	if camera then blur.Parent = camera end

	self.BackgroundEffects = {
		Background = bg,
		ParticleHolder = particles,
		BlurEffect = blur,
		IsParticleActive = false,
	}

	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local c = Workspace.CurrentCamera
			if not c or not self.BackgroundEffects then return end
			local s = c.ViewportSize
			self.BackgroundEffects.Background.Size = UDim2New(0, s.X, 0, s.Y)
		end)
	end
end

function Library:SetBackgroundEffectsVisible(is_open, instant)
	self:SetupBackgroundEffects()
	local fx = self.BackgroundEffects
	if not fx then return end

	local show_darken = is_open == true and self.BackgroundDarkenEnabled ~= false
	local show_particles = is_open == true and Menu.ParticlesEnabled == true
	fx.IsParticleActive = show_particles == true

	local show = show_darken or show_particles
	fx.Background.Visible = show

	local target_t = show_darken and 0.55 or 1
	local target_blur = show_darken and 18 or 0
	if instant then
		fx.Background.BackgroundTransparency = target_t
		fx.BlurEffect.Size = target_blur
	else
		Menu:Tween(fx.Background, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = target_t,
		})
		Menu:Tween(fx.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = target_blur,
		})
	end

	if not is_open then
		fx.IsParticleActive = false
		fx.Background.Visible = false
		fx.Background.BackgroundTransparency = 1
		fx.BlurEffect.Size = 0
		self:ClearBackgroundParticles()
	end
end

function Library:SetBackgroundDarkenEnabled(bool, skip_save)
	self.BackgroundDarkenEnabled = bool == true
	Menu.BackgroundDarkenEnabled = self.BackgroundDarkenEnabled
	self:SetBackgroundEffectsVisible(self.WindowOpenState, true)
	if not self.LoadingConfig and skip_save ~= true then
		self:SaveLocalSettings()
	end
end

function Library:ApplyWindowInputState(bool)
	bool = bool == true
	if Menu.InputBlockGui then Menu.InputBlockGui.Enabled = bool end
	if Menu.InputBlocker then
		Menu.InputBlocker.Visible = bool
		Menu.InputBlocker.Active = false
	end
	if Menu.Holder then
		Menu.Holder.DisplayOrder = bool and self.DisplayOrders.HolderOpen or self.DisplayOrders.Holder
	end
	if Menu.Overlay then
		Menu.Overlay.DisplayOrder = bool and (self.DisplayOrders.OverlayOpen or 1100) or (self.DisplayOrders.Overlay or 200)
	end
	if Menu.FloatingButtonHolder then
		Menu.FloatingButtonHolder.DisplayOrder = bool and self.DisplayOrders.FloatingButtonOpen or self.DisplayOrders.FloatingButton
	end
	self:SetBackgroundEffectsVisible(bool, false)

	if Menu.CursorGui then Menu.CursorGui.Enabled = bool and not IsMobile end
	if Menu.MouseCursor then Menu.MouseCursor.Visible = bool and not IsMobile end

	pcall(function()
		ContextActionService:UnbindAction(self.InputBlockAction)
		ContextActionService:UnbindAction(self.InputBlockAction .. "_MOUSE")
	end)

	if not bool then return end

	ContextActionService:BindActionAtPriority(self.InputBlockAction, LPH_NO_VIRTUALIZE(function(_, state, input)
		if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.Change then
			return Enum.ContextActionResult.Pass
		end
		if not self.WindowOpenState or UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		local mk = Menu.MenuKeybind or Library.MenuKeybind
		if input and mk and (input.KeyCode == mk or input.UserInputType == mk) then
			return Enum.ContextActionResult.Pass
		end

		if input and (input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseButton3)
			and self:IsPointerOverHubGui() then
			return Enum.ContextActionResult.Pass
		end
		return Enum.ContextActionResult.Sink
	end), false, 5000,
		Enum.UserInputType.Gamepad1, Enum.UserInputType.MouseWheel,
		Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3)

	ContextActionService:BindActionAtPriority(self.InputBlockAction .. "_MOUSE", LPH_NO_VIRTUALIZE(function(_, state)
		if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.Change then
			return Enum.ContextActionResult.Pass
		end
		if not self.WindowOpenState or UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		if self:IsPointerOverHubGui() then return Enum.ContextActionResult.Pass end
		return Enum.ContextActionResult.Sink
	end), false, 5000, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
end

function Library:ResetPositions()
	local window = self.CurrentWindow or Menu.CurrentWindow
	if window and type(window.SetCenter) == "function" then
		window:SetCenter()
	end

	local btn_size = IsMobile and 70 or 50
	local floating_saved = IsMobile
		and { X = { Scale = 0, Offset = 24 }, Y = { Scale = 0.5, Offset = -MathFloor(btn_size / 2) } }
		or { X = { Scale = 0, Offset = 15 }, Y = { Scale = 0, Offset = 50 } }
	if self.FloatingButton then
		safe_set(self.FloatingButton, {
			Size = UDim2New(0, btn_size, 0, btn_size),
			Position = UDim2New(floating_saved.X.Scale, floating_saved.X.Offset, floating_saved.Y.Scale, floating_saved.Y.Offset),
			AnchorPoint = Vector2New(0, 0),
		})
	end
	Menu.Flags.FloatingButtonPosition = floating_saved
	self.FloatingButtonPosition = floating_saved

	local wm = self.WatermarkObject or self.WatermarkInstance
	if wm and type(wm.SetCenter) == "function" then
		wm:SetCenter()
	end

	local kb = self.KeyList
	if kb and kb.Frame then
		safe_set(kb.Frame, {
			AnchorPoint = Vector2New(0, 0.5),
			Position = UDim2New(0, 10, 0.5, 0),
		})
	end

	local qc_saved = {
		X = { Scale = 0, Offset = 10 },
		Y = { Scale = 0, Offset = 120 },
	}
	local qc = self.QuickConfigs
	if qc and qc.Frame then
		safe_set(qc.Frame, {
			AnchorPoint = Vector2New(0, 0),
			Position = UDim2New(0, 10, 0, 120),
		})
	end
	Menu.Flags.QuickConfigsPosition = qc_saved
	self.QuickConfigsPosition = qc_saved

	local spectators = self.SpectatorListObject or self.SpectatorListInstance
	if spectators and spectators.Frame then
		safe_set(spectators.Frame, {
			AnchorPoint = Vector2New(1, 0.5),
			Position = UDim2New(1, -10, 0.5, 0),
		})
	end

	self:SaveLocalSettings()
	self:Notification({ Name = "Success", Description = "UI positions reset" })
end

function Library:CreateFloatingButton(window)
	if not Menu.FloatingButtonHolder then return end
	if self.FloatingButton then return self.FloatingButton end

	local btn_size = IsMobile and 70 or 50
	local default_x = IsMobile and 24 or 15
	local default_y = IsMobile and -MathFloor(btn_size / 2) or 50
	local default_sx = 0
	local default_sy = IsMobile and 0.5 or 0

	local btn = Draw:Create("ImageButton", {
		Parent = Menu.FloatingButtonHolder,
		Size = UDim2New(0, btn_size, 0, btn_size),
		Position = UDim2New(default_sx, default_x, default_sy, default_y),
		BackgroundColor3 = Menu.Theme.Background,
		Image = Library.LogoFallback or "rbxassetid://137698471325689",
		ImageColor3 = Menu.Theme.Accent,
		ScaleType = Enum.ScaleType.Fit,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 128,
		Theme = { BackgroundColor3 = "Background" },
	})
	corner(btn, IsMobile and 14 or 10)
	Library:ApplyLogoImage(btn)

	local pos = Menu.Flags.FloatingButtonPosition or self.FloatingButtonPosition
	if type(pos) == "table" and pos.X and pos.Y then
		btn.Position = UDim2New(pos.X.Scale or 0, pos.X.Offset or 0, pos.Y.Scale or 0, pos.Y.Offset or 0)
	end

	local function save_floating_pos()
		local p = btn.Position
		local saved = {
			X = { Scale = p.X.Scale, Offset = p.X.Offset },
			Y = { Scale = p.Y.Scale, Offset = p.Y.Offset },
		}
		Menu.Flags.FloatingButtonPosition = saved
		self.FloatingButtonPosition = saved
		self:SaveLocalSettings()
	end

	local dragging, moved, drag_start, start_pos, move_c, end_c
	local threshold = 6

	local function stop_drag(toggle_if_click)
		local was_moved = moved
		dragging = false
		moved = false
		drag_start = nil
		start_pos = nil
		if move_c then pcall(function() move_c:Disconnect() end); move_c = nil end
		if end_c then pcall(function() end_c:Disconnect() end); end_c = nil end
		if was_moved then
			save_floating_pos()
		elseif toggle_if_click and window and window.SetOpen then
			window:SetOpen(not window.IsOpen)
		end
	end

	btn.InputBegan:Connect(function(input)
		if self.FloatingButtonLocked or dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		moved = false
		drag_start = Vector2New(input.Position.X, input.Position.Y)
		start_pos = btn.Position

		move_c = UserInputService.InputChanged:Connect(LPH_NO_VIRTUALIZE(function(move)
			if not dragging or not drag_start or not start_pos then return end
			if move.UserInputType ~= Enum.UserInputType.MouseMovement and move.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local delta = Vector2New(move.Position.X, move.Position.Y) - drag_start
			if not moved and delta.Magnitude < threshold then return end
			moved = true
			btn.Position = UDim2New(
				start_pos.X.Scale,
				start_pos.X.Offset + delta.X,
				start_pos.Y.Scale,
				start_pos.Y.Offset + delta.Y
			)
		end))

		end_c = UserInputService.InputEnded:Connect(function(ended)
			if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
				if dragging then stop_drag(true) end
			end
		end)
	end)

	self.FloatingButton = btn
	Menu.FloatingButtonHolder.Enabled = self.ShowMenuButton ~= false
	return btn
end

function Library:ApplyLocalSettingsTable(decoded, options)
	if type(decoded) ~= "table" then return end
	options = options or {}

	if type(decoded.SafeMode) == "boolean" then self.SafeMode = decoded.SafeMode; Menu.SafeMode = decoded.SafeMode end
	if type(decoded.AutoloadConfigEnabled) == "boolean" then
		self.AutoloadConfigEnabled = decoded.AutoloadConfigEnabled
		Menu.AutoloadConfig = decoded.AutoloadConfigEnabled
	end
	if type(decoded.AutoloadThemeEnabled) == "boolean" then
		self.AutoloadThemeEnabled = decoded.AutoloadThemeEnabled
		Menu.AutoloadTheme = decoded.AutoloadThemeEnabled
	end
	if type(decoded.BackgroundEffect) == "string" then self:SetBackgroundEffect(decoded.BackgroundEffect) end
	if type(decoded.BackgroundDarkenEnabled) == "boolean" then self.BackgroundDarkenEnabled = decoded.BackgroundDarkenEnabled; Menu.BackgroundDarkenEnabled = decoded.BackgroundDarkenEnabled end
	if type(decoded.ShowWatermark) == "boolean" then self.ShowWatermark = decoded.ShowWatermark end
	if type(decoded.ShowKeybindList) == "boolean" then self.ShowKeybindList = decoded.ShowKeybindList end
	if type(decoded.ShowQuickConfigs) == "boolean" then self.ShowQuickConfigs = decoded.ShowQuickConfigs end
	if type(decoded.QuickConfigSlots) == "table" then
		local slots = {}
		local max_n = self.QuickConfigsMax or 4
		if #decoded.QuickConfigSlots > 0 then
			for i = 1, #decoded.QuickConfigSlots do
				if #slots >= max_n then break end
				local n = tostring(decoded.QuickConfigSlots[i])
				if n ~= "" then TableInsert(slots, n) end
			end
		else
			for k, v in next, decoded.QuickConfigSlots do
				if #slots >= max_n then break end
				if v == true and type(k) == "string" and k ~= "" then
					TableInsert(slots, k)
				elseif type(v) == "string" and v ~= "" then
					TableInsert(slots, v)
				end
			end
		end
		self.QuickConfigSlots = slots
		Menu.Flags["Quick Config Slots"] = slots
	end
	if type(decoded.ShowMenuButton) == "boolean" then self.ShowMenuButton = decoded.ShowMenuButton; Menu.ShowMenuButton = decoded.ShowMenuButton
	elseif type(decoded.ShowFloatingButton) == "boolean" then self.ShowMenuButton = decoded.ShowFloatingButton; Menu.ShowMenuButton = decoded.ShowFloatingButton end
	if type(decoded.AutoExecute) == "boolean" then self.AutoExecute = decoded.AutoExecute; Menu.AutoExecute = decoded.AutoExecute end
	if type(decoded.BackgroundTransparency) == "number" then self.BackgroundTransparency = MathClamp(decoded.BackgroundTransparency, 0, 1) end
	if type(decoded.MenuTweenTime) == "number" then Menu.TweenSettings.Time = decoded.MenuTweenTime; Library.Tween.Time = decoded.MenuTweenTime end
	if type(decoded.MenuFadeTime) == "number" then self.FadeSpeed = decoded.MenuFadeTime; Menu.FadeSpeed = decoded.MenuFadeTime end
	if type(decoded.MenuScalePreset) == "string" then
		self.MenuScalePreset = decoded.MenuScalePreset
		if SCALE_PRESETS[decoded.MenuScalePreset] then self:SetScaleNumeric(SCALE_PRESETS[decoded.MenuScalePreset]) end
	end
	if type(decoded.MenuTweenStyle) == "string" and Enum.EasingStyle[decoded.MenuTweenStyle] then
		Menu.TweenSettings.Style = Enum.EasingStyle[decoded.MenuTweenStyle]
		Library.Tween.Style = Menu.TweenSettings.Style
	end
	if type(decoded.MenuTweenDirection) == "string" and Enum.EasingDirection[decoded.MenuTweenDirection] then
		Menu.TweenSettings.Direction = Enum.EasingDirection[decoded.MenuTweenDirection]
		Library.Tween.Direction = Menu.TweenSettings.Direction
	end
	if type(decoded.UIFont) == "string" then self:ApplyFont(decoded.UIFont) end
	if type(decoded.UIMainTextSize) == "number" then Menu.FontSettings.TextSize = MathClamp(MathFloor(decoded.UIMainTextSize), 10, 20) end
	if type(decoded.UISmallTextSize) == "number" then Menu.FontSettings.SmallTextSize = MathClamp(MathFloor(decoded.UISmallTextSize), 8, 16) end
	if type(decoded.UITitleTextSize) == "number" then Menu.FontSettings.TitleTextSize = MathClamp(MathFloor(decoded.UITitleTextSize), 14, 28) end
	if type(decoded.FloatingButtonPosition) == "table" then
		self.FloatingButtonPosition = decoded.FloatingButtonPosition
		Menu.Flags.FloatingButtonPosition = decoded.FloatingButtonPosition
		if self.FloatingButton and decoded.FloatingButtonPosition.X and decoded.FloatingButtonPosition.Y then
			local p = decoded.FloatingButtonPosition
			safe_set(self.FloatingButton, {
				Position = UDim2New(p.X.Scale or 0, p.X.Offset or 15, p.Y.Scale or 0, p.Y.Offset or 50),
			})
		end
	end
	if type(decoded.QuickConfigsPosition) == "table" then
		self.QuickConfigsPosition = decoded.QuickConfigsPosition
		Menu.Flags.QuickConfigsPosition = decoded.QuickConfigsPosition
		if self.QuickConfigs and self.QuickConfigs.Frame and decoded.QuickConfigsPosition.X and decoded.QuickConfigsPosition.Y then
			local p = decoded.QuickConfigsPosition
			safe_set(self.QuickConfigs.Frame, {
				Position = UDim2New(p.X.Scale or 0, p.X.Offset or 10, p.Y.Scale or 0, p.Y.Offset or 120),
			})
		end
	end
	if options.ApplyFont == true then self:ApplyFont(Menu.FontSettings.Name) end
end

function Library:LoadLocalSettings(options)
	local path = local_settings_path()
	if not (isfile and isfile(path) and readfile) then return end
	local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if ok and type(decoded) == "table" then self:ApplyLocalSettingsTable(decoded, options) end
end

function Library:SaveLocalSettings()
	if not writefile then return end
	local settings = {
		SafeMode = self.SafeMode == true,
		AutoloadConfigEnabled = self.AutoloadConfigEnabled == true,
		AutoloadThemeEnabled = self.AutoloadThemeEnabled == true,
		BackgroundEffect = Menu.ParticleMode or "None",
		BackgroundDarkenEnabled = self.BackgroundDarkenEnabled ~= false,
		ShowWatermark = self.ShowWatermark == true,
		ShowKeybindList = self.ShowKeybindList == true,
		ShowQuickConfigs = self.ShowQuickConfigs == true,
		QuickConfigSlots = self.QuickConfigSlots or {},
		ShowMenuButton = self.ShowMenuButton ~= false,
		AutoExecute = self.AutoExecute == true,
		BackgroundTransparency = self.BackgroundTransparency,
		MenuTweenTime = Menu.TweenSettings.Time,
		MenuFadeTime = self.FadeSpeed or Menu.FadeSpeed or 0.15,
		MenuScalePreset = self.MenuScalePreset or "Medium",
		MenuTweenStyle = tostring(Menu.TweenSettings.Style):match("%.(%w+)$") or "Quad",
		MenuTweenDirection = tostring(Menu.TweenSettings.Direction):match("%.(%w+)$") or "Out",
		UIFont = Menu.FontSettings.Name,
		UIMainTextSize = Menu.FontSettings.TextSize,
		UISmallTextSize = Menu.FontSettings.SmallTextSize,
		UITitleTextSize = Menu.FontSettings.TitleTextSize,
		FloatingButtonPosition = self.FloatingButtonPosition or Menu.Flags.FloatingButtonPosition,
		QuickConfigsPosition = self.QuickConfigsPosition or Menu.Flags.QuickConfigsPosition,
	}
	pcall(function()
		writefile(local_settings_path(), HttpService:JSONEncode(settings))
	end)
end

function Library:ApplyMenuSettingsFromLocal(watermark, keybind_list, window)
	local wm = watermark or self.WatermarkInstance or self.WatermarkObject
	local kb = keybind_list or self.KeyList
	if wm and wm.SetVisible then wm:SetVisible(self.ShowWatermark == true)
	elseif wm and wm.SetVisibility then wm:SetVisibility(self.ShowWatermark == true) end
	if wm and wm.SetTransparency then wm:SetTransparency() end
	if kb and kb.SetVisible then kb:SetVisible(self.ShowKeybindList == true)
	elseif kb and kb.SetVisibility then kb:SetVisibility(self.ShowKeybindList == true) end
	if kb and kb.SetTransparency then kb:SetTransparency() end
	if not self.QuickConfigs and self.CreateQuickConfigs then
		self:CreateQuickConfigs()
	end
	local qc = self.QuickConfigs
	if qc and qc.SetVisible then qc:SetVisible(self.ShowQuickConfigs == true)
	elseif qc and qc.SetVisibility then qc:SetVisibility(self.ShowQuickConfigs == true) end
	if qc and qc.SetTransparency then qc:SetTransparency() end
	if qc and qc.Refresh then qc:Refresh() end
	if Menu.FloatingButtonHolder then Menu.FloatingButtonHolder.Enabled = self.ShowMenuButton ~= false end
	if window and window.SetTransparency and type(self.BackgroundTransparency) == "number" then
		window:SetTransparency(self.BackgroundTransparency)
	end
	self:SetBackgroundDarkenEnabled(self.BackgroundDarkenEnabled, true)
end

function Library:FinalizeMenuSettings(watermark, keybind_list, window)
	if self.MenuSettingsFinalized then return end
	self.MenuSettingsFinalized = true
	self:LoadLocalSettings({ ApplyFont = false })
	self:CheckForAutoLoad()
	self:ApplyMenuSettingsFromLocal(watermark, keybind_list, window)
	if window and window.SetOpen then
		if self.SafeMode then
			window:SetOpen(false)
			if Menu.FloatingButtonHolder then
				Menu.FloatingButtonHolder.Enabled = self.ShowMenuButton ~= false
			end
		else
			window:SetOpen(true)
		end
	end
end

function Library:SetTextSizes(main, small, title, skip_save)
	if type(main) == "number" then Menu.FontSettings.TextSize = MathClamp(MathFloor(main), 10, 20) end
	if type(small) == "number" then Menu.FontSettings.SmallTextSize = MathClamp(MathFloor(small), 8, 16) end
	if type(title) == "number" then Menu.FontSettings.TitleTextSize = MathClamp(MathFloor(title), 14, 28) end
	if skip_save ~= true then self:SaveLocalSettings() end
end

function Library:CreateFontSettingsSection(page, data)
	data = data or {}
	local section = page:Section({ Name = data.Name or "Fonts", Side = data.Side or 2, Collapsed = false })
	section:Dropdown({
		Name = "Menu Font", Flag = "Menu Font", Items = self:GetFontNames(), Default = Menu.FontSettings.Name,
		Callback = function(v) self:ApplyFont(v); self:SaveLocalSettings() end,
	})
	return section
end


function Library:CreateServersPage(window)
	local freemium_servers = self.FreemiumMode == true
	local page = window:Page({ Name = "Servers" })
	local root = page.UI and page.UI.Columns
	if not root then return page end

	if page.ColumnsData then
		if page.ColumnsData[1] then page.ColumnsData[1].Visible = false end
		if page.ColumnsData[2] then page.ColumnsData[2].Visible = false end
		if page.ColumnsData[0] then
			page.ColumnsData[0].Visible = true
			root = page.ColumnsData[0]
		end
	end

	local columns = {
		{ Title = "SERVER", X = 0.02, W = 0.34 },
		{ Title = "PLAYERS", X = 0.40, W = 0.22 },
		{ Title = "PING", X = 0.63, W = 0.18 },
		{ Title = "FPS", X = 0.82, W = 0.16 },
	}
	local MathCeil = math.ceil
	local per_page, row_h = 50, 26
	local all_servers, selected_id, current_page, fetching, rows = {}, nil, 1, false, {}
	local page_label, empty_lbl

	local function notify(msg, color)
		self:Notification({ Name = "Servers", Description = msg, Color = color or FromRGB(120, 255, 120), Duration = 3 })
	end

	local function http_get(url)
		local ok, body = pcall(function()
			if type(game.HttpGet) == "function" then return game:HttpGet(url) end
			local req = (syn and syn.request) or request or http_request
			if req then
				local res = req({ Url = url, Method = "GET" })
				return type(res) == "table" and res.Body or nil
			end
			return nil
		end)
		return (ok and type(body) == "string") and body or nil
	end

	local function make_cell(parent, spec, text, is_header)
		return Draw:Create("TextLabel", {
			Parent = parent, Size = UDim2New(spec.W, 0, 1, 0), Position = UDim2New(spec.X, 0, 0, 0),
			BackgroundTransparency = 1, Text = text or "",
			TextColor3 = is_header and Menu.Theme["Inactive Text"] or Menu.Theme.Text,
			TextSize = 12, FontFace = Menu.Font, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
			Theme = { TextColor3 = is_header and "Inactive Text" or "Text" },
		})
	end

	local panel = Draw:Create("Frame", {
		Parent = root, Size = UDim2New(1, -16, 1, -16), Position = UDim2New(0, 8, 0, 8),
		BackgroundColor3 = Menu.Theme.Inline, BorderSizePixel = 0, ZIndex = 5,
		Theme = { BackgroundColor3 = "Inline" },
	})
	corner(panel, 6)
	Draw:Create("UIPadding", {
		Parent = panel,
		PaddingTop = UDimNew(0, 12),
		PaddingBottom = UDimNew(0, 12),
		PaddingLeft = UDimNew(0, 12),
		PaddingRight = UDimNew(0, 12),
	})
	Draw:Create("TextLabel", {
		Parent = panel, Size = UDim2New(1, 0, 0, 18), Position = UDim2New(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = "Servers", TextColor3 = Menu.Theme.Accent, TextSize = 15, FontFace = Menu.Font,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Theme = { TextColor3 = "Accent" },
	})

	local header = Draw:Create("Frame", {
		Parent = panel, Size = UDim2New(1, 0, 0, 16), Position = UDim2New(0, 0, 0, 26),
		BackgroundTransparency = 1, ZIndex = 6,
	})
	for i = 1, #columns do make_cell(header, columns[i], columns[i].Title, true) end

	local scroll = Draw:Create("ScrollingFrame", {
		Parent = panel, Size = UDim2New(1, 0, 1, -150), Position = UDim2New(0, 0, 0, 50),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageColor3 = Menu.Theme.Accent, CanvasSize = UDim2New(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 5,
		Theme = { ScrollBarImageColor3 = "Accent" },
	})
	Draw:Create("UIListLayout", { Parent = scroll, Padding = UDimNew(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })

	empty_lbl = Draw:Create("TextLabel", {
		Parent = scroll, Size = UDim2New(1, 0, 0, 40), BackgroundTransparency = 1,
		Text = "Loading servers...", TextColor3 = Menu.Theme["Inactive Text"], TextSize = 13,
		FontFace = Menu.Font, LayoutOrder = 999, ZIndex = 6, Theme = { TextColor3 = "Inactive Text" },
	})

	local function ping_color(ping)
		ping = tonumber(ping) or 0
		if ping <= 0 then
			return Menu.Theme["Inactive Text"] or Menu.Theme.Text
		end
		if ping < 100 then
			return FromRGB(80, 220, 120)
		end
		if ping <= 200 then
			return FromRGB(255, 200, 90)
		end
		return FromRGB(255, 90, 90)
	end

	local function render_page()
		local start = (current_page - 1) * per_page
		for i = 1, per_page do
			local row = rows[i]
			local server = all_servers[start + i]
			if server then
				row._id = server.id
				row.Button.Visible = true
				row.Cells[1].Text = tostring(server.id):sub(1, 8)
				row.Cells[2].Text = tostring(server.playing or 0) .. " / " .. tostring(server.maxPlayers or 0)
				local ping = tonumber(server.ping) or 0
				row.Cells[3].Text = ping > 0 and (tostring(MathFloor(ping)) .. " ms") or "-"
				row.Cells[3].TextColor3 = ping_color(ping)
				local fps = tonumber(server.fps) or 0
				row.Cells[4].Text = fps > 0 and tostring(MathFloor(fps)) or "-"
				local selected = selected_id == server.id
				row.Button.BackgroundTransparency = selected and 0 or 1
			else
				row._id = nil
				row.Button.Visible = false
				row.Button.BackgroundTransparency = 1
			end
		end
		empty_lbl.Visible = #all_servers == 0
		if #all_servers == 0 and not fetching then empty_lbl.Text = "No servers found" end
		if page_label then
			page_label.Text = "Page " .. current_page .. " / " .. MathMax(1, MathCeil(#all_servers / per_page))
		end
	end

	for i = 1, per_page do
		local row_btn = Draw:Create("TextButton", {
			Parent = scroll, Size = UDim2New(1, -4, 0, row_h), BackgroundColor3 = Menu.Theme.Accent,
			BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
			LayoutOrder = i, Visible = false, ZIndex = 6, Theme = { BackgroundColor3 = "Accent" },
		})
		corner(row_btn, 4)
		local cells = {}
		for ci = 1, #columns do
			cells[ci] = make_cell(row_btn, columns[ci], "", false)
		end

		if cells[3] then
			pcall(function()
				cells[3]:SetAttribute("Theme", nil)
			end)
		end
		local row = { Button = row_btn, Cells = cells, _id = nil }
		row_btn.MouseButton1Click:Connect(function()
			if not row._id then return end
			if selected_id == row._id then
				selected_id = nil
			else
				selected_id = row._id
			end
			render_page()
		end)

		row_btn.MouseEnter:Connect(function()
			row_btn.BackgroundTransparency = (selected_id == row._id) and 0 or 1
		end)
		row_btn.MouseLeave:Connect(function()
			row_btn.BackgroundTransparency = (selected_id == row._id) and 0 or 1
		end)
		rows[i] = row
	end

	local function fetch_servers()
		if fetching then return end
		fetching = true
		empty_lbl.Visible = true
		empty_lbl.Text = "Loading servers..."
		spawn(function()
			local list, cursor, max_servers = {}, nil, per_page * 40
			repeat
				local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Desc&limit=100"
				if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
				local body = http_get(url)
				cursor = nil
				if body then
					local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
					if ok and type(data) == "table" and type(data.data) == "table" then
						for i = 1, #data.data do list[#list + 1] = data.data[i] end
						if type(data.nextPageCursor) == "string" and data.nextPageCursor ~= "" then cursor = data.nextPageCursor end
					end
				end
				if cursor then task.wait(0.35) end
			until not cursor or #list >= max_servers
			table.sort(list, function(a, b) return (tonumber(a.playing) or 0) > (tonumber(b.playing) or 0) end)
			all_servers = list
			current_page, selected_id, fetching = 1, nil, false
			render_page()
		end)
	end

	local footer = Draw:Create("Frame", {
		Parent = panel, Size = UDim2New(1, 0, 0, 26), Position = UDim2New(0, 0, 1, -68),
		AnchorPoint = Vector2New(0, 1), BackgroundTransparency = 1, ZIndex = 6,
	})
	local function make_btn(text, pos, size, accent, cb)
		local b = Draw:Create("TextButton", {
			Parent = footer, Position = pos, Size = size,
			BackgroundColor3 = accent and Menu.Theme.Accent or Menu.Theme.Element,
			BorderSizePixel = 0, AutoButtonColor = false, Text = text,
			TextColor3 = Menu.Theme.Text, TextSize = 12, FontFace = Menu.Font, ZIndex = 7,
			Theme = accent and { BackgroundColor3 = "Accent", TextColor3 = "Text" } or { BackgroundColor3 = "Element", TextColor3 = "Text" },
		})
		corner(b, 4)
		b.MouseButton1Down:Connect(cb)
		return b
	end
	make_btn("< Prev", UDim2New(0, 0, 0, 0), UDim2New(0.3, -3, 1, 0), false, function()
		if current_page > 1 then current_page -= 1; render_page() end
	end)
	page_label = Draw:Create("TextLabel", {
		Parent = footer, Position = UDim2New(0.3, 3, 0, 0), Size = UDim2New(0.4, -6, 1, 0),
		BackgroundTransparency = 1, Text = "Page 1 / 1", TextColor3 = Menu.Theme.Text,
		TextSize = 12, FontFace = Menu.Font, ZIndex = 7, Theme = { TextColor3 = "Text" },
	})
	make_btn("Next >", UDim2New(0.7, 3, 0, 0), UDim2New(0.3, -3, 1, 0), false, function()
		local max_p = MathMax(1, MathCeil(#all_servers / per_page))
		if current_page < max_p then current_page += 1; render_page() end
	end)

	local actions = Draw:Create("Frame", {
		Parent = panel, Size = UDim2New(1, 0, 0, 28), Position = UDim2New(0, 0, 1, -34),
		AnchorPoint = Vector2New(0, 1), BackgroundTransparency = 1, ZIndex = 6,
	})
	local function act(text, x, w, accent, cb)
		local b = Draw:Create("TextButton", {
			Parent = actions, Position = UDim2New(x, 0, 0, 0), Size = UDim2New(w, -4, 1, 0),
			BackgroundColor3 = accent and Menu.Theme.Accent or Menu.Theme.Element,
			BorderSizePixel = 0, AutoButtonColor = false, Text = text,
			TextColor3 = Menu.Theme.Text, TextSize = 12, FontFace = Menu.Font, ZIndex = 7,
			Theme = accent and { BackgroundColor3 = "Accent", TextColor3 = "Text" } or { BackgroundColor3 = "Element", TextColor3 = "Text" },
		})
		corner(b, 4)
		b.MouseButton1Down:Connect(cb)
	end
	act("Join", 0, 0.33, true, function()
		if freemium_servers then
			Library:NotifyPremiumFeature()
			return
		end
		if not selected_id then notify("Select a server first", FromRGB(255, 190, 90)); return end
		notify("Joining server...")
		pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, selected_id, LocalPlayer) end)
	end)
	act("Refresh", 0.33, 0.34, false, fetch_servers)
	act("Copy Join", 0.67, 0.33, false, function()
		if freemium_servers then
			Library:NotifyPremiumFeature()
			return
		end
		if not selected_id then notify("Select a server first", FromRGB(255, 190, 90)); return end
		local code = 'game:GetService("TeleportService"):TeleportToPlaceInstance(' .. game.PlaceId .. ', "' .. selected_id .. '")'
		if setclipboard then setclipboard(code) elseif toclipboard then toclipboard(code) end
		notify("Join link copied")
	end)

	fetch_servers()
	return page
end

	Library.Pages.ModelViewerSection = function(self, Data)
		Data = Data or {}

		local Section = {
			Window = self.Window,
			Page = self,

			Name = Data.Name or Data.name or "Model Viewer",
			Side = ResolveSectionSide(Data),
			Height = Data.Height or Data.height or 200,

			EnableInputCamera = Data.EnableInputCamera ~= false,
			EnableZoom = Data.EnableZoom ~= false,
			AutoRotate = Data.AutoRotate ~= false,
			RotationSpeed = Data.RotationSpeed or Data.rotationSpeed or 0.01,
			ZoomMultiplier = Data.ZoomMultiplier or Data.zoomMultiplier or 2,
			CameraDistance = Data.CameraDistance or Data.cameraDistance,
			CameraDistanceScale = Data.CameraDistanceScale or Data.cameraDistanceScale or 1.6,
			AutoRefresh = false,
			RefreshRate = Data.RefreshRate or Data.refreshRate or 30,

			IsViewing = false,
			Items = {},
		}

		local Items = Section.Items
		local viewportFrame
		local camera
		local model
		local originalModel
		local autoRefreshThread

		local rotationX, rotationY = -0.26, 0
		local distance = Section.CameraDistance or 10
		local dragging = false
		local hovering = false
		local lastpos = Vector2.zero

		local function stopAutoRefresh()
			if autoRefreshThread then
				task.cancel(autoRefreshThread)
				autoRefreshThread = nil
			end
		end

		local function centerDisplayModel(displayModel)
			if not displayModel then return end
			local bbox_cf = select(1, displayModel:GetBoundingBox())
			local center = bbox_cf.Position
			if center.Magnitude > 0.001 then
				displayModel:PivotTo(CFrame.new(-center) * displayModel:GetPivot())
			end
		end

		local function getModelCenter(displayModel)
			if not displayModel then return Vector3.zero end
			return select(1, displayModel:GetBoundingBox()).Position
		end

		local function getModelFitDistance(displayModel)
			if not displayModel then return 2 end
			local _, model_size = displayModel:GetBoundingBox()
			local max_extent = math.max(model_size.X, model_size.Y, model_size.Z)
			local scale = Section.CameraDistanceScale or 1.6
			return math.max(max_extent * scale, 0.35)
		end

		local function prepareModel(item)
			if not item or item == workspace or item:IsA("Terrain") then
				return nil
			end

			local displayModel

			if item:IsA("BasePart") and not item:IsA("Model") then
				displayModel = InstanceNew("Model")
				displayModel.Parent = viewportFrame.Instance

				local clone = item:Clone()
				clone.Parent = displayModel
				displayModel.PrimaryPart = clone

				if displayModel.SetPrimaryPartCFrame then
					displayModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
				else
					displayModel:PivotTo(CFrame.new(0, 0, 0))
				end
				centerDisplayModel(displayModel)
			elseif item:IsA("Model") then
				item.Archivable = true

				if #item:GetChildren() == 0 then
					return nil
				end

				displayModel = item:Clone()
				displayModel.Parent = viewportFrame.Instance

				if not displayModel.PrimaryPart then
					local found = false

					for _, child in displayModel:GetDescendants() do
						if child:IsA("BasePart") then
							displayModel.PrimaryPart = child

							if displayModel.SetPrimaryPartCFrame then
								displayModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
							else
								displayModel:PivotTo(CFrame.new(0, 0, 0))
							end

							found = true
							break
						end
					end

					if not found then
						displayModel:Destroy()
						return nil
					end
				else
					centerDisplayModel(displayModel)
				end
			else
				return nil
			end

			return displayModel
		end

		Items["Section"] = Instances:Create("Frame", {
			Parent = resolve_column_parent(Section.Page, Section.Side),
			Name = "\0",
			Size = UDim2New(1, 0, 0, 28),
			BackgroundColor3 = Library.Theme["Inline"],
			BorderColor3 = FromRGB(0, 0, 0),
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2
		}):AddToTheme({BackgroundColor3 = "Inline"})

		Instances:Create("UICorner", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			CornerRadius = UDimNew(0, 5)
		})

		Instances:Create("UIGradient", {
			Parent = Items["Section"].Instance,
			Name = "\0"
		})

		Items["Text"] = Instances:Create("TextLabel", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			Size = UDim2New(0, 0, 0, 15),
			Position = UDim2New(0, 8, 0, 7),
			BackgroundTransparency = 1,
			BorderColor3 = FromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Text = Section.Name,
			TextColor3 = Library.Theme["Text"],
			TextSize = 14,
			FontFace = Library.Font,
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = 2
		}):AddToTheme({TextColor3 = "Text"})

		Items["Line"] = Instances:Create("Frame", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			Size = UDim2New(1, -16, 0, 1),
			Position = UDim2New(0, 8, 0, 28),
			BackgroundColor3 = Library.Theme["Border"],
			BorderColor3 = FromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 2
		}):AddToTheme({BackgroundColor3 = "Border"})

		Items["ViewerHolder"] = Instances:Create("Frame", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			Size = UDim2New(1, -16, 0, Section.Height),
			Position = UDim2New(0, 8, 0, 35),
			BackgroundColor3 = Library.Theme["Element"],
			BorderColor3 = FromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2
		}):AddToTheme({BackgroundColor3 = "Element"})

		Items["ViewerHolder"].Instance:SetAttribute("BlockWindowDrag", true)
		Items["ViewerHolder"].Instance.Active = true

		Instances:Create("UICorner", {
			Parent = Items["ViewerHolder"].Instance,
			Name = "\0",
			CornerRadius = UDimNew(0, 4)
		})

		viewportFrame = Instances:Create("ViewportFrame", {
			Parent = Items["ViewerHolder"].Instance,
			Name = "\0",
			Size = UDim2New(1, -8, 1, -8),
			Position = UDim2New(0, 4, 0, 4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = Section.EnableInputCamera,
			ZIndex = 2,
			Ambient = FromRGB(140, 140, 140),
			LightColor = FromRGB(255, 255, 255),
			LightDirection = Vector3New(-1, -1, -1)
		})
		viewportFrame.Instance:SetAttribute("BlockWindowDrag", true)

		Instances:Create("UIPadding", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			PaddingBottom = UDimNew(0, 8)
		})

		Items["Content"] = Instances:Create("Frame", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			Size = UDim2New(1, -16, 0, 0),
			Position = UDim2New(0, 8, 0, 35 + Section.Height + 6),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
		})

		Instances:Create("UIListLayout", {
			Parent = Items["Content"].Instance,
			Name = "\0",
			Padding = UDimNew(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		function Section:StopViewModel(updating)
			stopAutoRefresh()

			if updating then
				local existing = viewportFrame.Instance:FindFirstChildOfClass("Model")
				if existing then
					existing:Destroy()
				end
			else
				camera = nil
				model = nil
				originalModel = nil
				viewportFrame.Instance:ClearAllChildren()
				self.IsViewing = false
				Items["Text"].Instance.Text = self.Name
			end
		end

		function Section:ViewModel(item, updating)
			if not item then
				return
			end

			self:StopViewModel(updating)

			model = prepareModel(item)
			if not model or not model.PrimaryPart then
				return
			end

			originalModel = item

			if self.AutoRefresh and not updating then
				autoRefreshThread = task.spawn(function()
					while model and self.AutoRefresh and originalModel do
						self:ViewModel(originalModel, true)
						task.wait(1 / self.RefreshRate)
					end
				end)
			end

			if not updating then
				camera = InstanceNew("Camera")
				viewportFrame.Instance.CurrentCamera = camera
				camera.Parent = viewportFrame.Instance
				camera.FieldOfView = 42

				distance = getModelFitDistance(model)
				if type(Section.CameraDistance) == "number" then
					distance = Section.CameraDistance
				end

				Items["Text"].Instance.Text = item.Name .. " - Preview"
				self.IsViewing = true
			end
		end

		function Section:Refresh()
			if originalModel then
				self:ViewModel(originalModel)
			end
		end

		function Section:SetAutoRotate(value)
			self.AutoRotate = value
		end

		function Section:SetAutoRefresh(value)
			self.AutoRefresh = value

			if value and originalModel then
				self:ViewModel(originalModel)
			elseif not value then
				stopAutoRefresh()
			end
		end

		function Section:SetPreviewTitle(title)
			if type(title) ~= "string" or title == "" then
				title = "N/A - Preview"
			end
			Items["Text"].Instance.Text = title
		end

		function Section:SetHeight(value)
			self.Height = value
			Items["ViewerHolder"].Instance.Size = UDim2New(1, -16, 0, value)
		end

		local drag_move_c, drag_end_c
		local function stop_orbit_drag()
			dragging = false
			Library.BlockWindowDrag = false
			if drag_move_c then pcall(function() drag_move_c:Disconnect() end); drag_move_c = nil end
			if drag_end_c then pcall(function() drag_end_c:Disconnect() end); drag_end_c = nil end
			if type(Library.SetWindowDragEnabled) == "function" then
				Library:SetWindowDragEnabled(not Library:IsPointerOverBlockWindowDrag())
			end
		end

		local function start_orbit_drag(input)
			if not Section.EnableInputCamera or dragging then return end
			Library.BlockWindowDrag = true
			if type(Library.SetWindowDragEnabled) == "function" then
				Library:SetWindowDragEnabled(false)
			end
			dragging = true
			lastpos = Vector2New(input.Position.X, input.Position.Y)

			drag_move_c = UserInputService.InputChanged:Connect(LPH_NO_VIRTUALIZE(function(move)
				if not dragging then return end
				if move.UserInputType ~= Enum.UserInputType.MouseMovement and move.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				local pos = Vector2New(move.Position.X, move.Position.Y)
				local delta = pos - lastpos
				lastpos = pos
				rotationY -= delta.X * 0.01
				rotationX -= delta.Y * 0.01
				rotationX = MathClamp(rotationX, -math.pi / 2 + 0.1, math.pi / 2 - 0.1)
			end))

			drag_end_c = UserInputService.InputEnded:Connect(function(ended)
				if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
					stop_orbit_drag()
				end
			end)
		end

		viewportFrame:Connect("InputBegan", function(input)
			if not Section.EnableInputCamera then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				start_orbit_drag(input)
			elseif Section.EnableZoom and input.KeyCode == Enum.KeyCode.LeftShift then
				Section.ZoomMultiplier = 10
			end
		end)


		Items["ViewerHolder"]:Connect("InputBegan", function(input)
			if not Section.EnableInputCamera then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				start_orbit_drag(input)
			end
		end)

		viewportFrame:Connect("MouseEnter", function()
			hovering = true
		end)

		viewportFrame:Connect("MouseLeave", function()
			hovering = false
		end)

		Items["ViewerHolder"]:Connect("MouseEnter", function()
			hovering = true
		end)

		Items["ViewerHolder"]:Connect("MouseLeave", function()
			if not dragging then hovering = false end
		end)

		viewportFrame:Connect("InputEnded", function(input)
			if Section.EnableZoom and input.KeyCode == Enum.KeyCode.LeftShift then
				Section.ZoomMultiplier = 2
			end
		end)

		Library:Connect(UserInputService.InputChanged, LPH_NO_VIRTUALIZE(function(input)
			if not Section.EnableInputCamera or not Section.EnableZoom then return end
			if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
			if not hovering and not dragging then return end
			distance = MathClamp(distance - (input.Position.Z * Section.ZoomMultiplier), 0.1, math.huge)
		end))

		Library:Connect(RunService.RenderStepped, LPH_NO_VIRTUALIZE(function(dt)
			if not camera or not model then
				return
			end

			if not dragging and Section.AutoRotate then
				rotationY += Section.RotationSpeed * dt * 60
			end

			local center = getModelCenter(model)
			local offset = CFrame.new(0, 0, distance)
			local rotation = CFrame.Angles(0, rotationY, 0) * CFrame.Angles(rotationX, 0, 0)
			local camCF = CFrame.new(center) * rotation * offset

			camera.CFrame = CFrame.lookAt(camCF.Position, center)
		end))

		if Data.Model or Data.model then
			Section:ViewModel(Data.Model or Data.model)
		end

		table.insert(Library.AllSections, Section)
		return setmetatable(Section, Library.Sections)
	end

	Library.Pages.ImageViewerSection = function(self, Data)
		Data = Data or {}

		local scale_type = Data.ScaleType or Data.scaleType or Enum.ScaleType.Fit
		if type(scale_type) == "string" then
			scale_type = Enum.ScaleType[scale_type] or Enum.ScaleType.Fit
		end

		local Section = {
			Window = self.Window,
			Page = self,

			Name = Data.Name or Data.name or "Image Viewer",
			Side = ResolveSectionSide(Data),
			Height = Data.Height or Data.height or 180,
			ScaleType = scale_type,

			IsViewing = false,
			Items = {},
		}

		local Items = Section.Items
		local image_label

		local function resolve_image_source(value)
			if value == nil or value == "" then
				return nil
			end

			if IsRobloxInstance(value) then
				if value:IsA("Decal") then
					return value.Texture
				elseif value:IsA("ImageLabel") or value:IsA("ImageButton") then
					return value.Image
				elseif value:IsA("MeshPart") then
					return value.TextureID
				elseif value:IsA("StringValue") then
					return resolve_image_source(value.Value)
				elseif value:IsA("Model") or value:IsA("BasePart") then
					return nil
				end
			end

			if type(value) == "number" then
				return "rbxassetid://" .. tostring(value)
			end

			if type(value) ~= "string" then
				return nil
			end

			if value:sub(1, 5) == "game." or value:sub(1, 10) == "workspace." then
				local chunk = loadstring("return " .. value)
				if type(chunk) == "function" then
					local ok, result = pcall(chunk)
					if ok then
						return resolve_image_source(result)
					end
				end
				return nil
			end

			if value:match("^%d+$") then
				return "rbxassetid://" .. value
			end

			return value
		end

		Items["Section"] = Instances:Create("Frame", {
			Parent = resolve_column_parent(Section.Page, Section.Side),
			Name = "\0",
			Size = UDim2New(1, 0, 0, 28),
			BackgroundColor3 = Library.Theme["Inline"],
			BorderColor3 = FromRGB(0, 0, 0),
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2
		}):AddToTheme({BackgroundColor3 = "Inline"})

		Instances:Create("UICorner", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			CornerRadius = UDimNew(0, 5)
		})

		Instances:Create("UIGradient", {
			Parent = Items["Section"].Instance,
			Name = "\0"
		})

		Items["Text"] = Instances:Create("TextLabel", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			Size = UDim2New(0, 0, 0, 15),
			Position = UDim2New(0, 8, 0, 7),
			BackgroundTransparency = 1,
			BorderColor3 = FromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Text = Section.Name,
			TextColor3 = Library.Theme["Text"],
			TextSize = 14,
			FontFace = Library.Font,
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = 2
		}):AddToTheme({TextColor3 = "Text"})

		Items["Line"] = Instances:Create("Frame", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			Size = UDim2New(1, -16, 0, 1),
			Position = UDim2New(0, 8, 0, 28),
			BackgroundColor3 = Library.Theme["Border"],
			BorderColor3 = FromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 2
		}):AddToTheme({BackgroundColor3 = "Border"})

		Items["ViewerHolder"] = Instances:Create("Frame", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			Size = UDim2New(1, -16, 0, Section.Height),
			Position = UDim2New(0, 8, 0, 35),
			BackgroundColor3 = Library.Theme["Element"],
			BorderColor3 = FromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2
		}):AddToTheme({BackgroundColor3 = "Element"})

		Items["ViewerHolder"].Instance:SetAttribute("BlockWindowDrag", true)
		Items["ViewerHolder"].Instance.Active = true

		Instances:Create("UICorner", {
			Parent = Items["ViewerHolder"].Instance,
			Name = "\0",
			CornerRadius = UDimNew(0, 4)
		})

		image_label = Instances:Create("ImageLabel", {
			Parent = Items["ViewerHolder"].Instance,
			Name = "\0",
			Size = UDim2New(1, -8, 1, -8),
			Position = UDim2New(0, 4, 0, 4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScaleType = Section.ScaleType,
			Image = "",
			ZIndex = 2
		})

		Instances:Create("UIPadding", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			PaddingBottom = UDimNew(0, 8)
		})

		Items["Content"] = Instances:Create("Frame", {
			Parent = Items["Section"].Instance,
			Name = "\0",
			Size = UDim2New(1, -16, 0, 0),
			Position = UDim2New(0, 8, 0, 35 + Section.Height + 6),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
		})

		Instances:Create("UIListLayout", {
			Parent = Items["Content"].Instance,
			Name = "\0",
			Padding = UDimNew(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		function Section:SetPreviewTitle(title)
			if type(title) ~= "string" or title == "" then
				title = "N/A - Preview"
			end
			Items["Text"].Instance.Text = title
		end

		function Section:StopViewImage()
			image_label.Instance.Image = ""
			self.IsViewing = false
			Items["Text"].Instance.Text = self.Name
		end

		function Section:ClearImage()
			self:StopViewImage()
		end

		function Section:ViewImage(value)
			local image = resolve_image_source(value)
			if not image or image == "" then
				return false
			end

			image_label.Instance.Image = image
			self.IsViewing = true
			Items["Text"].Instance.Text = self.Name .. " - Preview"
			return true
		end

		function Section:SetImage(value)
			return self:ViewImage(value)
		end

		function Section:SetHeight(value)
			self.Height = value
			Items["ViewerHolder"].Instance.Size = UDim2New(1, -16, 0, value)
		end

		function Section:SetScaleType(value)
			self.ScaleType = value
			image_label.Instance.ScaleType = value
		end

		Section.MountedPreview = nil

		function Section:ClearMountedPreview()
			local holder = Items["ViewerHolder"].Instance
			for _, child in holder:GetChildren() do
				if child ~= image_label.Instance and child.Name == "MountedPreview" then
					child:Destroy()
				end
			end
			self.MountedPreview = nil
			image_label.Instance.Visible = true
			image_label.Instance.Image = ""
			self.IsViewing = false
			Items["Text"].Instance.Text = self.Name
		end

		function Section:MountViewport(viewport_frame)
			if typeof(viewport_frame) ~= "Instance" or not viewport_frame:IsA("ViewportFrame") then
				return false
			end

			self:ClearMountedPreview()
			image_label.Instance.Visible = false
			image_label.Instance.Image = ""

			viewport_frame.Name = "MountedPreview"
			viewport_frame.Parent = Items["ViewerHolder"].Instance
			viewport_frame.AnchorPoint = Vector2.new(0, 0)
			viewport_frame.Position = UDim2New(0, 4, 0, 4)
			viewport_frame.Size = UDim2New(1, -8, 1, -8)
			viewport_frame.BackgroundTransparency = 0
			viewport_frame.BackgroundColor3 = FromRGB(20, 20, 20)
			viewport_frame.BorderSizePixel = 0
			viewport_frame.ClipsDescendants = true
			viewport_frame.Visible = true
			viewport_frame.Active = false
			viewport_frame.ZIndex = 3
			viewport_frame:SetAttribute("BlockWindowDrag", true)

			self.MountedPreview = viewport_frame
			self.IsViewing = true
			Items["Text"].Instance.Text = self.Name .. " - Preview"
			return true
		end

		function Section:MountPreviewGui(gui_frame)
			if typeof(gui_frame) ~= "Instance" then
				return false
			end

			if gui_frame:IsA("ViewportFrame") then
				return self:MountViewport(gui_frame)
			end

			self:ClearMountedPreview()
			image_label.Instance.Visible = false
			image_label.Instance.Image = ""

			gui_frame.Name = "MountedPreview"
			gui_frame.Parent = Items["ViewerHolder"].Instance
			gui_frame.AnchorPoint = Vector2.new(0, 0)
			gui_frame.Position = UDim2New(0, 0, 0, 0)
			gui_frame.Size = UDim2New(1, 0, 1, 0)
			gui_frame.BackgroundTransparency = 1
			gui_frame.BorderSizePixel = 0
			gui_frame.Visible = true
			gui_frame.ZIndex = 3
			gui_frame:SetAttribute("BlockWindowDrag", true)

			if IsRobloxInstance(button) then
				button.AnchorPoint = Vector2.new(0, 0)
				button.Size = UDim2New(1, 0, 1, 0)
				button.Position = UDim2New(0, 0, 0, 0)
				button.BackgroundTransparency = 1
				button:SetAttribute("BlockWindowDrag", true)
				for _, child in button:GetChildren() do
					if child:IsA("ViewportFrame") then
						child.AnchorPoint = Vector2.new(0, 0)
						child.Size = UDim2New(1, 0, 1, 0)
						child.Position = UDim2New(0, 0, 0, 0)
						child.ZIndex = 3
						child.Active = false
						child:SetAttribute("BlockWindowDrag", true)
					elseif child.Name == "Icon" or child.Name == "Weapon" or child.Name == "Locked" then
						child.Visible = false
					end
				end
			end

			self.MountedPreview = gui_frame
			self.IsViewing = true
			Items["Text"].Instance.Text = self.Name .. " - Preview"
			return true
		end

		local initial_image = Data.Image or Data.image
		if initial_image ~= nil then
			Section:ViewImage(initial_image)
		end

		table.insert(Library.AllSections, Section)
		return setmetatable(Section, Library.Sections)
	end

	Library.Pages.ImagePreviewSection = Library.Pages.ImageViewerSection

	Library.TargetIndicator = function(self, Data)
		Data = Data or {}

		local Indicator = {
			Title = Data.Name or Data.name or Data.Title or Data.title or "Target",
			Visible = false,
			Lines = {},
			HealthConnection = nil,
			BoundHumanoid = nil,
			BoundTarget = nil,
			Items = {},
		}

		local Items = {} do
			Items["Root"] = Instances:Create("Frame", {
				Parent = Library.Holder.Instance,
				Name = "\0",
				Position = UDim2New(0.5, -130, 0, 80),
				Size = UDim2New(0, 260, 0, 0),
				BackgroundColor3 = Library.Theme["Background"],
				BackgroundTransparency = 0.15,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Background"})

			Items["Root"]:MakeDraggable()

			Instances:Create("UICorner", {
				Parent = Items["Root"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5),
			})

			Instances:Create("UIGradient", {
				Parent = Items["Root"].Instance,
				Name = "\0",
				Rotation = 90,
				Color = RGBSequence{
					RGBSequenceKeypoint(0, FromRGB(255, 255, 255)),
					RGBSequenceKeypoint(1, FromRGB(200, 200, 200)),
				},
			})

			Items["AccentBar"] = Instances:Create("Frame", {
				Parent = Items["Root"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 2),
				BackgroundColor3 = Library.Theme["Accent"],
				BorderSizePixel = 0,
				ZIndex = 5,
			}):AddToTheme({BackgroundColor3 = "Accent"})

			Instances:Create("UICorner", {
				Parent = Items["AccentBar"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5),
			})

			Items["Body"] = Instances:Create("Frame", {
				Parent = Items["Root"].Instance,
				Name = "\0",
				Position = UDim2New(0, 0, 0, 2),
				Size = UDim2New(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				ZIndex = 4,
			})

			Instances:Create("UIPadding", {
				Parent = Items["Body"].Instance,
				Name = "\0",
				PaddingTop = UDimNew(0, 10),
				PaddingBottom = UDimNew(0, 10),
				PaddingLeft = UDimNew(0, 10),
				PaddingRight = UDimNew(0, 10),
			})

			Instances:Create("UIListLayout", {
				Parent = Items["Body"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
			})

			Items["HeaderRow"] = Instances:Create("Frame", {
				Parent = Items["Body"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 0,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["HeaderRow"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			})

			Items["Avatar"] = Instances:Create("ImageLabel", {
				Parent = Items["HeaderRow"].Instance,
				Name = "\0",
				Size = UDim2New(0, 52, 0, 52),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
				LayoutOrder = 0,
				ZIndex = 4,
			})

			Instances:Create("UICorner", {
				Parent = Items["Avatar"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5),
			})

			Instances:Create("UIStroke", {
				Parent = Items["Avatar"].Instance,
				Name = "\0",
				Color = Library.Theme["Border"],
				Thickness = 1,
			}):AddToTheme({Color = "Border"})

			Items["HeaderText"] = Instances:Create("Frame", {
				Parent = Items["HeaderRow"].Instance,
				Name = "\0",
				Size = UDim2New(1, -60, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["HeaderText"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
			})

			Items["Title"] = Instances:Create("TextLabel", {
				Parent = Items["HeaderText"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = Indicator.Title,
				TextColor3 = Library.Theme["Accent"],
				TextSize = 14,
				FontFace = Library.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 0,
				ZIndex = 4,
			}):AddToTheme({TextColor3 = "Accent"})

			Items["Subtitle"] = Instances:Create("TextLabel", {
				Parent = Items["HeaderText"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "No target",
				TextColor3 = Library.Theme["Inactive Text"],
				TextSize = 12,
				FontFace = Library.Font,
				TextTransparency = 0.35,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				ZIndex = 4,
			}):AddToTheme({TextColor3 = "Inactive Text"})

			Items["InfoScroll"] = Instances:Create("ScrollingFrame", {
				Parent = Items["Body"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Library.Theme["Accent"],
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2New(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				ZIndex = 4,
			}):AddToTheme({ScrollBarImageColor3 = "Accent"})

			Instances:Create("UIPadding", {
				Parent = Items["InfoScroll"].Instance,
				Name = "\0",
				PaddingRight = UDimNew(0, 4),
			})

			Items["InfoList"] = Instances:Create("Frame", {
				Parent = Items["InfoScroll"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["InfoList"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
			})

			Items["HealthTrack"] = Instances:Create("Frame", {
				Parent = Items["Body"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 10),
				BackgroundColor3 = Library.Theme["Element"],
				BorderSizePixel = 0,
				LayoutOrder = 2,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Element"})

			Instances:Create("UICorner", {
				Parent = Items["HealthTrack"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(1, 0),
			})

			Items["HealthFill"] = Instances:Create("Frame", {
				Parent = Items["HealthTrack"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 1, 0),
				BackgroundColor3 = Library.Theme["Accent"],
				BorderSizePixel = 0,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Accent"})

			Instances:Create("UICorner", {
				Parent = Items["HealthFill"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(1, 0),
			})

			Instances:Create("UIGradient", {
				Parent = Items["HealthFill"].Instance,
				Name = "\0",
				Rotation = 90,
				Color = RGBSequence{
					RGBSequenceKeypoint(0, FromRGB(255, 255, 255)),
					RGBSequenceKeypoint(1, FromRGB(190, 190, 190)),
				},
			})

			Items["HealthText"] = Instances:Create("TextLabel", {
				Parent = Items["HealthTrack"].Instance,
				Name = "\0",
				Size = UDim2New(1, -8, 1, 0),
				Position = UDim2New(0, 4, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "0 / 0",
				TextColor3 = Library.Theme["Text"],
				TextSize = 11,
				FontFace = Library.Font,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 5,
			}):AddToTheme({TextColor3 = "Text"})
		end

		Indicator.Items = Items

		local function ClampInfoScrollHeight()
			local LineCount = 0

			for _ in Indicator.Lines do
				LineCount += 1
			end

			local TargetHeight = MathClamp(LineCount * 17, 0, 102)
			Items["InfoScroll"].Instance.Size = UDim2New(1, 0, 0, TargetHeight)
		end

		function Indicator:SetVisibility(Bool)
			Indicator.Visible = Bool and true or false
			Items["Root"].Instance.Visible = Indicator.Visible
		end

		function Indicator:SetPosition(Position)
			Items["Root"].Instance.AnchorPoint = Vector2New(0, 0)
			Items["Root"].Instance.Position = Position
		end

		function Indicator:Center()
			local AbsPos = Items["Root"].Instance.AbsolutePosition
			local GuiInset = GuiService:GetGuiInset().Y

			Items["Root"].Instance.AnchorPoint = Vector2New(0, 0)
			Items["Root"].Instance.Position = UDim2New(0, AbsPos.X, 0, AbsPos.Y + GuiInset)
		end

		function Indicator:SetTitle(Text)
			Items["Title"].Instance.Text = tostring(Text or "")
		end

		function Indicator:SetSubtitle(Text)
			Items["Subtitle"].Instance.Text = tostring(Text or "")
		end

		function Indicator:SetAvatar(Image)
			Items["Avatar"].Instance.Image = tostring(Image or "rbxasset://textures/ui/GuiImagePlaceholder.png")
		end

		function Indicator:ResetHealthConnection()
			if Indicator.HealthConnection then
				Indicator.HealthConnection:Disconnect()
				Indicator.HealthConnection = nil
			end

			Indicator.BoundHumanoid = nil
			Indicator.BoundTarget = nil
		end

		function Indicator:SetHealth(Current, Maximum, FillColor)
			local MaxHealth = math.max(tonumber(Maximum) or 0, 1)
			local Health = math.clamp(tonumber(Current) or 0, 0, MaxHealth)
			local Alpha = Health / MaxHealth

			Items["HealthText"].Instance.Text = string.format("%d / %d", MathFloor(Health + 0.5), MathFloor(MaxHealth + 0.5))
			Items["HealthFill"]:Tween(nil, {Size = UDim2New(Alpha, 0, 1, 0)})

			if typeof(FillColor) == "Color3" then
				Items["HealthFill"].Instance.BackgroundColor3 = FillColor
			end
		end

		function Indicator:ClearInfo()
			for _, Child in Items["InfoList"].Instance:GetChildren() do
				if Child:IsA("TextLabel") then
					Child:Destroy()
				end
			end

			Indicator.Lines = {}
			ClampInfoScrollHeight()
		end

		function Indicator:RemoveLine(Key)
			local LineKey = tostring(Key)
			local LineData = Indicator.Lines[LineKey]

			if LineData and LineData.Item and LineData.Item.Instance then
				LineData.Item.Instance:Destroy()
			end

			Indicator.Lines[LineKey] = nil
			ClampInfoScrollHeight()
		end

		function Indicator:SetLine(Key, Value, Options)
			Options = Options or {}
			local LineKey = tostring(Key)
			local LineValue = tostring(Value)
			local LineText = Options.Text or string.format("%s: %s", LineKey, LineValue)
			local LayoutOrder = Options.Order or Options.layoutOrder

			if not LayoutOrder then
				local Count = 0

				for _ in Indicator.Lines do
					Count += 1
				end

				LayoutOrder = Count
			end

			local LineData = Indicator.Lines[LineKey]

			if not LineData then
				LineData = {}
				Indicator.Lines[LineKey] = LineData

				LineData.Item = Instances:Create("TextLabel", {
					Parent = Items["InfoList"].Instance,
					Name = "\0",
					Size = UDim2New(1, 0, 0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = LineText,
					TextColor3 = Options.Color or Library.Theme["Text"],
					TextSize = 12,
					FontFace = Library.Font,
					TextTransparency = Options.Transparency or 0.35,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = LayoutOrder,
					ZIndex = 4,
				})

				if not Options.Color then
					LineData.Item:AddToTheme({TextColor3 = "Text"})
				end
			else
				LineData.Item.Instance.Text = LineText
				LineData.Item.Instance.LayoutOrder = LayoutOrder

				if Options.Color then
					LineData.Item.Instance.TextColor3 = Options.Color
				end

				if Options.Transparency then
					LineData.Item.Instance.TextTransparency = Options.Transparency
				end
			end

			LineData.Key = LineKey
			LineData.Value = LineValue
			ClampInfoScrollHeight()
		end

		function Indicator:SetInfo(Info)
			self:ClearInfo()

			if type(Info) ~= "table" then
				return
			end

			if #Info > 0 then
				for Index, Entry in Info do
					if type(Entry) == "table" then
						local Key = Entry[1] or Entry.Key or Entry.key or Entry.Name or Entry.name or ("Line " .. Index)
						local Value = Entry[2] or Entry.Value or Entry.value or ""
						self:SetLine(Key, Value, Entry)
					elseif type(Entry) == "string" then
						self:SetLine("Info " .. Index, Entry)
					end
				end
			else
				for Key, Value in Info do
					if type(Key) == "string" and type(Value) ~= "table" and type(Value) ~= "function" then
						self:SetLine(Key, Value)
					end
				end
			end
		end

		function Indicator:UpdateInfo(Info)
			if type(Info) ~= "table" then
				return
			end

			if #Info > 0 then
				for Index, Entry in Info do
					if type(Entry) == "table" then
						local Key = Entry[1] or Entry.Key or Entry.key or Entry.Name or Entry.name
						local Value = Entry[2] or Entry.Value or Entry.value

						if Key then
							self:SetLine(Key, Value, Entry)
						end
					end
				end
			else
				for Key, Value in Info do
					if type(Key) == "string" and type(Value) ~= "table" and type(Value) ~= "function" then
						self:SetLine(Key, Value)
					end
				end
			end
		end

		function Indicator:ClearTarget()
			self:ResetHealthConnection()
			self:SetSubtitle("No target")
			self:SetAvatar("rbxasset://textures/ui/GuiImagePlaceholder.png")
			self:SetHealth(0, 0)
		end

		function Indicator:SetTarget(Target)
			self:ResetHealthConnection()

			if not Target then
				self:ClearTarget()
				return false
			end

			local TargetName = "Unknown"
			local TargetUserId = nil

			if IsRobloxInstance(Target) then
				if Target:IsA("Player") then
					TargetName = Target.Name
					TargetUserId = Target.UserId
					Indicator.BoundTarget = Target
				elseif Target:IsA("Model") then
					TargetName = Target.Name

					local Player = Players:GetPlayerFromCharacter(Target)
					if Player then
						TargetUserId = Player.UserId
						Indicator.BoundTarget = Player
					end
				elseif Target:IsA("Humanoid") then
					local Model = Target.Parent
					TargetName = Model and Model.Name or TargetName

					local Player = Model and Players:GetPlayerFromCharacter(Model)
					if Player then
						TargetUserId = Player.UserId
						Indicator.BoundTarget = Player
					end

					Indicator.BoundHumanoid = Target
				end
			end

			self:SetSubtitle(TargetName)

			if TargetUserId then
				local Success, Thumbnail = pcall(function()
					return Players:GetUserThumbnailAsync(TargetUserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
				end)

				if Success and Thumbnail then
					self:SetAvatar(Thumbnail)
				end
			end

			local Humanoid = Indicator.BoundHumanoid

			if not Humanoid and Indicator.BoundTarget and Indicator.BoundTarget.Character then
				Humanoid = Indicator.BoundTarget.Character:FindFirstChildOfClass("Humanoid")
			end

			if IsRobloxInstance(Target) and Target:IsA("Model") and not Humanoid then
				Humanoid = Target:FindFirstChildOfClass("Humanoid")
			end

			if not Humanoid then
				self:SetHealth(0, 0)
				return false
			end

			Indicator.BoundHumanoid = Humanoid

			local function OnHealthChanged(Health)
				if Indicator.BoundHumanoid ~= Humanoid then
					return
				end

				self:SetHealth(Health, Humanoid.MaxHealth)
			end

			OnHealthChanged(Humanoid.Health)
			Indicator.HealthConnection = Humanoid.HealthChanged:Connect(OnHealthChanged)

			return true
		end

		function Indicator:Show()
			self:SetVisibility(true)
		end

		function Indicator:Hide()
			self:SetVisibility(false)
		end

		Indicator:SetHealth(0, 100)
		Indicator:Center()

		return Indicator
	end

	Library.TargetHudIndicator = function(self, Data)
		Data = Data or {}

		local HudPath = GetFolders().Datas .. "/target_hud.json"

		local Hud = {
			Enabled = false,
			OffsetX = tonumber(Data.OffsetX or Data.offset_x) or 26,
			OffsetY = tonumber(Data.OffsetY or Data.offset_y) or 28,
			UIScalePercent = tonumber(Data.UIScale or Data.ui_scale) or 75,
			ItemScalePercent = tonumber(Data.ItemScale or Data.item_scale) or 81,
			ActiveSlot = nil,
			Dragged = false,
			DamageDealt = 0,
			DamageTaken = 0,
			LastTargetHealth = nil,
			LastLocalHealth = nil,
			TargetKey = nil,
			HealthConnection = nil,
			LocalHealthConnection = nil,
			BoundHumanoid = nil,
			BoundLocalHumanoid = nil,
			BoundTarget = nil,
			Items = {},
		}

		local Items = {}
		local SlotStrokes = {}
		local SlotImages = {}
		local StatValues = {}

		local function NormalizeImageId(Value)
			if type(Value) == "number" then
				return "rbxassetid://" .. tostring(Value)
			end

			if type(Value) ~= "string" or Value == "" then
				return ""
			end

			local NumericId = string.match(Value, "rbxassetid://(%d+)") or string.match(Value, "^(%d+)$")

			if NumericId then
				return "rbxassetid://" .. NumericId
			end

			return Value
		end

		local function MakeIconSlot(Parent, LayoutOrder)
			local IconFrame = Instances:Create("Frame", {
				Parent = Parent.Instance,
				Name = "\0",
				Size = UDim2FromOffset(60, 60),
				BackgroundColor3 = Library.Theme["Element"],
				BorderSizePixel = 0,
				LayoutOrder = LayoutOrder,
				ZIndex = 5,
			}):AddToTheme({BackgroundColor3 = "Element"})

			Instances:Create("UICorner", {
				Parent = IconFrame.Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 4),
			})

			local Stroke = Instances:Create("UIStroke", {
				Parent = IconFrame.Instance,
				Name = "\0",
				Thickness = 1,
				Color = Library.Theme["Border"],
				Transparency = 0,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			}):AddToTheme({Color = "Border"})

			local ImageLabel = Instances:Create("ImageLabel", {
				Parent = IconFrame.Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0.5, 0.5),
				Position = UDim2FromScale(0.5, 0.5),
				Size = UDim2FromScale(2.55, 2.55),
				BackgroundTransparency = 1,
				Image = "",
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 6,
			})

			local SlotIndex = #SlotStrokes + 1
			SlotStrokes[SlotIndex] = Stroke
			SlotImages[SlotIndex] = ImageLabel

			return IconFrame
		end

		local function MakeStatPair(Parent, LabelText, LayoutOrder)
			local PairFrame = Instances:Create("Frame", {
				Parent = Parent.Instance,
				Name = "\0",
				Size = UDim2New(0, 0, 1, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = LayoutOrder,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = PairFrame.Instance,
				Name = "\0",
				Padding = UDimNew(0, 6),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Instances:Create("TextLabel", {
				Parent = PairFrame.Instance,
				Name = "\0",
				Size = UDim2New(0, 0, 1, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Text = LabelText,
				TextColor3 = Library.Theme["Inactive Text"],
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				ZIndex = 5,
			}):AddToTheme({TextColor3 = "Inactive Text"})

			local ValueLabel = Instances:Create("TextLabel", {
				Parent = PairFrame.Instance,
				Name = "\0",
				Size = UDim2New(0, 0, 1, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Text = "0",
				TextColor3 = Library.Theme["Accent"],
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				ZIndex = 5,
			}):AddToTheme({TextColor3 = "Accent"})

			StatValues[LabelText] = ValueLabel
		end

		local function MakeMetric(Parent, LabelText, LayoutOrder)
			local MetricFrame = Instances:Create("Frame", {
				Parent = Parent.Instance,
				Name = "\0",
				Size = UDim2New(1, -30, 0, 16),
				BackgroundTransparency = 1,
				LayoutOrder = LayoutOrder,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = MetricFrame.Instance,
				Name = "\0",
				Padding = UDimNew(0, 4),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			local TextRow = Instances:Create("Frame", {
				Parent = MetricFrame.Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 10),
				BackgroundTransparency = 1,
				ZIndex = 5,
			})

			Instances:Create("TextLabel", {
				Parent = TextRow.Instance,
				Name = "\0",
				Size = UDim2FromScale(1, 1),
				BackgroundTransparency = 1,
				Text = LabelText,
				TextColor3 = Library.Theme["Inactive Text"],
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				ZIndex = 5,
			}):AddToTheme({TextColor3 = "Inactive Text"})

			local ValueLabel = Instances:Create("TextLabel", {
				Parent = TextRow.Instance,
				Name = "\0",
				Size = UDim2FromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = Library.Theme["Text"],
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = Library.Font,
				ZIndex = 5,
			}):AddToTheme({TextColor3 = "Text"})

			local BarRow = Instances:Create("Frame", {
				Parent = MetricFrame.Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 4),
				BackgroundTransparency = 1,
				ZIndex = 5,
			})

			local Track = Instances:Create("Frame", {
				Parent = BarRow.Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 4),
				BackgroundColor3 = Library.Theme["Border"],
				BorderSizePixel = 0,
				ZIndex = 5,
			}):AddToTheme({BackgroundColor3 = "Border"})

			Instances:Create("UICorner", {
				Parent = Track.Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 2),
			})

			local Fill = Instances:Create("Frame", {
				Parent = Track.Instance,
				Name = "\0",
				Size = UDim2New(0, 0, 1, 0),
				BackgroundColor3 = Library.Theme["Accent"],
				BorderSizePixel = 0,
				ZIndex = 6,
			}):AddToTheme({BackgroundColor3 = "Accent"})

			Instances:Create("UICorner", {
				Parent = Fill.Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 2),
			})

			return MetricFrame, ValueLabel, Fill
		end

		do
			Items["Root"] = Instances:Create("Frame", {
				Parent = Library.Holder.Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0.5, 0.5),
				Position = UDim2New(0.26, 0, 0.28, 0),
				Size = UDim2FromOffset(528, 208),
				BackgroundColor3 = Library.Theme["Background"],
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Background"})

			Items["Root"]:MakeDraggable()

			Instances:Create("UIStroke", {
				Parent = Items["Root"].Instance,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Color = Library.Theme["Outline"],
			}):AddToTheme({Color = "Outline"})

			Instances:Create("UIStroke", {
				Parent = Items["Root"].Instance,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Color = Library.Theme["Border"],
				BorderOffset = UDimNew(0, 1),
			}):AddToTheme({Color = "Border"})

			Items["UIScale"] = Instances:Create("UIScale", {
				Parent = Items["Root"].Instance,
				Name = "\0",
				Scale = 1,
			})

			Items["BorderFrame"] = Instances:Create("Frame", {
				Parent = Items["Root"].Instance,
				Name = "\0",
				Position = UDim2FromOffset(1, 1),
				Size = UDim2New(1, -2, 1, -2),
				BackgroundColor3 = Library.Theme["Inline"],
				BorderColor3 = Library.Theme["Border"],
				BorderSizePixel = 1,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Inline", BorderColor3 = "Border"})

			Items["PaddedFrame"] = Instances:Create("Frame", {
				Parent = Items["BorderFrame"].Instance,
				Name = "\0",
				Position = UDim2FromOffset(8, 8),
				Size = UDim2New(1, -16, 1, -16),
				BackgroundColor3 = Library.Theme["Background"],
				BorderColor3 = Library.Theme["Border"],
				BorderSizePixel = 1,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})

			Items["InnerBorder"] = Instances:Create("Frame", {
				Parent = Items["PaddedFrame"].Instance,
				Name = "\0",
				Position = UDim2FromOffset(8, 8),
				Size = UDim2New(1, -16, 1, -16),
				BackgroundColor3 = Library.Theme["Background"],
				BorderColor3 = Library.Theme["Border"],
				BorderSizePixel = 1,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})

			Items["Content"] = Instances:Create("Frame", {
				Parent = Items["InnerBorder"].Instance,
				Name = "\0",
				Position = UDim2FromOffset(2, 2),
				Size = UDim2New(1, -4, 1, -4),
				BackgroundColor3 = Library.Theme["Inline"],
				BorderColor3 = Library.Theme["Border"],
				BorderSizePixel = 1,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Inline", BorderColor3 = "Border"})

			Items["LeftIcons"] = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Size = UDim2New(0, 75, 1, 0),
				BackgroundTransparency = 1,
				ZIndex = 5,
			})

			Items["LeftIconScale"] = Instances:Create("UIScale", {
				Parent = Items["LeftIcons"].Instance,
				Name = "\0",
				Scale = 1,
			})

			Instances:Create("UIGridLayout", {
				Parent = Items["LeftIcons"].Instance,
				Name = "\0",
				CellSize = UDim2FromOffset(60, 60),
				CellPadding = UDim2FromOffset(0, 15),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Instances:Create("UIPadding", {
				Parent = Items["LeftIcons"].Instance,
				Name = "\0",
				PaddingLeft = UDimNew(0, 15),
				PaddingTop = UDimNew(0, 15),
			})

			MakeIconSlot(Items["LeftIcons"], 1)
			MakeIconSlot(Items["LeftIcons"], 2)

			Items["RightIcons"] = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(1, 0),
				Position = UDim2New(1, 0, 0, 0),
				Size = UDim2New(0, 75, 1, 0),
				BackgroundTransparency = 1,
				ZIndex = 5,
			})

			Items["RightIconScale"] = Instances:Create("UIScale", {
				Parent = Items["RightIcons"].Instance,
				Name = "\0",
				Scale = 1,
			})

			Instances:Create("UIGridLayout", {
				Parent = Items["RightIcons"].Instance,
				Name = "\0",
				CellSize = UDim2FromOffset(60, 60),
				CellPadding = UDim2FromOffset(0, 15),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Instances:Create("UIPadding", {
				Parent = Items["RightIcons"].Instance,
				Name = "\0",
				PaddingTop = UDimNew(0, 15),
			})

			MakeIconSlot(Items["RightIcons"], 3)
			MakeIconSlot(Items["RightIcons"], 4)

			Items["Middle"] = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0.5, 0),
				Position = UDim2New(0.5, 0, 0, 0),
				Size = UDim2New(1, -150, 1, 0),
				BackgroundTransparency = 1,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["Middle"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 12),
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Items["NameBlock"] = Instances:Create("Frame", {
				Parent = Items["Middle"].Instance,
				Name = "\0",
				Size = UDim2New(1, -30, 0, 40),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["NameBlock"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 6),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Items["NameLabel"] = Instances:Create("TextLabel", {
				Parent = Items["NameBlock"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = Library.Theme["Text"],
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Center,
				FontFace = Library.Font,
				ZIndex = 5,
			}):AddToTheme({TextColor3 = "Text"})

			Items["InfoBlock"] = Instances:Create("Frame", {
				Parent = Items["NameBlock"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 20),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["InfoBlock"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 2),
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Items["InfoRowTop"] = Instances:Create("Frame", {
				Parent = Items["InfoBlock"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 9),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["InfoRowTop"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 10),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			MakeStatPair(Items["InfoRowTop"], "level", 1)
			MakeStatPair(Items["InfoRowTop"], "rank", 2)

			Items["InfoRowBottom"] = Instances:Create("Frame", {
				Parent = Items["InfoBlock"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 9),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["InfoRowBottom"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 10),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			MakeStatPair(Items["InfoRowBottom"], "device", 1)
			MakeStatPair(Items["InfoRowBottom"], "streak", 2)

			local DividerHolder = Instances:Create("Frame", {
				Parent = Items["Middle"].Instance,
				Name = "\0",
				Size = UDim2New(1, -30, 0, 6),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				ZIndex = 5,
			})

			local DividerLine = Instances:Create("Frame", {
				Parent = DividerHolder.Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0.5, 0.5),
				Position = UDim2FromScale(0.5, 0.5),
				Size = UDim2New(1, 0, 0, 1),
				BackgroundColor3 = Library.Theme["Border"],
				BorderSizePixel = 0,
				ZIndex = 5,
			}):AddToTheme({BackgroundColor3 = "Border"})

			local _, HealthValueLabel, HealthFill = MakeMetric(Items["Middle"], "health", 3)
			local _, DamageValueLabel, DamageFill = MakeMetric(Items["Middle"], "damage ratio", 4)
			DamageValueLabel.Instance.RichText = true

			Items["HealthValue"] = HealthValueLabel
			Items["HealthFill"] = HealthFill
			Items["DamageValue"] = DamageValueLabel
			Items["DamageFill"] = DamageFill
			Items["SlotStrokes"] = SlotStrokes
			Items["SlotImages"] = SlotImages
			Items["StatValues"] = StatValues
		end

		Hud.Items = Items
		local ApplyingPreset = false

		local function gui(key)
			return GetWrapperInstance(Items[key])
		end

		local function slot_gui(index)
			return GetWrapperInstance(SlotImages[index])
		end

		local function stroke_gui(index)
			return GetWrapperInstance(SlotStrokes[index])
		end

		local function stat_gui(key)
			return GetWrapperInstance(StatValues[key])
		end

		local function SavePosition()
			if not writefile then
				return
			end

			pcall(function()
				local Frame = gui("Root")
				if not Frame then
					return
				end

				writefile(HudPath, HttpService:JSONEncode({
					X = Frame.Position.X.Scale,
					XOffset = Frame.Position.X.Offset,
					Y = Frame.Position.Y.Scale,
					YOffset = Frame.Position.Y.Offset,
					Dragged = Hud.Dragged == true,
				}))
			end)
		end

		local function LoadPosition()
			if not readfile or not isfile or not isfile(HudPath) then
				return
			end

			pcall(function()
				local Saved = HttpService:JSONDecode(readfile(HudPath))
				local Root = gui("Root")

				if Saved.Dragged == true and Root then
					Hud.Dragged = true
					ApplyingPreset = true
					Root.AnchorPoint = Vector2New(0, 0)
					Root.Position = UDim2New(
						Saved.X or 0,
						Saved.XOffset or 0,
						Saved.Y or 0,
						Saved.YOffset or 0
					)
					ApplyingPreset = false
				end
			end)
		end

		local function ApplyPresetPosition()
			if Hud.Dragged == true then
				return
			end

			local Root = gui("Root")
			if not Root then
				return
			end

			ApplyingPreset = true
			Root.AnchorPoint = Vector2New(0.5, 0.5)
			Root.Position = UDim2New(Hud.OffsetX / 100, 0, Hud.OffsetY / 100, 0)
			ApplyingPreset = false
		end

		function Hud:SetEnabled(Bool)
			Hud.Enabled = Bool == true
			if Hud.Enabled ~= true then
				local Root = gui("Root")
				if Root then
					Root.Visible = false
				end
			end
		end

		function Hud:SetOffset(X, Y)
			Hud.OffsetX = math.clamp(tonumber(X) or Hud.OffsetX, 0, 100)
			Hud.OffsetY = math.clamp(tonumber(Y) or Hud.OffsetY, 0, 100)
			Hud.Dragged = false
			ApplyPresetPosition()
		end

		function Hud:SetUIScale(Percent)
			local Scale = math.clamp((tonumber(Percent) or 100) / 100, 0.5, 2.5)
			Hud.UIScalePercent = Scale * 100
			local UIScale = gui("UIScale")
			if UIScale then
				UIScale.Scale = Scale
			end
		end

		function Hud:SetItemScale(Percent)
			local Scale = math.clamp((tonumber(Percent) or 100) / 100, 0.5, 2.5)
			Hud.ItemScalePercent = Scale * 100
			local LeftScale = gui("LeftIconScale")
			local RightScale = gui("RightIconScale")
			if LeftScale then
				LeftScale.Scale = Scale
			end
			if RightScale then
				RightScale.Scale = Scale
			end
		end

		function Hud:ResetDamageState()
			Hud.DamageDealt = 0
			Hud.DamageTaken = 0
			Hud.LastTargetHealth = nil
			Hud.LastLocalHealth = nil
		end

		function Hud:ResetConnections()
			if Hud.HealthConnection then
				Hud.HealthConnection:Disconnect()
				Hud.HealthConnection = nil
			end

			if Hud.LocalHealthConnection then
				Hud.LocalHealthConnection:Disconnect()
				Hud.LocalHealthConnection = nil
			end

			Hud.BoundHumanoid = nil
			Hud.BoundLocalHumanoid = nil
			Hud.BoundTarget = nil
		end

		function Hud:SetHealth(Current, Maximum)
			local MaxHealth = math.max(tonumber(Maximum) or 0, 1)
			local Health = math.clamp(tonumber(Current) or 0, 0, MaxHealth)
			local Alpha = Health / MaxHealth
			local HealthValue = gui("HealthValue")

			if HealthValue then
				HealthValue.Text = string.format("%d / %d", MathFloor(Health + 0.5), MathFloor(MaxHealth + 0.5))
			end

			if Items["HealthFill"] then
				Items["HealthFill"]:Tween(nil, {Size = UDim2New(Alpha, 0, 1, 0)})
			end
		end

		function Hud:SetDamageRatio()
			local Dealt = math.max(tonumber(Hud.DamageDealt) or 0, 0)
			local Taken = math.max(tonumber(Hud.DamageTaken) or 0, 0)
			local Total = math.max(Dealt + Taken, 1)
			local Alpha = Dealt / Total
			local DealtText = tostring(MathFloor(Dealt + 0.5))
			local TakenText = tostring(MathFloor(Taken + 0.5))
			local DealtColor = Library.Theme["Accent"]
			local TakenColor = Color3.fromRGB(255, 90, 90)
			local DamageValue = gui("DamageValue")

			if DamageValue then
				DamageValue.Text = string.format(
					"%s \226\150\178 %s \226\150\188",
					Library:ToRich(DealtText, DealtColor),
					Library:ToRich(TakenText, TakenColor)
				)
			end

			if Items["DamageFill"] then
				Items["DamageFill"]:Tween(nil, {Size = UDim2New(Alpha, 0, 1, 0)})
			end
		end

		function Hud:SetSlotImages(Slot1, Slot2, Slot3, Slot4)
			local Images = {Slot1, Slot2, Slot3, Slot4}

			for Index = 1, 4 do
				local ImageId = NormalizeImageId(Images[Index])
				local ImageLabel = slot_gui(Index)
				if ImageLabel then
					ImageLabel.Image = ImageId
					ImageLabel.ImageTransparency = ImageId == "" and 1 or 0
					ImageLabel.Visible = true
				end
			end
		end

		function Hud:SetCurrentSlot(SlotIndex)
			local ActiveSlot = tonumber(SlotIndex)
			Hud.ActiveSlot = ActiveSlot

			for Index = 1, 4 do
				local IsActive = Index == ActiveSlot
				local StrokeColor = IsActive and Library.Theme["Accent"] or Library.Theme["Border"]
				local Stroke = stroke_gui(Index)
				if Stroke then
					Stroke.Color = StrokeColor
					Stroke.Thickness = IsActive and 2 or 1
				end
			end
		end

		function Hud:OnThemeChanged()
			self:SetCurrentSlot(Hud.ActiveSlot)
			self:SetDamageRatio()
		end

		function Hud:SetStats(Level, Rank, Device, Streak)
			local LevelLabel = stat_gui("level")
			local RankLabel = stat_gui("rank")
			local DeviceLabel = stat_gui("device")
			local StreakLabel = stat_gui("streak")

			if LevelLabel then LevelLabel.Text = tostring(Level or "0") end
			if RankLabel then RankLabel.Text = tostring(Rank or "unranked") end
			if DeviceLabel then DeviceLabel.Text = tostring(Device or "unknown") end
			if StreakLabel then StreakLabel.Text = tostring(Streak or "0") end
		end

		function Hud:GetTargetKey(Target)
			if IsRobloxInstance(Target) then
				if Target:IsA("Player") then
					return "player:" .. tostring(Target.UserId)
				end

				if Target:IsA("Model") then
					local Player = Players:GetPlayerFromCharacter(Target)

					if Player then
						return "player:" .. tostring(Player.UserId)
					end

					return "model:" .. Target:GetFullName()
				end

				if Target:IsA("Humanoid") then
					local Model = Target.Parent
					local Player = Model and Players:GetPlayerFromCharacter(Model)

					if Player then
						return "player:" .. tostring(Player.UserId)
					end

					return "humanoid:" .. Target:GetFullName()
				end
			end

			return nil
		end

		function Hud:BindHealthListeners(Humanoid)
			if not Humanoid then
				return
			end

			Hud.BoundHumanoid = Humanoid
			Hud.LastTargetHealth = Humanoid.Health

			local function OnTargetHealthChanged(Health)
				if Hud.BoundHumanoid ~= Humanoid then
					return
				end

				local LastHealth = Hud.LastTargetHealth

				if type(LastHealth) == "number" and Health < LastHealth then
					Hud.DamageDealt += LastHealth - Health
					Hud:SetDamageRatio()
				end

				Hud.LastTargetHealth = Health
				Hud:SetHealth(Health, Humanoid.MaxHealth)
			end

			OnTargetHealthChanged(Humanoid.Health)
			Hud.HealthConnection = Humanoid.HealthChanged:Connect(OnTargetHealthChanged)

			local Character = LocalPlayer.Character
			local LocalHumanoid = Character and Character:FindFirstChildOfClass("Humanoid")

			if LocalHumanoid then
				Hud.BoundLocalHumanoid = LocalHumanoid
				Hud.LastLocalHealth = LocalHumanoid.Health

				local function OnLocalHealthChanged(Health)
					if Hud.BoundLocalHumanoid ~= LocalHumanoid then
						return
					end

					local LastHealth = Hud.LastLocalHealth

					if type(LastHealth) == "number" and Health < LastHealth then
						Hud.DamageTaken += LastHealth - Health
						Hud:SetDamageRatio()
					end

					Hud.LastLocalHealth = Health
				end

				OnLocalHealthChanged(LocalHumanoid.Health)
				Hud.LocalHealthConnection = LocalHumanoid.HealthChanged:Connect(OnLocalHealthChanged)
			end
		end

		function Hud:ClearTarget()
			self:ResetConnections()
			self:ResetDamageState()
			Hud.TargetKey = nil

			RunGuiMutation(function()
				local NameLabel = gui("NameLabel")
				if NameLabel then
					NameLabel.Text = ""
				end

				self:SetHealth(0, 0)
				self:SetDamageRatio()
				self:SetStats("", "", "", "")
				self:SetSlotImages("", "", "", "")
				self:SetCurrentSlot(nil)

				local Root = gui("Root")
				if Root then
					Root.Visible = false
				end
			end)
		end

		function Hud:SetTargetHudIndicator(Target, Slot1, Slot2, Slot3, Slot4, Streak, Rank, Level, Device, CurrentSlot)
			if type(Target) == "table" and Target.target ~= nil then
				local Payload = Target
				return self:SetTargetHudIndicator(
					Payload.target,
					Payload.slots and Payload.slots[1] or Payload.slot1,
					Payload.slots and Payload.slots[2] or Payload.slot2,
					Payload.slots and Payload.slots[3] or Payload.slot3,
					Payload.slots and Payload.slots[4] or Payload.slot4,
					Payload.streak,
					Payload.rank,
					Payload.level,
					Payload.device,
					Payload.current_slot
				)
			end

			if not Target then
				self:ClearTarget()
				return false
			end

			local TargetName = "Unknown"
			local TargetKey = self:GetTargetKey(Target)

			if IsRobloxInstance(Target) then
				if Target:IsA("Player") then
					TargetName = Target.Name
					Hud.BoundTarget = Target
				elseif Target:IsA("Model") then
					TargetName = Target.Name

					local Player = Players:GetPlayerFromCharacter(Target)

					if Player then
						Hud.BoundTarget = Player
						TargetName = Player.Name
					end
				elseif Target:IsA("Humanoid") then
					local Model = Target.Parent
					TargetName = Model and Model.Name or TargetName

					local Player = Model and Players:GetPlayerFromCharacter(Model)

					if Player then
						Hud.BoundTarget = Player
						TargetName = Player.Name
					end
				end
			end

			if TargetKey ~= Hud.TargetKey then
				self:ResetConnections()
				self:ResetDamageState()
				Hud.TargetKey = TargetKey
			end

			local Humanoid = nil

			if IsRobloxInstance(Target) and Target:IsA("Humanoid") then
				Humanoid = Target
			elseif Hud.BoundTarget and Hud.BoundTarget.Character then
				Humanoid = Hud.BoundTarget.Character:FindFirstChildOfClass("Humanoid")
			elseif IsRobloxInstance(Target) and Target:IsA("Model") then
				Humanoid = Target:FindFirstChildOfClass("Humanoid")
			end

			local ShowRoot = Hud.Enabled == true and Humanoid ~= nil

			RunGuiMutation(function()
				local NameLabel = gui("NameLabel")
				if NameLabel then
					NameLabel.Text = TargetName
				end

				self:SetStats(Level, Rank, Device, Streak)
				self:SetSlotImages(Slot1, Slot2, Slot3, Slot4)
				self:SetCurrentSlot(CurrentSlot)

				if not Humanoid then
					self:SetHealth(0, 0)
					return
				end

				local Root = gui("Root")
				if Root then
					Root.Visible = ShowRoot
				end
			end)

			if not Humanoid then
				return false
			end

			if Hud.BoundHumanoid ~= Humanoid then
				if Hud.HealthConnection then
					Hud.HealthConnection:Disconnect()
					Hud.HealthConnection = nil
				end

				if Hud.LocalHealthConnection then
					Hud.LocalHealthConnection:Disconnect()
					Hud.LocalHealthConnection = nil
				end

				self:BindHealthListeners(Humanoid)
			end

			return true
		end

		local RootInstance = gui("Root")
		if RootInstance then
			RootInstance:GetPropertyChangedSignal("Position"):Connect(function()
				if ApplyingPreset == true then
					return
				end

				Hud.Dragged = true
				SavePosition()
			end)
		end

		LoadPosition()
		ApplyPresetPosition()
		Hud:SetUIScale(Hud.UIScalePercent)
		Hud:SetItemScale(Hud.ItemScalePercent)
		Hud:SetHealth(0, 100)
		Hud:SetDamageRatio()

		return Hud
	end

	Library.DuelStatsIndicator = function(self, Data)
		Data = Data or {}

		local HudPath = GetFolders().Datas .. "/duel_stats_hud.json"
		local Hud = {
			Enabled = false,
			OffsetX = tonumber(Data.OffsetX or Data.offset_x) or 72,
			OffsetY = tonumber(Data.OffsetY or Data.offset_y) or 18,
			UIScalePercent = tonumber(Data.UIScale or Data.ui_scale) or 75,
			Dragged = false,
			LastStats = {},
			Items = {},
		}

		local Items = {}
		local StatValues = {}
		local StatRows = {}
		local DEFAULT_STAT_ORDER = {
			"kills",
			"deaths",
			"damage dealt",
			"damage taken",
			"headshot %",
			"score",
			"round",
			"time elapsed",
			"mode",
		}
		local StatOrder = table.clone(DEFAULT_STAT_ORDER)
		local DragState = nil
		local SaveHudConfig
		local RowHighlightTweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local RowPulseTweenInfo = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local function GetHudMousePoint()
			return Vector2New(Mouse.X, Mouse.Y)
		end

		local LEGACY_STAT_KEYS = {
			ko = "kills",
			time = "time elapsed",
		}

		local function ValidateStatOrder(Order)
			if type(Order) ~= "table" or #Order ~= #DEFAULT_STAT_ORDER then
				return nil
			end

			local Seen = {}

			for Index = 1, #Order do
				local Key = Order[Index]

				if type(Key) ~= "string" or Seen[Key] == true then
					return nil
				end

				Seen[Key] = true
			end

			for Index = 1, #DEFAULT_STAT_ORDER do
				if Seen[DEFAULT_STAT_ORDER[Index]] ~= true then
					return nil
				end
			end

			return Order
		end

		local function MigrateStatOrder(Order)
			if type(Order) ~= "table" then
				return nil
			end

			local Migrated = {}

			for Index = 1, #Order do
				local Key = Order[Index]

				if type(Key) ~= "string" then
					return nil
				end

				Migrated[Index] = LEGACY_STAT_KEYS[Key] or Key
			end

			return ValidateStatOrder(Migrated)
		end

		local function ApplyStatOrder(Order)
			Order = ValidateStatOrder(Order) or DEFAULT_STAT_ORDER
			StatOrder = table.clone(Order)

			for Index = 1, #StatOrder do
				local RowData = StatRows[StatOrder[Index]]

				if RowData and RowData.Row and RowData.Row.Instance then
					RowData.Row.Instance.LayoutOrder = Index
				end
			end

			Hud.StatOrder = StatOrder
		end

		local function SetRowHighlight(RowData, Active)
			if type(RowData) ~= "table" or not RowData.Highlight then
				return
			end

			local Highlight = GetWrapperInstance(RowData.Highlight)

			if not Highlight then
				return
			end

			TweenService:Create(Highlight, RowHighlightTweenInfo, {
				BackgroundTransparency = Active == true and 0.82 or 1,
			}):Play()
		end

		local function ClearRowHighlights()
			for Index = 1, #DEFAULT_STAT_ORDER do
				local RowData = StatRows[DEFAULT_STAT_ORDER[Index]]

				if RowData then
					SetRowHighlight(RowData, false)
				end
			end
		end

		local function PulseRow(RowData)
			if type(RowData) ~= "table" or not RowData.Highlight then
				return
			end

			local Highlight = GetWrapperInstance(RowData.Highlight)

			if not Highlight then
				return
			end

			local PulseIn = TweenService:Create(Highlight, RowPulseTweenInfo, {
				BackgroundTransparency = 0.72,
			})

			PulseIn:Play()
			PulseIn.Completed:Connect(function()
				TweenService:Create(Highlight, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1,
				}):Play()
			end)
		end

		local function GetRowKeyAtPosition(ScreenPoint)
			for Index = 1, #StatOrder do
				local Key = StatOrder[Index]
				local RowData = StatRows[Key]

				if RowData and RowData.Row and RowData.Row.Instance then
					local Frame = RowData.Row.Instance
					local Position = Frame.AbsolutePosition
					local Size = Frame.AbsoluteSize

					if ScreenPoint.X >= Position.X and ScreenPoint.X <= Position.X + Size.X
						and ScreenPoint.Y >= Position.Y and ScreenPoint.Y <= Position.Y + Size.Y then
						return Key, RowData
					end
				end
			end

			return nil, nil
		end

		local function SwapStatOrder(KeyA, KeyB)
			if KeyA == KeyB then
				return false
			end

			local IndexA, IndexB

			for Index = 1, #StatOrder do
				if StatOrder[Index] == KeyA then
					IndexA = Index
				elseif StatOrder[Index] == KeyB then
					IndexB = Index
				end
			end

			if not IndexA or not IndexB then
				return false
			end

			StatOrder[IndexA], StatOrder[IndexB] = StatOrder[IndexB], StatOrder[IndexA]
			ApplyStatOrder(StatOrder)
			PulseRow(StatRows[KeyA])
			PulseRow(StatRows[KeyB])
			return true
		end

		local function DestroyDragGhost()
			if DragState and DragState.Ghost and DragState.Ghost.Parent then
				DragState.Ghost:Destroy()
			end

			if DragState and DragState.GhostScale and DragState.GhostScale.Parent then
				DragState.GhostScale:Destroy()
			end
		end

		local function StopRowDrag(DidSwap)
			if type(DragState) ~= "table" then
				return
			end

			Library.BlockWindowDrag = false

			if DragState.MoveConnection then
				pcall(function()
					DragState.MoveConnection:Disconnect()
				end)
			end

			if DragState.EndConnection then
				pcall(function()
					DragState.EndConnection:Disconnect()
				end)
			end

			local SourceRow = StatRows[DragState.Key]

			if SourceRow and SourceRow.DragHandle and SourceRow.DragHandle.Instance then
				SourceRow.DragHandle.Instance.TextTransparency = 0
			end

			if SourceRow and SourceRow.Row and SourceRow.Row.Instance then
				SourceRow.Row.Instance.BackgroundTransparency = 1
			end

			ClearRowHighlights()
			DestroyDragGhost()
			DragState = nil

			if DidSwap == true then
				SaveHudConfig()
			end
		end

		local UpdateRowDrag = LPH_NO_VIRTUALIZE(function()
			if type(DragState) ~= "table" then
				return
			end

			local Mouse = GetHudMousePoint()
			local Delta = (Mouse - DragState.StartMouse).Magnitude

			if DragState.Active ~= true and Delta >= 4 then
				DragState.Active = true
				Library.BlockWindowDrag = true

				local SourceRow = StatRows[DragState.Key]

				if SourceRow and SourceRow.Row and SourceRow.Row.Instance then
					local Frame = SourceRow.Row.Instance
					local Ghost = Instances:Create("Frame", {
						Parent = Library.Holder.Instance,
						Name = "\0",
						AnchorPoint = Vector2New(0.5, 0.5),
						Position = UDim2FromOffset(Mouse.X, Mouse.Y),
						Size = UDim2FromOffset(math.max(Frame.AbsoluteSize.X, 120), math.max(Frame.AbsoluteSize.Y, 16)),
						BackgroundColor3 = Library.Theme["Element"],
						BackgroundTransparency = 0.08,
						BorderSizePixel = 0,
						ZIndex = 30,
					}):AddToTheme({BackgroundColor3 = "Element"})

					Instances:Create("UICorner", {
						Parent = Ghost.Instance,
						CornerRadius = UDimNew(0, 6),
					})

					Instances:Create("UIStroke", {
						Parent = Ghost.Instance,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Library.Theme["Accent"],
						Thickness = 1.5,
						Transparency = 0.15,
					}):AddToTheme({Color = "Accent"})

					Instances:Create("TextLabel", {
						Parent = Ghost.Instance,
						Name = "\0",
						Size = UDim2New(1, -12, 1, 0),
						Position = UDim2FromOffset(6, 0),
						BackgroundTransparency = 1,
						Text = DragState.LabelText or DragState.Key,
						TextColor3 = Library.Theme["Accent"],
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left,
						FontFace = Library.Font,
						ZIndex = 31,
					}):AddToTheme({TextColor3 = "Accent"})

					local GhostScale = Instances:Create("UIScale", {
						Parent = Ghost.Instance,
						Scale = 1.04,
					})

					DragState.Ghost = Ghost.Instance
					DragState.GhostScale = GhostScale.Instance

					SourceRow.Row.Instance.BackgroundTransparency = 0.65
					SourceRow.DragHandle.Instance.TextTransparency = 0.45
				end
			end

			if DragState.Ghost then
				DragState.Ghost.Position = UDim2FromOffset(Mouse.X, Mouse.Y)
			end

			if DragState.Active ~= true then
				return
			end

			local HoverKey = GetRowKeyAtPosition(Mouse)
			local HoverRow = HoverKey and StatRows[HoverKey] or nil

			if HoverKey ~= DragState.HoverKey then
				if DragState.HoverKey and StatRows[DragState.HoverKey] then
					SetRowHighlight(StatRows[DragState.HoverKey], false)
				end

				DragState.HoverKey = HoverKey

				if HoverKey and HoverKey ~= DragState.Key and HoverRow then
					SetRowHighlight(HoverRow, true)
				end
			end
		end)

		local function BeginRowDrag(Key, LabelText, Input)
			if type(DragState) == "table" then
				StopRowDrag(false)
			end

			DragState = {
				Key = Key,
				LabelText = LabelText,
				StartMouse = GetHudMousePoint(),
				StartPosition = Input.Position,
				Active = false,
				HoverKey = nil,
				Ghost = nil,
				GhostScale = nil,
			}

			DragState.MoveConnection = UserInputService.InputChanged:Connect(LPH_NO_VIRTUALIZE(function(MoveInput)
				if MoveInput.UserInputType ~= Enum.UserInputType.MouseMovement
					and MoveInput.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				UpdateRowDrag()
			end))

			DragState.EndConnection = UserInputService.InputEnded:Connect(function(EndInput)
				if EndInput.UserInputType ~= Enum.UserInputType.MouseButton1
					and EndInput.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				local DidSwap = false

				if DragState.Active == true and DragState.HoverKey and DragState.HoverKey ~= DragState.Key then
					DidSwap = SwapStatOrder(DragState.Key, DragState.HoverKey) == true
				end

				StopRowDrag(DidSwap)
			end)

			UpdateRowDrag()
		end

		local function MakeStatRow(Parent, Key, LayoutOrder)
			local Row = Instances:Create("Frame", {
				Parent = Parent.Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 14),
				BackgroundColor3 = Library.Theme["Element"],
				BackgroundTransparency = 1,
				LayoutOrder = LayoutOrder,
				ZIndex = 5,
			}):AddToTheme({BackgroundColor3 = "Element"})

			Row.Instance:SetAttribute("BlockWindowDrag", true)

			local Highlight = Instances:Create("Frame", {
				Parent = Row.Instance,
				Name = "\0",
				Size = UDim2New(1, 6, 1, 4),
				Position = UDim2FromOffset(-3, -2),
				BackgroundColor3 = Library.Theme["Accent"],
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Accent"})

			Instances:Create("UICorner", {
				Parent = Highlight.Instance,
				CornerRadius = UDimNew(0, 5),
			})

			local DragHandle = Instances:Create("TextButton", {
				Parent = Row.Instance,
				Name = "\0",
				Size = UDim2New(0.55, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = Key,
				TextColor3 = Library.Theme["Inactive Text"],
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				AutoButtonColor = false,
				ZIndex = 6,
			}):AddToTheme({TextColor3 = "Inactive Text"})

			DragHandle.Instance:SetAttribute("BlockWindowDrag", true)

			local ValueLabel = Instances:Create("TextLabel", {
				Parent = Row.Instance,
				Name = "\0",
				AnchorPoint = Vector2New(1, 0),
				Position = UDim2New(1, 0, 0, 0),
				Size = UDim2New(0.45, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "0",
				TextColor3 = Library.Theme["Accent"],
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = Library.Font,
				ZIndex = 5,
			}):AddToTheme({TextColor3 = "Accent"})

			StatValues[Key] = ValueLabel
			StatRows[Key] = {
				Key = Key,
				Row = Row,
				DragHandle = DragHandle,
				ValueLabel = ValueLabel,
				Highlight = Highlight,
			}

			DragHandle:Connect("InputBegan", function(InputObject)
				if InputObject.UserInputType ~= Enum.UserInputType.MouseButton1
					and InputObject.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				BeginRowDrag(Key, Key, InputObject)
			end)

			DragHandle:Connect("MouseEnter", function()
				if type(DragState) == "table" and DragState.Active == true then
					return
				end

				TweenService:Create(DragHandle.Instance, RowHighlightTweenInfo, {
					TextColor3 = Library.Theme["Accent"],
				}):Play()
			end)

			DragHandle:Connect("MouseLeave", function()
				if type(DragState) == "table" then
					return
				end

				TweenService:Create(DragHandle.Instance, RowHighlightTweenInfo, {
					TextColor3 = Library.Theme["Inactive Text"],
				}):Play()
			end)

			return Row
		end

		do
			Items["Root"] = Instances:Create("Frame", {
				Parent = Library.Holder.Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0.5, 0.5),
				Position = UDim2New(0.72, 0, 0.18, 0),
				Size = UDim2FromOffset(250, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Library.Theme["Background"],
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 4,
			}):AddToTheme({BackgroundColor3 = "Background"})

			Items["Root"]:MakeDraggable()

			Instances:Create("UIStroke", {
				Parent = Items["Root"].Instance,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Library.Theme["Outline"],
			}):AddToTheme({Color = "Outline"})

			Items["UIScale"] = Instances:Create("UIScale", {
				Parent = Items["Root"].Instance,
				Name = "\0",
				Scale = 1,
			})

			Instances:Create("UIPadding", {
				Parent = Items["Root"].Instance,
				PaddingTop = UDimNew(0, 10),
				PaddingBottom = UDimNew(0, 10),
				PaddingLeft = UDimNew(0, 10),
				PaddingRight = UDimNew(0, 10),
			})

			Items["Content"] = Instances:Create("Frame", {
				Parent = Items["Root"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 6),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Items["Header"] = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 46),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["Header"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 8),
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Items["Avatar"] = Instances:Create("ImageLabel", {
				Parent = Items["Header"].Instance,
				Name = "\0",
				Size = UDim2FromOffset(42, 42),
				BackgroundColor3 = Library.Theme["Element"],
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Image = "",
				LayoutOrder = 1,
				ZIndex = 5,
			}):AddToTheme({BackgroundColor3 = "Element"})

			Instances:Create("UICorner", {
				Parent = Items["Avatar"].Instance,
				CornerRadius = UDimNew(1, 0),
			})

			Items["NameColumn"] = Instances:Create("Frame", {
				Parent = Items["Header"].Instance,
				Name = "\0",
				Size = UDim2New(1, -50, 1, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["NameColumn"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 2),
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Items["UsernameLabel"] = Instances:Create("TextLabel", {
				Parent = Items["NameColumn"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = "@username",
				TextColor3 = Library.Theme["Accent"],
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				FontFace = Library.Font,
				LayoutOrder = 1,
				ZIndex = 5,
			}):AddToTheme({TextColor3 = "Accent"})

			Items["DisplayNameLabel"] = Instances:Create("TextLabel", {
				Parent = Items["NameColumn"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 14),
				BackgroundTransparency = 1,
				Text = "Display Name",
				TextColor3 = Library.Theme["Inactive Text"],
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				FontFace = Library.Font,
				LayoutOrder = 2,
				ZIndex = 5,
			}):AddToTheme({TextColor3 = "Inactive Text"})

			Items["HeaderDivider"] = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 1),
				BackgroundColor3 = Library.Theme["Border"],
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				ZIndex = 5,
			}):AddToTheme({BackgroundColor3 = "Border"})

			Items["StatsBlock"] = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 3,
				ZIndex = 5,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["StatsBlock"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 3),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			MakeStatRow(Items["StatsBlock"], "kills", 1)
			MakeStatRow(Items["StatsBlock"], "deaths", 2)
			MakeStatRow(Items["StatsBlock"], "damage dealt", 3)
			MakeStatRow(Items["StatsBlock"], "damage taken", 4)
			MakeStatRow(Items["StatsBlock"], "headshot %", 5)
			MakeStatRow(Items["StatsBlock"], "score", 6)
			MakeStatRow(Items["StatsBlock"], "round", 7)
			MakeStatRow(Items["StatsBlock"], "time elapsed", 8)
			MakeStatRow(Items["StatsBlock"], "mode", 9)

			Items["StatsBlock"].Instance:SetAttribute("BlockWindowDrag", true)
		end

		Hud.Items = Items
		Hud.StatRows = StatRows
		Hud.StatOrder = StatOrder
		local ApplyingPreset = false

		local function gui(key)
			return GetWrapperInstance(Items[key])
		end

		local function stat_gui(key)
			return GetWrapperInstance(StatValues[key])
		end

		SaveHudConfig = function()
			if not writefile then return end
			pcall(function()
				local Frame = gui("Root")
				if not Frame then return end
				writefile(HudPath, HttpService:JSONEncode({
					X = Frame.Position.X.Scale,
					XOffset = Frame.Position.X.Offset,
					Y = Frame.Position.Y.Scale,
					YOffset = Frame.Position.Y.Offset,
					Dragged = Hud.Dragged == true,
					StatOrder = StatOrder,
				}))
			end)
		end

		local function LoadHudConfig()
			if not readfile or not isfile or not isfile(HudPath) then return end
			pcall(function()
				local Saved = HttpService:JSONDecode(readfile(HudPath))
				local Root = gui("Root")
				if Saved.Dragged == true and Root then
					Hud.Dragged = true
					ApplyingPreset = true
					Root.AnchorPoint = Vector2New(0, 0)
					Root.Position = UDim2New(Saved.X or 0, Saved.XOffset or 0, Saved.Y or 0, Saved.YOffset or 0)
					ApplyingPreset = false
				end
				local LoadedOrder = MigrateStatOrder(Saved.StatOrder)
				if LoadedOrder then
					ApplyStatOrder(LoadedOrder)
					Hud.StatOrder = StatOrder
				end
			end)
		end

		local function ApplyPresetPosition()
			if Hud.Dragged == true then return end
			local Root = gui("Root")
			if not Root then return end
			ApplyingPreset = true
			Root.AnchorPoint = Vector2New(0.5, 0.5)
			Root.Position = UDim2New(Hud.OffsetX / 100, 0, Hud.OffsetY / 100, 0)
			ApplyingPreset = false
		end

		function Hud:SetEnabled(Bool)
			Hud.Enabled = Bool == true
			RunGuiMutation(function()
				local Root = gui("Root")
				if Root then Root.Visible = Hud.Enabled end
			end)
		end

		function Hud:SetOffset(X, Y)
			Hud.OffsetX = math.clamp(tonumber(X) or Hud.OffsetX, 0, 100)
			Hud.OffsetY = math.clamp(tonumber(Y) or Hud.OffsetY, 0, 100)
			Hud.Dragged = false
			RunGuiMutation(ApplyPresetPosition)
		end

		function Hud:SetUIScale(Percent)
			local Scale = math.clamp((tonumber(Percent) or 100) / 100, 0.5, 2.5)
			Hud.UIScalePercent = Scale * 100
			RunGuiMutation(function()
				local UIScale = gui("UIScale")
				if UIScale then UIScale.Scale = Scale end
			end)
		end

		function Hud:UpdateStats(Stats)
			if type(Stats) ~= "table" then return end
			local username = Players.LocalPlayer and Players.LocalPlayer.Name or "unknown"
			local display_name = Players.LocalPlayer and Players.LocalPlayer.DisplayName or username
			if type(Stats.username) == "string" and Stats.username ~= "" then username = Stats.username end
			if type(Stats.display_name) == "string" and Stats.display_name ~= "" then display_name = Stats.display_name end
			local mapping = {
				["kills"] = Stats.kills or Stats.ko,
				["deaths"] = Stats.deaths,
				["damage dealt"] = Stats.damage_dealt,
				["damage taken"] = Stats.damage_taken,
				["headshot %"] = Stats.headshot_pct and (tostring(Stats.headshot_pct) .. "%") or "0%",
				["score"] = Stats.score,
				["round"] = Stats.round,
				["time elapsed"] = Stats.time_elapsed or Stats.time,
				["mode"] = Stats.mode,
			}
			RunGuiMutation(function()
				for key, value in pairs(mapping) do
					local label = stat_gui(key)
					if label then label.Text = tostring(value or "0") end
				end
				local username_label = gui("UsernameLabel")
				if username_label then username_label.Text = "@" .. username end
				local display_name_label = gui("DisplayNameLabel")
				if display_name_label then display_name_label.Text = display_name end
				local avatar = gui("Avatar")
				if avatar and Players.LocalPlayer then
					avatar.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=420&height=420&format=png", tostring(Players.LocalPlayer.UserId))
				end
			end)
			Hud.LastStats = Stats
		end

		function Hud:Destroy()
			if type(DragState) == "table" then
				StopRowDrag(false)
			end

			local Root = gui("Root")
			if Root and Root.Parent then Root:Destroy() end
			for key in pairs(Items) do Items[key] = nil end
		end

		local RootInstance = gui("Root")
		if RootInstance then
			RootInstance:GetPropertyChangedSignal("Position"):Connect(function()
				if ApplyingPreset == true then return end
				Hud.Dragged = true
				SaveHudConfig()
			end)
		end

		function Hud:GetStatOrder()
			return table.clone(StatOrder)
		end

		function Hud:SetStatOrder(Order)
			local LoadedOrder = ValidateStatOrder(Order)
			if not LoadedOrder then
				return false
			end
			ApplyStatOrder(LoadedOrder)
			Hud.StatOrder = StatOrder
			SaveHudConfig()
			return true
		end

		function Hud:ResetStatOrder()
			ApplyStatOrder(DEFAULT_STAT_ORDER)
			Hud.StatOrder = StatOrder
			SaveHudConfig()
		end

		LoadHudConfig()
		ApplyPresetPosition()
		Hud:SetUIScale(Hud.UIScalePercent)
		Hud:UpdateStats({})

		return Hud
	end

	Library.CosmeticsChanger = function(self, Config)
		Config = type(Config) == "table" and Config or {}

		local Categories = Config.Categories or Config.categories or { "Skin", "Wrap", "Charm", "Finisher" }

		local Window = {
			Items = {},
			Config = Config,
			_weapon_slots = {},
			_cosmetic_slots = {},
			_category_tabs = {},
			_active_weapon = nil,
			_active_category = Categories[1] or "Skin",
			_weapon_query = "",
			_cosmetic_query = "",
			_enabled = false,
			_main_open = false,
			_visibility_index = nil,
			_slot_style = 16,
			_preview_queue_token = 0,
			_preview_runner_conn = nil,
			_prewarm_token = 0,
		}

		local Items = Window.Items
		local FromRGB = Color3.fromRGB
		local WINDOW_SIZE = Vector2.new(600, 630)
		local WEAPON_CARD_SIZE = 72
		local SCROLLBAR_THICKNESS = 4
		local SCROLLBAR_GUTTER = 4
		local LAYOUT = {
			WEAPON_LABEL_H = 12,
			WEAPON_LABEL_GAP = 3,
			WEAPON_SEARCH_H = 20,
			WEAPON_SECTION_GAP = 3,
			WEAPON_PANEL_H = 170,
			SECTION_GAP = 3,
			CATEGORY_ROW_H = 22,
			CATEGORY_GAP = 3,
			FOOTER_H = 46,
			GRID_PAD = 3,
		}

		local function GetWeaponHeaderHeight()
			return LAYOUT.WEAPON_LABEL_H + LAYOUT.WEAPON_LABEL_GAP + LAYOUT.WEAPON_SEARCH_H + LAYOUT.WEAPON_SECTION_GAP
		end

		local weapon_panel_top = GetWeaponHeaderHeight()
		local category_row_top = weapon_panel_top + LAYOUT.WEAPON_PANEL_H + LAYOUT.SECTION_GAP
		local cosmetic_top = category_row_top + LAYOUT.CATEGORY_ROW_H + LAYOUT.CATEGORY_GAP

		local function NormalizeImage(Value)
			if type(Value) == "number" then return "rbxassetid://" .. tostring(Value) end
			if type(Value) ~= "string" or Value == "" then return "" end
			local numeric = string.match(Value, "rbxassetid://(%d+)") or string.match(Value, "^(%d+)$")
			return numeric and ("rbxassetid://" .. numeric) or Value
		end

		local function GetCfg()
			return Window.Config or Config
		end

		local function GetCfgFn(Key)
			local cfg = GetCfg()
			return cfg[Key] or cfg[string.lower(Key)]
		end

		local function StrokeLabel(Label)
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 1
			stroke.Color = FromRGB(0, 0, 0)
			stroke.Transparency = 0.85
			stroke.Parent = Label
		end

		local function MakePanel(ParentInstance, Position, Size, ZIndex)
			local panel = Instance.new("Frame")
			panel.BackgroundColor3 = Library.Theme["Inline"]
			panel.BorderSizePixel = 0
			panel.Position = Position
			panel.Size = Size
			panel.ZIndex = ZIndex
			panel.Parent = ParentInstance

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = panel

			local stroke = Instance.new("UIStroke")
			stroke.Color = Library.Theme["Border"]
			stroke.Transparency = 0.35
			stroke.Parent = panel

			local padding = Instance.new("UIPadding")
			padding.PaddingTop = UDim.new(0, 2)
			padding.PaddingBottom = UDim.new(0, 2)
			padding.PaddingLeft = UDim.new(0, 2)
			padding.PaddingRight = UDim.new(0, 2)
			padding.Parent = panel

			return panel
		end

		local function MakeCard(ParentInstance, LayoutOrder, CardSize)
			CardSize = CardSize or 84
			local card = Instance.new("ImageButton")
			card.Name = "\0"
			card.LayoutOrder = LayoutOrder
			card.Size = UDim2.fromOffset(CardSize, CardSize)
			card.BackgroundColor3 = Library.Theme["Element"]
			card.BackgroundTransparency = 0
			card.BorderSizePixel = 0
			card.ClipsDescendants = true
			card.Image = ""
			card.AutoButtonColor = false
			card.ZIndex = 50
			card.Parent = ParentInstance

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = card

			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Library.Theme["Border"]
			stroke.Transparency = 0.4
			stroke.Thickness = 1
			stroke.Parent = card

			local gradient = Instance.new("UIGradient")
			gradient.Rotation = 90
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, FromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, FromRGB(216, 216, 216)),
			})
			gradient.Parent = card

			local icon = Instance.new("ImageLabel")
			icon.BackgroundTransparency = 1
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.5, 0.42)
			icon.Size = UDim2.fromScale(1.35, 1.35)
			icon.Image = ""
			icon.ZIndex = 52
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Parent = card

			local enabled_dot = Instance.new("Frame")
			enabled_dot.Name = "EnabledDot"
			enabled_dot.AnchorPoint = Vector2.new(1, 0)
			enabled_dot.Position = UDim2.new(1, -6, 0, 6)
			enabled_dot.Size = UDim2.fromOffset(7, 7)
			enabled_dot.BackgroundColor3 = Library.Theme["Accent"]
			enabled_dot.BorderSizePixel = 0
			enabled_dot.Visible = false
			enabled_dot.ZIndex = 54
			enabled_dot.Parent = card

			local dot_corner = Instance.new("UICorner")
			dot_corner.CornerRadius = UDim.new(1, 0)
			dot_corner.Parent = enabled_dot

			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.BackgroundTransparency = 1
			title.AnchorPoint = Vector2.new(0.5, 1)
			title.Position = UDim2.new(0.5, 0, 1, -6)
			title.Size = UDim2.new(0.92, 0, 0, 22)
			title.ZIndex = 53
			title.FontFace = Library.Font
			title.Text = ""
			title.TextColor3 = Library.Theme["Text"]
			title.TextSize = 9
			title.TextWrapped = true
			title.TextTruncate = Enum.TextTruncate.AtEnd
			title.TextXAlignment = Enum.TextXAlignment.Center
			title.TextYAlignment = Enum.TextYAlignment.Bottom
			title.Parent = card
			StrokeLabel(title)

			return {
				Button = { Instance = card },
				Icon = { Instance = icon },
				Label = { Instance = title },
				Stroke = stroke,
				Gradient = gradient,
				EnabledDot = enabled_dot,
				Name = "",
			}
		end

		local function MakeCosmeticCard(ParentInstance, LayoutOrder, CardSize)
			local slot = MakeCard(ParentInstance, LayoutOrder, CardSize)
			local preview_host = Instance.new("Frame")
			preview_host.Name = "PreviewHost"
			preview_host.BackgroundTransparency = 1
			preview_host.AnchorPoint = Vector2.new(0.5, 0.5)
			preview_host.Position = UDim2.fromScale(0.5, 0.38)
			preview_host.Size = UDim2.fromScale(0.9, 0.6)
			preview_host.ClipsDescendants = true
			preview_host.ZIndex = 55
			preview_host.Parent = slot.Button.Instance
			slot.PreviewHost = { Instance = preview_host }
			slot._preview_key = nil
			return slot
		end

		local CARD_SELECTED = FromRGB(34, 89, 25)

		local function SetCardStyle(Slot, Selected, Enabled, IsWeaponCard)
			if not Slot or not Slot.Button or not Slot.Button.Instance then return end
			local card = Slot.Button.Instance
			local stroke = Slot.Stroke
			if Selected == true then
				card.BackgroundColor3 = CARD_SELECTED
				card.BackgroundTransparency = 0.85
				if Slot.Gradient then
					Slot.Gradient.Transparency = NumberSequence.new(1)
				end
				if stroke then
					stroke.Color = CARD_SELECTED
					stroke.Transparency = 0.25
					stroke.Thickness = 1.5
				end
			else
				card.BackgroundColor3 = Library.Theme["Element"]
				card.BackgroundTransparency = IsWeaponCard == true and Enabled == false and 0.35 or 0
				if Slot.Gradient then
					Slot.Gradient.Transparency = NumberSequence.new(0)
				end
				if stroke then
					stroke.Color = Library.Theme["Border"]
					stroke.Transparency = 0.4
					stroke.Thickness = 1
				end
			end
			if Slot.Icon and Slot.Icon.Instance then
				Slot.Icon.Instance.ImageTransparency = IsWeaponCard == true and Enabled == false and 0.5 or 0
			end
			if Slot.Label and Slot.Label.Instance then
				Slot.Label.Instance.TextColor3 = Library.Theme["Text"]
			end
			if Slot.EnabledDot then
				Slot.EnabledDot.Visible = IsWeaponCard == true and Enabled == true and Selected ~= true
			end
		end

		local function MakeActionButton(ParentInstance, Text, LayoutOrder, Accent, Callback)
			local button = Instance.new("TextButton")
			button.LayoutOrder = LayoutOrder
			button.Size = UDim2.new(1, 0, 0, 22)
			button.BackgroundColor3 = Accent == true and Library.Theme["Accent"] or Library.Theme["Element"]
			button.BorderSizePixel = 0
			button.Text = ""
			button.AutoButtonColor = false
			button.ZIndex = 40
			button.Parent = ParentInstance

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 5)
			corner.Parent = button

			if Accent ~= true then
				local gradient = Instance.new("UIGradient")
				gradient.Rotation = 90
				gradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, FromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(1, FromRGB(216, 216, 216)),
				})
				gradient.Parent = button

				local border = Instance.new("UIStroke")
				border.Color = Library.Theme["Border"]
				border.Transparency = 0.4
				border.Parent = button
			end

			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = Text
			label.TextColor3 = Library.Theme["Text"]
			label.TextSize = 11
			label.FontFace = Library.Font
			label.ZIndex = 41
			label.Parent = button

			Library:Connect(button.MouseEnter, function()
				button.BackgroundTransparency = 0.2
			end)
			Library:Connect(button.MouseLeave, function()
				button.BackgroundTransparency = 0
			end)
			Library:Connect(button.MouseButton1Click, function()
				if type(Callback) == "function" then Callback() end
			end)

			return button
		end

		do
			Items["Root"] = Instances:Create("Frame", {
				Parent = Library.Holder.Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0.5, 0.5),
				Position = UDim2New(0.5, 0, 0.5, 0),
				Size = UDim2FromOffset(WINDOW_SIZE.X, WINDOW_SIZE.Y),
				BackgroundColor3 = Library.Theme["Background"],
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Visible = false,
				ZIndex = 20,
			}):AddToTheme({ BackgroundColor3 = "Background" })

			Items["Root"]:MakeDraggable()

			Instances:Create("UICorner", { Parent = Items["Root"].Instance, CornerRadius = UDimNew(0, 8) })
			Instances:Create("UIStroke", { Parent = Items["Root"].Instance, Color = Library.Theme["Outline"] }):AddToTheme({ Color = "Outline" })

			Items["Header"] = Instances:Create("Frame", {
				Parent = Items["Root"].Instance,
				Size = UDim2New(1, 0, 0, 32),
				BackgroundColor3 = Library.Theme["Inline"],
				BorderSizePixel = 0,
				ZIndex = 30,
			}):AddToTheme({ BackgroundColor3 = "Inline" })

			Items["Title"] = Instances:Create("TextLabel", {
				Parent = Items["Header"].Instance,
				Position = UDim2FromOffset(12, 0),
				Size = UDim2New(1, -48, 1, 0),
				BackgroundTransparency = 1,
				Text = "Cosmetic Changer",
				TextColor3 = Library.Theme["Text"],
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				ZIndex = 31,
			}):AddToTheme({ TextColor3 = "Text" })

			Items["Close"] = Instances:Create("TextButton", {
				Parent = Items["Header"].Instance,
				AnchorPoint = Vector2New(1, 0.5),
				Position = UDim2New(1, -10, 0.5, 0),
				Size = UDim2FromOffset(24, 24),
				BackgroundColor3 = Library.Theme["Element"],
				BorderSizePixel = 0,
				Text = "×",
				TextColor3 = Library.Theme["Text"],
				TextSize = 16,
				FontFace = Library.Font,
				AutoButtonColor = false,
				ZIndex = 31,
			}):AddToTheme({ BackgroundColor3 = "Element", TextColor3 = "Text" })

			Instances:Create("UICorner", { Parent = Items["Close"].Instance, CornerRadius = UDimNew(0, 6) })

			local content = Instance.new("Frame")
			content.Name = "Content"
			content.BackgroundTransparency = 1
			content.Position = UDim2.fromOffset(8, 38)
			content.Size = UDim2.new(1, -16, 1, -46)
			content.ZIndex = 30
			content.Parent = Items["Root"].Instance
			Items["Content"] = { Instance = content }

			Items["WeaponLabel"] = Instances:Create("TextLabel", {
				Parent = content,
				Position = UDim2.fromOffset(0, 0),
				Size = UDim2.new(1, 0, 0, LAYOUT.WEAPON_LABEL_H),
				BackgroundTransparency = 1,
				Text = "Weapon Filter",
				TextColor3 = Library.Theme["Inactive Text"],
				TextSize = 10,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				ZIndex = 31,
			}):AddToTheme({ TextColor3 = "Inactive Text" })

			Items["WeaponSearch"] = Instances:Create("TextBox", {
				Parent = content,
				Position = UDim2.fromOffset(0, LAYOUT.WEAPON_LABEL_H + LAYOUT.WEAPON_LABEL_GAP),
				Size = UDim2.new(1, 0, 0, LAYOUT.WEAPON_SEARCH_H),
				BackgroundColor3 = Library.Theme["Element"],
				BorderSizePixel = 0,
				PlaceholderText = "Search weapons...",
				Text = "",
				TextColor3 = Library.Theme["Text"],
				PlaceholderColor3 = Library.Theme["Inactive Text"],
				TextSize = 12,
				FontFace = Library.Font,
				ClearTextOnFocus = false,
				ZIndex = 31,
			}):AddToTheme({ BackgroundColor3 = "Element", TextColor3 = "Text", PlaceholderColor3 = "Inactive Text" })

			Instances:Create("UICorner", { Parent = Items["WeaponSearch"].Instance, CornerRadius = UDimNew(0, 5) })

			local weapon_panel = MakePanel(content, UDim2.fromOffset(0, weapon_panel_top), UDim2.new(1, 0, 0, LAYOUT.WEAPON_PANEL_H), 31)
			Window._weapon_panel = weapon_panel

			Items["WeaponGrid"] = Instances:Create("ScrollingFrame", {
				Parent = weapon_panel,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 4,
				ScrollBarInset = Enum.ScrollBarInset.Always,
				ScrollBarImageColor3 = Library.Theme["Accent"],
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ZIndex = 32,
			}):AddToTheme({ ScrollBarImageColor3 = "Accent" })

			Instances:Create("UIPadding", {
				Parent = Items["WeaponGrid"].Instance,
				PaddingRight = UDim.new(0, SCROLLBAR_GUTTER),
			})

			local weapon_grid_layout = Instance.new("UIGridLayout")
			weapon_grid_layout.CellSize = UDim2.fromOffset(WEAPON_CARD_SIZE, WEAPON_CARD_SIZE)
			weapon_grid_layout.CellPadding = UDim2.fromOffset(LAYOUT.GRID_PAD, LAYOUT.GRID_PAD)
			weapon_grid_layout.SortOrder = Enum.SortOrder.LayoutOrder
			weapon_grid_layout.Parent = Items["WeaponGrid"].Instance
			Window._weapon_grid_layout = weapon_grid_layout

			Items["CategoryRow"] = Instances:Create("Frame", {
				Parent = content,
				Position = UDim2.fromOffset(0, category_row_top),
				Size = UDim2.new(1, 0, 0, LAYOUT.CATEGORY_ROW_H),
				BackgroundTransparency = 1,
				ZIndex = 31,
			})

			Items["CategoryBar"] = Instances:Create("Frame", {
				Parent = Items["CategoryRow"].Instance,
				Size = UDim2.new(1, -250, 1, 0),
				BackgroundTransparency = 1,
				ZIndex = 31,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["CategoryBar"].Instance,
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDimNew(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			Items["CategoryRight"] = Instances:Create("Frame", {
				Parent = Items["CategoryRow"].Instance,
				AnchorPoint = Vector2New(1, 0),
				Position = UDim2New(1, 0, 0, 0),
				Size = UDim2FromOffset(242, LAYOUT.CATEGORY_ROW_H),
				BackgroundTransparency = 1,
				ZIndex = 31,
			})

			Instances:Create("UIListLayout", {
				Parent = Items["CategoryRight"].Instance,
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDimNew(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			})

			Items["CosmeticRandomize"] = Instances:Create("TextButton", {
				Parent = Items["CategoryRight"].Instance,
				LayoutOrder = 1,
				Size = UDim2FromOffset(76, LAYOUT.CATEGORY_ROW_H),
				BackgroundColor3 = Library.Theme["Element"],
				BorderSizePixel = 0,
				Text = "Randomize",
				TextColor3 = Library.Theme["Text"],
				TextSize = 11,
				FontFace = Library.Font,
				AutoButtonColor = false,
				ZIndex = 31,
			}):AddToTheme({ BackgroundColor3 = "Element", TextColor3 = "Text" })

			Instances:Create("UICorner", { Parent = Items["CosmeticRandomize"].Instance, CornerRadius = UDimNew(0, 5) })

			Items["CosmeticSearch"] = Instances:Create("TextBox", {
				Parent = Items["CategoryRight"].Instance,
				LayoutOrder = 2,
				Size = UDim2FromOffset(160, LAYOUT.CATEGORY_ROW_H),
				BackgroundColor3 = Library.Theme["Element"],
				BorderSizePixel = 0,
				PlaceholderText = "Search cosmetics...",
				Text = "",
				TextColor3 = Library.Theme["Text"],
				PlaceholderColor3 = Library.Theme["Inactive Text"],
				TextSize = 11,
				FontFace = Library.Font,
				ClearTextOnFocus = false,
				ZIndex = 31,
			}):AddToTheme({ BackgroundColor3 = "Element", TextColor3 = "Text", PlaceholderColor3 = "Inactive Text" })

			Instances:Create("UICorner", { Parent = Items["CosmeticSearch"].Instance, CornerRadius = UDimNew(0, 5) })

			local cosmetic_panel = MakePanel(content, UDim2.fromOffset(0, cosmetic_top), UDim2.new(1, 0, 1, -(cosmetic_top + LAYOUT.FOOTER_H)), 31)
			Window._cosmetic_panel = cosmetic_panel

			Items["CosmeticGrid"] = Instances:Create("ScrollingFrame", {
				Parent = cosmetic_panel,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 4,
				ScrollBarInset = Enum.ScrollBarInset.Always,
				ScrollBarImageColor3 = Library.Theme["Accent"],
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ZIndex = 32,
			}):AddToTheme({ ScrollBarImageColor3 = "Accent" })

			Instances:Create("UIPadding", {
				Parent = Items["CosmeticGrid"].Instance,
				PaddingRight = UDim.new(0, SCROLLBAR_GUTTER),
			})

			local cosmetic_grid_layout = Instance.new("UIGridLayout")
			cosmetic_grid_layout.CellSize = UDim2.fromOffset(72, 72)
			cosmetic_grid_layout.CellPadding = UDim2.fromOffset(LAYOUT.GRID_PAD, LAYOUT.GRID_PAD)
			cosmetic_grid_layout.SortOrder = Enum.SortOrder.LayoutOrder
			cosmetic_grid_layout.Parent = Items["CosmeticGrid"].Instance
			Window._cosmetic_grid_layout = cosmetic_grid_layout

			local footer_panel = Instance.new("Frame")
			footer_panel.BackgroundTransparency = 1
			footer_panel.AnchorPoint = Vector2.new(0, 1)
			footer_panel.Position = UDim2.new(0, 0, 1, 0)
			footer_panel.Size = UDim2.new(1, 0, 0, LAYOUT.FOOTER_H)
			footer_panel.ZIndex = 31
			footer_panel.Parent = content
			Window._footer_panel = footer_panel

			Items["Hint"] = Instances:Create("TextLabel", {
				Parent = footer_panel,
				Position = UDim2.fromOffset(0, 0),
				Size = UDim2.new(1, 0, 0, 11),
				BackgroundTransparency = 1,
				Text = "Right-click a weapon to toggle skin changer for it.",
				TextColor3 = Library.Theme["Inactive Text"],
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				ZIndex = 40,
			}):AddToTheme({ TextColor3 = "Inactive Text" })

			Items["Status"] = Instances:Create("TextLabel", {
				Parent = footer_panel,
				Position = UDim2.fromOffset(0, 12),
				Size = UDim2.new(1, 0, 0, 12),
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = Library.Theme["Inactive Text"],
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				ZIndex = 40,
			}):AddToTheme({ TextColor3 = "Inactive Text" })

			local action_bar = Instance.new("Frame")
			action_bar.BackgroundTransparency = 1
			action_bar.Position = UDim2.fromOffset(0, 24)
			action_bar.Size = UDim2.new(1, 0, 0, 22)
			action_bar.ZIndex = 40
			action_bar.Parent = footer_panel

			Instances:Create("UIListLayout", {
				Parent = action_bar,
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
			})

			Window._apply_button = MakeActionButton(action_bar, "Apply To All", 1, true, function()
				if not Window._active_weapon or not Window._active_category or Window._active_category == "Skin" then return end
				local get_selected = GetCfgFn("GetSelected")
				local selected = type(get_selected) == "function" and get_selected(Window._active_weapon, Window._active_category) or nil
				if type(selected) ~= "string" or selected == "" then return end
				local on_apply = GetCfg().OnApplyAllSelected
				if type(on_apply) == "function" then on_apply(Window._active_category, selected) end
			end)

			MakeActionButton(action_bar, "Randomize All", 2, true, function()
				local on_randomize_all = GetCfg().OnRandomizeAll
				if type(on_randomize_all) == "function" then on_randomize_all() end
				task.defer(function()
					Window:Refresh()
				end)
			end)

			MakeActionButton(action_bar, "Reset Defaults", 3, false, function()
				local on_reset = GetCfg().OnReset
				if type(on_reset) == "function" then on_reset() end
			end)

			MakeActionButton(action_bar, "Close", 4, false, function()
				local on_close = GetCfg().OnClose
				if type(on_close) == "function" then on_close() end
			end)
		end

		local function GetGridLayoutWidth(GridInstance)
			if not GridInstance then return 0 end
			local width = GridInstance.AbsoluteSize.X - SCROLLBAR_THICKNESS - SCROLLBAR_GUTTER
			if width < 40 then return 0 end
			return width
		end

		local function UpdateGridCellSizes()
			local pad = LAYOUT.GRID_PAD
			local function fit_grid(grid_instance, layout, min_cols, max_cols, min_cell)
				if not grid_instance or not layout then return end
				local width = GetGridLayoutWidth(grid_instance)
				if width < 40 then return end
				local best_cell = min_cell
				for cols = max_cols, min_cols, -1 do
					local cell = math.floor((width - (cols - 1) * pad) / cols)
					if cell >= min_cell then
						best_cell = cell
						break
					end
				end
				layout.CellSize = UDim2.fromOffset(best_cell, best_cell)
				layout.CellPadding = UDim2.fromOffset(pad, pad)
			end
			local weapon_grid = Items["WeaponGrid"] and Items["WeaponGrid"].Instance
			local cosmetic_grid = Items["CosmeticGrid"] and Items["CosmeticGrid"].Instance
			fit_grid(weapon_grid, Window._weapon_grid_layout, 5, 9, 50)
			fit_grid(cosmetic_grid, Window._cosmetic_grid_layout, 5, 9, 48)
		end

		local function UpdateLayout()
			local content = Items["Content"] and Items["Content"].Instance
			if not content then return end
			local content_h = content.AbsoluteSize.Y
			local content_w = content.AbsoluteSize.X
			if content_h < 120 then return end

			local weapon_panel_h = content_h < 520 and 156 or LAYOUT.WEAPON_PANEL_H
			local footer_h = content_h < 520 and 46 or LAYOUT.FOOTER_H
			local search_y = LAYOUT.WEAPON_LABEL_H + LAYOUT.WEAPON_LABEL_GAP
			local panel_y = GetWeaponHeaderHeight()
			local category_y = panel_y + weapon_panel_h + LAYOUT.SECTION_GAP
			local cosmetic_top_y = category_y + LAYOUT.CATEGORY_ROW_H + LAYOUT.CATEGORY_GAP
			local search_w = content_w < 540 and 118 or 160
			local randomize_w = 76
			local right_w = randomize_w + search_w + 6

			if Items["WeaponLabel"] and Items["WeaponLabel"].Instance then
				Items["WeaponLabel"].Instance.Position = UDim2.fromOffset(0, 0)
				Items["WeaponLabel"].Instance.Size = UDim2.new(1, 0, 0, LAYOUT.WEAPON_LABEL_H)
			end
			if Items["WeaponSearch"] and Items["WeaponSearch"].Instance then
				Items["WeaponSearch"].Instance.Position = UDim2.fromOffset(0, search_y)
				Items["WeaponSearch"].Instance.Size = UDim2.new(1, 0, 0, LAYOUT.WEAPON_SEARCH_H)
			end
			if Window._weapon_panel then
				Window._weapon_panel.Position = UDim2.fromOffset(0, panel_y)
				Window._weapon_panel.Size = UDim2.new(1, 0, 0, weapon_panel_h)
			end
			if Items["CategoryRow"] and Items["CategoryRow"].Instance then
				Items["CategoryRow"].Instance.Position = UDim2.fromOffset(0, category_y)
			end
			if Items["CategoryBar"] and Items["CategoryBar"].Instance then
				Items["CategoryBar"].Instance.Size = UDim2.new(1, -(right_w + 8), 1, 0)
			end
			if Items["CategoryRight"] and Items["CategoryRight"].Instance then
				Items["CategoryRight"].Instance.Size = UDim2.fromOffset(right_w, LAYOUT.CATEGORY_ROW_H)
			end
			if Items["CosmeticRandomize"] and Items["CosmeticRandomize"].Instance then
				Items["CosmeticRandomize"].Instance.Size = UDim2.fromOffset(randomize_w, LAYOUT.CATEGORY_ROW_H)
			end
			if Items["CosmeticSearch"] and Items["CosmeticSearch"].Instance then
				Items["CosmeticSearch"].Instance.Size = UDim2.fromOffset(search_w, LAYOUT.CATEGORY_ROW_H)
			end
			if Window._cosmetic_panel then
				Window._cosmetic_panel.Position = UDim2.fromOffset(0, cosmetic_top_y)
				Window._cosmetic_panel.Size = UDim2.new(1, 0, 1, -(cosmetic_top_y + footer_h))
			end
			if Window._footer_panel then
				Window._footer_panel.Size = UDim2.new(1, 0, 0, footer_h)
			end
			UpdateGridCellSizes()
		end

		local function SetCosmeticIconLayout(IconInstance, Category)
			if not IconInstance then return end
			IconInstance.ScaleType = Enum.ScaleType.Fit
			if Category == "Finisher" then
				IconInstance.Position = UDim2.fromScale(0.5, 0.4)
				IconInstance.Size = UDim2.fromScale(0.82, 0.82)
			elseif Category == "Charm" then
				IconInstance.Position = UDim2.fromScale(0.5, 0.42)
				IconInstance.Size = UDim2.fromScale(1.0, 1.0)
			elseif Category == "Wrap" then
				IconInstance.Position = UDim2.fromScale(0.5, 0.42)
				IconInstance.Size = UDim2.fromScale(1.0, 1.0)
				IconInstance.ScaleType = Enum.ScaleType.Crop
			else
				IconInstance.Position = UDim2.fromScale(0.5, 0.42)
				IconInstance.Size = UDim2.fromScale(1.22, 1.22)
			end
		end

		local function UpdateApplyButtonVisibility()
			local show_apply = Window._active_category ~= "Skin"
			if Window._apply_button then Window._apply_button.Visible = show_apply == true end
		end

		local function GetWeaponIcon(WeaponName)
			local get_icon = GetCfgFn("GetIcon")
			local get_selected = GetCfgFn("GetSelected")
			if type(get_icon) ~= "function" then return "" end
			local selected_skin = type(get_selected) == "function" and get_selected(WeaponName, "Skin") or nil
			local cosmetic = type(selected_skin) == "string" and selected_skin ~= "" and selected_skin or "Default"
			return NormalizeImage(get_icon(WeaponName, cosmetic, "Skin"))
		end

		local function UpdateStatusText(weapon_count, cosmetic_count)
			if not Items["Status"] or not Items["Status"].Instance then return end
			local weapon_name = Window._active_weapon or "None"
			local category = Window._active_category or "Skin"
			Items["Status"].Instance.Text = tostring(weapon_count) .. " weapons • " .. tostring(cosmetic_count) .. " " .. string.lower(category) .. "s • " .. weapon_name
		end

		local function RefreshWeaponSlots()
			local cfg = GetCfg()
			local weapons = cfg.Weapons or cfg.weapons or {}
			local get_icon = GetCfgFn("GetIcon")
			local get_selected = GetCfgFn("GetSelected")
			local is_weapon_enabled = GetCfgFn("IsWeaponEnabled")
			local query = string.lower(Window._weapon_query or "")
			local visible_count = 0
			for index = 1, #weapons do
				local weapon_name = weapons[index]
				local slot = Window._weapon_slots[index]
				if not slot then
					slot = MakeCard(Items["WeaponGrid"].Instance, index, WEAPON_CARD_SIZE)
					Window._weapon_slots[index] = slot
					Library:Connect(slot.Button.Instance.MouseButton1Click, function()
						if type(slot.Name) ~= "string" or slot.Name == "" then return end
						Window._active_weapon = slot.Name
						local on_select = GetCfg().OnSelectWeapon
						if type(on_select) == "function" then on_select(slot.Name) end
						Window:Refresh()
					end)
					Library:Connect(slot.Button.Instance.MouseButton2Click, function()
						if type(slot.Name) ~= "string" or slot.Name == "" then return end
						local enabled = type(is_weapon_enabled) ~= "function" or is_weapon_enabled(slot.Name) == true
						local on_toggle = GetCfg().OnToggleWeapon
						if type(on_toggle) == "function" then on_toggle(slot.Name, not enabled) end
						Window:Refresh()
					end)
				end
				local visible = query == "" or string.find(string.lower(weapon_name), query, 1, true) ~= nil
				slot.Button.Instance.Visible = visible
				if visible then
					visible_count = visible_count + 1
					slot.Name = weapon_name
					slot.Label.Instance.Text = weapon_name
					if type(get_icon) == "function" and type(get_selected) == "function" then
						local selected_skin = get_selected(weapon_name, "Skin")
						local cosmetic = type(selected_skin) == "string" and selected_skin ~= "" and selected_skin or "Default"
						slot.Icon.Instance.Image = NormalizeImage(get_icon(weapon_name, cosmetic, "Skin"))
					else
						slot.Icon.Instance.Image = GetWeaponIcon(weapon_name)
					end
					slot.Icon.Instance.ScaleType = Enum.ScaleType.Fit
					slot.Icon.Instance.Position = UDim2.fromScale(0.5, 0.42)
					slot.Icon.Instance.Size = UDim2.fromScale(1.15, 1.15)
					local enabled = type(is_weapon_enabled) ~= "function" or is_weapon_enabled(weapon_name) == true
					SetCardStyle(slot, Window._active_weapon == weapon_name, enabled, true)
				end
			end
			for index = #weapons + 1, #Window._weapon_slots do
				Window._weapon_slots[index].Button.Instance.Visible = false
			end
			return visible_count
		end

		local PREVIEW_MOUNT_BATCH_CACHED = 8
		local PREVIEW_MOUNT_BATCH_CREATE = 2
		local PREVIEW_SCROLL_BUFFER = 72
		local PREVIEW_UNMOUNT_INTERVAL = 0.15
		local preview_pending_scratch = {}
		local preview_unmount_clock = 0

		local function IsCosmeticSlotInViewport(slot, buffer)
			if not slot or not slot.Button or not slot.Button.Instance then return false end
			if slot.Button.Instance.Visible ~= true then return false end
			local scroll = Items["CosmeticGrid"] and Items["CosmeticGrid"].Instance
			if not scroll then return true end
			local card = slot.Button.Instance
			local scroll_pos = scroll.AbsolutePosition
			local scroll_size = scroll.AbsoluteSize
			local card_pos = card.AbsolutePosition
			local card_size = card.AbsoluteSize
			buffer = type(buffer) == "number" and buffer or PREVIEW_SCROLL_BUFFER
			local card_top = card_pos.Y
			local card_bottom = card_pos.Y + card_size.Y
			local view_top = scroll_pos.Y - buffer
			local view_bottom = scroll_pos.Y + scroll_size.Y + buffer
			return card_bottom >= view_top and card_top <= view_bottom
		end

		local function CancelPreviewQueue()
			Window._preview_queue_token = (Window._preview_queue_token or 0) + 1
		end

		local function StopPreviewRunner()
			if Window._preview_runner_conn then
				Window._preview_runner_conn:Disconnect()
				Window._preview_runner_conn = nil
			end
		end

		local function ProcessPreviewQueue()
			local category = Window._active_category
			if category ~= "Wrap" and category ~= "Charm" then return end
			local mount_preview = GetCfgFn("MountCardPreview")
			local clear_preview = GetCfgFn("ClearCardPreview")
			local is_cached = GetCfgFn("IsPreviewCached")
			if type(mount_preview) ~= "function" then return end
			local queue_token = Window._preview_queue_token or 0
			local mounted = 0
			local create_mounted = 0
			table.clear(preview_pending_scratch)
			for slot_index = 1, #Window._cosmetic_slots do
				local slot = Window._cosmetic_slots[slot_index]
				if slot and slot._preview_key and slot._preview_mounted_key ~= slot._preview_key and slot._preview_loading_key ~= slot._preview_key and IsCosmeticSlotInViewport(slot) then
					preview_pending_scratch[#preview_pending_scratch + 1] = slot
				end
			end
			table.sort(preview_pending_scratch, function(left, right)
				local left_y = left.Button.Instance.AbsolutePosition.Y
				local right_y = right.Button.Instance.AbsolutePosition.Y
				if left_y == right_y then return (left._preview_order or 0) < (right._preview_order or 0) end
				return left_y < right_y
			end)
			for pending_index = 1, #preview_pending_scratch do
				if mounted >= PREVIEW_MOUNT_BATCH_CACHED and create_mounted >= PREVIEW_MOUNT_BATCH_CREATE then break end
				local slot = preview_pending_scratch[pending_index]
				local preview_key = slot._preview_key
				local cosmetic_name = slot.Name
				local cached = type(is_cached) == "function" and is_cached(category, cosmetic_name) == true
				local host = slot.PreviewHost and slot.PreviewHost.Instance
				if host and host.Parent then
					if cached and mounted < PREVIEW_MOUNT_BATCH_CACHED then
						mounted = mounted + 1
						local ok = mount_preview(host, category, cosmetic_name) == true
						if ok and slot._preview_key == preview_key then slot._preview_mounted_key = preview_key end
					elseif not cached and create_mounted < PREVIEW_MOUNT_BATCH_CREATE then
						mounted = mounted + 1
						create_mounted = create_mounted + 1
						slot._preview_loading_key = preview_key
						task.defer(function()
							if Window._preview_queue_token ~= queue_token then
								slot._preview_loading_key = nil
								return
							end
							if slot._preview_key ~= preview_key then
								slot._preview_loading_key = nil
								return
							end
							if not host.Parent then
								slot._preview_loading_key = nil
								return
							end
							local ok = mount_preview(host, category, cosmetic_name) == true
							slot._preview_loading_key = nil
							if ok and slot._preview_key == preview_key then slot._preview_mounted_key = preview_key end
						end)
					end
				end
			end
			local now = os.clock()
			if now - preview_unmount_clock >= PREVIEW_UNMOUNT_INTERVAL then
				preview_unmount_clock = now
				for slot_index = 1, #Window._cosmetic_slots do
					local slot = Window._cosmetic_slots[slot_index]
					if slot and slot._preview_mounted_key and not IsCosmeticSlotInViewport(slot, PREVIEW_SCROLL_BUFFER * 3) then
						if type(clear_preview) == "function" then clear_preview(slot.PreviewHost.Instance) end
						slot._preview_mounted_key = nil
						slot._preview_loading_key = nil
					end
				end
			end
		end

		local function EnsurePreviewRunner()
			local category = Window._active_category
			if category ~= "Wrap" and category ~= "Charm" then
				StopPreviewRunner()
				return
			end
			if Window._preview_runner_conn then return end
			Window._preview_runner_conn = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
				if Window._active_category ~= "Wrap" and Window._active_category ~= "Charm" then
					StopPreviewRunner()
					return
				end
				ProcessPreviewQueue()
			end))
		end

		local function RefreshCosmeticSlots()
			local weapon_name = Window._active_weapon
			local category = Window._active_category
			local get_cosmetics = GetCfgFn("GetCosmetics")
			local get_icon = GetCfgFn("GetIcon")
			local get_selected = GetCfgFn("GetSelected")
			local clear_preview = GetCfgFn("ClearCardPreview")
			local mount_preview = GetCfgFn("MountCardPreview")
			local release_all = GetCfgFn("ReleaseAllCardPreviews")
			if Window._last_preview_category ~= category then
				CancelPreviewQueue()
				if type(release_all) == "function" then release_all() end
				Window._last_preview_category = category
				for slot_index = 1, #Window._cosmetic_slots do
					local preview_slot = Window._cosmetic_slots[slot_index]
					if preview_slot then
						preview_slot._preview_key = nil
						preview_slot._preview_mounted_key = nil
						preview_slot._preview_loading_key = nil
					end
				end
			end
			local cosmetics = {}
			if weapon_name and type(get_cosmetics) == "function" then
				local ok, result = pcall(get_cosmetics, weapon_name, category)
				if ok and type(result) == "table" then cosmetics = result end
			end
			local query = string.lower(Window._cosmetic_query or "")
			local selected = weapon_name and type(get_selected) == "function" and get_selected(weapon_name, category) or nil
			local visible_count = 0
			for index = 1, #cosmetics do
				local cosmetic_name = cosmetics[index]
				local slot = Window._cosmetic_slots[index]
				if not slot then
					slot = MakeCosmeticCard(Items["CosmeticGrid"].Instance, index, 72)
					Window._cosmetic_slots[index] = slot
					Library:Connect(slot.Button.Instance.MouseButton1Click, function()
						if not Window._active_weapon or not Window._active_category then return end
						local on_select = GetCfg().OnSelectCosmetic
						if type(on_select) == "function" then on_select(Window._active_weapon, Window._active_category, slot.Name) end
						Window:Refresh()
					end)
				end
				local visible = query == "" or string.find(string.lower(cosmetic_name), query, 1, true) ~= nil
				slot.Button.Instance.Visible = visible
				if visible then
					visible_count = visible_count + 1
					slot.Name = cosmetic_name
					slot._preview_order = index
					slot.Label.Instance.Text = cosmetic_name
					local use_viewport = category == "Charm" or category == "Wrap"
					local is_default = cosmetic_name == "None" or cosmetic_name == "Default"
					if use_viewport and not is_default then
						slot.Icon.Instance.Visible = false
						local preview_key = category .. ":" .. cosmetic_name
						if slot._preview_key ~= preview_key then
							slot._preview_key = preview_key
							slot._preview_mounted_key = nil
							slot._preview_loading_key = nil
							if type(clear_preview) == "function" then clear_preview(slot.PreviewHost.Instance) end
						end
					else
						slot._preview_key = nil
						slot._preview_mounted_key = nil
						slot._preview_loading_key = nil
						if slot.PreviewHost and type(clear_preview) == "function" then clear_preview(slot.PreviewHost.Instance) end
						slot.Icon.Instance.Visible = true
						if weapon_name and type(get_icon) == "function" then
							slot.Icon.Instance.Image = NormalizeImage(get_icon(weapon_name, cosmetic_name, category))
						else
							slot.Icon.Instance.Image = ""
						end
						SetCosmeticIconLayout(slot.Icon.Instance, category)
					end
					SetCardStyle(slot, selected == cosmetic_name, true, false)
				elseif slot.PreviewHost then
					slot._preview_key = nil
					slot._preview_mounted_key = nil
					slot._preview_loading_key = nil
					if type(clear_preview) == "function" then clear_preview(slot.PreviewHost.Instance) end
				end
			end
			for index = #cosmetics + 1, #Window._cosmetic_slots do
				local hidden_slot = Window._cosmetic_slots[index]
				hidden_slot.Button.Instance.Visible = false
				if hidden_slot.PreviewHost and type(clear_preview) == "function" then
					hidden_slot._preview_key = nil
					hidden_slot._preview_mounted_key = nil
					hidden_slot._preview_loading_key = nil
					clear_preview(hidden_slot.PreviewHost.Instance)
				end
			end
			if category == "Wrap" or category == "Charm" then
				Window._prewarm_token = (Window._prewarm_token or 0) + 1
				local prewarm = GetCfgFn("PrewarmPreviewCache")
				if type(prewarm) == "function" then
					local prewarm_names = {}
					local prewarm_count = 0
					for prewarm_index = 1, #cosmetics do
						local prewarm_name = cosmetics[prewarm_index]
						if type(prewarm_name) == "string" and prewarm_name ~= "Default" and prewarm_name ~= "None" then
							local prewarm_visible = query == "" or string.find(string.lower(prewarm_name), query, 1, true) ~= nil
							if prewarm_visible then
								prewarm_count = prewarm_count + 1
								prewarm_names[#prewarm_names + 1] = prewarm_name
								if prewarm_count >= 48 then break end
							end
						end
					end
					if #prewarm_names > 0 then prewarm(category, prewarm_names, Window._prewarm_token) end
				end
				EnsurePreviewRunner()
				ProcessPreviewQueue()
			else
				StopPreviewRunner()
				CancelPreviewQueue()
			end
			return visible_count
		end

		local function BuildCategoryTab(category, index)
			local tab_button = Instances:Create("TextButton", {
				Parent = Items["CategoryBar"].Instance,
				LayoutOrder = index,
				Size = UDim2FromOffset(0, 22),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Library.Theme["Element"],
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 35,
			}):AddToTheme({ BackgroundColor3 = "Element" })
			Instances:Create("UICorner", { Parent = tab_button.Instance, CornerRadius = UDimNew(0, 5) })
			Instances:Create("UIGradient", {
				Parent = tab_button.Instance,
				Rotation = 90,
				Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))},
			})
			Instances:Create("UIStroke", { Parent = tab_button.Instance, Color = Library.Theme["Border"], Transparency = 0.4 }):AddToTheme({ Color = "Border" })
			local tab_label = Instances:Create("TextLabel", {
				Parent = tab_button.Instance,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = category,
				TextColor3 = Library.Theme["Text"],
				TextSize = 11,
				FontFace = Library.Font,
				ZIndex = 36,
			}):AddToTheme({ TextColor3 = "Text" })
			Instances:Create("UIPadding", { Parent = tab_button.Instance, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
			Library:Connect(tab_button.Instance.MouseButton1Click, function()
				if Window._active_category ~= category then
					CancelPreviewQueue()
					local release_all = GetCfgFn("ReleaseAllCardPreviews")
					if type(release_all) == "function" then release_all() end
					Window._last_preview_category = nil
				end
				Window._active_category = category
				task.defer(function()
					Window:Refresh()
				end)
			end)
			return {
				Button = tab_button,
				Label = tab_label,
				ButtonInstance = tab_button.Instance,
				LabelInstance = tab_label.Instance,
			}
		end

		local function EnsureCategoryTabs()
			if Window._category_tabs_built == true then return end
			Window._category_tabs_built = true
			local cfg = GetCfg()
			local categories = cfg.Categories or cfg.categories or Categories
			for index = 1, #categories do
				if not Window._category_tabs[index] then
					Window._category_tabs[index] = BuildCategoryTab(categories[index], index)
				end
			end
		end

		local function RefreshCategoryTabs()
			EnsureCategoryTabs()
			local cfg = GetCfg()
			local categories = cfg.Categories or cfg.categories or Categories
			for index = 1, #categories do
				local category = categories[index]
				local tab = Window._category_tabs[index]
				if not tab then
					tab = BuildCategoryTab(category, index)
					Window._category_tabs[index] = tab
				end
				local tab_instance = tab.ButtonInstance or (tab.Button and tab.Button.Instance)
				local label_instance = tab.LabelInstance or (tab.Label and tab.Label.Instance)
				if typeof(tab_instance) == "Instance" then
					local active = Window._active_category == category
					pcall(function()
						tab_instance.BackgroundColor3 = active and Library.Theme["Accent"] or Library.Theme["Element"]
						local tab_gradient = tab_instance:FindFirstChildOfClass("UIGradient")
						if tab_gradient then
							tab_gradient.Color = active and ColorSequence.new(Library.Theme["Accent"]) or ColorSequence.new({
								ColorSequenceKeypoint.new(0, FromRGB(255, 255, 255)),
								ColorSequenceKeypoint.new(1, FromRGB(216, 216, 216)),
							})
						end
						if typeof(label_instance) == "Instance" then
							label_instance.TextColor3 = active and Library.Theme["Text"] or Library.Theme["Inactive Text"]
						end
						tab_instance.Visible = true
					end)
				end
			end
			for index = #categories + 1, #Window._category_tabs do
				local hidden_tab = Window._category_tabs[index]
				local hidden_instance = hidden_tab and (hidden_tab.ButtonInstance or (hidden_tab.Button and hidden_tab.Button.Instance))
				if typeof(hidden_instance) == "Instance" then
					pcall(function() hidden_instance.Visible = false end)
				end
			end
		end

		function Window:UpdateVisibility()
			local visible = self._enabled == true
			if Items["Root"] and Items["Root"].Instance then Items["Root"].Instance.Visible = visible end
			if visible then
				task.defer(UpdateLayout)
			end
		end

		function Window:SetEnabled(Bool)
			self._enabled = Bool == true
			self:UpdateVisibility()
		end

		function Window:SetMainOpen(Bool)
			self._main_open = Bool == true
			self:UpdateVisibility()
		end

		function Window:SetVisible(Bool)
			self:SetEnabled(Bool)
		end

		function Window:Refresh()
			local cfg = GetCfg()
			local weapons = cfg.Weapons or cfg.weapons or {}
			if not self._active_weapon then
				for index = 1, #weapons do
					if weapons[index] ~= "Default" then self._active_weapon = weapons[index] break end
				end
				if not self._active_weapon then self._active_weapon = weapons[1] end
			end
			if self._active_weapon and not self._active_category then
				self._active_category = (cfg.Categories or cfg.categories or Categories)[1] or "Skin"
			end
			RefreshCategoryTabs()
			UpdateApplyButtonVisibility()
			local weapon_count = RefreshWeaponSlots()
			local cosmetic_count = RefreshCosmeticSlots()
			UpdateStatusText(weapon_count, cosmetic_count)
			UpdateLayout()
		end

		function Window:Destroy()
			self._enabled = false
			StopPreviewRunner()
			CancelPreviewQueue()
			if type(Library.OnMainVisibilityChanged) == "table" and self._visibility_index then
				Library.OnMainVisibilityChanged[self._visibility_index] = nil
			end
			local clear_all = GetCfgFn("ClearAllCardPreviews")
			if type(clear_all) == "function" then pcall(clear_all) end
			self._last_preview_category = nil
			for index = 1, #self._cosmetic_slots do
				local slot = self._cosmetic_slots[index]
				if slot then slot._preview_key = nil end
			end
			if Items["Root"] and Items["Root"].Instance then Items["Root"].Instance:Destroy() end
		end

		Library:Connect(Items["CosmeticRandomize"].Instance.MouseButton1Click, function()
			if not Window._active_weapon or not Window._active_category then return end
			local on_randomize = GetCfg().OnRandomizeCategory
			if type(on_randomize) == "function" then on_randomize(Window._active_weapon, Window._active_category) end
			Window:Refresh()
		end)

		Library:Connect(Items["Close"].Instance.MouseButton1Click, function()
			local on_close = GetCfg().OnClose
			if type(on_close) == "function" then on_close() end
		end)

		Library:Connect(Items["WeaponSearch"].Instance:GetPropertyChangedSignal("Text"), function()
			Window._weapon_query = Items["WeaponSearch"].Instance.Text
			RefreshWeaponSlots()
		end)

		Library:Connect(Items["CosmeticSearch"].Instance:GetPropertyChangedSignal("Text"), function()
			Window._cosmetic_query = Items["CosmeticSearch"].Instance.Text
			RefreshCosmeticSlots()
		end)

		Library:Connect(Items["Content"].Instance:GetPropertyChangedSignal("AbsoluteSize"), UpdateLayout)
		Library:Connect(Items["WeaponGrid"].Instance:GetPropertyChangedSignal("AbsoluteSize"), UpdateGridCellSizes)
		Library:Connect(Items["CosmeticGrid"].Instance:GetPropertyChangedSignal("AbsoluteSize"), UpdateGridCellSizes)
		Library:Connect(Items["CosmeticGrid"].Instance:GetPropertyChangedSignal("CanvasPosition"), ProcessPreviewQueue)

		Window:Refresh()
		return Window
	end

function Library:Window(data)
	local window = Menu.Classes.Window.new(data)
	Menu.CurrentWindow = window
	Library.CurrentWindow = window
	if Library.CreateFloatingButton then Library:CreateFloatingButton(window) end
	if Library.SetupBackgroundEffects then Library:SetupBackgroundEffects() end
	if Library.LoadLocalSettings then Library:LoadLocalSettings({ ApplyFont = false }) end
	if Library.CreateQuickConfigs then Library:CreateQuickConfigs() end
	if Library.QuickConfigs and Library.QuickConfigs.SetTransparency then
		Library.QuickConfigs:SetTransparency()
	end

	if type(window.Init) == "function" then
		pcall(window.Init, window)
	elseif type(window.SetOpen) == "function" then
		pcall(window.SetOpen, window, true)
	end

	function window:Page(d)
		return self:CreatePage(d)
	end
	function window:SetMainOpen(b) self:SetOpen(b) end
	function window:SetEnabled(b) self:SetVisible(b) end
	function window:UpdateVisibility() self.UI.MainFrame.Visible = self.IsOpen and self.Visible end
	function window:ChangeSize(x, y) self.UI.MainFrame.Size = UDim2New(0, x, 0, y) end
	function window:SetCenter()
		self.UI.MainFrame.Position = UDim2New(0.5, 0, 0.5, 0)
		self.UI.MainFrame.AnchorPoint = Vector2New(0.5, 0.5)
	end
	function window:SetTransparency(a) self.UI.MainFrame.BackgroundTransparency = a end
	function window:Refresh() end

	local page_mt_open = Menu.Classes.Page.new
	local old_create = window.CreatePage
	function window:CreatePage(d)
		local page = old_create(self, d)
		function page:Section(sd)
			return self:CreateSection(sd)
		end
		function page:SubPage(sd)
			local sp = self:CreateSubPage(sd)
			function sp:Section(ssd)
				return self:CreateSection(ssd)
			end
			function sp:ModelViewerSection(d)
				return Library.Pages.ModelViewerSection(self, d)
			end
			function sp:ImageViewerSection(d)
				return Library.Pages.ImageViewerSection(self, d)
			end
			function sp:ImagePreviewSection(d)
				return Library.Pages.ImageViewerSection(self, d)
			end
			return sp
		end

		function page:ModelViewerSection(d)
			return Library.Pages.ModelViewerSection(self, d)
		end
		function page:ImageViewerSection(d)
			return Library.Pages.ImageViewerSection(self, d)
		end
		function page:ImagePreviewSection(d)
			return Library.Pages.ImageViewerSection(self, d)
		end
		return page
	end

	local section_class = Menu.Classes.Section
	local old_section_new = section_class.new

	if not section_class._section_api_ready then
		section_class._section_api_ready = true
		local function elevated_call(fn, ...)
			local args = table.pack(...)
			local result
			local ok, err = run_with_elevated_thread_identity(function()
				result = fn(table.unpack(args, 1, args.n))
			end)
			if not ok then
				error(tostring(err or "element create failed"), 2)
			end
			return result
		end
		function section_class:Toggle(d)
			d = d or {}
			d.Title = data_name(d, "Toggle")
			d.Name = d.Title
			return elevated_call(self.CreateToggle, self, d)
		end
		function section_class:Checkbox(d)
			d = d or {}
			d.Title = data_name(d, "Checkbox")
			return elevated_call(self.CreateCheckbox, self, d)
		end
		function section_class:Slider(d)
			d = d or {}
			d.Title = data_name(d, "Slider")
			return elevated_call(self.CreateSlider, self, d)
		end
		function section_class:Dropdown(d)
			d = d or {}
			d.Title = data_name(d, "Dropdown")
			return elevated_call(self.CreateDropdown, self, d)
		end
		function section_class:Label(name, desc)
			local d
			if type(name) == "table" then d = name
			else d = { Title = name, Name = name, Description = desc } end
			return elevated_call(self.CreateLabel, self, d)
		end
		function section_class:Textbox(d)
			d = d or {}
			d.Title = data_name(d, "Textbox")
			return elevated_call(self.CreateTextbox, self, d)
		end
		function section_class:ImageTextbox(d)
			d = d or {}
			d.Title = data_name(d, "Image")
			return elevated_call(self.CreateImageTextbox, self, d)
		end
		function section_class:SubSlider(d)
			d = d or {}
			local titled = d.Title or d.Name or d.name
			if titled ~= nil and titled ~= "" then
				d.Title = tostring(titled)
			else
				d.Title = nil
			end
			return elevated_call(self.CreateSubSlider, self, d)
		end
		function section_class:Button(d)
			return elevated_call(self.CreateButton, self, d or {})
		end
	end

	return window
end

function Menu:CreateWindow(parameters)
	return Library:Window(parameters)
end

Library.Flags = Menu.Flags
Library.Elements = Menu.Elements
Library.LoadingConfig = false

Library.Holder = { Instance = Menu.Holder }
Library.Overlay = { Instance = Menu.Overlay }

pcall(function()
	Players.PlayerRemoving:Connect(function(player)
		if player == LocalPlayer and Library.AutoSave then
			pcall(function()
				if writefile then writefile(GetAutoloadPath(), Library:GetConfig()) end
			end)
		end
	end)
end)

getgenv().Library = Library
return Library

--========================================================================
--  CubiX MAX  -  single LocalScript
--  Put this LocalScript in StarterGui. It builds the whole "CubiX MAX"
--  ScreenGui from code (instance names match your Explorer tree).
--  Fill the ICONS table below with your own rbxassetid://... images.
--  Empty icon ids fall back to a short ASCII label so nothing is invisible.
--========================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================== ICONS (YOUR IMAGES) =========================
local ICONS = {
	Logo = "", Home = "", Code = "", Search = "", Settings = "", Console = "", Arrow = "",
	Palette = "", Client = "", Folder = "", File = "", Key = "", Sliders = "", Reset = "",
	ChevronDown = "", ChevronRight = "", Trash = "", Wand = "", Broom = "", Copy = "",
	Paste = "", ExecFile = "", Play = "", Check = "", Info = "", Warn = "", Error = "",
	Plus = "", NewFolder = "", NewFile = "", Filter = "", Grid = "", Close = "",
}
local FALLBACK = {
	Logo = "CX", Home = "H", Code = "</>", Search = "S", Settings = "*", Console = ">_", Arrow = "->",
	Palette = "P", Client = "C", Folder = "D", File = "F", Key = "K", Sliders = "=", Reset = "R",
	ChevronDown = "v", ChevronRight = ">", Trash = "X", Wand = "~", Broom = "#", Copy = "[]",
	Paste = "T", ExecFile = "E", Play = ">", Check = "OK", Info = "i", Warn = "!", Error = "x",
	Plus = "+", NewFolder = "D+", NewFile = "F+", Filter = "Y", Grid = "G", Close = "x",
}

--========================== CONSTANTS ===================================
local DW, DH = 2538, 1398 -- design size of the mockup images

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local DIM = Color3.fromRGB(140, 140, 146)
local DIMMER = Color3.fromRGB(88, 88, 94)
local NAV_OFF = Color3.fromRGB(150, 150, 156)
local DARK_ICON = Color3.fromRGB(22, 22, 25)
local FILL = Color3.fromRGB(27, 27, 31)
local STROKE_C = Color3.fromRGB(42, 42, 48)
local ERR = Color3.fromRGB(255, 125, 125)
local F_REG = Enum.Font.Gotham
local F_MED = Enum.Font.GothamMedium
local F_BOLD = Enum.Font.GothamBold
local F_CODE = Enum.Font.Code
local SAVE_DIR = "CubiXMAX"

--========================== SETTINGS ====================================
local DEFAULTS = {
	Syntax = true, Gradient = true, C0 = {240, 240, 240}, C1 = {150, 150, 156}, Animations = true,
	FontSize = "Medium", AutoIndent = true, WordWrap = false,
	AutoExecute = false, AntiAFK = false, FPSCap = "Off",
	ShowExt = true, ConfirmDelete = true,
	AutoScroll = true, CaptureGame = true, MaxLines = "300",
	Keybind = "RightControl", Notifications = true,
}
local Settings = {}
local function resetSettingsTable()
	for k, v in pairs(DEFAULTS) do
		if type(v) == "table" then
			Settings[k] = {v[1], v[2], v[3]}
		else
			Settings[k] = v
		end
	end
end
resetSettingsTable()

--========================== GUI HELPERS =================================
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function corner(o, r)
	return new("UICorner", {CornerRadius = UDim.new(0, r)}, o)
end

local function stroke(o, color, thick)
	return new("UIStroke", {
		Color = color or STROKE_C,
		Thickness = thick or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end

local function frame(parent, name, x, y, w, h, color, radius)
	local f = new("Frame", {
		Name = name,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = color or BLACK,
		BackgroundTransparency = color and 0 or 1,
		BorderSizePixel = 0,
	}, parent)
	if radius then
		corner(f, radius)
	end
	return f
end

local function label(parent, text, x, y, w, h, size, color, font, xalign)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		Text = text,
		TextSize = size,
		TextColor3 = color or WHITE,
		Font = font or F_MED,
		TextXAlignment = xalign or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		BorderSizePixel = 0,
	}, parent)
end

local function button(parent, name, x, y, w, h)
	return new("TextButton", {
		Name = name,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, parent)
end

local function panel(parent, name, x, y, w, h, r)
	local f = frame(parent, name, x, y, w, h, Color3.fromRGB(24, 24, 28), r)
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(27, 27, 31), Color3.fromRGB(17, 17, 20)),
	}, f)
	stroke(f, Color3.fromRGB(31, 31, 36), 2)
	return f
end

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function tween(obj, time, props, style, dir)
	if not Settings.Animations or time <= 0 then
		for k, v in pairs(props) do
			obj[k] = v
		end
		return
	end
	TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
end

local function makeIcon(parent, key, size, cx, cy, color)
	local id = ICONS[key]
	local o
	if id and id ~= "" then
		o = new("ImageLabel", {
			BackgroundTransparency = 1,
			Image = id,
			ImageColor3 = color or WHITE,
			ScaleType = Enum.ScaleType.Fit,
			BorderSizePixel = 0,
		})
	else
		local t = FALLBACK[key] or "?"
		o = new("TextLabel", {
			BackgroundTransparency = 1,
			Text = t,
			Font = F_BOLD,
			TextColor3 = color or WHITE,
			TextSize = math.floor(size * (#t > 2 and 0.42 or 0.62)),
			BorderSizePixel = 0,
		})
	end
	o.Name = key
	o.AnchorPoint = Vector2.new(0.5, 0.5)
	o.Size = UDim2.fromOffset(size, size)
	o.Position = UDim2.fromOffset(cx, cy)
	o.Parent = parent
	return o
end

local function setIconColor(o, c)
	if o:IsA("ImageLabel") then
		o.ImageColor3 = c
	else
		o.TextColor3 = c
	end
end

local function press(btn, target)
	target = target or btn
	local base = target.Size
	local function down()
		tween(target, 0.08, {Size = UDim2.new(base.X.Scale, base.X.Offset * 0.86, base.Y.Scale, base.Y.Offset * 0.86)})
	end
	local function up()
		tween(target, 0.16, {Size = base})
	end
	btn.MouseButton1Down:Connect(down)
	btn.MouseButton1Up:Connect(up)
	btn.MouseLeave:Connect(up)
end

local function iconButton(parent, key, size, cx, cy, color, cb)
	local pad = size + 40
	local b = button(parent, key .. "Bn", cx - pad / 2, cy - pad / 2, pad, pad)
	local ic = makeIcon(b, key, size, pad / 2, pad / 2, color)
	press(b, ic)
	if cb then
		b.MouseButton1Click:Connect(cb)
	end
	return b, ic
end

--========================== THEME (ACCENT GRADIENT) =====================
local accents = {}
local ColourStorage

local function themeSequence()
	local c0 = Color3.fromRGB(Settings.C0[1], Settings.C0[2], Settings.C0[3])
	local c1 = Color3.fromRGB(Settings.C1[1], Settings.C1[2], Settings.C1[3])
	if Settings.Gradient then
		return ColorSequence.new(c0, c1)
	end
	return ColorSequence.new(c0)
end

local function accent(obj, rotation)
	local g = new("UIGradient", {Rotation = rotation or 90, Color = themeSequence()}, obj)
	table.insert(accents, g)
	return g
end

local function applyTheme()
	local seq = themeSequence()
	for i = #accents, 1, -1 do
		local g = accents[i]
		if g.Parent then
			g.Color = seq
		else
			table.remove(accents, i)
		end
	end
	if ColourStorage then
		ColourStorage.C0.Value = Color3.fromRGB(Settings.C0[1], Settings.C0[2], Settings.C0[3])
		ColourStorage.C1.Value = Color3.fromRGB(Settings.C1[1], Settings.C1[2], Settings.C1[3])
		ColourStorage.Gradient.Value = Settings.Gradient
	end
end

--========================== FILE SYSTEM (VIRTUAL) =======================
local State = {
	Root = nil, active = nil, selectedFolder = nil,
	page = "HomePg", lastPage = "HomePg",
	searchMode = "open", cloudCols = 3, cloudTag = "All", cloudQuery = "",
}

local function mkFile(name, content)
	return {kind = "file", name = name, content = content or ""}
end

local function mkFolder(name, kids)
	return {kind = "folder", name = name, children = kids or {}, open = true}
end

local function link(node, parent)
	node.parent = parent
	if node.kind == "folder" then
		for _, c in ipairs(node.children) do
			link(c, node)
		end
	end
end

local function findChild(folder, name)
	for _, c in ipairs(folder.children) do
		if c.name == name then
			return c
		end
	end
	return nil
end

local function nodePath(node)
	local parts = {}
	local n = node
	while n do
		table.insert(parts, 1, n.name)
		n = n.parent
	end
	return table.concat(parts, "/")
end

local function uniqueName(folder, name)
	local function taken(n)
		for _, c in ipairs(folder.children) do
			if c.name:lower() == n:lower() then
				return true
			end
		end
		return false
	end
	if not taken(name) then
		return name
	end
	local base, ext = name:match("^(.-)(%.[%w]+)$")
	if not base then
		base, ext = name, ""
	end
	local i = 1
	while taken(base .. " (" .. i .. ")" .. ext) do
		i = i + 1
	end
	return base .. " (" .. i .. ")" .. ext
end

local function defaultTree()
	local backend = mkFolder("Backend", {mkFile("Server.lua", "-- backend code\nprint(\"backend ready\")")})
	backend.open = false
	local tabs = mkFolder("Script Tabs", {
		mkFolder("UI", {}),
		mkFile("Src.lua", "print(\"Hello from CubiX MAX\")"),
		mkFile("Script #1.lua", ""),
		backend,
	})
	local saved = mkFolder("Saved Scripts", {})
	saved.open = false
	local auto = mkFolder("Auto Execute", {})
	auto.open = false
	local root = mkFolder("All Files", {tabs, saved, auto})
	root.isRoot = true
	link(root, nil)
	return root
end

local function serialize(n)
	local t = {kind = n.kind, name = n.name}
	if n.kind == "file" then
		t.content = n.content
	else
		t.open = n.open
		t.children = {}
		for _, c in ipairs(n.children) do
			table.insert(t.children, serialize(c))
		end
	end
	return t
end

local function deserialize(t)
	if t.kind == "file" then
		return mkFile(t.name, t.content)
	end
	local f = mkFolder(t.name, {})
	f.open = (t.open ~= false)
	for _, c in ipairs(t.children or {}) do
		table.insert(f.children, deserialize(c))
	end
	return f
end

--========================== PERSISTENCE (executor fs only) ==============
local scheduleSave, loadAll
do
local function canFS()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local saveToken = 0
local function writeAll()
	if not canFS() then
		return
	end
	pcall(function()
		if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(SAVE_DIR) then
			makefolder(SAVE_DIR)
		end
		writefile(SAVE_DIR .. "/settings.json", HttpService:JSONEncode(Settings))
		writefile(SAVE_DIR .. "/files.json", HttpService:JSONEncode(serialize(State.Root)))
	end)
end

function scheduleSave()
	if not canFS() then
		return
	end
	saveToken = saveToken + 1
	local my = saveToken
	task.delay(1.2, function()
		if my == saveToken then
			writeAll()
		end
	end)
end

function loadAll()
	local root
	if canFS() then
		pcall(function()
			if isfile(SAVE_DIR .. "/settings.json") then
				local data = HttpService:JSONDecode(readfile(SAVE_DIR .. "/settings.json"))
				for k in pairs(DEFAULTS) do
					if data[k] ~= nil then
						Settings[k] = data[k]
					end
				end
			end
			if isfile(SAVE_DIR .. "/files.json") then
				local data = HttpService:JSONDecode(readfile(SAVE_DIR .. "/files.json"))
				root = deserialize(data)
				root.isRoot = true
				if #root.children < 3 then
					root = nil
				end
			end
		end)
	end
	if root then
		link(root, nil)
	else
		root = defaultTree()
	end
	State.Root = root
	local tabs = root.children[1]
	State.selectedFolder = findChild(tabs, "UI") or tabs
	for _, c in ipairs(tabs.children) do
		if c.kind == "file" then
			State.active = c
			break
		end
	end
end
end

--========================== FORWARD DECLARATIONS ========================
local openFile, runCode, runNode, notify, addLog, showPage, openPopup, closePopup
local refreshExplorer, refreshFileEx, renderCloud, applySettings, deleteNode, createNode
local setEditorText, closeDropdowns, openFileSearch, selectCategory, renderConsole, refreshConfigRows
local openPicker

--========================== SYNTAX HIGHLIGHT ============================
local highlight
do
local KEYWORDS = {}
for _, w in ipairs({"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in",
	"local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue"}) do
	KEYWORDS[w] = true
end
local BUILTINS = {}
for _, w in ipairs({"print", "warn", "error", "pairs", "ipairs", "pcall", "xpcall", "require", "tostring", "tonumber",
	"type", "typeof", "select", "next", "unpack", "setmetatable", "getmetatable", "rawget", "rawset", "assert",
	"game", "workspace", "script", "task", "math", "string", "table", "os", "Instance", "Vector3", "Vector2",
	"CFrame", "Color3", "UDim2", "UDim", "Enum", "wait", "spawn", "delay", "tick", "time", "loadstring",
	"shared", "_G", "coroutine", "debug", "utf8", "Random", "TweenInfo", "Ray", "Rect"}) do
	BUILTINS[w] = true
end
local C = {
	keyword = "#C792EA", builtin = "#82AAFF", string = "#C3E88D", number = "#F78C6C",
	comment = "#5F6672", func = "#FFCB6B", plain = "#E6E6EA",
}

local function esc(s)
	s = string.gsub(s, "&", "&amp;")
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	return s
end

local function paint(col, s)
	return '<font color="' .. col .. '">' .. esc(s) .. "</font>"
end

function highlight(src)
	local len = #src
	if len > 24000 then
		return esc(src)
	end
	local out, n, i = {}, 0, 1
	local function push(s)
		n = n + 1
		out[n] = s
	end
	while i <= len do
		local c = src:sub(i, i)
		if src:sub(i, i + 1) == "--" then
			local lb = src:match("^%-%-%[(=*)%[", i)
			local e
			if lb then
				local _, f = src:find("]" .. lb .. "]", i, true)
				e = f or len
			else
				local s = src:find("\n", i, true)
				e = s and (s - 1) or len
			end
			push(paint(C.comment, src:sub(i, e)))
			i = e + 1
		elseif c == '"' or c == "'" then
			local j = i + 1
			while j <= len do
				local d = src:sub(j, j)
				if d == "\\" then
					j = j + 2
				elseif d == c or d == "\n" then
					break
				else
					j = j + 1
				end
			end
			if j > len then
				j = len
			end
			push(paint(C.string, src:sub(i, j)))
			i = j + 1
		elseif c == "[" and src:match("^%[=*%[", i) then
			local lb = src:match("^%[(=*)%[", i)
			local _, f = src:find("]" .. lb .. "]", i, true)
			local e = f or len
			push(paint(C.string, src:sub(i, e)))
			i = e + 1
		elseif c:match("%d") or (c == "." and src:sub(i + 1, i + 1):match("%d")) then
			local num = src:match("^0[xX]%x+", i) or src:match("^%d*%.?%d+[eE][%+%-]?%d+", i) or src:match("^%d*%.?%d*", i)
			if not num or num == "" then
				num = c
			end
			push(paint(C.number, num))
			i = i + #num
		elseif c:match("[%a_]") then
			local word = src:match("^[%w_]+", i)
			local nextc = src:match("^%s*(.)", i + #word)
			if KEYWORDS[word] then
				push(paint(C.keyword, word))
			elseif BUILTINS[word] then
				push(paint(C.builtin, word))
			elseif nextc == "(" then
				push(paint(C.func, word))
			else
				push(esc(word))
			end
			i = i + #word
		elseif c:match("%s") then
			local ws = src:match("^%s+", i)
			push(ws)
			i = i + #ws
		else
			push(esc(c))
			i = i + 1
		end
	end
	return table.concat(out)
end
end

--========================== BEAUTIFY ====================================
local function beautify(src)
	src = string.gsub(src, "\r", "")
	local out, depth = {}, 0
	for line in (src .. "\n"):gmatch("(.-)\n") do
		local t = trim(line)
		if t == "" then
			table.insert(out, "")
		else
			local code = t
			code = code:gsub("\"[^\"]*\"", "\"\"")
			code = code:gsub("'[^']*'", "''")
			code = code:gsub("%-%-.*$", "")
			local first = code:match("^%s*([%a_]+)")
			local lead = 0
			if code:match("^%s*end%f[^%w_]") or code:match("^%s*until%f[^%w_]") or code:match("^%s*[%)}%]]") then
				lead = 1
			elseif first == "else" or first == "elseif" then
				lead = 1
			end
			local kwOpen, kwClose = 0, 0
			for w in code:gmatch("[%a_][%w_]*") do
				if w == "function" or w == "repeat" or w == "do" then
					kwOpen = kwOpen + 1
				elseif w == "then" then
					if first ~= "elseif" then
						kwOpen = kwOpen + 1
					end
				elseif w == "end" or w == "until" then
					kwClose = kwClose + 1
				end
			end
			local _, po = code:gsub("[%({%[]", "")
			local _, pc = code:gsub("[%)}%]]", "")
			local net = po - pc
			local kwNet = kwOpen - kwClose
			local opens = math.max(kwNet > 0 and kwNet or 0, net > 0 and 1 or 0)
			local closes = math.max(kwNet < 0 and -kwNet or 0, net < 0 and 1 or 0)
			local d = math.max(0, depth - lead)
			table.insert(out, string.rep("    ", d) .. t)
			depth = math.max(0, depth + opens - closes)
		end
	end
	while #out > 0 and out[#out] == "" do
		table.remove(out)
	end
	return table.concat(out, "\n")
end

--========================== CLOUD SCRIPT LIST ===========================
local CLOUD = {
	{name = "Hello World", tag = "Basics", desc = "Prints a greeting to the console.",
		code = 'print("Hello from CubiX MAX")'},
	{name = "Player List", tag = "Utility", desc = "Prints every player in the server with their user id.",
		code = [[for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
	print(p.Name, p.UserId)
end]]},
	{name = "FPS Counter", tag = "Debug", desc = "Small on-screen FPS label in the top left corner.",
		code = [[local gui = Instance.new("ScreenGui")
gui.Name = "FpsCounter"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.fromOffset(120, 32)
lbl.Position = UDim2.fromOffset(10, 10)
lbl.BackgroundTransparency = 0.4
lbl.BackgroundColor3 = Color3.new(0, 0, 0)
lbl.TextColor3 = Color3.new(1, 1, 1)
lbl.Font = Enum.Font.Code
lbl.TextSize = 18
lbl.Parent = gui
local frames, last = 0, os.clock()
game:GetService("RunService").RenderStepped:Connect(function()
	frames = frames + 1
	if os.clock() - last >= 1 then
		lbl.Text = "FPS: " .. frames
		frames = 0
		last = os.clock()
	end
end)]]},
	{name = "Neon Cube", tag = "Visual", desc = "Spawns a glowing cube in front of your camera.",
		code = [[local cam = workspace.CurrentCamera
local part = Instance.new("Part")
part.Anchored = true
part.Size = Vector3.new(4, 4, 4)
part.Material = Enum.Material.Neon
part.Color = Color3.fromRGB(120, 200, 255)
part.CFrame = cam.CFrame * CFrame.new(0, 0, -15)
part.Parent = workspace
print("Spawned part at", part.Position)]]},
	{name = "Rainbow Ambient", tag = "Visual", desc = "Cycles the lighting ambient colour for ten seconds.",
		code = [[local lighting = game:GetService("Lighting")
local t = 0
local conn
conn = game:GetService("RunService").RenderStepped:Connect(function(dt)
	t = t + dt * 0.2
	lighting.Ambient = Color3.fromHSV(t % 1, 0.5, 0.8)
	if t > 10 then
		conn:Disconnect()
	end
end)]]},
	{name = "Workspace Count", tag = "Debug", desc = "Counts every descendant inside Workspace.",
		code = [[local function count(inst)
	local n = 0
	for _, c in ipairs(inst:GetChildren()) do
		n = n + 1 + count(c)
	end
	return n
end
print("Workspace descendants:", count(workspace))]]},
	{name = "Ping Check", tag = "Debug", desc = "Prints your current network ping in milliseconds.",
		code = [[local lp = game:GetService("Players").LocalPlayer
print("Ping (ms):", math.floor(lp:GetNetworkPing() * 1000))]]},
}
local CLOUD_TAGS = {"All", "Basics", "Utility", "Visual", "Debug"}

--========================== ROOT GUI ====================================
do
local old = PlayerGui:FindFirstChild("CubiX MAX")
if old then
	old:Destroy()
end
end

local Gui = new("ScreenGui", {
	Name = "CubiX MAX", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
}, PlayerGui)

local Connections = {}
local function conn(c)
	table.insert(Connections, c)
	return c
end

local function makeRoot(name, z)
	local holder = new("Frame", {
		Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z, BorderSizePixel = 0,
	}, Gui)
	local main = new("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DW, DH), BackgroundTransparency = 1, BorderSizePixel = 0,
	}, holder)
	new("UIAspectRatioConstraint", {AspectRatio = DW / DH}, main)
	local sc = new("UIScale", {Scale = 0.5}, main)
	return holder, main, sc
end

local PopHolder, PopMain, PopScale = makeRoot("Popups", 5)
local UIHolder, UIMain, UIScaleObj = makeRoot("UI", 1)

UIMain.BackgroundTransparency = 0
UIMain.BackgroundColor3 = BLACK
corner(UIMain, 150)

local function updateScale()
	local vp = Gui.AbsoluteSize
	local frac = (vp.X < 1100) and 0.96 or 0.64
	local s = math.min(vp.X * frac / DW, vp.Y * frac / DH)
	if s < 0.05 then
		s = 0.05
	end
	UIScaleObj.Scale = s
	PopScale.Scale = s
end
updateScale()
conn(Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale))

ColourStorage = new("Folder", {Name = "ColourStorage"}, PopMain)
new("Color3Value", {Name = "C0"}, ColourStorage)
new("Color3Value", {Name = "C1"}, ColourStorage)
new("BoolValue", {Name = "Gradient"}, ColourStorage)

--========================== LOAD DATA ===================================
loadAll()
applyTheme()

--========================== DRAGGING ====================================
local function pointerPos(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
	end
	return UserInputService:GetMouseLocation()
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local drag = {active = false}
local function startDrag(input)
	if not isPress(input) then
		return
	end
	drag.active = true
	drag.start = pointerPos(input)
	drag.pos = UIMain.Position
end

conn(UserInputService.InputChanged:Connect(function(input)
	if drag.active and isMove(input) then
		local d = pointerPos(input) - drag.start
		local sz = Gui.AbsoluteSize
		local p = UDim2.fromScale(drag.pos.X.Scale + d.X / sz.X, drag.pos.Y.Scale + d.Y / sz.Y)
		UIMain.Position = p
		PopMain.Position = p
	end
end))
conn(UserInputService.InputEnded:Connect(function(input)
	if isPress(input) then
		drag.active = false
	end
end))

--========================== HEADER ======================================
local Content = new("Frame", {
	Name = "Content", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
}, UIMain)
local Pages = {}
for _, n in ipairs({"CloudPg", "CodePg", "ConfigPg", "HomePg", "ConsolePg"}) do
	Pages[n] = new("Frame", {
		Name = n, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, BorderSizePixel = 0,
	}, Content)
end

do
local DragBn = button(UIMain, "DragBn", 0, 0, DW, 140)
DragBn.InputBegan:Connect(startDrag)

local Logo = makeIcon(UIMain, "Logo", 126, 236, 219, WHITE)
Logo.InputBegan:Connect(startDrag)
end

local NavBar = frame(UIMain, "NavBar", 375, 150, 658, 140, Color3.fromRGB(23, 23, 27), 70)
stroke(NavBar, Color3.fromRGB(33, 33, 38), 2)
local NavPill = frame(NavBar, "Pill", 0, 0, 118, 118, WHITE, 59)
NavPill.AnchorPoint = Vector2.new(0.5, 0.5)
NavPill.Position = UDim2.fromOffset(69, 70)
accent(NavPill)

local NAV = {
	{key = "Home", page = "HomePg"},
	{key = "Code", page = "CodePg"},
	{key = "Search", popup = true},
	{key = "Settings", page = "ConfigPg"},
	{key = "Console", page = "ConsolePg"},
}
local navIcons = {}
for i, n in ipairs(NAV) do
	local cx = 69 + (i - 1) * 130
	local b = button(NavBar, n.key .. "Bn", cx - 60, 10, 120, 120)
	local ic = makeIcon(b, n.key, 64, 60, 60, NAV_OFF)
	press(b, ic)
	navIcons[i] = ic
	b.MouseButton1Click:Connect(function()
		if n.popup then
			openFileSearch("open")
		else
			showPage(n.page)
		end
	end)
end

local function setNav(index)
	if index then
		tween(NavPill, 0.25, {BackgroundTransparency = 0, Position = UDim2.fromOffset(69 + (index - 1) * 130, 70)})
	else
		tween(NavPill, 0.2, {BackgroundTransparency = 1})
	end
	for i, ic in ipairs(navIcons) do
		setIconColor(ic, (i == index) and DARK_ICON or NAV_OFF)
	end
end

do
local CloudBn = frame(UIMain, "CloudBn", 2238, 150, 140, 140, Color3.fromRGB(16, 16, 19), 70)
stroke(CloudBn, Color3.fromRGB(30, 30, 35), 3)
local CloudInner = frame(CloudBn, "Inner", 11, 11, 118, 118, WHITE, 59)
accent(CloudInner)
local CloudHit = button(CloudBn, "Hit", 0, 0, 140, 140)
local CloudIcon = makeIcon(CloudBn, "Arrow", 58, 70, 70, DARK_ICON)
CloudIcon.ZIndex = 2
CloudHit.ZIndex = 3
press(CloudHit, CloudInner)
CloudHit.MouseButton1Click:Connect(function()
	if State.page == "CloudPg" then
		showPage(State.lastPage or "HomePg")
	else
		State.lastPage = State.page
		showPage("CloudPg")
	end
end)

local ExitUI = frame(UIMain, "ExitUI", 2440, 40, 70, 70)
local ExitBn = iconButton(ExitUI, "Close", 34, 35, 35, DIMMER, function()
	openPopup("ExitP")
end)
end

--========================== TOAST =======================================
do
local Toast = frame(UIMain, "Toast", 0, 0, 640, 115, BLACK, 57)
Toast.AnchorPoint = Vector2.new(0.5, 0)
Toast.Position = UDim2.fromOffset(1270, 60)
Toast.Visible = false
Toast.ZIndex = 50
local ToastStroke = new("UIStroke", {Color = WHITE, Thickness = 5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, Toast)
local ToastIcon = makeIcon(Toast, "Check", 58, 62, 57, WHITE)
local ToastText = label(Toast, "", 118, 0, 500, 115, 56, WHITE, F_MED)
local ToastCount = label(Toast, "2s", 0, -26, 92, 48, 40, WHITE, F_MED, Enum.TextXAlignment.Center)
ToastCount.BackgroundColor3 = BLACK
ToastCount.BackgroundTransparency = 0

local toastToken = 0
function notify(text, kind)
	if not Settings.Notifications then
		return
	end
	kind = kind or "success"
	toastToken = toastToken + 1
	local my = toastToken
	local w = math.floor(190 + #text * 30)
	Toast.Size = UDim2.fromOffset(w, 115)
	ToastText.Size = UDim2.fromOffset(w - 130, 115)
	ToastText.Text = text
	ToastCount.Position = UDim2.fromOffset(w - 200, -26)
	local keys = {success = "Check", error = "Error", warn = "Warn", info = "Info"}
	if ToastIcon then
		ToastIcon:Destroy()
	end
	local col = (kind == "error") and ERR or WHITE
	ToastIcon = makeIcon(Toast, keys[kind] or "Check", 58, 62, 57, col)
	ToastStroke.Color = col
	ToastText.TextColor3 = col
	Toast.Visible = true
	Toast.Position = UDim2.fromOffset(1270, 60)
	tween(Toast, 0.45, {Position = UDim2.fromOffset(1270, 205)}, Enum.EasingStyle.Back)
	task.spawn(function()
		for s = 2, 1, -1 do
			if my ~= toastToken then
				return
			end
			ToastCount.Text = s .. "s"
			task.wait(1)
		end
		if my ~= toastToken then
			return
		end
		ToastCount.Text = "0s"
		tween(Toast, 0.35, {Position = UDim2.fromOffset(1270, 60)})
		task.wait(0.4)
		if my == toastToken then
			Toast.Visible = false
		end
	end)
end
end

--========================== CONSOLE LOG STORE ===========================
local ConsoleLogs = {}
local ConsoleFilter = {Info = true, Warn = true, Error = true, Text = "", ShowSearch = false}
local consoleScroll
local entryObjs = {}
local entryOrder = 0
local KIND_COLOR = {
	Output = Color3.fromRGB(225, 225, 230), Info = Color3.fromRGB(150, 200, 255),
	Warn = Color3.fromRGB(255, 205, 110), Error = ERR,
}

local function kindGroup(kind)
	if kind == "Warn" then
		return "Warn"
	elseif kind == "Error" then
		return "Error"
	end
	return "Info"
end

local function logPasses(l)
	if not ConsoleFilter[kindGroup(l.kind)] then
		return false
	end
	if ConsoleFilter.Text ~= "" and not l.text:lower():find(ConsoleFilter.Text:lower(), 1, true) then
		return false
	end
	return true
end

local function maxLines()
	return tonumber(Settings.MaxLines) or 300
end

local function addEntry(l)
	entryOrder = entryOrder + 1
	local t = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Text = "[" .. l.time .. "] " .. l.text, Font = F_CODE, TextSize = 36, TextColor3 = KIND_COLOR[l.kind] or WHITE,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = entryOrder, BorderSizePixel = 0,
	}, consoleScroll)
	table.insert(entryObjs, t)
	while #entryObjs > maxLines() do
		local first = table.remove(entryObjs, 1)
		if first then
			first:Destroy()
		end
	end
	if Settings.AutoScroll then
		task.defer(function()
			if consoleScroll then
				consoleScroll.CanvasPosition = Vector2.new(0, consoleScroll.AbsoluteCanvasSize.Y)
			end
		end)
	end
end

function addLog(kind, text)
	local l = {kind = kind, text = tostring(text), time = os.date("%H:%M:%S")}
	table.insert(ConsoleLogs, l)
	while #ConsoleLogs > maxLines() do
		table.remove(ConsoleLogs, 1)
	end
	if consoleScroll and logPasses(l) then
		addEntry(l)
	end
end

function renderConsole()
	if not consoleScroll then
		return
	end
	for _, o in ipairs(entryObjs) do
		o:Destroy()
	end
	entryObjs = {}
	for _, l in ipairs(ConsoleLogs) do
		if logPasses(l) then
			addEntry(l)
		end
	end
end

conn(LogService.MessageOut:Connect(function(msg, mt)
	if not Settings.CaptureGame then
		return
	end
	local kind = "Output"
	if mt == Enum.MessageType.MessageWarning then
		kind = "Warn"
	elseif mt == Enum.MessageType.MessageError then
		kind = "Error"
	elseif mt == Enum.MessageType.MessageInfo then
		kind = "Info"
	end
	addLog(kind, msg)
end))

--========================== EXECUTION ===================================
function runCode(src, name)
	if not src:find("%S") then
		notify("Nothing to execute", "warn")
		return false
	end
	local okCompile, fn, err = pcall(function()
		return loadstring(src, "=" .. (name or "CubiX"))
	end)
	if not okCompile then
		addLog("Error", "loadstring is not available in this environment. (" .. tostring(fn) .. ")")
		notify("Execution Failed", "error")
		return false
	end
	if type(fn) ~= "function" then
		addLog("Error", tostring(err))
		notify("Syntax Error", "error")
		return false
	end
	addLog("Info", "Executing " .. (name or "script") .. " ...")
	task.spawn(function()
		local ok, e = xpcall(fn, function(m)
			return debug.traceback(tostring(m), 2)
		end)
		if not ok then
			addLog("Error", tostring(e))
		end
	end)
	notify("Code Executed!", "success")
	return true
end

function runNode(node)
	if node.kind == "file" then
		return runCode(node.content, node.name)
	end
	local any = false
	local function walk(f)
		for _, c in ipairs(f.children) do
			if c.kind == "file" then
				any = true
				runCode(c.content, c.name)
			else
				walk(c)
			end
		end
	end
	walk(node)
	if not any then
		notify("Folder is empty", "warn")
	end
	return any
end

--========================== EDITOR (HOME + CODE PAGES) ==================
local FONT_SIZES = {Small = 34, Medium = 40, Large = 48}
local viewW, viewH = 1098, 650

local EditorPanel = panel(Pages.HomePg, "EditorPanel", 900, 400, 1478, 840, 60)
EditorPanel.ClipsDescendants = true

local Scroll = new("ScrollingFrame", {
	Name = "Scroll", Position = UDim2.fromOffset(40, 30), Size = UDim2.fromOffset(viewW, viewH),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8,
	ScrollBarImageColor3 = Color3.fromRGB(70, 70, 76), CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.XY, ClipsDescendants = true,
}, EditorPanel)

local Hl = new("TextLabel", {
	Name = "Highlight", BackgroundTransparency = 1, Size = UDim2.fromOffset(viewW, viewH), Text = "",
	Font = F_CODE, TextSize = 40, TextColor3 = Color3.fromRGB(230, 230, 234), RichText = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 1, BorderSizePixel = 0,
}, Scroll)
new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6)}, Hl)

local Box = new("TextBox", {
	Name = "Box", BackgroundTransparency = 1, Size = UDim2.fromOffset(viewW, viewH), Text = "",
	Font = F_CODE, TextSize = 40, TextColor3 = Color3.fromRGB(230, 230, 234), TextTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	MultiLine = true, ClearTextOnFocus = false, TextWrapped = false, ZIndex = 2, BorderSizePixel = 0,
	SelectionColor3 = Color3.fromRGB(70, 90, 130), CursorPosition = 1,
}, Scroll)
new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6)}, Box)

local Tile = frame(EditorPanel, "Tile", 1178, 20, 280, 280, Color3.fromRGB(33, 33, 37), 40)
local TileLines = label(Tile, "0 lines", 0, 100, 280, 40, 36, DIM, F_MED, Enum.TextXAlignment.Center)
local TileChars = label(Tile, "0 chars", 0, 145, 280, 40, 32, DIMMER, F_REG, Enum.TextXAlignment.Center)

local suppress = false
local lastLen = 0

local function refreshCanvas()
	local tb = Box.TextBounds
	local wrap = Settings.WordWrap
	local w = wrap and (viewW - 14) or math.max(viewW - 14, tb.X + 80)
	local h = math.max(viewH, tb.Y + 100)
	local sz = UDim2.fromOffset(w, h)
	if Box.Size ~= sz then
		Box.Size = sz
		Hl.Size = sz
	end
	Scroll.CanvasSize = UDim2.fromOffset(wrap and 0 or w, h)
end

local function renderHighlight()
	if Settings.Syntax then
		Hl.Text = highlight(Box.Text)
	else
		Hl.Text = ""
	end
end

local function updateStats()
	local txt = Box.Text
	local _, nl = txt:gsub("\n", "")
	TileLines.Text = (nl + 1) .. " lines"
	TileChars.Text = #txt .. " chars"
end

local function applyEditorLook()
	local size = FONT_SIZES[Settings.FontSize] or 40
	Box.TextSize = size
	Hl.TextSize = size
	Box.TextWrapped = Settings.WordWrap
	Hl.TextWrapped = Settings.WordWrap
	Scroll.ScrollingDirection = Settings.WordWrap and Enum.ScrollingDirection.Y or Enum.ScrollingDirection.XY
	Box.TextTransparency = Settings.Syntax and 1 or 0
	Hl.Visible = Settings.Syntax
	renderHighlight()
	refreshCanvas()
end

local function followCaret()
	local txt = Box.Text
	local cp = Box.CursorPosition
	if cp < 1 then
		return
	end
	local _, line = txt:sub(1, cp - 1):gsub("\n", "")
	local _, total = txt:gsub("\n", "")
	total = total + 1
	local lineH = Box.TextBounds.Y / total
	if lineH <= 0 then
		return
	end
	local y = line * lineH
	local top = Scroll.CanvasPosition.Y
	if y < top then
		Scroll.CanvasPosition = Vector2.new(Scroll.CanvasPosition.X, math.max(0, y - lineH))
	elseif y + lineH * 2 > top + viewH then
		Scroll.CanvasPosition = Vector2.new(Scroll.CanvasPosition.X, y + lineH * 3 - viewH)
	end
end

local function newTabFile()
	local tabs = State.Root.children[1]
	local i = 1
	local nm = "Script #" .. i .. ".lua"
	while findChild(tabs, nm) do
		i = i + 1
		nm = "Script #" .. i .. ".lua"
	end
	local f = mkFile(nm, "")
	f.parent = tabs
	table.insert(tabs.children, f)
	return f
end

local function syncText()
	local txt = Box.Text
	if not State.active then
		State.active = newTabFile()
		if refreshExplorer then
			refreshExplorer()
		end
	end
	State.active.content = txt
	lastLen = #txt
	renderHighlight()
	refreshCanvas()
	updateStats()
	scheduleSave()
end

local function opensBlock(s)
	if s:match("%f[%w_]then$") or s:match("%f[%w_]do$") or s:match("%f[%w_]else$") or s:match("%f[%w_]repeat$") then
		return true
	end
	if s:match("{$") or s:match("%(%s*$") then
		return true
	end
	if s:match("function%s*[%w_%.:]*%b()$") then
		return true
	end
	return false
end

Box:GetPropertyChangedSignal("Text"):Connect(function()
	if suppress then
		return
	end
	local txt = Box.Text
	if txt:find("\t", 1, true) then
		local cp = Box.CursorPosition
		local _, nb = txt:sub(1, math.max(cp - 1, 0)):gsub("\t", "")
		suppress = true
		Box.Text = (txt:gsub("\t", "    "))
		Box.CursorPosition = cp + nb * 3
		suppress = false
		txt = Box.Text
	end
	if Settings.AutoIndent and #txt == lastLen + 1 then
		local cp = Box.CursorPosition
		if cp > 1 and txt:sub(cp - 1, cp - 1) == "\n" then
			local prev = txt:sub(1, cp - 2):match("([^\n]*)$") or ""
			local ind = prev:match("^%s*") or ""
			if opensBlock(trim(prev)) then
				ind = ind .. "    "
			end
			if #ind > 0 then
				suppress = true
				Box.Text = txt:sub(1, cp - 1) .. ind .. txt:sub(cp)
				Box.CursorPosition = cp + #ind
				suppress = false
			end
		end
	end
	syncText()
	followCaret()
end)
Box:GetPropertyChangedSignal("TextBounds"):Connect(refreshCanvas)
Box:GetPropertyChangedSignal("CursorPosition"):Connect(followCaret)

function setEditorText(txt)
	txt = string.gsub(txt, "\r", "")
	suppress = true
	Box.Text = txt
	suppress = false
	syncText()
end

-- toolbar
local toolbarButtons = {}
do
local TOOL_COLORS = {
	Broom = Color3.fromRGB(255, 155, 155), Wand = Color3.fromRGB(140, 210, 250),
	Copy = Color3.fromRGB(140, 210, 250), Paste = Color3.fromRGB(140, 210, 250),
	ExecFile = Color3.fromRGB(150, 250, 180), Play = Color3.fromRGB(150, 250, 180),
}

local function copyText()
	local txt = Box.Text
	if typeof(setclipboard) == "function" then
		pcall(setclipboard, txt)
		notify("Copied!", "success")
	elseif typeof(toclipboard) == "function" then
		pcall(toclipboard, txt)
		notify("Copied!", "success")
	else
		Box:CaptureFocus()
		Box.SelectionStart = 1
		Box.CursorPosition = #txt + 1
		notify("Selected - press Ctrl+C", "info")
	end
end

local function pasteText()
	local getter = nil
	if typeof(getclipboard) == "function" then
		getter = getclipboard
	elseif typeof(fromclipboard) == "function" then
		getter = fromclipboard
	end
	if getter then
		local ok, txt = pcall(getter)
		if ok and type(txt) == "string" then
			setEditorText(Box.Text .. txt)
			notify("Pasted!", "success")
			return
		end
	end
	Box:CaptureFocus()
	notify("Press Ctrl+V to paste", "info")
end

local TOOLS = {
	{key = "Broom", cb = function()
		setEditorText("")
		notify("Editor cleared", "info")
	end},
	{key = "Wand", cb = function()
		setEditorText(beautify(Box.Text))
		notify("Formatted!", "success")
	end},
	{key = "Copy", cb = copyText},
	{key = "Paste", cb = pasteText},
	{key = "ExecFile", cb = function()
		openFileSearch("run")
	end},
	{key = "Play", cb = function()
		runCode(Box.Text, State.active and State.active.name or "Editor")
	end},
}
for i, t in ipairs(TOOLS) do
	local b = iconButton(EditorPanel, t.key, 62, 739 + (i - 3.5) * 130, 727, TOOL_COLORS[t.key], t.cb)
	toolbarButtons[i] = b
end
end

local function layoutEditor(mode)
	local home = (mode == "home")
	EditorPanel.Parent = home and Pages.HomePg or Pages.CodePg
	local W = home and 1478 or 2218
	EditorPanel.Position = UDim2.fromOffset(home and 900 or 160, 400)
	EditorPanel.Size = UDim2.fromOffset(W, 840)
	viewW = W - 40 - 340
	viewH = 650
	Scroll.Size = UDim2.fromOffset(viewW, viewH)
	Tile.Position = UDim2.fromOffset(W - 300, 20)
	for i, b in ipairs(toolbarButtons) do
		b.Position = UDim2.fromOffset(W / 2 + (i - 3.5) * 130 - 51, 727 - 51)
	end
	refreshCanvas()
end

--========================== EXPLORER (HOME PAGE) ========================
do
local ExplorerPanel = panel(Pages.HomePg, "FileExplorer", 160, 400, 680, 840, 60)
ExplorerPanel.ClipsDescendants = true
label(ExplorerPanel, "File Explorer", 78, 50, 400, 80, 56, WHITE, F_MED)
iconButton(ExplorerPanel, "NewFolder", 56, 443, 92, WHITE, function()
	openPopup("FolderGenP")
end)
iconButton(ExplorerPanel, "NewFile", 56, 513, 92, WHITE, function()
	openPopup("FileGenP")
end)
iconButton(ExplorerPanel, "Settings", 56, 583, 92, WHITE, function()
	showPage("ConfigPg")
	selectCategory(4)
end)

local ExplorerList = new("ScrollingFrame", {
	Name = "List", Position = UDim2.fromOffset(0, 140), Size = UDim2.fromOffset(680, 700),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
}, ExplorerPanel)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0)}, ExplorerList)

local ExplorerFade = frame(ExplorerPanel, "Fade", 0, 690, 680, 150, Color3.fromRGB(17, 17, 20), nil)
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
}, ExplorerFade)

local function displayName(node)
	if node.kind == "file" and not Settings.ShowExt then
		local n = node.name:gsub("%.lua$", "")
		return n
	end
	return node.name
end

local function onActivePath(node)
	local a = State.active
	while a do
		if a == node then
			return true
		end
		a = a.parent
	end
	return node == State.selectedFolder
end

function refreshExplorer()
	for _, c in ipairs(ExplorerList:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local order = 0
	local function addRow(node, depth)
		order = order + 1
		local bright = onActivePath(node)
		local row = new("TextButton", {
			Name = node.name, Size = UDim2.new(1, 0, 0, 100), BackgroundTransparency = 1, Text = "",
			AutoButtonColor = false, LayoutOrder = order, BorderSizePixel = 0,
		}, ExplorerList)
		local dotX, iconX, textX
		if depth == 0 then
			iconX, textX = 103, 156
		else
			local o = (depth - 1) * 70
			dotX, iconX, textX = 105 + o, 183 + o, 236 + o
		end
		local col = bright and WHITE or Color3.fromRGB(120, 120, 126)
		if dotX then
			local dot = frame(row, "Dot", dotX - 8, 42, 16, 16, bright and WHITE or Color3.fromRGB(100, 100, 106), 8)
		end
		makeIcon(row, node.kind == "folder" and "Folder" or "File", 52, iconX, 50, col)
		local t = label(row, displayName(node), textX, 0, 570 - textX, 100, 54, col, F_MED)
		t.TextTruncate = Enum.TextTruncate.AtEnd
		if node.kind == "folder" then
			makeIcon(row, node.open and "ChevronDown" or "ChevronRight", 44, 583, 50, col)
		end
		row.MouseButton1Click:Connect(function()
			if node.kind == "folder" then
				node.open = not node.open
				State.selectedFolder = node
				refreshExplorer()
				scheduleSave()
			else
				openFile(node)
			end
		end)
		if node.kind == "folder" and node.open then
			for _, c in ipairs(node.children) do
				addRow(c, depth + 1)
			end
		end
	end
	for _, c in ipairs(State.Root.children) do
		addRow(c, 0)
	end
end

function openFile(node)
	if node.kind ~= "file" then
		return
	end
	State.active = node
	State.selectedFolder = node.parent
	setEditorText(node.content)
	refreshExplorer()
	if refreshFileEx then
		refreshFileEx()
	end
	if State.page ~= "HomePg" and State.page ~= "CodePg" then
		showPage("HomePg")
	end
end

function deleteNode(node)
	if node.parent == State.Root or node.isRoot then
		return
	end
	local a = State.active
	while a do
		if a == node then
			State.active = nil
			setEditorText("")
			break
		end
		a = a.parent
	end
	if State.selectedFolder == node then
		State.selectedFolder = node.parent
	end
	local p = node.parent
	for i, c in ipairs(p.children) do
		if c == node then
			table.remove(p.children, i)
			break
		end
	end
	refreshExplorer()
	refreshFileEx()
	scheduleSave()
	notify("Deleted " .. node.name, "info")
end

function createNode(kind, name)
	name = trim(name or "")
	if name == "" then
		notify("Enter a name first", "warn")
		return false
	end
	local folder = State.selectedFolder or State.Root.children[1]
	if kind == "file" then
		local low = name:lower()
		if not (low:match("%.lua$") or low:match("%.luau$") or low:match("%.txt$")) then
			name = name .. ".lua"
		end
	end
	name = uniqueName(folder, name)
	local node = (kind == "file") and mkFile(name, "") or mkFolder(name, {})
	node.parent = folder
	table.insert(folder.children, node)
	folder.open = true
	if kind == "file" then
		openFile(node)
	else
		State.selectedFolder = node
		refreshExplorer()
		refreshFileEx()
	end
	scheduleSave()
	notify((kind == "file" and "File" or "Folder") .. " created", "success")
	return true
end
end

--========================== CONSOLE PAGE ================================
do
	local page = Pages.ConsolePg
	local pill = frame(page, "FilterBar", 1651, 150, 535, 140, Color3.fromRGB(23, 23, 27), 70)
	stroke(pill, Color3.fromRGB(33, 33, 38), 2)
	local panelC = panel(page, "ConsolePanel", 160, 400, 2218, 840, 60)
	panelC.ClipsDescendants = true

	local filterBox = new("TextBox", {
		Name = "FilterBox", Position = UDim2.fromOffset(40, 24), Size = UDim2.fromOffset(2138, 90),
		BackgroundColor3 = FILL, Text = "", PlaceholderText = "Filter output..", PlaceholderColor3 = DIMMER,
		TextColor3 = WHITE, Font = F_MED, TextSize = 44, TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, Visible = false, BorderSizePixel = 0,
	}, panelC)
	corner(filterBox, 45)
	stroke(filterBox, STROKE_C, 2)
	new("UIPadding", {PaddingLeft = UDim.new(0, 36)}, filterBox)

	consoleScroll = new("ScrollingFrame", {
		Name = "Logs", Position = UDim2.fromOffset(40, 30), Size = UDim2.fromOffset(2138, 720),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8,
		ScrollBarImageColor3 = Color3.fromRGB(70, 70, 76), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
	}, panelC)
	new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)}, consoleScroll)

	local clearBtn = new("TextButton", {
		Name = "Clear", Position = UDim2.fromOffset(2018, 770), Size = UDim2.fromOffset(160, 56),
		BackgroundTransparency = 1, Text = "clear", Font = F_MED, TextSize = 38, TextColor3 = DIMMER,
		AutoButtonColor = false, BorderSizePixel = 0,
	}, panelC)
	clearBtn.MouseButton1Click:Connect(function()
		ConsoleLogs = {}
		renderConsole()
	end)

	local btns = {}
	local function layoutConsole()
		if ConsoleFilter.ShowSearch then
			filterBox.Visible = true
			consoleScroll.Position = UDim2.fromOffset(40, 130)
			consoleScroll.Size = UDim2.fromOffset(2138, 620)
		else
			filterBox.Visible = false
			consoleScroll.Position = UDim2.fromOffset(40, 30)
			consoleScroll.Size = UDim2.fromOffset(2138, 720)
		end
	end
	local function paintButtons()
		for key, ic in pairs(btns) do
			local on
			if key == "Search" then
				on = ConsoleFilter.ShowSearch
			else
				on = ConsoleFilter[key == "Info" and "Info" or (key == "Warn" and "Warn" or "Error")]
			end
			setIconColor(ic, on and WHITE or Color3.fromRGB(72, 72, 78))
		end
	end
	local keys = {"Search", "Info", "Warn", "Error"}
	for i, key in ipairs(keys) do
		local _, ic = iconButton(pill, key, 56, 70 + (i - 1) * 131, 70, NAV_OFF, function()
			if key == "Search" then
				ConsoleFilter.ShowSearch = not ConsoleFilter.ShowSearch
				layoutConsole()
			else
				ConsoleFilter[key] = not ConsoleFilter[key]
				renderConsole()
			end
			paintButtons()
		end)
		btns[key] = ic
	end
	paintButtons()
	filterBox:GetPropertyChangedSignal("Text"):Connect(function()
		ConsoleFilter.Text = filterBox.Text
		renderConsole()
	end)
end

--========================== CLOUD PAGE ==================================
local CloudScroll, CloudSearchBox
do
	local page = Pages.CloudPg
	local sp = frame(page, "SearchPill", 160, 400, 1600, 120, Color3.fromRGB(24, 24, 28), 60)
	stroke(sp, STROKE_C, 2)
	makeIcon(sp, "Search", 52, 70, 60, DIM)
	CloudSearchBox = new("TextBox", {
		Name = "CloudSearch", Position = UDim2.fromOffset(120, 0), Size = UDim2.fromOffset(1440, 120),
		BackgroundTransparency = 1, Text = "", PlaceholderText = "Search cloud scripts..", PlaceholderColor3 = DIMMER,
		TextColor3 = WHITE, Font = F_MED, TextSize = 50, TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, BorderSizePixel = 0,
	}, sp)
	local fb = frame(page, "FilterBtn", 1810, 400, 120, 120, Color3.fromRGB(24, 24, 28), 60)
	stroke(fb, STROKE_C, 2)
	local fh = button(fb, "Hit", 0, 0, 120, 120)
	makeIcon(fb, "Filter", 52, 60, 60, WHITE)
	fh.MouseButton1Click:Connect(function()
		openPopup("CloudSFilterP")
	end)
	local gb = frame(page, "GridBtn", 1960, 400, 120, 120, Color3.fromRGB(24, 24, 28), 60)
	stroke(gb, STROKE_C, 2)
	local gh = button(gb, "Hit", 0, 0, 120, 120)
	makeIcon(gb, "Grid", 52, 60, 60, WHITE)
	gh.MouseButton1Click:Connect(function()
		openPopup("CloudGridCtrlP")
	end)

	CloudScroll = new("ScrollingFrame", {
		Name = "Cards", Position = UDim2.fromOffset(160, 560), Size = UDim2.fromOffset(2218, 680),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
	}, page)
	new("UIGridLayout", {
		Name = "Grid", SortOrder = Enum.SortOrder.LayoutOrder, CellPadding = UDim2.fromOffset(30, 30),
		CellSize = UDim2.fromOffset(719, 300),
	}, CloudScroll)

	CloudSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		State.cloudQuery = CloudSearchBox.Text
		renderCloud()
	end)
end

function renderCloud()
	for _, c in ipairs(CloudScroll:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local cols = State.cloudCols
	local w = math.floor((2218 - 30 * (cols - 1)) / cols)
	CloudScroll.Grid.CellSize = UDim2.fromOffset(w, 300)
	local q = State.cloudQuery:lower()
	local order = 0
	for _, item in ipairs(CLOUD) do
		local okTag = (State.cloudTag == "All") or (item.tag == State.cloudTag)
		local okQ = (q == "") or item.name:lower():find(q, 1, true) or item.desc:lower():find(q, 1, true)
		if okTag and okQ then
			order = order + 1
			local card = panel(CloudScroll, item.name, 0, 0, w, 300, 50)
			card.LayoutOrder = order
			local tl = label(card, item.name, 50, 30, w - 100, 70, 50, WHITE, F_BOLD)
			tl.TextTruncate = Enum.TextTruncate.AtEnd
			local d = label(card, item.desc, 50, 105, w - 100, 90, 34, DIM, F_REG)
			d.TextWrapped = true
			d.TextYAlignment = Enum.TextYAlignment.Top
			local chip = frame(card, "Tag", 50, 218, 190, 52, Color3.fromRGB(36, 36, 41), 26)
			label(chip, item.tag, 0, 0, 190, 52, 30, DIM, F_MED, Enum.TextXAlignment.Center)
			local load = new("TextButton", {
				Name = "Load", Position = UDim2.fromOffset(w - 50 - 150, 208), Size = UDim2.fromOffset(150, 70),
				BackgroundColor3 = WHITE, Text = "Load", Font = F_BOLD, TextSize = 38, TextColor3 = DARK_ICON,
				AutoButtonColor = false, BorderSizePixel = 0,
			}, card)
			corner(load, 35)
			accent(load)
			local run = new("TextButton", {
				Name = "Run", Position = UDim2.fromOffset(w - 50 - 150 - 20 - 130, 208), Size = UDim2.fromOffset(130, 70),
				BackgroundColor3 = Color3.fromRGB(36, 36, 41), Text = "Run", Font = F_BOLD, TextSize = 38,
				TextColor3 = WHITE, AutoButtonColor = false, BorderSizePixel = 0,
			}, card)
			corner(run, 35)
			load.MouseButton1Click:Connect(function()
				local tabs = State.Root.children[1]
				local nm = uniqueName(tabs, item.name .. ".lua")
				local f = mkFile(nm, item.code)
				f.parent = tabs
				table.insert(tabs.children, f)
				tabs.open = true
				openFile(f)
				showPage("HomePg")
				notify("Loaded " .. item.name, "success")
			end)
			run.MouseButton1Click:Connect(function()
				runCode(item.code, item.name)
			end)
		end
	end
end

--========================== SETTINGS PAGE ===============================
do
local Config = {cat = 1}
local dropdownClosers = {}

function closeDropdowns()
	local list = dropdownClosers
	dropdownClosers = {}
	for _, fn in ipairs(list) do
		fn()
	end
end

local function toggleWidget(parent, x, y, getv, setv)
	local b = new("TextButton", {
		Name = "Toggle", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(63, 63), Text = "",
		AutoButtonColor = false, BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, parent)
	corner(b, 20)
	local g = accent(b)
	local dot = frame(b, "Dot", 0, 0, 28, 28, Color3.fromRGB(24, 24, 28), 10)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	local function render(v)
		if v then
			b.BackgroundColor3 = WHITE
			g.Enabled = true
			dot.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
		else
			b.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
			g.Enabled = false
			dot.BackgroundColor3 = Color3.fromRGB(72, 72, 78)
		end
	end
	render(getv())
	b.MouseButton1Click:Connect(function()
		local nv = not getv()
		setv(nv)
		render(nv)
	end)
	return b
end

local function dropdown(card, x, y, w, h, options, current, cb)
	local btn = new("TextButton", {
		Name = "Select", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Color3.fromRGB(26, 26, 31), Text = "", AutoButtonColor = false, BorderSizePixel = 0,
	}, card)
	corner(btn, 26)
	stroke(btn, STROKE_C, 2)
	label(btn, tostring(current), 30, 0, w - 100, h, 44, DIM, F_MED)
	makeIcon(btn, "ChevronDown", 40, w - 46, h / 2, DIM)
	local list
	local function closeList()
		if list then
			list:Destroy()
			list = nil
			card.ZIndex = 1
		end
	end
	btn.MouseButton1Click:Connect(function()
		if list then
			closeList()
			return
		end
		closeDropdowns()
		card.ZIndex = 20
		list = frame(card, "List", x, y + h + 10, w, #options * 76 + 20, Color3.fromRGB(22, 22, 26), 28)
		list.ZIndex = 30
		stroke(list, STROKE_C, 2)
		for i, opt in ipairs(options) do
			local ob = new("TextButton", {
				Name = opt, Position = UDim2.fromOffset(10, 10 + (i - 1) * 76), Size = UDim2.fromOffset(w - 20, 70),
				BackgroundTransparency = 1, Text = opt, Font = F_MED, TextSize = 42,
				TextColor3 = (opt == tostring(current)) and WHITE or DIM, AutoButtonColor = false,
				ZIndex = 31, BorderSizePixel = 0,
			}, list)
			ob.MouseButton1Click:Connect(function()
				closeList()
				cb(opt)
			end)
		end
		table.insert(dropdownClosers, closeList)
	end)
	return btn
end

local CATS = {
	{name = "Appearance", icon = "Palette", rows = {
		{t = "toggle", key = "Syntax", title = "Luau Syntax",
			desc = "Luau Syntax dynamically highlights keywords and formats code structure to elevate your scripting experience."},
		{t = "theme"},
		{t = "gradient"},
		{t = "toggle", key = "Animations", title = "Animations",
			desc = "Smooth UI transitions and tweens. Turn this off for instant UI on slower devices."},
	}},
	{name = "Editor", icon = "Code", rows = {
		{t = "select", key = "FontSize", title = "Font Size", options = {"Small", "Medium", "Large"},
			desc = "Changes the size of the code in the editor and the highlight layer."},
		{t = "toggle", key = "AutoIndent", title = "Auto Indent",
			desc = "Keeps the indentation of the previous line and adds a level after blocks like then, do and function."},
		{t = "toggle", key = "WordWrap", title = "Word Wrap",
			desc = "Wraps long lines instead of scrolling the editor sideways."},
	}},
	{name = "Client", icon = "Client", rows = {
		{t = "toggle", key = "AutoExecute", title = "Auto Execute",
			desc = "Runs every script inside the Auto Execute folder when CubiX MAX loads."},
		{t = "toggle", key = "AntiAFK", title = "Anti AFK",
			desc = "Prevents the idle kick by sending a small input when Roblox reports you as idle."},
		{t = "select", key = "FPSCap", title = "FPS Cap", options = {"Off", "30", "60", "120", "240"},
			desc = "Limits the frame rate. Needs an environment that provides setfpscap."},
	}},
	{name = "File Explorer", icon = "Folder", rows = {
		{t = "toggle", key = "ShowExt", title = "Show Extensions",
			desc = "Shows the .lua ending on file names inside the explorer."},
		{t = "toggle", key = "ConfirmDelete", title = "Confirm Delete",
			desc = "Asks for a second tap on the trash icon before a file or folder is deleted."},
	}},
	{name = "Console", icon = "Console", rows = {
		{t = "toggle", key = "AutoScroll", title = "Auto Scroll",
			desc = "Keeps the console scrolled to the newest line."},
		{t = "toggle", key = "CaptureGame", title = "Capture Game Output",
			desc = "Shows prints, warnings and errors from the game inside the console page."},
		{t = "select", key = "MaxLines", title = "Max Lines", options = {"100", "300", "1000"},
			desc = "How many console lines are kept before the oldest ones are removed."},
	}},
	{name = "license", icon = "Key", rows = {
		{t = "info", title = "License", value = "Free",
			desc = "CubiX MAX is a local tool. No key is needed and nothing is sent anywhere. Version 1.0."},
	}},
	{name = "miscellaneous", icon = "Sliders", rows = {
		{t = "select", key = "Keybind", title = "Toggle Keybind", options = {"RightControl", "RightShift", "Insert", "Home", "F6"},
			desc = "Key that shows or hides the whole UI."},
		{t = "toggle", key = "Notifications", title = "Notifications",
			desc = "Shows the small pop up messages like Code Executed."},
	}},
}

local ConfigPanel, ConfigTitle, ConfigTitleIcon, ConfigRows
local menuItems = {}

local function card(parent, h, order)
	local c = new("Frame", {
		Size = UDim2.fromOffset(1538, h), BackgroundColor3 = Color3.fromRGB(28, 28, 32),
		BorderSizePixel = 0, LayoutOrder = order,
	}, parent)
	corner(c, 50)
	new("UIGradient", {
		Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(30, 30, 34), Color3.fromRGB(22, 22, 26)),
	}, c)
	stroke(c, Color3.fromRGB(40, 40, 46), 3)
	return c
end

local function addRowText(c, title, desc, width)
	label(c, title, 40, 28, 1100, 64, 50, WHITE, F_BOLD)
	local d = label(c, desc, 40, 92, width or 1230, 100, 38, DIM, F_REG)
	d.TextWrapped = true
	d.TextYAlignment = Enum.TextYAlignment.Top
end

function refreshConfigRows()
	if not ConfigRows then
		return
	end
	closeDropdowns()
	for _, c in ipairs(ConfigRows:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local cat = CATS[Config.cat]
	local order = 0
	for _, r in ipairs(cat.rows) do
		order = order + 1
		if r.t == "toggle" then
			local c = card(ConfigRows, 200, order)
			addRowText(c, r.title, r.desc)
			toggleWidget(c, 1538 - 69 - 63, 68, function()
				return Settings[r.key]
			end, function(v)
				Settings[r.key] = v
				applySettings(r.key)
			end)
		elseif r.t == "select" then
			local c = card(ConfigRows, 200, order)
			addRowText(c, r.title, r.desc)
			dropdown(c, 1538 - 67 - 240, 60, 240, 80, r.options, Settings[r.key], function(v)
				Settings[r.key] = v
				applySettings(r.key)
				refreshConfigRows()
			end)
		elseif r.t == "theme" then
			local c = card(ConfigRows, 200, order)
			addRowText(c, "Colour Theme", "Colour Theme helps choose between plain mode and gradient mode and change colours of UI elements.", 1030)
			local prev = frame(c, "Preview", 1538 - 67 - 240 - 40 - 64, 68, 64, 64, WHITE, 32)
			accent(prev)
			dropdown(c, 1538 - 67 - 240, 60, 240, 80, {"Gradient", "Plain"}, Settings.Gradient and "Gradient" or "Plain", function(v)
				Settings.Gradient = (v == "Gradient")
				applySettings("Gradient")
				refreshConfigRows()
			end)
		elseif r.t == "gradient" then
			if Settings.Gradient then
				local c = card(ConfigRows, 140, order)
				local res = frame(c, "Result", 1538 - 40 - 76, 32, 76, 76, WHITE, 22)
				accent(res)
				for stop = 2, 1, -1 do
					local bx = 1538 - 40 - 76 - 24 - (3 - stop) * 100 + 0
					local pb = new("TextButton", {
						Name = "Stop" .. stop, Position = UDim2.fromOffset(bx - 76 + 76 - 0, 32), Size = UDim2.fromOffset(76, 76),
						BackgroundColor3 = Color3.fromRGB(26, 26, 31), Text = "", AutoButtonColor = false, BorderSizePixel = 0,
					}, c)
					pb.Position = UDim2.fromOffset(1538 - 40 - 76 - 24 - 76 - (2 - stop) * 100 - (stop == 2 and 0 or 0), 32)
					corner(pb, 22)
					stroke(pb, STROKE_C, 2)
					makeIcon(pb, "Plus", 40, 38, 34, DIM)
					local bar = frame(pb, "Bar", 18, 60, 40, 6, Color3.fromRGB(Settings["C" .. (stop - 1)][1], Settings["C" .. (stop - 1)][2], Settings["C" .. (stop - 1)][3]), 3)
					pb.MouseButton1Click:Connect(function()
						openPicker(stop)
					end)
				end
			else
				order = order - 1
			end
		elseif r.t == "info" then
			local c = card(ConfigRows, 200, order)
			addRowText(c, r.title, r.desc, 1100)
			label(c, r.value, 1538 - 67 - 240, 60, 240, 80, 48, DIM, F_BOLD, Enum.TextXAlignment.Center)
		end
	end
	new("Frame", {Size = UDim2.fromOffset(10, 300), BackgroundTransparency = 1, LayoutOrder = 999, BorderSizePixel = 0}, ConfigRows)
end

function selectCategory(i)
	Config.cat = i
	closeDropdowns()
	for idx, it in ipairs(menuItems) do
		local on = (idx == i)
		tween(it.icon, 0.2, {Position = UDim2.fromOffset(on and 102 or 53, 45)})
		tween(it.text, 0.2, {Position = UDim2.fromOffset(on and 150 or 101, 0)})
		tween(it.dot, 0.2, {BackgroundTransparency = on and 0 or 1})
		local col = on and WHITE or Color3.fromRGB(150, 150, 156)
		setIconColor(it.icon, col)
		it.text.TextColor3 = col
	end
	if ConfigTitle then
		ConfigTitle.Text = CATS[i].name
		ConfigTitleIcon:Destroy()
		ConfigTitleIcon = makeIcon(ConfigPanel, CATS[i].icon, 58, 82, 75, WHITE)
	end
	refreshConfigRows()
end

local function resetAllSettings()
	resetSettingsTable()
	applySettings("Gradient")
	applySettings("Syntax")
	applySettings("FontSize")
	applySettings("AntiAFK")
	refreshConfigRows()
	notify("Settings reset", "info")
end

do
	local page = Pages.ConfigPg
	local ys = {452, 552, 652, 752, 852, 952, 1048}
	for i, cat in ipairs(CATS) do
		local it = frame(page, "Menu" .. cat.name, 160, ys[i] - 45, 500, 90)
		local dot = frame(it, "Dot", 30, 35, 20, 20, WHITE, 10)
		dot.BackgroundTransparency = 1
		local ic = makeIcon(it, cat.icon, 52, 53, 45, Color3.fromRGB(150, 150, 156))
		local tx = label(it, cat.name, 101, 0, 380, 90, 54, Color3.fromRGB(150, 150, 156), F_MED)
		local hit = button(it, "Hit", 0, 0, 500, 90)
		hit.MouseButton1Click:Connect(function()
			selectCategory(i)
		end)
		menuItems[i] = {icon = ic, text = tx, dot = dot}
	end
	frame(page, "Divider", 160, 1117, 500, 2, Color3.fromRGB(45, 45, 50))
	local rs = frame(page, "ResetItem", 160, 1147, 500, 90)
	makeIcon(rs, "Reset", 52, 53, 45, DIM)
	label(rs, "Reset", 101, 0, 380, 90, 54, DIM, F_MED)
	local rh = button(rs, "Hit", 0, 0, 500, 90)
	rh.MouseButton1Click:Connect(resetAllSettings)

	ConfigPanel = panel(page, "SettingsPanel", 760, 400, 1618, 840, 70)
	ConfigPanel.ClipsDescendants = true
	ConfigTitleIcon = makeIcon(ConfigPanel, "Palette", 58, 82, 75, WHITE)
	ConfigTitle = label(ConfigPanel, "Appearance", 148, 35, 900, 80, 66, WHITE, F_MED)
	ConfigRows = new("ScrollingFrame", {
		Name = "Rows", Position = UDim2.fromOffset(40, 130), Size = UDim2.fromOffset(1538, 700),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ClipsDescendants = false,
	}, ConfigPanel)
	ConfigRows.ClipsDescendants = true
	new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 20)}, ConfigRows)
	local fade = frame(ConfigPanel, "Fade", 0, 730, 1618, 110, Color3.fromRGB(17, 17, 20))
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
	}, fade)
end
end

--========================== PAGE SWITCHING ==============================
local PAGE_NAV = {HomePg = 1, CodePg = 2, ConfigPg = 4, ConsolePg = 5}

function showPage(name)
	closeDropdowns()
	for n, f in pairs(Pages) do
		f.Visible = (n == name)
	end
	if name == "HomePg" then
		layoutEditor("home")
	elseif name == "CodePg" then
		layoutEditor("code")
	end
	State.page = name
	setNav(PAGE_NAV[name])
	local pg = Pages[name]
	pg.Position = UDim2.fromOffset(0, 24)
	tween(pg, 0.3, {Position = UDim2.fromOffset(0, 0)})
	if name == "CloudPg" then
		renderCloud()
	elseif name == "ConsolePg" then
		renderConsole()
	end
end

--========================== POPUPS ======================================
local Dim = new("TextButton", {
	Name = "Dim", Size = UDim2.fromOffset(DW, DH), BackgroundColor3 = BLACK, BackgroundTransparency = 1,
	Text = "", AutoButtonColor = false, Visible = false, BorderSizePixel = 0, ZIndex = 1,
}, PopMain)
corner(Dim, 150)

local PopFrames, PopBase, popupOpeners = {}, {}, {}
local currentPopup

local function makePopup(name, x, y, w, h, bare)
	local f
	if bare then
		f = frame(PopMain, name, x, y, w, h)
	else
		f = frame(PopMain, name, x, y, w, h, Color3.fromRGB(21, 21, 25), 100)
		new("UIGradient", {
			Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(25, 25, 29), Color3.fromRGB(17, 17, 20)),
		}, f)
		stroke(f, Color3.fromRGB(36, 36, 41), 2)
	end
	f.Visible = false
	f.ZIndex = 2
	PopFrames[name] = f
	PopBase[name] = f.Position
	return f
end

function openPopup(name)
	closeDropdowns()
	if currentPopup and currentPopup ~= name then
		PopFrames[currentPopup].Visible = false
	end
	currentPopup = name
	local f = PopFrames[name]
	Dim.Visible = true
	tween(Dim, 0.2, {BackgroundTransparency = 0.35})
	if popupOpeners[name] then
		popupOpeners[name]()
	end
	f.Visible = true
	f.Position = PopBase[name] + UDim2.fromOffset(0, 40)
	tween(f, 0.3, {Position = PopBase[name]})
end

function closePopup()
	if not currentPopup then
		return
	end
	PopFrames[currentPopup].Visible = false
	currentPopup = nil
	tween(Dim, 0.2, {BackgroundTransparency = 1})
	task.delay(0.22, function()
		if not currentPopup then
			Dim.Visible = false
		end
	end)
end
Dim.MouseButton1Click:Connect(closePopup)

-------------------- FileExP : search / run picker --------------------
do
local FileEx = makePopup("FileExP", 570, 160, 1400, 1000, true)
local SearchBar = frame(FileEx, "SearchBar", 0, 0, 1400, 200, Color3.fromRGB(21, 21, 25), 100)
stroke(SearchBar, Color3.fromRGB(36, 36, 41), 2)
local SearchPillBg = frame(SearchBar, "Pill", 41, 41, 1157, 118, FILL, 59)
stroke(SearchPillBg, STROKE_C, 2)
makeIcon(SearchPillBg, "Search", 52, 62, 59, DIM)
local FileExBox = new("TextBox", {
	Name = "Query", Position = UDim2.fromOffset(120, 0), Size = UDim2.fromOffset(1010, 118), BackgroundTransparency = 1,
	Text = "", PlaceholderText = "Type to Search..", PlaceholderColor3 = DIM, TextColor3 = WHITE, Font = F_MED,
	TextSize = 54, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0,
}, SearchPillBg)
local GoBtn = frame(SearchBar, "Go", 1239, 41, 121, 121, WHITE, 60)
accent(GoBtn)
local GoHit = button(GoBtn, "Hit", 0, 0, 121, 121)
local GoIcon = makeIcon(GoBtn, "Arrow", 54, 60, 60, DARK_ICON)
local FileExResultsBg = frame(FileEx, "Results", 0, 241, 1400, 759, Color3.fromRGB(21, 21, 25), 100)
stroke(FileExResultsBg, Color3.fromRGB(36, 36, 41), 2)
local FileExResults = new("ScrollingFrame", {
	Name = "List", Position = UDim2.fromOffset(41, 40), Size = UDim2.fromOffset(1318, 679), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ClipsDescendants = true,
}, FileExResultsBg)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 24)}, FileExResults)

local function visibleNodes(query)
	local list = {}
	local q = query:lower()
	local function walk(node, depth)
		for _, c in ipairs(node.children) do
			if q == "" then
				table.insert(list, {node = c, depth = depth})
				if c.kind == "folder" and c.open then
					walk(c, depth + 1)
				end
			else
				if c.name:lower():find(q, 1, true) then
					table.insert(list, {node = c, depth = (c.parent == State.Root) and 0 or 1})
				end
				if c.kind == "folder" then
					walk(c, depth + 1)
				end
			end
		end
	end
	walk(State.Root, 0)
	return list
end

local pendingDelete

local function activateNode(node)
	if node.kind == "folder" then
		node.open = not node.open
		State.selectedFolder = node
		refreshExplorer()
		refreshFileEx()
		return
	end
	closePopup()
	if State.searchMode == "run" then
		runNode(node)
	else
		openFile(node)
	end
end

function refreshFileEx()
	for _, c in ipairs(FileExResults:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local entries = visibleNodes(FileExBox.Text)
	local order = 0
	for _, e in ipairs(entries) do
		order = order + 1
		local node = e.node
		local isRootRow = (node.parent == State.Root)
		local holder = new("Frame", {
			Size = UDim2.new(1, 0, 0, 116), BackgroundTransparency = 1, LayoutOrder = order, BorderSizePixel = 0,
		}, FileExResults)
		local x0 = isRootRow and 0 or 126
		local pw = 1318 - x0
		local pill = frame(holder, "Pill", x0, 0, pw, 116, FILL, 58)
		stroke(pill, STROKE_C, 2)
		if not isRootRow then
			local radio = frame(holder, "Radio", 57, 44, 28, 28, (node == State.active) and WHITE or Color3.fromRGB(34, 34, 38), 14)
			stroke(radio, Color3.fromRGB(50, 50, 56), 2)
		end
		local hit = button(pill, "Hit", 0, 0, pw, 116)
		makeIcon(pill, node.kind == "folder" and "Folder" or "File", 52, 71, 58, WHITE)
		local t = label(pill, node.name, 125, 0, pw - 420, 116, 54, WHITE, F_MED)
		t.TextTruncate = Enum.TextTruncate.AtEnd
		hit.MouseButton1Click:Connect(function()
			activateNode(node)
		end)
		if node.kind == "folder" then
			makeIcon(pill, node.open and "ChevronDown" or "ChevronRight", 46, pw - 60, 58, DIM)
		end
		if not isRootRow then
			local wb = iconButton(pill, "Wand", 50, pw - 232, 58, DIM, function()
				closePopup()
				runNode(node)
			end)
			local tb, tIcon = iconButton(pill, "Trash", 50, pw - 142, 58, DIM, function() end)
			tb.MouseButton1Click:Connect(function()
				if Settings.ConfirmDelete and pendingDelete ~= node then
					pendingDelete = node
					setIconColor(tIcon, ERR)
					task.delay(2, function()
						if pendingDelete == node then
							pendingDelete = nil
							if tIcon.Parent then
								setIconColor(tIcon, DIM)
							end
						end
					end)
					return
				end
				pendingDelete = nil
				deleteNode(node)
			end)
		end
	end
end

local function firstFileResult()
	for _, e in ipairs(visibleNodes(FileExBox.Text)) do
		if e.node.kind == "file" then
			return e.node
		end
	end
	return nil
end

FileExBox:GetPropertyChangedSignal("Text"):Connect(refreshFileEx)
FileExBox.FocusLost:Connect(function(enter)
	if enter then
		local n = firstFileResult()
		if n then
			activateNode(n)
		end
	end
end)
GoHit.MouseButton1Click:Connect(function()
	local n = firstFileResult()
	if n then
		activateNode(n)
	else
		notify("No file found", "warn")
	end
end)
press(GoHit, GoIcon)

popupOpeners.FileExP = function()
	pendingDelete = nil
	FileExBox.Text = ""
	FileExBox.PlaceholderText = (State.searchMode == "run") and "Pick a file to execute.." or "Type to Search.."
	refreshFileEx()
	task.delay(0.35, function()
		if currentPopup == "FileExP" then
			FileExBox:CaptureFocus()
		end
	end)
end

function openFileSearch(mode)
	State.searchMode = mode
	openPopup("FileExP")
end
end

-------------------- FileGenP / FolderGenP ----------------------------
local function makeCreatePopup(name, kind, btnText, placeholder)
	local p = makePopup(name, 570, 440, 1400, 520)
	local nb = frame(p, "NamePill", 40, 40, 1320, 120, FILL, 60)
	stroke(nb, STROKE_C, 2)
	local box = new("TextBox", {
		Name = "Name", Position = UDim2.fromOffset(42, 0), Size = UDim2.fromOffset(1230, 120), BackgroundTransparency = 1,
		Text = "", PlaceholderText = placeholder, PlaceholderColor3 = DIM, TextColor3 = WHITE, Font = F_MED,
		TextSize = 56, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0,
	}, nb)
	local pp = frame(p, "PathPill", 40, 200, 1320, 120, FILL, 60)
	stroke(pp, STROKE_C, 2)
	local pathLbl = label(pp, "", 42, 0, 1230, 120, 54, DIM, F_MED)
	pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
	local create = new("TextButton", {
		Name = "Create", Position = UDim2.fromOffset(40, 360), Size = UDim2.fromOffset(480, 120), BackgroundColor3 = WHITE,
		Text = btnText, Font = F_MED, TextSize = 60, TextColor3 = DARK_ICON, AutoButtonColor = false, BorderSizePixel = 0,
	}, p)
	corner(create, 60)
	accent(create)
	local go = frame(p, "Go", 1240, 360, 120, 120, WHITE, 60)
	accent(go)
	local goHit = button(go, "Hit", 0, 0, 120, 120)
	local goIcon = makeIcon(go, "Arrow", 54, 60, 60, DARK_ICON)
	press(goHit, goIcon)
	local function submit()
		if createNode(kind, box.Text) then
			closePopup()
		end
	end
	create.MouseButton1Click:Connect(submit)
	goHit.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(enter)
		if enter then
			submit()
		end
	end)
	popupOpeners[name] = function()
		box.Text = ""
		local f = State.selectedFolder or State.Root.children[1]
		pathLbl.Text = "Path: " .. nodePath(f)
		task.delay(0.35, function()
			if currentPopup == name then
				box:CaptureFocus()
			end
		end)
	end
end
makeCreatePopup("FileGenP", "file", "Create File", "Enter File Name..")
makeCreatePopup("FolderGenP", "folder", "Create Folder", "Enter Folder Name..")

-------------------- Cloud filter / grid popups -----------------------
local function makeChoicePopup(name, title, options, getCurrent, onPick)
	local h = 190 + #options * 120
	local p = makePopup(name, 869, math.floor((DH - h) / 2), 800, h)
	label(p, title, 60, 40, 680, 90, 58, WHITE, F_BOLD)
	local holder = frame(p, "Options", 0, 150, 800, #options * 120 + 20)
	local function render()
		for _, c in ipairs(holder:GetChildren()) do
			c:Destroy()
		end
		for i, opt in ipairs(options) do
			local on = (tostring(getCurrent()) == tostring(opt))
			local b = new("TextButton", {
				Name = tostring(opt), Position = UDim2.fromOffset(40, (i - 1) * 120), Size = UDim2.fromOffset(720, 100),
				BackgroundColor3 = on and WHITE or FILL, Text = tostring(opt), Font = F_MED, TextSize = 50,
				TextColor3 = on and DARK_ICON or WHITE, AutoButtonColor = false, BorderSizePixel = 0,
			}, holder)
			corner(b, 50)
			if on then
				accent(b)
			else
				stroke(b, STROKE_C, 2)
			end
			b.MouseButton1Click:Connect(function()
				onPick(opt)
				closePopup()
			end)
		end
	end
	popupOpeners[name] = render
end
makeChoicePopup("CloudSFilterP", "Filter by tag", CLOUD_TAGS, function()
	return State.cloudTag
end, function(v)
	State.cloudTag = v
	renderCloud()
end)
makeChoicePopup("CloudGridCtrlP", "Grid columns", {1, 2, 3, 4}, function()
	return State.cloudCols
end, function(v)
	State.cloudCols = tonumber(v) or 3
	renderCloud()
end)

-------------------- ExitP (confirm) ----------------------------------
do
	local p = makePopup("ExitP", 769, 489, 1000, 420)
	label(p, "Close CubiX MAX?", 60, 50, 880, 100, 64, WHITE, F_BOLD)
	local d = label(p, "The UI will be removed. Run the script again to bring it back.", 60, 150, 880, 100, 40, DIM, F_REG)
	d.TextWrapped = true
	d.TextYAlignment = Enum.TextYAlignment.Top
	local cancel = new("TextButton", {
		Name = "Cancel", Position = UDim2.fromOffset(60, 280), Size = UDim2.fromOffset(420, 100), BackgroundColor3 = FILL,
		Text = "Cancel", Font = F_MED, TextSize = 50, TextColor3 = WHITE, AutoButtonColor = false, BorderSizePixel = 0,
	}, p)
	corner(cancel, 50)
	stroke(cancel, STROKE_C, 2)
	local ok = new("TextButton", {
		Name = "Close", Position = UDim2.fromOffset(520, 280), Size = UDim2.fromOffset(420, 100), BackgroundColor3 = WHITE,
		Text = "Close", Font = F_BOLD, TextSize = 50, TextColor3 = DARK_ICON, AutoButtonColor = false, BorderSizePixel = 0,
	}, p)
	corner(ok, 50)
	accent(ok)
	cancel.MouseButton1Click:Connect(closePopup)
	ok.MouseButton1Click:Connect(function()
		for _, c in ipairs(Connections) do
			pcall(function()
				c:Disconnect()
			end)
		end
		Gui:Destroy()
	end)
end

-------------------- GraidentGenP (colour picker) ---------------------
do
local Picker = {h = 0, s = 0, v = 1, stop = 1, drag = nil}
do
	local p = makePopup("GraidentGenP", 719, 320, 1100, 760)
	local title = label(p, "Pick Colour", 50, 30, 700, 80, 58, WHITE, F_BOLD)
	local svArea = frame(p, "SV", 50, 130, 620, 460, Color3.new(1, 0, 0), 28)
	local whiteO = frame(svArea, "White", 0, 0, 620, 460, WHITE, 28)
	new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, whiteO)
	local blackO = frame(svArea, "Black", 0, 0, 620, 460, BLACK, 28)
	new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)}, blackO)
	local knob = frame(svArea, "Knob", 0, 0, 40, 40, nil, 20)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	stroke(knob, WHITE, 5)
	local svHit = button(svArea, "Hit", 0, 0, 620, 460)
	svHit.ZIndex = 5

	local hueBar = frame(p, "Hue", 710, 130, 70, 460, WHITE, 24)
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
	}, hueBar)
	local hueKnob = frame(hueBar, "Knob", 0, 0, 90, 16, WHITE, 8)
	hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	local hueHit = button(hueBar, "Hit", 0, 0, 70, 460)
	hueHit.ZIndex = 5

	local preview = frame(p, "Preview", 830, 130, 220, 150, WHITE, 28)
	local hex = new("TextBox", {
		Name = "Hex", Position = UDim2.fromOffset(830, 305), Size = UDim2.fromOffset(220, 90), BackgroundColor3 = FILL,
		Text = "#FFFFFF", TextColor3 = WHITE, Font = F_CODE, TextSize = 44, ClearTextOnFocus = false, BorderSizePixel = 0,
	}, p)
	corner(hex, 30)
	stroke(hex, STROKE_C, 2)
	local apply = new("TextButton", {
		Name = "Apply", Position = UDim2.fromOffset(830, 425), Size = UDim2.fromOffset(220, 100), BackgroundColor3 = WHITE,
		Text = "Apply", Font = F_BOLD, TextSize = 50, TextColor3 = DARK_ICON, AutoButtonColor = false, BorderSizePixel = 0,
	}, p)
	corner(apply, 50)
	accent(apply)
	local cancel = new("TextButton", {
		Name = "Cancel", Position = UDim2.fromOffset(830, 545), Size = UDim2.fromOffset(220, 90), BackgroundTransparency = 1,
		Text = "Cancel", Font = F_MED, TextSize = 44, TextColor3 = DIM, AutoButtonColor = false, BorderSizePixel = 0,
	}, p)
	label(p, "Drag the square and the bar, or type a hex code.", 50, 630, 1000, 70, 36, DIMMER, F_REG)

	local function toHex(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function refresh()
		local col = Color3.fromHSV(Picker.h, Picker.s, Picker.v)
		svArea.BackgroundColor3 = Color3.fromHSV(Picker.h, 1, 1)
		preview.BackgroundColor3 = col
		hex.Text = toHex(col)
		knob.Position = UDim2.fromOffset(Picker.s * 620, (1 - Picker.v) * 460)
		hueKnob.Position = UDim2.fromOffset(35, Picker.h * 460)
	end
	local function clamp01(x)
		return math.max(0, math.min(1, x))
	end
	local function update(input)
		local pos = pointerPos(input)
		if Picker.drag == "sv" then
			local rel = (pos - svArea.AbsolutePosition) / svArea.AbsoluteSize
			Picker.s = clamp01(rel.X)
			Picker.v = 1 - clamp01(rel.Y)
		elseif Picker.drag == "hue" then
			local rel = (pos - hueBar.AbsolutePosition) / hueBar.AbsoluteSize
			Picker.h = math.min(0.999, clamp01(rel.Y))
		end
		refresh()
	end
	svHit.InputBegan:Connect(function(input)
		if isPress(input) then
			Picker.drag = "sv"
			update(input)
		end
	end)
	hueHit.InputBegan:Connect(function(input)
		if isPress(input) then
			Picker.drag = "hue"
			update(input)
		end
	end)
	conn(UserInputService.InputChanged:Connect(function(input)
		if Picker.drag and isMove(input) then
			update(input)
		end
	end))
	conn(UserInputService.InputEnded:Connect(function(input)
		if isPress(input) then
			Picker.drag = nil
		end
	end))
	hex.FocusLost:Connect(function()
		local s = hex.Text:gsub("#", "")
		if #s == 6 and s:match("^%x+$") then
			local r = tonumber(s:sub(1, 2), 16)
			local g = tonumber(s:sub(3, 4), 16)
			local b = tonumber(s:sub(5, 6), 16)
			Picker.h, Picker.s, Picker.v = Color3.fromRGB(r, g, b):ToHSV()
			if Picker.h >= 1 then
				Picker.h = 0.999
			end
		end
		refresh()
	end)
	apply.MouseButton1Click:Connect(function()
		local c = Color3.fromHSV(Picker.h, Picker.s, Picker.v)
		Settings["C" .. (Picker.stop - 1)] = {
			math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5),
		}
		applyTheme()
		scheduleSave()
		closePopup()
		refreshConfigRows()
	end)
	cancel.MouseButton1Click:Connect(closePopup)

	function openPicker(stop)
		Picker.stop = stop
		local s = Settings["C" .. (stop - 1)]
		Picker.h, Picker.s, Picker.v = Color3.fromRGB(s[1], s[2], s[3]):ToHSV()
		if Picker.h >= 1 then
			Picker.h = 0.999
		end
		title.Text = "Pick Colour  -  Stop " .. stop
		refresh()
		openPopup("GraidentGenP")
	end
end
end

--========================== APPLY SETTINGS ==============================
local afkConn
local function updateAntiAfk()
	if afkConn then
		afkConn:Disconnect()
		afkConn = nil
	end
	if Settings.AntiAFK then
		afkConn = LocalPlayer.Idled:Connect(function()
			pcall(function()
				local vu = game:GetService("VirtualUser")
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end)
		end)
	end
end

local function updateFpsCap()
	if typeof(setfpscap) == "function" then
		pcall(setfpscap, tonumber(Settings.FPSCap) or 0)
	end
end

function applySettings(key)
	if key == "Syntax" or key == "FontSize" or key == "WordWrap" then
		applyEditorLook()
	elseif key == "Gradient" or key == "C0" or key == "C1" then
		applyTheme()
	elseif key == "AntiAFK" then
		updateAntiAfk()
	elseif key == "FPSCap" then
		updateFpsCap()
	elseif key == "ShowExt" then
		refreshExplorer()
	elseif key == "MaxLines" then
		renderConsole()
	end
	scheduleSave()
end

--========================== UIBn (FLOATING TOGGLE) ======================
do
local UIBn = new("TextButton", {
	Name = "UIBn", Position = UDim2.fromOffset(14, 70), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = BLACK,
	Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 20,
}, Gui)
corner(UIBn, 27)
stroke(UIBn, Color3.fromRGB(60, 60, 66), 2)
local UIBnIcon = makeIcon(UIBn, "Logo", 32, 27, 27, WHITE)
local function toggleUI()
	local vis = not UIHolder.Visible
	UIHolder.Visible = vis
	PopHolder.Visible = vis
end
UIBn.MouseButton1Click:Connect(toggleUI)

conn(UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.Escape and currentPopup then
			closePopup()
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		local ok, code = pcall(function()
			return Enum.KeyCode[Settings.Keybind]
		end)
		if ok and code and input.KeyCode == code then
			toggleUI()
		end
	end
end))
end

--========================== STARTUP =====================================
applyEditorLook()
refreshExplorer()
selectCategory(1)
renderCloud()
showPage("HomePg")
if State.active then
	setEditorText(State.active.content)
end
updateAntiAfk()
updateFpsCap()

addLog("Info", "CubiX MAX loaded.")
do
local okLS = pcall(function()
	return loadstring("return 1")()
end)
if not okLS then
	addLog("Warn", "loadstring is not available here, so Execute cannot run code in this environment.")
end
end

if Settings.AutoExecute then
	local auto = findChild(State.Root, "Auto Execute")
	if auto then
		task.delay(1, function()
			runNode(auto)
		end)
	end
end

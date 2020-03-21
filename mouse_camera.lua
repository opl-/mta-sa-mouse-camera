--[[
	Quick explanation of how translating the camera works:
	- The first time the mouse button is held down, the moveCenter is set
	- Every time the mouse is moved, the camera is moved by the relative change between the center and the current cursor position
	- The camera is now positioned so that the cursor is once again pointing at the moveCenter
]]

local TAU = math.pi / 2

-- SETTINGS

-- Horizontal rotation sensitivity. Rotation is inverted if this value is negative.
local OPT_SENSITIVITY_X = 1

-- Vertical rotation sensitivity. Rotation is inverted if this value is negative.
local OPT_SENSITIVITY_Y = 1

-- Normal zoom speed.
local OPT_ZOOM_SENSITIVITY = 7

-- Zoom speed with a modifier (left shift).
local OPT_ZOOM_MOD_SENSITIVITY = 1

-- Not recommended, the vertical rotation is really awkward and basically broken.
local OPT_ROTATE_AROUND_CURSOR = false


-- VARIABLES

local shiftModifier = false

-- The center point of the camera move, relative to which the change is calculated. It also determines the Z coord of the move plane. If false, not moving. If nil, move is just starting.
local moveCenter = false

-- The point on the screen which was clicked at the start of the rotation or false if not rotating.
local rotateCenter = false

local editorSuspended = false

-- MATH

local function rayPlaneIntersect(rayStart, rayEnd, planePos, planeNormal)
	local rayDir = (rayEnd - rayStart):getNormalized()

	local rel = planePos - rayStart
	local relD = rel:dot(planeNormal)
	if relD == 0 then return rayStart, 0 end

	local x = rayDir:dot(planeNormal)
	if x == 0 then return false, false end

	local d = relD / x

	return rayStart + rayDir * d, d
end

local function rayWorldIntersect(rayStart, rayPoint)
	local hit, hitX, hitY, hitZ = processLineOfSight(rayStart, rayStart + (rayPoint - rayStart):getNormalized() * 1000, true, true, true, false, false)
	if not hit then return false end

	local pos = Vector3(hitX, hitY, hitZ)

	if (pos - rayStart):getSquaredLength() < 0.01 then return false end

	return pos
end

local function getCameraPos()
	local cameraPosX, cameraPosY, cameraPosZ, cameraTargetX, cameraTargetY, cameraTargetZ = getCameraMatrix()

	local cameraPos = Vector3(cameraPosX, cameraPosY, cameraPosZ)
	local cameraTarget = Vector3(cameraTargetX, cameraTargetY, cameraTargetZ)

	return cameraPos, cameraTarget
end

local function rotateAroundBackup(pos, center, rotation)
	local rotateDiff = rotateCenter - Vector2(absX, absY)
	local rel = cameraPos - moveCenter

	-- Change the last - sign here if you want to invert rotation direction
	local rotZ = math.atan2(rel.y, rel.x) - rotateDiff.x / 100
	local rotV = TAU - math.asin(rel:getNormalized().z) - rotateDiff.y / 100

	rotV = math.max(0.001, math.min(rotV, math.pi - 0.001))

	local relPos = Vector3(math.cos(rotZ) * math.sin(rotV), math.sin(rotZ) * math.sin(rotV), math.cos(rotV)) * rel:getLength()
end

local function rotateAround(pos, center, rotation)
	local rel = pos - center

	local rotZ = math.atan2(rel.y, rel.x) + rotation.x
	local rotV = TAU - math.asin(rel:getNormalized().z) + rotation.y

	rotV = math.max(0.001, math.min(rotV, math.pi - 0.001))

	local relPos = Vector3(math.cos(rotZ) * math.sin(rotV), math.sin(rotZ) * math.sin(rotV), math.cos(rotV)) * rel:getLength()

	return center + relPos
end

-- CONTROLS

local function handleShiftModifier(key, keyState)
	shiftModifier = keyState == "down"
end

local function handleCameraMove(key, keyState)
	if keyState == "down" then
		-- drag just started
		moveCenter = nil

		if not shiftModifier then
			rotateCenter = nil
		end
	elseif keyState == "up" then
		-- drag is ending
		moveCenter = false
		rotateCenter = false
	end
end

local function handleCameraZoom(key)
	local cameraPos, cameraTarget = getCameraPos()

	local scrollSensitivity = shiftModifier and OPT_ZOOM_MOD_SENSITIVITY or OPT_ZOOM_SENSITIVITY
	local change = (cameraTarget - cameraPos):getNormalized() * (key == "mouse_wheel_up" and 1 or -1) * scrollSensitivity

	setCameraMatrix(cameraPos + change, cameraTarget + change)
end

local keybinds = {
	modifierLShift = {key = "lshift", keyState = "both", handler = handleShiftModifier},
	moveCamera = {key = "mouse3", keyState = "both", handler = handleCameraMove},
	zoomOut = {key = "mouse_wheel_down", keyState = "down", handler = handleCameraZoom},
	zoomIn = {key = "mouse_wheel_up", keyState = "down", handler = handleCameraZoom},
}

local function bindKeys()
	for name, keybind in pairs(keybinds) do
		bindKey(keybind.key, keybind.keyState or "up", keybind.handler)
	end
end

local function unbindKeys()
	for name, keybind in pairs(keybinds) do
		unbindKey(keybind.key, keybind.keyState or "up", keybind.handler)
	end
end

addEventHandler("onClientCursorMove", root, function(relX, relY, absX, absY, worldX, worldY, worldZ)
	if editorSuspended or moveCenter == false and rotateCenter == false then return end

	local cameraPos, cameraTarget = getCameraPos()

	if rotateCenter ~= false then
		if moveCenter == nil then
			local hit = rayWorldIntersect(cameraPos, OPT_ROTATE_AROUND_CURSOR and Vector3(worldX, worldY, worldZ) or cameraTarget)
	
			moveCenter = hit or (cameraPos + (cameraTarget - cameraPos):getNormalized())
		end

		if rotateCenter ~= nil then
			local rotateDiff = rotateCenter - Vector2(absX, absY)

			local rotation = Vector2(rotateDiff.x / -100 * OPT_SENSITIVITY_X, rotateDiff.y / -100 * OPT_SENSITIVITY_Y)

			local newCameraPos = rotateAround(cameraPos, moveCenter, rotation)
			local newCameraTarget = OPT_ROTATE_AROUND_CURSOR and rotateAround(cameraTarget, moveCenter, rotation) or moveCenter

			setCameraMatrix(newCameraPos, newCameraTarget)
		end

		rotateCenter = Vector2(absX, absY)
	elseif moveCenter ~= false then
		if moveCenter == nil then
			local hit = rayWorldIntersect(cameraPos, Vector3(worldX, worldY, worldZ))
	
			moveCenter = hit or (cameraPos + (Vector3(worldX, worldY, worldZ) - cameraPos):getNormalized() * 50)
		end

		local pos, distance = rayPlaneIntersect(cameraPos, Vector3(worldX, worldY, worldZ), Vector3(0, 0, moveCenter.z), Vector3(0, 0, 1))
		if distance <= 0 then return end

		-- If moving more than 150 units, don't.
		if (moveCenter - pos):getSquaredLength() > 22500 then
			outputChatBox("Moved too much. Limiting move to prevent game-killing lag.")
			return
		end

		local moveChange = moveCenter - pos
		setCameraMatrix(cameraPos + moveChange, cameraTarget + moveChange)
	end
end)

local function updateKeys()
	if editorSuspended or getElementData(localPlayer, "freecam:state") then
		unbindKeys()
	else
		bindKeys()
	end
end

addEventHandler("onClientElementDataChange", localPlayer, function(key, oldValue, newValue)
	if key ~= "freecam:state" then return end

	updateKeys()
end)

addEvent("onEditorResumed")
addEventHandler("onEditorResumed", root, function()
	editorSuspended = false

	updateKeys()
end)

addEvent("onEditorSuspended")
addEventHandler("onEditorSuspended", root, function()
	editorSuspended = true

	updateKeys()
end)

updateKeys()

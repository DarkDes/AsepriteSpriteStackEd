----------------------------------------------------------------------
-- Sprite Stack Viewer by DarkDes
-- v021 -- 06 08 2023
-- v020 -- 29 07 2023
-- v015 -- 28 07 2023
-- v011 -- 27 07 2023
-- v010 -- 26 07 2023
-- v000 -- 25 07 2023
----------------------------------------------------------------------

-- Requires v1.3-rc2 API
if app.apiVersion < 22 then
    return app.alert("This script requires Aseprite v1.3-rc2")
end

-- This script requires UI
if not app.isUIAvailable then
    return
end

-- Requires Sprite 
if app.sprite == nil then
	app.alert("WARNING: You should open a sprite first.")
	return
end

-- EVENTS pt1
function ev_dialog_repaint(ev)
	if dialog ~= nil and dialog.data["check_auto_repaint"] then
		dialog:repaint()
	end
end

function events_off()
	app.events:off(ev_sitechange_on)
	app.events:off(ev_dialog_repaint)
	app.sprite.events:off(ev_dialog_repaint)
	--print("off")
end
-- End EVENTS pt1

-- DIALOG OBJECT
local dialog = Dialog{title = "SpriteStack Previewer", onclose=events_off}
local mouse = {position = Point(0, 0), drag_position = Point(0,0), leftClick = false}

-- Global & Constants
local canvas_w = 128
local canvas_h = 128

local spritestack = {}
local settings = {} -- same as dialog.data ?

local sprite = nil
local ssprite_angle = 0

local sprite_fakez_distance = 1
local sprite_fill_distance_slices = true

-- Images 
local bufferImage = Image(1, 1, ColorMode.RGB) -- Contains a image of frame (Sprite)
local rotatedBufferImage = Image(1, 1, ColorMode.RGB) -- Contains a rotated image of Sprite (bufferImage)


-- Rotate point(px,py) around pivot point(cx, cy) by angle.
function rotate_point(cx, cy, angle, px, py)
	local s = math.sin(angle)
	local c = math.cos(angle)
	-- translate point back to origin:
	px = px - cx
	py = py - cy
	-- rotate point
	local xnew = px * c - py * s
	local ynew = px * s + py * c
	-- translate point back:
	px = xnew + cx
	py = ynew + cy
	return {x=px, y=py}
end

local buffer_index = 1
local prev_sprite_angle = -1
local frame_buffer = {}

function step_frame_buffer()
	-- Draw SpriteStack:
	local sprite_angle_rad = math.rad(ssprite_angle)

	-- Height divide control
	local height_modify = 1.0
	local size_modify = 1
	if dialog.data["check_divy"] then height_modify = 0.5 end
	if dialog.data["check_double_size"] then size_modify = 2 end
	
	local rotatedSpriteImageRect 	= Rectangle(0, 0, rotatedBufferImage.width, rotatedBufferImage.height)
	local rotatedImageDisplayWidth 	= rotatedBufferImage.width * size_modify
	local rotatedImageDisplayHeight = rotatedBufferImage.height * size_modify * height_modify
	local position_x 				= canvas_w/2 - rotatedImageDisplayWidth/2 + dialog.data["slider_shift_x"]
	local position_y 				= canvas_h/2 - rotatedImageDisplayHeight/2 * height_modify + dialog.data["slider_shift_y"]
	
	local sprite_slice_depth = 0
	if dialog.data["check_solid_zsteps"] then sprite_slice_depth = size_modify * sprite_fakez_distance end

	if buffer_index > #sprite.frames then
		buffer_index = 1
		dialog:repaint()
	end
	
	-- Draw Sprite to Buffer Image
	bufferImage:drawSprite(sprite, buffer_index)

	-- Draw rotated pixels from Buffer Image to Rotate Image (Buffer2)
	rotate_pixels(bufferImage, frame_buffer[buffer_index], sprite_angle_rad)

	buffer_index = buffer_index + 1
end

-- Rotate Pixels from ImageA to ImageB
function rotate_pixels(image_a, image_b, angle_radians)
	local pivotx = image_b.width / 2
	local pivoty = image_b.height / 2
	local shiftx = image_a.width / 2
	local shifty = image_a.height / 2
	
	image_b:clear()
	local maskColor = image_a.spec.transparentColor
	for it in image_b:pixels() do
		local newpoint = rotate_point( pivotx, pivoty, angle_radians, it.x, it.y )
		newpoint.x = newpoint.x - pivotx + shiftx
		newpoint.y = newpoint.y - pivoty + shifty
		
		--if image_a.bounds.contains(Rectangle(newpoint.x,newpoint.y,1,1)) then --
		if newpoint.x < image_a.width and newpoint.y < image_a.height and newpoint.x >= 0 and newpoint.y >= 0 then
			local pixelValue = image_a:getPixel(newpoint.x, newpoint.y)
			image_b:drawPixel(it.x, it.y, pixelValue)
		end
	end
end
-- End

function setup_spritestack()

	if sprite ~= nil then
		sprite.events:off(ev_dialog_repaint)
	end
	
	sprite = app.sprite
	sprite.events:on('change',ev_dialog_repaint)

	-- Image
	if bufferImage.width ~= sprite.width or bufferImage.height ~= sprite.height then
		bufferImage:resize(sprite.width, sprite.height)
	end

	-- Change bufferedImage size
	local target_widthheight = math.ceil(math.sqrt(sprite.width*sprite.width + sprite.height*sprite.height))
	rotatedBufferImage:clear()
	if( rotatedBufferImage.width ~= target_widthheight or rotatedBufferImage.height ~= target_widthheight ) then
		rotatedBufferImage:resize( target_widthheight, target_widthheight )
	end

	-- Allocate buffers for each layer (frame)
	frame_buffer = {}
	for i,frame in ipairs(sprite.frames) do
		table.insert(frame_buffer, Image(target_widthheight, target_widthheight, ColorMode.RGB))
	end

	-- update dialog elements
	if dialog.data["slider_frame"] ~= nil then
		dialog:modify{id="slider_frame", max = #sprite.frames, value = app.frame }
	end
end

-- Start
setup_spritestack()

-- Canvas
dialog
:canvas{
	id = "canvas",
	width = canvas_w,
	height = canvas_h,
	hexpand = false,
	vexpand = false,
	
	-- Update information about left mouse button being pressed
	onmousedown = function(ev)
		mouse.leftClick = ev.button == MouseButton.LEFT
		mouse.drag_position = Point(ev.x, ev.y)
		mouse.old_angle = ssprite_angle
	end,
	-- Update the mouse position
	onmousemove = function(ev)
		mouse.position = Point(ev.x, ev.y)
		if mouse.leftClick then
			-- New angle value
			ssprite_angle = mouse.old_angle + 360*(mouse.position.x- mouse.drag_position.x)/canvas_w
			ssprite_angle = math.fmod(ssprite_angle+360, 360)
			ssprite_angle = math.floor(ssprite_angle)

			dialog:modify{ id = "slider_angle", value = ssprite_angle }
		end
	end,
	-- When releasing left mouse button
	onmouseup = function(ev)
		mouse.leftClick = false
	end,
	
	-- Redraw function
	onpaint = function(ev)
		local gc = ev.context
		
		-- Draw RoundRect Zone
		local canvas_round_rect = Rectangle(0, 0, canvas_w, canvas_h)
		gc.color = Color(255, 255, 255, 255)
		gc:roundedRect(canvas_round_rect, 16, 16)
		gc:fill()
		gc:clip()
		
		-- Background Grid
		local color_a = Color{gray=180, alpha=255} -- 0x3e3546
		local color_b = Color{gray=150, alpha=255} -- 0x625565
		local colors = {color_a, color_b}
		local size = 16
		for i=0, canvas_w/size, 1 do
			for j=0, canvas_w/size, 1 do
				gc.color = colors[(i+j)%2 + 1]
				gc:fillRect(Rectangle(i * size, j*size, size, size))
			end
		end
		gc:restore()
		gc.color = Color(255, 255, 255, 255)
		-- End Draw RoundRect Zone
		
		-- Draw SpriteStack:
		local sprite_angle_rad = math.rad(ssprite_angle)

		-- Height divide control
		local height_modify = 1.0
		local size_modify = 1
		if dialog.data["check_divy"] then height_modify = 0.5 end
		if dialog.data["check_double_size"] then size_modify = 2 end
		
		local rotatedSpriteImageRect 	= Rectangle(0, 0, rotatedBufferImage.width, rotatedBufferImage.height)
		local rotatedImageDisplayWidth 	= rotatedBufferImage.width * size_modify
		local rotatedImageDisplayHeight = rotatedBufferImage.height * size_modify * height_modify
		local position_x 				= canvas_w/2 - rotatedImageDisplayWidth/2 + dialog.data["slider_shift_x"]
		local position_y 				= canvas_h/2 - rotatedImageDisplayHeight/2 * height_modify + dialog.data["slider_shift_y"]
		
		local sprite_slice_depth = 0
		if dialog.data["check_solid_zsteps"] then sprite_slice_depth = size_modify * sprite_fakez_distance end
		
		-- Function Draw rotated image to the canvas
		local function draw_sprite_on_canvas(frame_index)
			-- Draw Sprite to Buffer Image
			bufferImage:drawSprite(sprite, frame_index)
			
			-- Draw rotated pixels from Buffer Image to Rotate Image (Buffer2)
			rotate_pixels(bufferImage, rotatedBufferImage, sprite_angle_rad)
			
			-- Draw Rotated Image to Canvas
			for j=sprite_slice_depth, 0, -1 do 
				gc:drawImage(rotatedBufferImage, rotatedSpriteImageRect, Rectangle(position_x, position_y - frame_index*size_modify*sprite_fakez_distance + j, rotatedImageDisplayWidth, rotatedImageDisplayHeight))
			end
		end
		
		-- Draw one Slice (Frame)
		if dialog.data["check_only_one_slice"] then
			local frame_index = app.frame.frameNumber -- dialog.data["slider_frame"]
			draw_sprite_on_canvas(frame_index)
		else
			if async_rendering_timer.isRunning then
				-- Copy frame buffer onto canvas
				for i,frame in ipairs(sprite.frames) do
					for j=sprite_slice_depth, 0, -1 do 
						gc:drawImage(
							frame_buffer[i], 
							rotatedSpriteImageRect, 
							Rectangle(
								position_x, 
								position_y - i*size_modify*sprite_fakez_distance + j, 
								rotatedImageDisplayWidth, 
								rotatedImageDisplayHeight))
					end
				end
			else
				-- Each FRAME draw ...
				for i,frame in ipairs(sprite.frames) do
					draw_sprite_on_canvas(i)
				end
			end
		end
	end
}
-- UI Elements Declaration
dialog
:separator{
	id = "sep_angle",
	text = "Angle"
}
dialog
:slider{
    id = "slider_angle",
    min = 0,
    max = 360,
    value = 0,
    visible = true,
    onchange = function() 
		ssprite_angle = dialog.data["slider_angle"]
		--sprite_cache_angle_sprite(ssprite_angle)
		dialog:repaint()
	end
}
dialog
:check{ id="check_auto_angle",
	text="Rotation Animation",
	selected=false,
	onclick=function()
		if dialog.data["check_auto_angle"] == true then
			angle_animation_timer:start()
		else
			angle_animation_timer:stop()
		end
	end
}
dialog
:separator{
	id = "sep_slice",
	text = "Slice"
}
dialog
:check{ id="check_only_one_slice",
	text="Draw Only Selected Slice",
	selected=false,
	onclick=function()
		dialog:modify{id="slider_frame", enabled = dialog.data["check_only_one_slice"]}
		dialog:repaint()
	end
}
:slider{
	id = "slider_frame",
	text = "Frame:",
	min = 1,
	max = #sprite.frames,
	value = app.frame,
	visible = true,
	enabled = false,
	onchange = function() 
		app.frame = dialog.data["slider_frame"]
		dialog:repaint()
	end
}

dialog
:separator{
	id = "sep_distance",
	text = "Z Distance, Height"
}
dialog
:slider{
	id = "slider_fakez",
	min = 0,
	max = 32,
	value = sprite_fakez_distance,
	visible = true,
	onchange = function() 
		sprite_fakez_distance = dialog.data["slider_fakez"]
		dialog:repaint()
	end
}
dialog
:check{ id="check_solid_zsteps",
	text="Draw slice as solid block",
	selected=false,
	onclick=function()
		dialog:repaint()
	end
}
dialog:newrow()
dialog
:check{ id="check_divy",
	text="Half Sprite Height",
	selected=false,
	onclick=function()
		dialog:repaint()
	end }
dialog:newrow()
dialog
:check{ id="check_double_size",
	text="Double Size",
	selected=false,
	onclick=function()
		dialog:repaint()
	end }
	
dialog
:separator{
	id = "sep_shift",
	text = "Shift Sprite Position"
}
dialog
:slider{
	id = "slider_shift_x",
	min = -canvas_w/2,
	max = canvas_w/2,
	value = 0,
	onchange = function() 
		dialog:repaint()
	end
}
dialog
:slider{
	id = "slider_shift_y",
	min = -canvas_h/2,
	max = canvas_h/2,
	value = 0,
	onchange = function() 
		dialog:repaint()
	end
}
-- dialog
-- :separator{
	-- id = "sep_visualize",
	-- text = "Auto-Update"
-- }
dialog
:separator{
	id = "sep_update",
	text = "Update & Repaint"
}
dialog
:check{ id="check_auto_repaint",
	text="Auto-Repaint",
	selected=false,
	onclick=function(v)
		if dialog.data["check_auto_repaint"] == true then
			async_rendering_timer:start()
		else
			async_rendering_timer:stop()
		end
	end
}

-- Async rendering timer
async_rendering_timer =
Timer{
	interval=0.0,
	ontick = function()
		step_frame_buffer()
	end
}
dialog
:button{
	id = "button_update",
	text = "UPDATE",
	onclick = function()
		setup_spritestack()
		dialog:repaint()
	end
}
dialog
:button{
	id = "button_repaint",
	text = "REPAINT",
	onclick = function()
		dialog:repaint()
	end
}
-- End UI Elements Declaration

-- Rotation Animation Timer
angle_animation_timer =
Timer{
	interval=1.0/15.0,
	ontick = function()
		ssprite_angle = math.fmod(ssprite_angle + 1 + 360, 360)
		dialog:modify{id="slider_angle", value = ssprite_angle}
		dialog:repaint()
	end}
-- End Rotation Timer

-- EVENTS pt2
local oldSprite = app.sprite

function ev_sitechange_on(ev)
	if app.frame ~= nil then
		dialog:modify{id="slider_frame", value = app.frame.frameNumber}
	end
	
	if app.sprite ~= oldSprite then
		-- print("Sprite changed")
		setup_spritestack()
		dialog:repaint()
		oldSprite = app.sprite
	end
end



function events_on()
	app.events:on('sitechange', ev_sitechange_on)
	app.events:on('aftercommand',ev_dialog_repaint)
	app.sprite.events:on('change',ev_dialog_repaint)
end
-- End EVENTS pt2
events_on()

-- Show Sprite Stack Visualizer
dialog:show{ wait=false }

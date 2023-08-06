----------------------------------------------------------------------
-- Sprite Stack Slicer by DarkDes
-- v010 -- 05 08 2023
----------------------------------------------------------------------

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

-- Setup
local oldSprite = app.sprite
local oldFrame = app.frame
local newSprite = Sprite(app.sprite.width, app.sprite.height, app.sprite.colorMode)
newSprite:setPalette( oldSprite.palettes[1] )

-- Create bufferImage of the current Sprite
app.sprite = oldSprite
bufferImage = Image(oldSprite.width, oldSprite.height, oldSprite.colorMode)
bufferImage:drawSprite(oldSprite, oldFrame.frameNumber)

-- 'Copy' each vertical line of Image and 'paste' as a new frame of newSprite
for yy=1, bufferImage.height do
	local frame = newSprite:newEmptyFrame(newSprite.frames.frameNumber)
	
	--local iterator = bufferImage:pixels(Rectangle(0,yy,bufferImage.width, 1))
	
	if not bufferImage:isEmpty() then
		local cel = newSprite:newCel(newSprite.layers[1], frame)
		-- Copy Line of Image to Line of new Sprite
		for it in bufferImage:pixels(Rectangle(0,yy,bufferImage.width, 1)) do
		-- for xx=0, newSprite.width do
			for h=0, newSprite.height do
				cel.image:drawPixel(it.x, h, it())
			end
		end
	end
end
-- Delete extra Frame
newSprite:deleteFrame(newSprite.frames[1])
app.sprite = newSprite
## Gizmo
gizmo allows you to render 3D debug information on the screen known as gizmos.

## Usage
gizmos are only rendered for a single frame, this makes them easy to manage as they'll be cleaned up for you automatically. On the flip-side this means you need to call your draw method at least once per frame to make sure the gizmo is rendered continuously.

```lua
RunService:BindToRenderStep("DrawGizmos", 200, function ()
	gizmo.drawRay(ray.Origin, ray.Direction)
end)
```

By default, gizmos are not shown to the user. You must enable them. This can be done through the [studio plugin](https://www.roblox.com/library/6277906195/gizmo) or the following line of code:

```lua
workspace:SetAttribute("GizmosEnabled", true)
```

## Draw Methods
#### drawBox(CFrame orientation, Vector3 size)
Draws a box at a coordinate frame with a given size

#### drawWireBox(CFrame orientation, Vector3 size)
Draws a wire-box at a coordinate frame with a given size

#### drawSphere(CFrame orientation, int radius)
Draws a sphere at a coordinate frame with a given size

#### drawWireSphere(CFrame orientation, int radius)
Draws a wire-sphere at a coordinate frame with a given size

#### drawPoint(Vector3 position)
Draws a point at a position

#### drawLine(Vector3 from, Vector3 to)
Draws a line between two positions

#### drawArrow(Vector3 from, Vector3 to)
Draws an arrow between two positions

#### drawRay(Vector3 from, Vector3 direction)
Draws an arrow between from a position in a direction

_Note: The length of the ray is determined by the magnitude of direction_

#### drawText(Vector3 position, string formatText, ...formatParams)
Draws some text at the position, formatted with the specified parameters.

#### clear()
Clears all gizmos that are due to be rendered

## Style Methods
gizmos can be styled by calling any of the following style methods before your draw method

#### setColor(string brickColorName)
Sets the draw color to the Color3 that corresponds to the given brick-color

#### setColor3(Color3 color)
Sets the draw color of the gizmos

#### setTransparency
Sets the transparency of the gizmos

#### setOrigin(CFrame origin)
Assigns an offset from which all gizmos will be drawn relative to

#### setLayer(int layer)
Sets the ZIndex draw layer for the gizmos

#### setScale(float scale)
Sets the scale that gizmos should be drawn at

_Note: This won't affect the length or size of gizmos, just their thickness_

#### reset()
Resets the current style back to the default

local Components	= script:FindFirstAncestor("Components")
local Roact			= require(Components.Roact)
local Wormhole		= Roact.PureComponent:extend("Wormhole")
local MountEvent	= Roact.Event.Mounted
local UpdateEvent	= Roact.Event.Updated
local UnmountEvent	= Roact.Event.Unmounting

Wormhole.defaultProps = {
	[MountEvent] = nil,
	[UpdateEvent] = nil,
	[UnmountEvent] = nil,
}

function Wormhole:invoke(event, ...)
	local callback = self.props[event]
	if callback then
		callback(...)
	end
end

function Wormhole:init()
	self.parentRef = Roact.createRef()
end

function Wormhole:render()
	return Roact.createElement("Folder", {
		[Roact.Ref] = self.parentRef -- mount a folder to get an rbx ref to the container
	})
end

function Wormhole:didUpdate()
	self:invoke(UpdateEvent, self.parentRef:getValue())
end

function Wormhole:didMount()
	self:invoke(MountEvent, self.parentRef:getValue())
end

function Wormhole:willUnmount()
	self:invoke(UnmountEvent, nil)
end

return Wormhole

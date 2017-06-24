# Actions
Allows you to bind an action to multiple events in order to reduce code and make dealing with multiple devices easier.

## Documentation
There are two main objects, the module itself and an action.
### Module
#### action CreateAction(string name, function action)
Creates a new action which can be bound to events, accepts a string name to identify it and a callback function that will run everytime one of the bound events is fired.

The first parameter passed to the callback is the name of the event that called it.
```lua
local reset = actions:CreateAction("Reset", function ()
	local player = game:GetService'Players'.LocalPlayer
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass'Humanoid'
	if humanoid then
		humanoid.Health = 0
	end
end)
```
#### action GetAction(string name)
Retrieves a previously created action or errors if the action does not exist.
### Action
#### void Bind(RBXScriptSignal signal, function check)
Binds the action to the specified signal.
```lua
reset:Bind(gui.Button.MouseButton1Down)
```
The second parameter, check, is optional and can be used to check the events parameters before returning true or false as to whether or not to fire an action.
```lua
reset:Bind(userInputService.InputBegan, function (input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Keyboard
		and input.KeyCode == Enum.KeyCode.R
end)
```
#### void BindToInput(table inputMap)
Binds the action to input from UserInputService by mapping properties from a table onto the object and checking if they match.
```lua
reset:BindToInput({
	UserInputState = Enum.UserInputState.Begin,
	UserInputType = Enum.UserInputType.Keyboard,
	KeyCode = Enum.KeyCode.R
})
```
#### void SetActive(bool active)
Sets whether the action is enabled or disabled.

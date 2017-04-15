# Sockets
Sockets is a module that serves as an alternative method of communication between the client and server on ROBLOX.

## Updates
04/15/17
  - Groups - These allow you to group requests of similar purpose together.
  - Rooms - Clients can now be assigned to a room that you can send requests to.

## Documentation
### At a glance
Server
```lua
local sockets = require('server.lua')
sockets.Connected:connect(function (socket)

    local player = socket.Player
    print(player, "has connected")
    
    socket:Listen("Message", function (msg)
        print(player, "said", msg)
    end)
    
    socket:Listen("Double", function (n)
        return n + n
    end)
    
    socket.Disconnected:connect(function ()
        print(player, "has disconnected")
    end
    
end)
```
Client
```lua
local socket = require('client.lua')
socket:Emit("Message", "Howdy")
print(socket:Request("Double", 5))
```
Output
```
Player has connected
Player said Howdy
10
Player has disconnected
```
### Installation
The `server.lua` file should be placed somewhere your server scripts can access it. `client.lua` should be placed somewhere that constantly exists on the client, such as PlayerScripts.
### Module
This is returned when you require `server.lua`. It has multiple methods  that allow you to interact with multiple clients at once and allows you to listen for new connections.
#### Events
##### Connected
The connected event fires when a player opens a new connection with the sockets module. This will typically fire after PlayerAdded so be sure to check for this.
```lua
sockets.Connected:connect(function (socket)
    local player = socket.Player
    print(player, "has connected")
end)
```
#### Methods
##### Socket GetSocket(player)
This method returns the socket for the given player or nil if they have not yet connected.
```lua
local socket = sockets:GetSocket(player)
```
##### Sockets GetSockets
This method returns all the open sockets in the game.
```lua
local openSockets = sockets:GetSockets()
```
##### Emit(eventName, ...)
Fires the given event on all clients, passing ... through to the listener function.

Server
```lua
sockets:Emit("Message", "Hello")
```
Client
```lua
socket:Listen("Message", function (msg)
    -- msg is 'Hello'
end
```
##### EmitClients(players, eventName, ...)
Fires the given event on all clients in the players list, passing ... through to the listener function.
##### EmitRoom(roomName, eventName, ...)
Fires the given event on all clients in the given room, passing ... through to the listener function. (See Rooms)
##### Request(requestName, ..., callback)
Makes a request to all clients, passing ... through to the clients request listener function. When a client responds their socket will be passed into the callback along with any arguments returned by their request listener function.

Server
```lua
sockets:Request("Vote", choices, function (socket, choice)
    print(socket.Player, "picked", choice)
end)
```
Client
```lua
socketsListen("Vote", function (choices)
    return choices[math.random(1, #choices)] -- Pick a choice at random
end)
```
##### RequestClients(players, requestName, ..., callback)
Makes a request to all clients in the players list, passing ... through to the clients request listener function.
##### RequestRoom(players, requestName, ..., callback)
Makes a request to all clients in the given room, passing ... through to the clients request listener function. (See Rooms)

### Socket
A socket is used to communicate between the server and the client and it exposes many powerful methods to do so. It is created when the client first communicates with the server and returned by the connected event or by requiring the client module.
#### Events
##### Disconnected
The disconnected event fires when the player disconnects from the server for whatever reason. Once this event has been fired the socket is dead and can not be used anymore.

**Note: This event only exists on the server**
```lua
sockets.Connected:connect(function (socket)
    socket.Disconnected:connect(function ()
        print("Disconnected")
    end)
end)
```
#### Methods
##### RBXScriptConnection Listen(name, listenerFunction)
Subscribes to an event, calling the listener function whenever an event of the given name is emitted.
```lua
socket:Listen("Message", function (msg)
    print(msg)
end)
```
You can also use listen to respond to requests.
```lua
socket:Listen("Vote", function (choices)
    return choices[math.random(1, #choices)]
end)
```
**Note: Only the first function to subscribe is used to respond to requests, you can override this with SetCallback.**
##### Emit(name, ...)
Fires the given event passing ... through to the listener function.
```lua
socket:Emit("Message", "Howdy")
```
##### Variant Request(name, ...)
Makes a request, passing ... through to the given request callback function. Returns the result from the request callback function.
```lua
local choice = socket:Request("Vote", choices)
```
##### SetCallback(name, callbackFunction)
The SetCallback method sets the callback for all requests with the given name. It will override a callback set by the Listen method.
```lua
socket:SetCallback("Vote", function (choices)
    return choices[1]
end)
```
##### Group GetGroup(groupName)
Returns a group with the given name. (See Groups)
##### JoinRoom(roomName)
Adds the socket to the given room. This method can only be used on the server. (See Rooms)
##### LeaveRoom(roomName)
Removes the socket from the given room. This method can only be used on the server. (See Rooms)
##### Disconnect(message)
Disconnects the client from the server, message is optional. This method can only be used from the server.
### Rooms
A room allows you to communicate with specific clients. This is extremely useful in many situations. 
* You can add everybody who isn't spectating to a room so that they can listen for certain game specific events.
* You could make a chatroom for specific users.

Room creation is handled automatically, all you need to do is call `socket:JoinRoom(roomName)` from the server on the given socket. If you want to get all the sockets in a room you can access them through `module.Rooms[roomName]`.

Also, if you want a player to leave a room just call `socket:LeaveRoom(roomName)` from the server on their socket.
### Groups
Groups allow you to organize different types of communication together. You can have as many groups as you like and even create subgroups.
```lua
sockets.Connected:connect(function (socket)
    local purchases = socket:GetGroup("Purchases")
    
    purchases:Listen("RequestPurchase", function (item)
        -- Check player has enough money
        return true
    end)
    
    purchases:Listen("GetPrice", function (itemName)
        return items[itemName].Price
    end)
    
    local subGroup = purchases:GetGroup("Subgroup")
end)
```
Much like rooms, group creation is all handled automatically. All you need to do is called `GetGroup(groupName)` on the server and client

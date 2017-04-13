#Usage
A socket is created when a player joins the game. It is used to listen to events, fire events, listen to queries and fetch data.

##Module
###event Connected
```lua
Connected (Player player, Socket socket)
```
Fires when a player joins the game and communicates with the module
###method Emit/Fire
```lua
void Emit(string name, Variant... args)
```
Fires all listeners with the given name on all connected clients. Fire can also be used instead of Emit.
###method Query/Invoke
```lua
Query(string name, Variant... args, function (Variant...) callback)
```
Invokes a function with the given name on all connected clients. A callback must be the last parameter, it will be run for each client that responds. Invoke can also be used instead of Query.
###method EmitClients/FireClients
```lua
void EmitClients(Array<Player> clients, string name, Variant... args)
```
Fires the given listener on the specified clients. FireClients can also be used instead of EmitClients
###method QueryClients/InvokeClients
```lua
void QueryClients(Array<Player> clients, string name, Variant... args, function (Variant...) callback)
```
Invokes the given function on the specified clients. See module.Query for more information. InvokeClients can also be used instead of QueryClients.
###method GetSocket
```lua
Socket GetSocket(Player player)
```
Returns the players socket
###method GetSockets
```lua
Dictionary<Player, Socket> GetSockets()
```
Returns a dictionary of all the sockets that are currently active.

##Socket
A socket exists for each player connected to the game. It allows communication between the server and the client.
###method Connect
```lua
Connection Connect(string name, function (Variant...) listenerFunction)
Connection Connect(function (Variant...) listenerFunction)
```
Works much the same as the standard connect method for RBXScriptSignal except it also takes an optional name parameter which means the listener function will only fire when emit is called with the same name. If name is omitted the function will run regardless of the name.
###method Emit/Fire
```lua
void Emit(string name, Variant... args)
```
Fires an event with the given name. Fire can also be used instead of Emit.
###method Listen/On
```lua
void Listen(string name, function (Variant...) callback)
```
When Query is called the function specified by this method will be run. On can also be used instead of Listen.
###method Query/Invoke
```lua
Variant... Query(string name, Variant... args)
```
Invokes a function with the given name. Invoke can also be used instead of Query.
###property Player
The player that the socket belongs to, only exists on the servers version of the socket.
###Disconnected
Disconnected will automatically fire when the player leaves the game.

```lua
socket:connect("Disconnected", function ()
    -- This fires when the player leaves the game
end)
```

#Plans
There are a few things I'd like to do moving forward to make the module a bit nicer.

I plan to add groups to the sockets which will allow you to group certain types of function/event together with a common name. This is something I plan to do quite soon as it's an absolute must for any large scale project.

The naming of each method could be better. I am not entirely sure what I'd like to do instead though. I am thinking Listen makes more sense in the place of Connect.

Queries were just something I added in for the sake of it. They feel a bit too clunky at the moment, I'd really like to clean them up.

I would like to add rooms. These are essentially something a client can join or a server can assign. You'll then be able to fire events for a given room and all clients in that room will be contacted. This would be useful when you want to fire an event to people taking part in a game as opposed to those also in the lobby.

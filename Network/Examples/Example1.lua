-- Server
network:Invoked("ServerPrint", function (player, message)
	print(("%s says: %s"):format(tostring(player), message))
end)

-- Client
network:Invoke("ServerPrint", "Hi there!")

# Shift
Calculates the time shift between the client and the server allowing you to keep an accurate record of the users ping for use with projectiles or other network sensitive tasks

## Documentation
The responder file should be placed in a local script called 'Responder' within the shift module. The shift module is based entirely on the server.
### Module
#### number GetShift(Instance player)
Returns the offset between the servers tick and the clients tick.
#### number ServerToClient(Instance player [, number time])
Converts the given time (or the current value of tick if none is specified) to the equivilant value on the given client.
#### number ClientToServer(Instance player, number time])
Converts the given time on the client to what it would have been on the server.
#### number Resync(Instance player)
Resynchronizes the shift between the client and the server.
#### boolean Verify(Instance player, number time)
Takes a time returned by the client and verifies that they have not exploited it by comparing it with the servers elapsed time. Will return false if the value is invalid.

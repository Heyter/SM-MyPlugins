I will post the extension later if I find someone who will write it.

Windows: OK \
Linux: Don't tested \

Place binary to server_csgo/bin/ ( where lies srcds )

##### Signatures

###### Linux
CVehicleController::CVehicleController -> 55 89 E5 81 EC ? ? ? ? 8B 45 10 89 5D F8 8B 5D 08 89 75 FC 89 43 10 8B 45 18

###### Windows
CVehicleController::CVehicleController -> 55 8B EC 83 E4 F0 81 EC ? ? ? ? 8B 45 0C 56

##### Bugs

If server crashed when vehicle using handbrake, then set "skidallowed" to 0 ( scripts/vehicles/your_car.txt )

Windows: OK \
Linux: OK

Place binary to server_csgo/bin/

##### Signatures

###### Linux
CVehicleController::CVehicleController -> 55 89 E5 81 EC ? ? ? ? 8B 45 10 89 5D F8 8B 5D 08 89 75 FC 89 43 10 8B 45 18

###### Windows
CVehicleController::CVehicleController -> 55 8B EC 83 E4 F0 81 EC ? ? ? ? 8B 45 0C 56

##### Bugs

If the server crashes when using the handbrake then set "skidallowed" to 0 ( scripts/vehicles/your_car.txt ) \
or change "material" , "skidmaterial" , "brakematerial" on default values.

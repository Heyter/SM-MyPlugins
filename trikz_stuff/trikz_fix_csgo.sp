#pragma semicolon 1

#include <sdktools_sound>
#include <sdktools_functions>
#include <sdktools_entinput>
#include <sdktools_engine>
#include <sdktools_trace>
#include <sdkhooks>
//#include <clientprefs>
#include <trikznobug>
#include <blindhook>

// FlashBoost Extra Settings
#define REMOVE_FLASH 1

#pragma newdecls required

bool bLateLoad = false;
float g_fFlashMultiplier = 0.869325;

// FlashBoost
bool g_bFlashBoost[MAXPLAYERS+1];
float g_vFlashAbsVelocity[MAXPLAYERS+1][3];
bool g_bGroundBoost[MAXPLAYERS+1];
int g_FlashHitSound[2048];

// SkyBoost
bool g_bSkyEnable[MAXPLAYERS+1] = {true, ...};
float g_fBoosterAbsVelocityZ[MAXPLAYERS+1];
int g_SkyTouch[MAXPLAYERS+1];
int g_SkyReq[MAXPLAYERS+1];
float g_vSkyBoostVel[MAXPLAYERS+1][3];

public Plugin myinfo = 
{
	name = "[Trikz] Flash/Sky Fix",
	author = "ici & george",
	version = "2.02 GO"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	bLateLoad = late;
	CreateNative("Trikz_SkyFix", Native_Trikz_SkyFix);
	return APLRes_Success;
}

public int Native_Trikz_SkyFix(Handle plugin, int numParams) {
	g_bSkyEnable[GetNativeCell(1)] = view_as<bool>(GetNativeCell(2));
	return 1;
}

public Action CS_OnBlindPlayer(int iClient, int iAttacker, int iInflictor) {
	return Plugin_Stop;
}

public void OnPluginStart() {
	AddNormalSoundHook(SoundsHook);
	RegServerCmd("sm_flashmul", SM_FlashMul);
	
	if (bLateLoad)
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientConnected(i) && IsClientInGame(i))
				OnClientPutInServer(i);
}

public Action SM_FlashMul(int args)
{
	char sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));
	float arg1 = StringToFloat(sArg);
	g_fFlashMultiplier = arg1;
	PrintToChatAll("Flash Multiplier: %f", g_fFlashMultiplier);
}

public void OnClientPutInServer(int client) {

	// FlashBoost
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	
	// SkyBoost
	//SDKHook(client, SDKHook_Touch, Hook_Touch);
	
	g_SkyTouch[client] = 0;
	g_SkyReq[client] = 0;
}

public void OnEntityDestroyed(int edict) {
	if (IsValidEdict(edict)) {
		char sEdictName[32];
		GetEdictClassname(edict, sEdictName, sizeof(sEdictName));
		if (StrEqual(sEdictName, "flashbang_projectile"))
			g_FlashHitSound[edict] = 0;
	}
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {

	if (g_bFlashBoost[victim]
	|| !IsValidClient(victim)
	|| GetEntityMoveType(victim) == MOVETYPE_LADDER) return Plugin_Continue;
	
	char Weapon[32];
	GetEdictClassname(inflictor, Weapon, sizeof(Weapon));
	if (StrContains(Weapon, "flashbang", false) == -1) return Plugin_Continue;
	
	int GroundEntity = GetEntPropEnt(victim, Prop_Data, "m_hGroundEntity");
	if (IsValidEdict(GroundEntity)) {
		GetEdictClassname(GroundEntity, Weapon, sizeof(Weapon));
		if (StrContains(Weapon, "flashbang", false) == -1) {
			//PrintToChatAll("Failed GroundEntity");
			return Plugin_Continue;
		}
	}
	
	float vFlashOrigin[3];
	float vVictimOrigin[3];
	float vVictimAbsVelocity[3];
	float vAttackerOrigin[3];
	
	GetEntPropVector(inflictor, Prop_Data, "m_vecOrigin", vFlashOrigin);
	GetEntPropVector(victim, Prop_Data, "m_vecOrigin", vVictimOrigin);
	GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", vVictimAbsVelocity);
	GetEntPropVector(attacker, Prop_Data, "m_vecOrigin", vAttackerOrigin);
	
	// if ((vFlashOrigin[2] > vVictimOrigin[2])
	// || ((vVictimOrigin[2] >= vAttackerOrigin[2]))
	// || (((vFlashOrigin[0] < (vVictimOrigin[0] - 16.0)) || (vFlashOrigin[0] > (vVictimOrigin[0] + 16.0)))
	// && ((vFlashOrigin[1] < (vVictimOrigin[1] - 16.0)) || (vFlashOrigin[1] > (vVictimOrigin[1] + 16.0))))) {
		// PrintToChatAll("Something else is wrong");
		// return Plugin_Continue;
	// }
	
	if (g_FlashHitSound[inflictor] > 0)
		g_bGroundBoost[victim] = true;
	
	GetEntPropVector(inflictor, Prop_Data, "m_vecAbsVelocity", g_vFlashAbsVelocity[victim]);
	g_bFlashBoost[victim] = true;
	
#if (REMOVE_FLASH == 1)
	CreateTimer(0.01, Timer_RemoveFlash, inflictor);
#endif
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client) {

	if (g_bFlashBoost[client]) {
		float vClientAbsVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vClientAbsVelocity);
		
		//PrintToChatAll("Client: %.2f %.2f %.2f Flash: %.2f %.2f %.2f",
		//	vClientAbsVelocity[0], vClientAbsVelocity[1], vClientAbsVelocity[2],
		//	g_vFlashAbsVelocity[0], g_vFlashAbsVelocity[1], g_vFlashAbsVelocity[2]);
		
		// 0,8693248760112110724220573123187
		vClientAbsVelocity[0] += g_vFlashAbsVelocity[client][0] * -g_fFlashMultiplier;
		vClientAbsVelocity[1] += g_vFlashAbsVelocity[client][1] * -g_fFlashMultiplier;
		vClientAbsVelocity[2] = g_vFlashAbsVelocity[client][2];
		
		if (g_bGroundBoost[client]) {
			g_bGroundBoost[client] = false;
		} else {
			SetEntPropEnt(client, Prop_Data, "m_hGroundEntity", INVALID_ENT_REFERENCE);
			SetEntityFlags(client, (GetEntityFlags(client) & ~FL_ONGROUND));
		}
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vClientAbsVelocity);
		g_bFlashBoost[client] = false;
	}
	return Plugin_Continue;
}

public Action SoundsHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags) {

	if (!IsValidEdict(entity)) return Plugin_Continue;
	
	char sEntityName[32];
	GetEdictClassname(entity, sEntityName, sizeof(sEntityName));
	if (!StrEqual(sEntityName, "flashbang_projectile")) return Plugin_Continue;
	
	++g_FlashHitSound[entity];
	return Plugin_Continue;
}

public Action Hook_Touch(int victim, int other) {

	if (!g_bSkyEnable[victim]
	|| g_bFlashBoost[victim]
	|| !IsValidClient(other)
	|| GetEntityMoveType(victim) == MOVETYPE_LADDER
	|| GetEntityMoveType(other) == MOVETYPE_LADDER) return Plugin_Continue;
	
	int col = GetEntProp(other, Prop_Data, "m_CollisionGroup");
	if (col != 5) return Plugin_Continue;
	
	float vVictimOrigin[3];
	float vBoosterOrigin[3];
	
	GetEntPropVector(victim, Prop_Data, "m_vecOrigin", vVictimOrigin);
	GetEntPropVector(other, Prop_Data, "m_vecOrigin", vBoosterOrigin);
	
	if ((Math_Abs(vVictimOrigin[0] - vBoosterOrigin[0]) > 32.0)
	|| (Math_Abs(vVictimOrigin[1] - vBoosterOrigin[1]) > 32.0)
	|| (vVictimOrigin[2] - vBoosterOrigin[2]) < 45.0)
		return Plugin_Continue;
	
	float vBoosterAbsVelocity[3];
	GetEntPropVector(other, Prop_Data, "m_vecAbsVelocity", vBoosterAbsVelocity);
	if (vBoosterAbsVelocity[2] <= 0.0) return Plugin_Continue;
	
	g_fBoosterAbsVelocityZ[victim] += vBoosterAbsVelocity[2];
	++g_SkyTouch[victim];
	GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", g_vSkyBoostVel[victim]);
	
	RequestFrame(SkyFrame_Callback, victim);
	return Plugin_Continue;
}

public void SkyFrame_Callback(any victim) {

	if (g_SkyTouch[victim] == 0)
		return;
	
	if (g_bFlashBoost[victim]) {
		g_fBoosterAbsVelocityZ[victim] = 0.0;
		g_SkyTouch[victim] = 0;
		g_SkyReq[victim] = 0;
		return;
	}
	
	++g_SkyReq[victim];
	float vVictimAbsVelocity[3];
	GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", vVictimAbsVelocity);
	
	if (vVictimAbsVelocity[2] > 0.0) {
		g_vSkyBoostVel[victim][2] = vVictimAbsVelocity[2] + g_fBoosterAbsVelocityZ[victim] * 0.5;
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, g_vSkyBoostVel[victim]);
		g_fBoosterAbsVelocityZ[victim] = 0.0;
		g_SkyTouch[victim] = 0;
		g_SkyReq[victim] = 0;
	} else {
		if (g_SkyReq[victim] > 150) {
			g_fBoosterAbsVelocityZ[victim] = 0.0;
			g_SkyTouch[victim] = 0;
			g_SkyReq[victim] = 0;
			return;
		}
		// Recurse for a few more frames
		RequestFrame(SkyFrame_Callback, victim);
	}
}

public bool IsValidClient(int client) {
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsPlayerAlive(client));
}

public float Math_Abs(float value) {
	return (value >= 0.0 ? value : -value);
}

#if (REMOVE_FLASH == 1)
public Action Timer_RemoveFlash(Handle timer, any inflictor) {
	if (IsValidEdict(inflictor))
		AcceptEntityInput(inflictor, "Kill");
}
#endif

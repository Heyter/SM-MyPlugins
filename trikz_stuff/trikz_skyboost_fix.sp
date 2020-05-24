#include <sdktools>
#include <sdkhooks>
#include <tengu_stocks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "boost-fix",
	author      = "Tengu",
	description = "<insert_description_here>",
	version     = "0.1",
	url         = "http://steamcommunity.com/id/tengulawl/"
};

bool g_lateLoaded;
int g_skyFrame[MAX_PLAYERS];
int g_skyStep[MAX_PLAYERS];
float g_skyVel[MAX_PLAYERS][3];
float g_fallSpeed[MAX_PLAYERS];
int g_boostStep[MAX_PLAYERS];
int g_boostEnt[MAX_PLAYERS];
float g_boostVel[MAX_PLAYERS][3];
float g_boostTime[MAX_PLAYERS];
float g_playerVel[MAX_PLAYERS][3];
int g_playerFlags[MAX_PLAYERS];
bool g_groundBoost[MAX_PLAYERS];
bool g_bouncedOff[2048];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_lateLoaded = late;
}

public void OnMapStart() {
	if (g_lateLoaded) {
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);
		g_lateLoaded = false;
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_StartTouch, Client_StartTouch);
	SDKHook(client, SDKHook_PostThinkPost, Client_PostThinkPost);
}

public void OnClientDisconnect(int client) {
	g_skyFrame[client] = 0;
	g_skyStep[client] = 0;
	g_boostStep[client] = 0;
	g_boostTime[client] = 0.0;
	g_playerFlags[client] = 0;
}

public Action Client_StartTouch(int client, int other) {
	if (!IsValidClient(other, true) || g_playerFlags[other] & FL_ONGROUND || g_skyFrame[other] || g_boostStep[client] || GetGameTime() - g_boostTime[client] < 0.15)
		return;

	float clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);

	float otherOrigin[3];
	GetClientAbsOrigin(other, otherOrigin);

	float clientMaxs[3];
	GetClientMaxs(client, clientMaxs);

	float delta = otherOrigin[2] - clientOrigin[2] - clientMaxs[2];

	if (delta > 0.0 && delta < 2.0) {
		float velocity[3];
		GetAbsVelocity(client, velocity);

		if (velocity[2] > 0.0 && velocity[2] < 300.0 && !(GetClientButtons(other) & IN_DUCK)) {
			g_skyFrame[other] = 1;
			g_skyStep[other] = 1;
			g_skyVel[other] = velocity;
			GetAbsVelocity(other, velocity);
			g_fallSpeed[other] = FloatAbs(velocity[2]);
		}
	}
}

public void Client_PostThinkPost(int client) {
	if (g_skyFrame[client]) {
		if (g_boostStep[client] || (++g_skyFrame[client] >= 5 && g_skyStep[client] != 2 && g_skyStep[client] != 3)) {
			g_skyFrame[client] = 0;
			g_skyStep[client] = 0;
		}
	}

	if (g_boostStep[client] == 1) {
		int entity = EntRefToEntIndex(g_boostEnt[client]);

		if (entity != INVALID_ENT_REFERENCE) {
			float velocity[3];
			GetAbsVelocity(entity, velocity);

			if (velocity[2] > 0.0) {
				velocity[0] = g_boostVel[client][0] * 0.135;
				velocity[1] = g_boostVel[client][1] * 0.135;
				velocity[2] = g_boostVel[client][2] * -0.135;

				TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, velocity);
			}
		}

		g_boostStep[client] = 2;
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
	g_playerFlags[client] = GetEntityFlags(client);

	if (g_skyFrame[client] && g_boostStep[client]) {
		g_skyFrame[client] = 0;
		g_skyStep[client] = 0;
	}

	if (!g_skyStep[client] && !g_boostStep[client]) {
		if (GetGameTime() - g_boostTime[client] < 0.15) {
			float basevel[3];
			SetBaseVelocity(client, basevel);
		}
		return Plugin_Continue;
	}

	float velocity[3];
	SetBaseVelocity(client, velocity);

	if (g_skyStep[client]) {
		if (g_skyStep[client] == 1) {
			int flags = g_playerFlags[client];
			int oldButtons = GetOldButtons(client);

			if (flags & FL_ONGROUND && buttons & IN_JUMP && !(oldButtons & IN_JUMP))
				g_skyStep[client] = 2;
		} else if (g_skyStep[client] == 2) {
			GetAbsVelocity(client, velocity);

			velocity[0] -= g_skyVel[client][0];
			velocity[1] -= g_skyVel[client][1];
			velocity[2] += g_skyVel[client][2];

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

			g_skyStep[client] = 3;
		} else if (g_skyStep[client] == 3) {
			GetAbsVelocity(client, velocity);

			if (g_fallSpeed[client] < 300.0) {
				g_skyVel[client][2] *= g_fallSpeed[client] / 300.0;
			}

			velocity[0] += g_skyVel[client][0];
			velocity[1] += g_skyVel[client][1];
			velocity[2] += g_skyVel[client][2];

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

			g_skyStep[client] = 0;
		}
	}

	if (g_boostStep[client]) {
		if (g_boostStep[client] == 2) {
			velocity[0] = g_playerVel[client][0] - g_boostVel[client][0];
			velocity[1] = g_playerVel[client][1] - g_boostVel[client][1];
			velocity[2] = g_boostVel[client][2];

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

			g_boostStep[client] = 3;
		} else if (g_boostStep[client] == 3) {
			GetAbsVelocity(client, velocity);
			
			if (g_groundBoost[client]) {
				velocity[0] += g_boostVel[client][0];
				velocity[1] += g_boostVel[client][1];
				velocity[2] += g_boostVel[client][2];
			} else {
				velocity[0] += g_boostVel[client][0] * 0.135;
				velocity[1] += g_boostVel[client][1] * 0.135;
			}
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

			g_boostStep[client] = 0;
		}
	}

	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrContains(classname, "_projectile") != -1) {
		g_bouncedOff[entity] = false;
		SDKHook(entity, SDKHook_StartTouch, Projectile_StartTouch);
		SDKHook(entity, SDKHook_EndTouch, Projectile_EndTouch);
	}
}

public Action Projectile_StartTouch(int entity, int client) {
	if (!IsValidClient(client, true))
		return Plugin_Continue;

	CreateTimer(0.25, Timer_RemoveEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);

	if (g_boostStep[client] || g_playerFlags[client] & FL_ONGROUND)
		return Plugin_Continue;

	float entityOrigin[3];
	GetEntityAbsOrigin(entity, entityOrigin);

	float clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);

	float entityMaxs[3];
	GetEntityMaxs(entity, entityMaxs);

	float delta = clientOrigin[2] - entityOrigin[2] - entityMaxs[2];

	if (delta > 0.0 && delta < 2.0) {
		g_boostStep[client] = 1;
		g_boostEnt[client] = EntIndexToEntRef(entity);
		GetAbsVelocity(entity, g_boostVel[client]);
		GetAbsVelocity(client, g_playerVel[client]);
		g_groundBoost[client] = g_bouncedOff[entity];
		g_boostTime[client] = GetGameTime();
	}

	return Plugin_Continue;
}

public Action Projectile_EndTouch(int entity, int other) {
	if (!other)
		g_bouncedOff[entity] = true;
}

public Action Timer_RemoveEntity(Handle timer, any entref) {
	int entity = EntRefToEntIndex(entref);
	if (entity != INVALID_ENT_REFERENCE)
		AcceptEntityInput(entity, "Kill");
}
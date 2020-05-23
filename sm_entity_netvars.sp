#include <sdktools_functions>

#pragma semicolon 1
#pragma newdecls required

methodmap EntityMap < StringMap {
	public EntityMap() {
		return view_as<EntityMap>(new StringMap());
	}
	
	public any GetEntityValue(int entity, const char[] key, any def_value = 0) {
		if (entity > MaxClients)
			entity = EntIndexToEntRef(entity);
		
		char ref[8];
		IntToString(entity, ref, sizeof(ref));
	
		StringMap data;
		if (!this.GetValue(ref, data))
			return def_value;
		
		any value;
		if (!data.GetValue(key, value))
			return def_value;
		
		return value;
	}
	
	public bool GetEntityString(int entity, const char[] key, char[] value, int maxlen, char[] def_value = "") {
		if (entity > MaxClients)
			entity = EntIndexToEntRef(entity);
		
		char ref[8];
		IntToString(entity, ref, sizeof(ref));
	
		StringMap data;
		
		if (!this.GetValue(ref, data)) {
			strcopy(value, maxlen, def_value);
			return false;
		}
		
		bool found;
		if (!(found = data.GetString(key, value, maxlen)))
			strcopy(value, maxlen, def_value);
		
		return found;
	}
	
	public bool SetEntityValue(int entity, const char[] key, any value, bool replace = true) {
		if (entity > MaxClients)
			entity = EntIndexToEntRef(entity);
			
		char ref[8];
		IntToString(entity, ref, sizeof(ref));
	
		StringMap data;
		if (!this.GetValue(ref, data)) {
			data = new StringMap();
			if (!this.SetValue(ref, data))
				return false;
		}
		
		return data.SetValue(key, value, replace);
	}
	
	public bool SetEntityString(int entity, const char[] key, const char[] value, bool replace = true) {
		if (entity > MaxClients)
			entity = EntIndexToEntRef(entity);
		
		char ref[8];
		IntToString(entity, ref, sizeof(ref));
	
		StringMap data;
		if (!this.GetValue(ref, data)) {
			data = new StringMap();
			if (!this.SetValue(ref, data))
				return false;
		}
		
		return data.SetString(key, value, replace);
	}
	
	public void Close(int entity = -1) {
		if (entity == -1) {
			StringMapSnapshot snapshot = this.Snapshot();
			
			int len = snapshot.Length;
			for (int i = 0; i < len; i++) {
				char key[128];
				snapshot.GetKey(i, key, sizeof(key));
				
				StringMap data;
				if (this.GetValue(key, data)) 
					delete data;
			}
			
			delete this;
		} else {
			char ref[8];
			IntToString(entity, ref, sizeof(ref));
			
			StringMap data;
			if (this.GetValue(ref, data)) {
				this.Remove(ref);
				delete data;
			}
		}
	}
}

static EntityMap m_NetVar;

public void OnPluginStart() {
	m_NetVar = new EntityMap();
	m_NetVar.GetEntityString(1, "test", "sexy", 4);
}

public void OnLevelInit() {
	if (m_NetVar != null)
		m_NetVar.Close();
	
	m_NetVar = new EntityMap();
}

public void OnEntityDestroyed(int entity) {
	if (entity > MaxClients && m_NetVar != null)
		m_NetVar.Close(entity);
}

public void OnClientDisconnect(int client) {
	if (m_NetVar != null)
		m_NetVar.Close(client);
}

/* 
	Example ::
	
	m_NetVar.SetEntityString(i, "name", "test", 4);
	m_NetVar.SetEntityValue(i, "health", 100);
	
	char buff[32];
	m_NetVar.GetEntityString(i, "name", buff, sizeof(buff), "test");
	PrintToServer("%s", buff);
	
	m_NetVar.GetEntityValue(i, "health", 100);
	
	any GetEntityValue(int entity, const char[] key, any def_value = 0)
	bool GetEntityString(int entity, const char[] key, char[] value, int maxlen, char[] def_value = "")
	
	bool SetEntityValue(int entity, const char[] key, any value, bool replace = true)
	bool SetEntityString(int entity, const char[] key, const char[] value, bool replace = true)
	
	void Close(int entity = 0)
*/
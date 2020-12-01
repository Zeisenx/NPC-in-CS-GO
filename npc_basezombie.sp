
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dynamic>
#include <emitsoundany>

#include <zeisen_tools>

StringMap g_npc_list;
#include "zbaseai/method.sp"
#include "zbaseai/stock.inc"

#include "zbaseai/npc/npc_zombie.sp"

public OnPluginStart()
{
	g_npc_list = new StringMap();
	
	AddTempEntHook("PlayerAnimEvent", TE_PlayerAnimEvent);
	OnPluginStart_NPCZombie();
	
	AddNormalSoundHook(SoundHook);
}

public OnMapStart()
{
	OnMapStart_NPCZombie();
}


public Action TE_PlayerAnimEvent(const char[] te_name, const int[] Players, int numClients, float delay)
{
	int entityHandle = TE_ReadNum("m_hPlayer");
	int entity = EntRefToEntIndex(entityHandle | ~0x7FFF);
	int event = TE_ReadNum("m_iEvent");
	int data = TE_ReadNum("m_nData");
	
	char entity_name[64];
	GetEdictClassname(entity, entity_name, sizeof(entity_name));
	
	PrintToChatAll("%s(%d) %d %d", entity_name, entity, event, data);
}

public Action SoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (entity <= 0)
		return Plugin_Continue;
	
	Zombie_SoundHook(entity, sample);
	
	char ent_name[32];
	GetEdictClassname(entity, ent_name, sizeof(ent_name));
	if (StrContains(ent_name, "npc_") == 0)
	{
		if (StrContains(sample, "ambient/creatures/chicken") == 0)
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action ChickenFollowBlock(int entity, int activator, int caller, UseType type, float value)
{
	return Plugin_Handled;
}
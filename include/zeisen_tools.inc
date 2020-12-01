
#define MAXENTITIES 2048

enum SolidType_t
{
    SOLID_NONE            = 0,    // no solid model
    SOLID_BSP            = 1,    // a BSP tree
    SOLID_BBOX            = 2,    // an AABB
    SOLID_OBB            = 3,    // an OBB (not implemented yet)
    SOLID_OBB_YAW        = 4,    // an OBB, constrained so that it can only yaw
    SOLID_CUSTOM        = 5,    // Always call into the entity for tests
    SOLID_VPHYSICS        = 6,    // solid vphysics object, get vcollide from the model and collide with that
    SOLID_LAST,
}

stock Damage_PointHurt(victim, attacker, damage, dmg_type=DMG_GENERIC, char[] weapon="")
{
	if (victim <= 0 || !IsClientInGame(victim) || !IsPlayerAlive(victim) || damage <= 0)
		return;
	
	char dmg_str[16];
	IntToString(damage, dmg_str, sizeof(dmg_str));
	char dmg_type_str[32];
	IntToString(dmg_type, dmg_type_str, sizeof(dmg_type_str));
	
	int pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt)
	{
		char victim_targetname[64];
		GetEntPropString(victim, Prop_Data, "m_iName", victim_targetname, sizeof(victim_targetname));
		
		DispatchKeyValue(victim, "targetname", "war3_hurtme");
		DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
		DispatchKeyValue(pointHurt, "Damage", dmg_str);
		DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
		if(!StrEqual(weapon, ""))
			DispatchKeyValue(pointHurt, "classname", weapon);
		
		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", (attacker > 0) ? attacker : -1);
		
		DispatchKeyValue(victim, "targetname", victim_targetname);
		RemoveEdict(pointHurt);
	}
}

stock GetEntityEyePosition(int entity, float eyepos[3])
{
	if (entity >= 1 && entity <= MaxClients)
	{
		GetClientEyePosition(entity, eyepos);
		return;
	}
	
	float entity_pos[3];
	GetEntityOrigin(entity, entity_pos);
	
	int info_target = CreateEntityByName("info_target");
	DispatchSpawn(info_target);
	TeleportEntity(info_target, entity_pos, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(info_target, "SetParent", entity, info_target, 0);
	
	SetVariantString("eyes");
	AcceptEntityInput(info_target, "SetParentAttachment", info_target, info_target, 0);
	
	GetEntPropVector(info_target, Prop_Data, "m_vecAbsOrigin", eyepos);
	
	RemoveEdict(info_target);
}

stock bool EntityCanSeeTarget(int entity, int target)
{
	float target_pos[3];
	GetEntityOrigin(target, target_pos);
	
	target_pos[2] += 28.0;
	
	return EntityCanSeeOrigin(entity, target_pos);
}

stock bool EntityCanSeeOrigin(int entity, float fOrigin[3], float height_offset = 0.0)
{
	float fClientPosition[3];
	
	GetEntityEyePosition(entity, fClientPosition);
	float testorigin[3];
	testorigin = fOrigin;
	testorigin[2] += height_offset;

	Handle hTrace = TR_TraceRayFilterEx(fClientPosition, testorigin, MASK_VISIBLE_AND_NPCS, RayType_EndPoint, Base_TraceFilter);
	if (TR_GetFraction(hTrace) >= 0.8)
	{
		CloseHandle(hTrace);
		return true;
	}

	CloseHandle(hTrace);
	return false;
}

public bool Base_TraceFilter(int iEntity, int iContentsMask, int iData) {
	return iEntity == iData;
}

stock float GetEntityDistance(int entity, int target, bool is_2d = false)
{
	float entity_pos[3]; float target_pos[3];
	GetEntityOrigin(entity, entity_pos);
	GetEntityOrigin(target, target_pos);
	
	if (is_2d)
	{
		entity_pos[2] = 0.0;
		target_pos[2] = 0.0;
	}
	
	return GetVectorDistance(entity_pos, target_pos);
}

stock float GetTargetAngleToFOV(int entity, int target)
{
	float entity_pos[3]; float target_pos[3];
	GetEntityOrigin(entity, entity_pos);
	GetEntityOrigin(target, target_pos);
	
	float entity_angle[3];
	GetEntPropVector(entity, Prop_Send, "m_angRotation", entity_angle);
	
	float entity_angle_vector[3];
	GetAngleVectors(entity_angle, entity_angle_vector, NULL_VECTOR, NULL_VECTOR);
	
	float pos_vector[3];
	MakeVectorFromPoints(entity_pos, target_pos, pos_vector);
	NormalizeVector(pos_vector, pos_vector);
	
	return RadToDeg(ArcCosine(GetVectorDotProduct(pos_vector, entity_angle_vector)));
}

stock SolidType_t GetEntitySolidType(int entity)
{
	return view_as<SolidType_t>(GetEntProp(entity, Prop_Data, "m_nSolidType"));
}

stock SetEntitySolidType(int entity, SolidType_t type)
{
	SetEntProp(entity, Prop_Data, "m_nSolidType", type);
}

stock GetEntityOrigin(int entity, float origin[3])
{
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
}

stock Vector_Copy(float main_vector[3], float target_vector[3])
{
	for (int i=0; i<=2; i++)	
		target_vector[i] = main_vector[i];
}

stock bool GetClientAimLookAt(int client, float hOrigin[3])
{
	float vAngles[3];
	float fOrigin[3];
	GetClientEyePosition(client, fOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, Filter_GetClientAimLookAt, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(hOrigin, trace);
		CloseHandle(trace);
		return true;
	}

	CloseHandle(trace);
	return false;
}

public bool Filter_GetClientAimLookAt(int entity, int contentsMask, int client)
{
    return entity != client;
} 

stock ClearTimer(Handle &timer)
{
	if (timer == INVALID_HANDLE)
		return;
	
	KillTimer(timer);
	timer = INVALID_HANDLE;
}

stock GetRandomChoice(char[][] list, int size, char[] output, int output_size)
{
	strcopy(output, output_size, list[GetRandomInt(0, size - 1)]);
}

stock int Z_PreLoadModel(char[] filename)
{
	char buffer[256];
	
	Format(buffer, sizeof(buffer), "%s.dx90.vtx", filename);
	Z_PreLoadFile(buffer);
	Format(buffer, sizeof(buffer), "%s.mdl", filename);
	int precache_model = Z_PreLoadFile(buffer);
	Format(buffer, sizeof(buffer), "%s.phy", filename);
	Z_PreLoadFile(buffer);
	Format(buffer, sizeof(buffer), "%s.sw.vtx", filename);
	Z_PreLoadFile(buffer);
	Format(buffer, sizeof(buffer), "%s.vvd", filename);
	Z_PreLoadFile(buffer);
	
	return precache_model;
}

stock int Z_PreLoadFile(char[] filename)
{
	if (StrContains(filename, ".mdl") != -1)
	{
		AddFileToDownloadsTable(filename);
		return PrecacheModel(filename);
	}
	else if (StrContains(filename, ".mp3") != -1)
	{
		PrecacheSoundAny(filename);
		
		char buffer[192];
		Format(buffer, sizeof(buffer), "sound/%s", filename);
		
		AddFileToDownloadsTable(buffer);
		
		return 0;
	}
	
	AddFileToDownloadsTable(filename);
	return 0;
}
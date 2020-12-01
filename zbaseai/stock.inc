
stock ZBaseAI ZBaseAI_GetClass(int entity)
{
	char buffer[32];
	Format(buffer, sizeof(buffer), "ai_%d", entity);
	
	int handle;
	g_npc_list.GetValue(buffer, handle);
	
	return view_as<ZBaseAI>(handle);
}
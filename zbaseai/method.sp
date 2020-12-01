
methodmap ZBaseAI < Dynamic
{
	public ZBaseAI()
	{
		return view_as<ZBaseAI>(Dynamic());
	}
	
	property int Index
	{
		public get()
		{
			return this.GetInt("index");
		}
		public set(int value)
		{
			this.SetInt("index", value);
		}
	}
	
	property int iHealth
	{
		public get()
		{
			return this.GetInt("iHealth");
		}
		public set(int value)
		{
			this.SetInt("iHealth", value);
		}
	}
	
	property int iAniEnt
	{
		public get()
		{
			return this.GetInt("AniEnt");
		}
		public set(int value)
		{
			this.SetInt("AniEnt", value);
		}
	}
	
	property int iAnimation
	{
		public get()
		{
			return GetEntProp(this.iAniEnt, Prop_Send, "m_nSequence");
		}
	}
	
	property float flSpeed
	{
		public get()
		{
			return GetEntPropFloat(this.Index, Prop_Data, "m_flSpeed");
		}
		public set(float value)
		{
			SetEntPropFloat(this.Index, Prop_Data, "m_flSpeed", value);
		}
	}
	
	property int iState
	{
		public get()
		{
			return this.GetInt("State");
		}
		public set(int state)
		{
			this.SetInt("State", state);
		}
	}
	
	property int iTarget
	{
		public get()
		{
			return GetEntPropEnt(this.Index, Prop_Send, "m_leader");
		}
		public set(int entity)
		{
			SetEntPropEnt(this.Index, Prop_Send, "m_leader", entity);
		}
	}
	
	property float flGetTargetThink
	{
		public get()
		{
			return this.GetFloat("flGetTargetThink");
		}
		public set(float value)
		{
			this.SetFloat("flGetTargetThink", value);
		}
	}
	
	property float flNextThink
	{
		public get()
		{
			return this.GetFloat("NextThink");
		}
		public set(float value)
		{
			this.SetFloat("NextThink", value);
		}
	}
	
	public int Create(char[] npc_name, float pos[3], char[] modelname, char[] default_ani)
	{
		int ai_entity = CreateEntityByName("chicken");
		int ani_entity = CreateEntityByName("prop_dynamic_ornament");
		
		char buffer[32];
		Format(buffer, sizeof(buffer), "ai_%d", ai_entity);
		this.SetName(buffer);
		
		g_npc_list.SetValue(buffer, view_as<int>(this));
		
		this.Index = ai_entity;
		this.iAniEnt = ani_entity;
		this.flNextThink = 0.0;
		
		DispatchKeyValue(ai_entity, "classname", npc_name);
		DispatchSpawn(ai_entity);
		TeleportEntity(ai_entity, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(ai_entity, modelname);
		SetEntProp(ai_entity, Prop_Data, "m_nModelIndex", PrecacheModel("models/chicken/chicken.mdl"));
		
		DispatchKeyValue(ani_entity, "model", modelname);
		DispatchKeyValue(ani_entity, "DefaultAnim", default_ani);
		DispatchSpawn(ani_entity);
		TeleportEntity(ani_entity, pos, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(ani_entity, "SetAttached", ai_entity, ani_entity, 0);
		
		SetEntityRenderMode(ai_entity, RENDER_NONE);
		SDKHook(ai_entity, SDKHook_Use, ChickenFollowBlock);
	
		
		return ai_entity;
	}
	
	public void MakeSound(char[] sound, int channel, float delay = 0.0)
	{
		if (FloatCompare(delay, 0.0) == 0)
		{
			EmitSoundToAllAny(sound, this.Index, channel, SNDLEVEL_NORMAL, _, 1.0);
			return;
		}
		
		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(this.Index));
		pack.WriteCell(this.iAnimation);
		pack.WriteString(sound);
		pack.WriteCell(channel);
		
		CreateTimer(delay, ZBaseAI_MakeSoundTimer, pack);
	}
	
	public bool Kill()
	{
		//SetVariantString("!activator");
		if (this.iAniEnt != -1)
			AcceptEntityInput(this.iAniEnt, "BecomeRagdoll");
		
		char buffer[32];
		Format(buffer, sizeof(buffer), "ai_%d", this.Index);
		g_npc_list.Remove(buffer);
		
		if (!IsValidEntity(this.Index))
			return false;
		
		TeleportEntity(this.Index, view_as<float>({9999.0, 9999.0, 999.0}), NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(this.Index, "FadeAndKill");
		
		this.Dispose();
		
		return true;
	}
}

public Action ZBaseAI_MakeSoundTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int ai_entity = EntRefToEntIndex(pack.ReadCell());
	if (ai_entity == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
	
	ZBaseAI base_ai = ZBaseAI_GetClass(ai_entity);
	
	if (base_ai.iAniEnt == -1)
		return Plugin_Continue;
	
	int seq = pack.ReadCell();
	char sound[192];
	pack.ReadString(sound, sizeof(sound));
	int channel = pack.ReadCell();
	
	if (base_ai.iAnimation != seq)
		return Plugin_Continue;
	
	EmitSoundToAllAny(sound, ai_entity, channel, SNDLEVEL_NORMAL, _, 1.0);
	return Plugin_Continue;
}
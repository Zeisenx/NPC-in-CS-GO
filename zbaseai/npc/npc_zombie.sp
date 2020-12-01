
//=========================================================
// ZombieState
//=========================================================
enum
{
	Sleep,
	Idle,
	Hunt,
}

int gBlood1;
int gBloodDecal;

char g_attack_animation[][] = {"attackA", "attackB", "attackC", "attackD", "attackE", "attackF"};

char g_footstep_sound[][] = {"zombie/foot1.mp3",
							 "zombie/foot2.mp3",
							 "zombie/foot3.mp3"};

char g_attack_voice_sound[][] = 		{"zombie/zo_attack1.mp3",
										 "zombie/zo_attack2.mp3"};

char g_die_sound[][] = 		{"zombie/zombie_die1.mp3",
							 "zombie/zombie_die2.mp3",
							 "zombie/zombie_die3.mp3"};

char g_alert_sound[][] = 		{"zombie/zombie_alert1.mp3",
								 "zombie/zombie_alert2.mp3",
								 "zombie/zombie_alert3.mp3"};

char g_pain_sound[][] = 	{"zombie/zombie_pain1.mp3",
							 "zombie/zombie_pain2.mp3",
							 "zombie/zombie_pain3.mp3",
							 "zombie/zombie_pain4.mp3",
							 "zombie/zombie_pain5.mp3",
							 "zombie/zombie_pain6.mp3"};

char g_idle_sound[][] = 	{"zombie/zombie_voice_idle1.mp3",
							 "zombie/zombie_voice_idle2.mp3",
							 "zombie/zombie_voice_idle3.mp3",
							 "zombie/zombie_voice_idle4.mp3",
							 "zombie/zombie_voice_idle5.mp3",
							 "zombie/zombie_voice_idle6.mp3",
							 "zombie/zombie_voice_idle7.mp3",
							 "zombie/zombie_voice_idle8.mp3",
							 "zombie/zombie_voice_idle9.mp3",
							 "zombie/zombie_voice_idle10.mp3",
							 "zombie/zombie_voice_idle11.mp3",
							 "zombie/zombie_voice_idle12.mp3",
							 "zombie/zombie_voice_idle13.mp3",
							 "zombie/zombie_voice_idle14.mp3"};

methodmap ZombieAI < ZBaseAI
{
	public void SetAnimation(char[] name)
	{
		SetVariantString(name);
		AcceptEntityInput(this.iAniEnt, "SetAnimation");
		
		if (StrEqual(name, "walk", false))
		{
			this.MakeSound(g_footstep_sound[GetRandomInt(0, sizeof(g_footstep_sound) - 1)], SNDCHAN_BODY, 0.11 * 1.92);
			this.MakeSound(g_footstep_sound[GetRandomInt(0, sizeof(g_footstep_sound) - 1)], SNDCHAN_BODY, 0.33 * 1.92);
			this.MakeSound(g_footstep_sound[GetRandomInt(0, sizeof(g_footstep_sound) - 1)], SNDCHAN_BODY, 0.62 * 1.92);
			this.MakeSound(g_footstep_sound[GetRandomInt(0, sizeof(g_footstep_sound) - 1)], SNDCHAN_BODY, 0.84 * 1.92);
			
			this.flNextThink = GetGameTime() + 1.92;
		}
	}
	
	public void Attack(int target)
	{
		this.MakeSound(g_attack_voice_sound[GetRandomInt(0, sizeof(g_attack_voice_sound) - 1)], SNDCHAN_VOICE, 0.0);
		
		this.SetAnimation(g_attack_animation[GetRandomInt(0, sizeof(g_attack_animation) - 1)]);
		this.flNextThink = GetGameTime() + 1.86;
	}
	
	public bool IsAbleToEnemy(int target)
	{
		if (target == this.iTarget)
			return false;
		
		float angle = GetTargetAngleToFOV(this.Index, target);
		if (angle <= 50.0 && EntityCanSeeTarget(this.Index, target))
			return true;
		
		return false;
	}
	
	property float flNextIdleSound
	{
		public get()
		{
			return this.GetFloat("flNextIdleSound");
		}
		public set(float value)
		{
			this.SetFloat("flNextIdleSound", value);
		}
	}
	
	property float flCombatRange
	{
		public get()
		{
			return this.GetFloat("CombatRange");
		}
		public set(float value)
		{
			this.SetFloat("CombatRange", value);
		}
	}
}

public OnPluginStart_NPCZombie()
{	
	RegConsoleCmd("sm_testzombie", TestZombie);
	
	HookEvent("weapon_fire", OnWeaponFire);
}

public OnMapStart_NPCZombie()
{
	gBlood1 = PrecacheDecal("sprites/bloodspray.vmt");
	gBloodDecal = PrecacheDecal("decals/yblood1.vmt");
	
	Z_PreLoadModel("models/zombie/classic");
	
	for (int i=0; i<sizeof(g_attack_animation); i++)
		Z_PreLoadFile(g_attack_animation[i]);
		
	for (int i=0; i<sizeof(g_footstep_sound); i++)
		Z_PreLoadFile(g_footstep_sound[i]);
	
	for (int i=0; i<sizeof(g_pain_sound); i++)
		Z_PreLoadFile(g_pain_sound[i]);
		
	for (int i=0; i<sizeof(g_die_sound); i++)
		Z_PreLoadFile(g_die_sound[i]);
	
	for (int i=0; i<sizeof(g_attack_voice_sound); i++)
		Z_PreLoadFile(g_attack_voice_sound[i]);
	
	for (int i=0; i<sizeof(g_alert_sound); i++)
		Z_PreLoadFile(g_alert_sound[i]);
		
	for (int i=0; i<sizeof(g_idle_sound); i++)
		Z_PreLoadFile(g_idle_sound[i]);
}

public Action OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	NPCSoundCheck(client);
}

public Zombie_SoundHook(int sound_entity, char[] sample)
{
	if (StrContains(sample, "player") != -1)
	{
		NPCSoundCheck(sound_entity);
	}
}

public Action TestZombie(int client, int args)
{
	float aim_pos[3];
	if (!GetClientAimLookAt(client, aim_pos))
		return Plugin_Continue;
	
	ZombieAI base_ai = view_as<ZombieAI>(ZBaseAI());
	base_ai.Create("npc_zombie", aim_pos, "models/zombie/classic.mdl", "Idle01");
	
	base_ai.iState = Sleep;
	base_ai.iHealth = 300;
	base_ai.flSpeed = 130.0;
	//base_ai.iTarget = client;
	base_ai.flCombatRange = 75.0;
	base_ai.flNextIdleSound = GetGameTime() + GetRandomFloat(2.0, 4.0);
	
	SDKHook(base_ai.Index, SDKHook_Think, OnZombieThink);
	SDKHook(base_ai.Index, SDKHook_OnTakeDamage, OnZombieTakeDamage);
	return Plugin_Handled;
}

public NPCSoundCheck(int sound_entity)
{
	int zombie = -1;
	while ( (zombie = FindEntityByClassname(zombie, "npc_zombie")) != -1)
	{
		ZombieAI base_ai = view_as<ZombieAI>(ZBaseAI_GetClass(zombie));
		if (!base_ai.IsValid || base_ai.iHealth <= 0)
			continue;
		
		if (base_ai.iTarget <= 0)
		{
			float entity_eyepos[3];
			GetEntityEyePosition(zombie, entity_eyepos);
			
			float sound_pos[3];
			GetEntityOrigin(sound_entity, sound_pos);
			
			float pos_vec[3];
			MakeVectorFromPoints(entity_eyepos, sound_pos, pos_vec);
			
			float result_angle[3];
			GetVectorAngles(pos_vec, result_angle);
			
			result_angle[0] = 0.0;
			
			TeleportEntity(zombie, NULL_VECTOR, result_angle, NULL_VECTOR);
		}
	}
}
public Action OnZombieThink(int ai_entity)
{
	ZombieAI base_ai = view_as<ZombieAI>(ZBaseAI_GetClass(ai_entity));
	if (!base_ai.IsValid || base_ai.iHealth <= 0)
	{
		SDKUnhook(base_ai.Index, SDKHook_Think, OnZombieThink);
		return Plugin_Continue;
	}
	
	float gametime = GetGameTime();
	if (gametime >= base_ai.flNextIdleSound)
	{
		base_ai.MakeSound(g_idle_sound[GetRandomInt(0, sizeof(g_idle_sound) - 1)], SNDCHAN_VOICE, 0.0);
		base_ai.flNextIdleSound = gametime + GetRandomFloat(3.0, 5.0);
	}
	
	float angle[3];
	GetEntPropVector(ai_entity, Prop_Data, "m_angRotation", angle);
	
	bool go_forward = false;
	
	float distance = -1.0;
	if (base_ai.iTarget > 0)
	{
		distance = GetEntityDistance(ai_entity, base_ai.iTarget);
		if (distance > base_ai.flCombatRange)
			go_forward = true;
	}
	
	if (gametime >= base_ai.flGetTargetThink)
	{
		if (base_ai.iTarget > 0)
		{
			if (!EntityCanSeeTarget(ai_entity, base_ai.iTarget) || GetTargetAngleToFOV(ai_entity, base_ai.iTarget) > 50.0)
			{
				base_ai.iTarget = 0;
				base_ai.iState = Idle;
			}
		}
		
		int find_target = -1; float find_target_distance = 2000.0;
		
		int target = -1;
		while ( (target = FindEntityByClassname(target, "player") != -1) )
		{
			if (!(base_ai.IsAbleToEnemy(target)))
				continue;
			
			float i_distance = GetEntityDistance(ai_entity, target);
			if (i_distance > find_target_distance)
				continue;
				
			find_target = target;
			find_target_distance = i_distance;
		}
		
		if (find_target > 0)
		{
			base_ai.iTarget = find_target;
			go_forward = true;
			distance = GetEntityDistance(ai_entity, base_ai.iTarget);
			
			if (base_ai.iState == Sleep)
			{
				base_ai.iState = Hunt;
				base_ai.MakeSound(g_alert_sound[GetRandomInt(0, sizeof(g_alert_sound) - 1)], SNDCHAN_VOICE);
			}
		}
		
		base_ai.flGetTargetThink = gametime + base_ai.iTarget > 0 ? 3.0 : 0.25;
	}
	
	OnZombieAniThink(base_ai, distance);
	
	int seq = GetEntProp(ai_entity, Prop_Send, "m_nSequence");
	SetEntProp(ai_entity, Prop_Send, "m_nSequence", go_forward ? 2 : 0);
	
	if (go_forward)
	{
		if (base_ai.iTarget == -1)
			return Plugin_Continue;
		
		float f_velocity[3];
		GetAngleVectors(angle, f_velocity, NULL_VECTOR, NULL_VECTOR);
		
		float move_velocity[3];
		Vector_Copy(f_velocity, move_velocity);
		ScaleVector(move_velocity, GetEntPropFloat(ai_entity, Prop_Data, "m_flSpeed"));
		
		ScaleVector(f_velocity, -120.0);
		AddVectors(f_velocity, move_velocity, f_velocity);
		
		TeleportEntity(ai_entity, NULL_VECTOR, NULL_VECTOR, f_velocity);
	}
	else if (seq == 2 && base_ai.iTarget > 0 && distance <= base_ai.flCombatRange)
	{
		TeleportEntity(ai_entity, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
		base_ai.Attack(base_ai.iTarget);
	}
		
	return Plugin_Continue;
}

public OnZombieAniThink(ZombieAI zombie_ai, float distance)
{
	float gametime = GetGameTime();
	
	if (!zombie_ai.IsValid || zombie_ai.Index == -1)
		return;
		
	if (gametime < zombie_ai.flNextThink)
		return;
	
	if (zombie_ai.iTarget > 0)
	{
		if (distance <= zombie_ai.flCombatRange)
		{
			zombie_ai.Attack(zombie_ai.iTarget);
		}
		else
		{
			zombie_ai.SetAnimation("walk");
		}
	}
	else
		zombie_ai.SetAnimation("Idle01");
}

public Action OnZombieTakeDamage(int ai_entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	ZBaseAI base_ai = ZBaseAI_GetClass(ai_entity);
	
	float angles[3];
	GetEntPropVector(attacker, Prop_Send, "m_angRotation", angles);
	
	float pos[3];
	GetEntPropVector(ai_entity, Prop_Send, "m_vecOrigin", pos);
	
	GoreDecal(pos, 1);
	/*for (int i=1; i<=3; i++)
	{
		TE_SetupBloodSprite(damagePosition, angles, {255, 0, 0, 255}, 40, gBlood1, 0);
		TE_SendToAll();
	}*/
	
	MakeBlood(damagePosition, angles, "96", damage * 0.2, 1);
	
	int idamage = RoundToFloor(damage);
	base_ai.iHealth = base_ai.iHealth - idamage;
	if (base_ai.iHealth < 1)
	{
		base_ai.MakeSound(g_die_sound[GetRandomInt(0, sizeof(g_die_sound) - 1)], SNDCHAN_VOICE);
		base_ai.Kill();
	}
	else
	{
		base_ai.MakeSound(g_pain_sound[GetRandomInt(0, sizeof(g_pain_sound) - 1)], SNDCHAN_VOICE);
	}
	
	return Plugin_Handled;
}


GoreDecal(float pos[3], int count)
{
	for (int i = 0; i < count; i++)
	{
		pos[0] += GetRandomFloat(-25.0, 25.0);
		pos[1] += GetRandomFloat(-25.0, 25.0);

		TE_Start("World Decal");
		TE_WriteVector("m_vecOrigin", pos);
		TE_WriteNum("m_nIndex", gBloodDecal);
		TE_SendToAll();
	}
}

stock MakeBlood(float pos[3], float dir[3], char[] flags, float amount, int bloodcolor)
{
	int blood_entity = CreateEntityByName("env_blood");
	DispatchKeyValue(blood_entity, "spawnflags", flags);
	
	char buffer[32];
	Format(buffer, sizeof(buffer), "%d", RoundToFloor(amount));
	
	DispatchKeyValue(blood_entity, "amount", buffer);
	DispatchSpawn(blood_entity);
	TeleportEntity(blood_entity, pos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntPropVector(blood_entity, Prop_Data, "m_vecSprayDir", dir);
	SetEntProp(blood_entity, Prop_Data, "m_Color", 1);
	
	AcceptEntityInput(blood_entity, "EmitBlood");
	AcceptEntityInput(blood_entity, "Kill");
}
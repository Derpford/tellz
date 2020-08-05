class TargetHandler : EventHandler
{
	override void WorldThingSpawned(WorldEvent e)
	{
		Actor mo = e.thing;
		// If this doesn't do monster things, we can skip it.
		if( mo.bISMONSTER )
		{
			//console.printf("Gave "..mo.GetTag().." a Target Computer.");
			mo.A_GiveInventory("TargetingComputer");
		}

		// If it's a projectile, we should check if it has a tracer set.
		if( ( mo.bMISSILE || mo is "ArchvileFire" ) && mo.tracer != null )
		{
			//console.printf("Giving a "..mo.GetTag().." missile computer!" );
			mo.A_GiveInventory("MissileComputer");
			if( mo.tracer is "TargetPoint" )
			{
				let it = TargetPoint(mo.tracer);
				mo.tracer = it.realtarget;
			}
		}
	}
}

class TargetingComputer : Inventory
{
	Actor realtarget;
	Actor tpoint;
	default
	{
		Inventory.MaxAmount 1;
	}

	bool GrabTarget()
	{
		//console.printf("Getting a lock...");
		bool result = false;
		if( owner.target != null && !(owner.target is "TargetPoint" ) )
		{
			realtarget = owner.target;
			[result, owner.target] = realtarget.A_SpawnItemEX("TargetPoint");
			let tgt = TargetPoint(owner.target);
			if(tgt != null)
			{
				//console.printf("Lock successful.");
				tgt.master = owner;
				tgt.realtarget = realtarget;
			}
		}
		else
		{
			result = true; // We already have a targetpoint.
		}
		return result;
	}

	bool ReleaseTarget()
	{
		bool result = false;
		if( owner.target != null && owner.target is "TargetPoint" )
		{
			owner.target.SetState(owner.target.ResolveState("Pain"));
			result = true;
		}
		return result;
	}

	override void DoEffect()
	{
		//console.printf("Handling targeting for "..owner.GetTag());
		if( owner.bCORPSE )
		{
			//console.printf("User death imminent...");
			ReleaseTarget();
			return; // Don't do anything on dead monsters.
		}

		if( owner.InStateSequence( owner.curstate, owner.ResolveState("Missile") ) )
		{
			bool result = GrabTarget();
			//console.printf(owner.GetTag().." is shooting!");
			if(!result)
			{
				ReleaseTarget();
			}
		}

		if( owner.InStateSequence( owner.curstate, owner.ResolveState("Melee") ) || owner.bSKULLFLY )
		{
			bool result = GrabTarget();
			//console.printf(owner.GetTag().." is punching!");
			if( !result )
			{
				ReleaseTarget();
			}
			bool spawnedParticle; actor it;
			[spawnedParticle, it] = owner.A_SpawnItemEX("TargetCircle",zofs:owner.height/2);
			it.meleerange = owner.meleerange;
		}

		if( owner.curstate == owner.ResolveState("See") )
		{
			ReleaseTarget();
		}
	}
}

class MissileComputer : Inventory
{
	// Handles drawing the circle around homing missiles.
	default
	{
		Inventory.MaxAmount 1;
	}

	override void DoEffect()
	{
		if( true )
		{
			Vector3 npos = owner.pos;
			npos.z = owner.tracer.pos.z + owner.tracer.height/2;
			Actor circle = owner.Spawn("TargetCircle2",npos);
			Actor trace = owner.Spawn("TargetTracer2",npos);
			trace.A_Face(owner.tracer,max_pitch:180,z_ofs:owner.tracer.height/2);
			circle.meleerange = owner.Distance2D(owner.tracer);
		}
	}

}

class TargetPoint : Actor
{
	Actor realtarget;

	default
	{
		+NOGRAVITY;
		+NOINTERACTION;
		-SHOOTABLE;
		ReactionTime 3;
	}


	override int DamageMobj(Actor inflictor, Actor source, int dmg, name mod, int flags, double angle)
	{
		if( Distance2D(source)-self.radius <= source.meleerange || mod == "Melee")
		{
			if( realtarget.Distance2D(source)-realtarget.radius <= source.meleerange )
			{
				source.A_Face(realtarget);
				realtarget.DamageMobj(inflictor,source,dmg,mod,flags,angle);
			}
		}

		return super.DamageMobj(inflictor,source,dmg,mod,flags,angle);
	}

	states
	{
		Spawn:
			TNT1 A 0;
			TNT1 A 0
			{
				if( master == null )
				{
					return ResolveState("Death");
				}

				if( !master.bCORPSE )
				{
					//master.A_CustomRailgun(0,color1:"",color2:"red",
					//	flags: RGF_SILENT|RGF_FULLBRIGHT|RGF_NORANDOMPUFFZ,aim:1,pufftype:"TargetPuff");
					Vector3 npos = master.pos;
					npos.z += master.height/2;
					Actor trace = master.Spawn("TargetTracer",npos);
					trace.A_Face(self,max_pitch:180,z_ofs:realtarget.height/2);
				}

				if( master.curstate == master.ResolveState("See") )
				{
					// It's time to stop.
					return ResolveState("Death");
				}
				else
				{
					return ResolveState(null);
				}
			}
			TNT1 A 15 A_Countdown();
			Loop;
		Pain:
		Death:
			TNT1 A 1;
			Stop;
	}
}

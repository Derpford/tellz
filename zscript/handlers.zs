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
		if( ( mo.bMISSILE  ) && mo.tracer != null ) /*|| mo is "ArchvileFire" */
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
			owner.A_KillChildren("TargetPointRemover",filter:"TargetPoint"); // Remove any targetpoints that we might've switched from.
			realtarget = owner.target;
			[result, owner.target] = realtarget.A_SpawnItemEX("TargetPoint");
			let tgt = TargetPoint(owner.target);
			if(tgt != null)
			{
				//console.printf("Lock successful.");
				tgt.master = owner;
				tgt.realtarget = realtarget;
			}

			// Handle the archvile fire shenanigans.
			if( owner.tracer != null )
			{
				owner.tracer.tracer = owner.target;
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
	bool debug;

	property Debug: debug;

	default
	{
		TargetPoint.Debug true;
		+NOGRAVITY;
		+NOBLOCKMAP;
		+NOINTERACTION;
		+SHOOTABLE;
		+THRUACTORS;
		ReactionTime 3;
	}


	override int DamageMobj(Actor inflictor, Actor source, int dmg, name mod, int flags, double angle)
	{
		// Since this object is neither tangible nor interactable, it only takes damage if:
		// 1. Something has melee-attacked it.
		// 2. Something has archvile-fire'd it.
		// 3. Some other effect was supposed to direct-damage the player but was instead applied to the targetpoint.
		// Therefore, we can safely assume that any damage which is applied directly to the target point
		// was *supposed* to be applied on top of the player's position.
		// So we can transfer it with an AoE centered on the targetpoint.

		// First, check if this is a TargetPointRemover thing.
		if( mod == "TargetPointRemover" )
		{
			return super.DamageMobj(inflictor,source,dmg,mod,flags,angle);
		}
		else
		{
			BlockThingsIterator it = BlockThingsIterator.create(self,master.meleerange/4);
			//console.printf("Direct damage detected!");
			while( it.next() )
			{
				if( it.thing is master.species ) { continue; } // No infighting within species.
				if( it.thing == master ) { continue; } // skip master.
				double dmgmod = Distance3D(it.thing)/master.meleerange/4;

				it.thing.DamageMobj(inflictor,source,dmg*dmgmod,mod,flags,angle);
			}
			//A_Die();
			return super.DamageMobj(inflictor,source,dmg,mod,flags,angle);
		}
	}

	states
	{
		Spawn:
			TNT1 A 0;
			TNT1 A 0
			{
				if( debug )
				{
					return ResolveState("Debug");
				}
				else
				{
					return ResolveState("MainLoop");
				}
			}
		Debug:
			PLS2 A 0 bright;
		MainLoop:
			#### A 0;
			#### A 0
			{
				if( master == null )
				{
					return ResolveState("Death");
				}

				if( !master.bCORPSE )
				{
					if( master.InStateSequence(master.curstate,master.ResolveState("missile")) )
					{
						//master.A_CustomRailgun(0,color1:"",color2:"red",
						//	flags: RGF_SILENT|RGF_FULLBRIGHT|RGF_NORANDOMPUFFZ,aim:1,pufftype:"TargetPuff");
						Vector3 npos = master.pos;
						npos.z += master.height/2;
						Actor trace = master.Spawn("TargetTracer",npos);
						trace.A_Face(self,max_pitch:180,z_ofs:realtarget.height/2);
					}

					if( master.InStateSequence(master.curstate,master.ResolveState("melee")) )
					{
						bool spawnedParticle; actor it;
						[spawnedParticle, it] = master.A_SpawnItemEX("TargetCircle",zofs:master.height/2);
						it.meleerange = master.meleerange;
					}
				}
				else
				{
					return ResolveState("Death"); // Master's dead.
				}

				if( master.InStateSequence(master.curstate,master.ResolveState("See")) )
				{
					// It's time to stop.
					return ResolveState("Death");
				}
				else
				{
					return ResolveState(null);
				}
			}
			#### AB 7 ;//A_Countdown();
			Loop;
		Pain:
		Death:
			TNT1 A 1;
			Stop;
	}
}

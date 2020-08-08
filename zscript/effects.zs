class LaserEffect : Actor
{

	bool debug;

	color lasercolor;
	double laserlife;
	double lasersize;

	Property Color : lasercolor;
	Property Size : lasersize;
	Property Life : laserlife;

	virtual void DoLaserEffect()
	{
		// Creates the particle effects.
	}

	void LaserParticle(color col, double x, double y, double z)
	{
		//int extra = min(floor(life/12),35);
		A_SpawnParticle(col,SPF_FULLBRIGHT|SPF_RELANG,frandom(laserlife,laserlife*2),lasersize,frandom(-1.0,1.0),
			x,y,z);
	}

	override void PostBeginPlay()
	{
		DoLaserEffect();
		debug = false;
	}

	default
	{
		LaserEffect.Color "Red";
		LaserEffect.Size 2.0;
		LaserEffect.Life 20;
		radius 64;
		+NOINTERACTION;
		+THRUACTORS;
	}

	states
	{
		Spawn:
			TNT1 A 0
			{
				if( debug )
				{
					return ResolveState("debug");
				}
				else
				{
					return ResolveState("null");
				}
			}
			Stop;
		debug:
			PLS2 A -1;
			Stop;
	}
}

class TargetTracer : LaserEffect
{
	override void DoLaserEffect()
	{
		FLineTraceData laserTrace;
		LineTrace(angle, 16384, pitch, TRF_THRUACTORS, 32,  data: laserTrace);
		for( double f = 1; f< laserTrace.distance; f = f + frandom(1,5) )
		{
			LaserParticle(lasercolor,(cos(pitch) * cos(angle) * f),(cos(pitch) * sin(angle) * f),(sin(-pitch) * f));
		}
	}
}

class TargetTracer2 : LaserEffect
{
	default
	{
		LaserEffect.Color "Yellow";
		LaserEffect.Life 1;
	}
}

class TargetCircle : LaserEffect
{

	default
	{
		LaserEffect.Color "Yellow";
	}

	override void DoLaserEffect()
	{
		for( double f = 0; f < 360; f = f + meleerange / 18 )
		{
			double xp = ( sin(f) * meleerange );
			double yp = ( cos(f) * meleerange );
			LaserParticle(lasercolor,xp,yp,0);
		}
	}
}

class TargetCircle2 : TargetCircle
{
	default
	{
		LaserEffect.Color "Yellow";
		LaserEffect.Size 5.0;
		LaserEffect.Life 1;
	}

	override void DoLaserEffect()
	{
		for( double f = 0; f < 360; f = f + meleerange / 36 )
		{
			double xp = ( sin(f) * meleerange );
			double yp = ( cos(f) * meleerange );
			LaserParticle(lasercolor,xp,yp,0);
		}
	}
}

class TargetPuff : BulletPuff
{
	default
	{
		RenderStyle "add";
		+PUFFONACTORS;
		VSpeed 0;

	}

	states
	{
		Spawn:
		Melee:
			PLS2 AB 4 Bright;
			Stop;
		Crash:
			TNT1 A 0;
			Stop;
	}
}

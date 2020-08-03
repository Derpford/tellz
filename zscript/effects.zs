class LaserEffect : Actor
{
	virtual void DoLaserEffect()
	{
		// Creates the particle effects.
	}

	void LaserParticle(color col, double x, double y, double z, double life)
	{
		int extra = min(floor(life/12),35);
		A_SpawnParticle(col,SPF_FULLBRIGHT|SPF_RELANG,random(extra,20+extra),2.0,frandom(-1.0,1.0),
			x,y,z);
	}

	override void PostBeginPlay()
	{
		DoLaserEffect();
	}

	default
	{
		radius 64;
		+NOINTERACTION;
		+THRUACTORS;
	}

	states
	{
		Spawn:
			TNT1 A 0;
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
			LaserParticle("Red",(cos(pitch) * cos(angle) * f),(cos(pitch) * sin(angle) * f),(sin(-pitch) * f),35);
		}
	}
}

class TargetCircle : LaserEffect
{

	override void DoLaserEffect()
	{
		for( double f = 0; f < 360; f = f + frandom(1,2) )
		{

			double xp = ( sin(f) * meleerange );
			double yp = ( cos(f) * meleerange );
			LaserParticle("Yellow",xp,yp,0,35);
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

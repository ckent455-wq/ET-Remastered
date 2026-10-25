extends RefCounted
## Damaged bodies still answer the signal. Disabling a leg buys distance, not a free kill.
func reset(d):
 d["leg_trauma"]=0.0;d["limp_time"]=0.0;d["leg_resistance"]=0.0;d["combat_clock"]=float(d.index)*0.63
func tick(d,delta:float):
 for key in ["limp_time","leg_resistance"]:d[key]=maxf(0,d.get(key,0.0)-delta)
 d["combat_clock"]=d.get("combat_clock",0.0)+delta
func hit(d,zone:String,damage:float):
 if zone!="leg" or d.hp<=0 or d.get("leg_resistance",0.0)>0:return
 d["leg_trauma"]=d.get("leg_trauma",0.0)+damage
 if d.leg_trauma>=28.0:
  d.leg_trauma=0.0;d.limp_time=3.0;d.leg_resistance=7.0
func movement(d)->float:
 if d.get("limp_time",0.0)>0:return 0.48
 if d.hp>0 and d.hp<d.get("max_hp",240.0)*0.4:
  # A brief effort followed by recovery, rather than permanently faster wounded enemies.
  return 1.28 if fmod(d.get("combat_clock",0.0),4.5)<1.15 else 0.92
 return 1.0

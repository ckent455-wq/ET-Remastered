extends RefCounted
## A separate encounter in the Victorian cellar; it never follows the exit portal.
func update(enemies,data,delta: float):
	var game = enemies.game
	var cellar = game.victorian_house.cellar
	var inside = game.victorian_house.cellar_contains(game.player.global_position)
	var player: Vector3 = cellar.to_local(game.player.global_position)
	if data.state=="cellar_wait":
		if inside and player.z<0.3:
			data.state="cellar_rush"
			data.voice.stream=enemies.streams.attack
			data.voice.volume_db=-10
			data.voice.pitch_scale=0.75
			data.voice.play()
		return
	data.timer=maxf(0,data.timer-delta)
	data.cooldown=maxf(0,data.cooldown-delta)
	if data.state=="stagger":
		if data.timer<=0: data.state="cellar_rush"
		return
	if data.state=="attack":
		if not data.did_hit and data.timer<0.55:
			data.did_hit=true
			if inside and data.actor.global_position.distance_to(game.player.global_position)<1.8 and enemies.line_clear(data,game.player.global_position+Vector3.UP): game.take_damage(18)
		if data.timer<=0:
			data.state="cellar_rush"
			data.cooldown=1.1
		return
	if not inside:
		enemies.play(data,"idle1")
		enemies.house_encounter.move(data,Vector3.ZERO,delta)
		return
	var destination = Vector3(0,0.01,-1.8)
	if not data.cellar_waypoint and data.actor.global_position.distance_to(cellar.to_global(destination))<0.4: data.cellar_waypoint=true
	if data.cellar_waypoint: destination=Vector3(clampf(player.x,-3.0,3.0),0.01,clampf(player.z,-3.5,1.5))
	if data.actor.global_position.distance_to(game.player.global_position)<1.55 and data.cooldown<=0 and enemies.line_clear(data,game.player.global_position+Vector3.UP):
		data.state="attack"
		data.timer=1.15
		data.did_hit=false
		enemies.play(data,"punch")
		return
	var direction: Vector3 = cellar.to_global(destination)-data.actor.global_position
	direction.y=0
	enemies.play(data,"walk1")
	data.animation.speed_scale=1.3
	var desired = direction.normalized()*1.8 if direction.length()>0.3 else Vector3.ZERO
	enemies.house_encounter.move(data,desired,delta)

extends CharacterBody3D

@onready var BloodSplatter = preload("res://blood_splatter.tscn")
@onready var DeathBloodSplatter = preload("res://death_blood_splatter.tscn")
@onready var BloodDecal = preload("res://blood_decal.tscn")

@export var attack_damage = 25  # How much damage each hit does
@export var attack_cooldown = 1.0  # Time between attacks
var attack_timer = 0.0

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var ambient_sound: AudioStreamPlayer3D = $PigCopAmbientSound
@onready var blood_spawn: Node3D = $BloodSpawn

@export var move_speed = 2.0
@export var attack_range = 2.0
@export var max_hp = 100
var hp: int

@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("Player")
var dead = false

# constants for gravity
const GRAVITY = 30.0

var navigation_map: RID
var path: PackedVector3Array
var path_index: int = 0
var path_recalc_timer: float = 0.0
const PATH_RECALC_INTERVAL: float = 0.5

var knockback_timer := 0.0
var knockback_decay := 5.0  # Controls how fast knockback fades

@export var separation_range: float = 3.0
@export var separation_force: float = 1.0

func _ready():
	hp = max_hp
	ambient_sound.play()
	add_to_group("Enemy")
	
	var nav_region = get_tree().get_first_node_in_group("NavigationRegion3D")
	if not nav_region:
		nav_region = get_node_or_null("/root/World/NavigationRegion3D")
	if nav_region:
		navigation_map = nav_region.get_navigation_map()
		print("Navigation map set: ", navigation_map)
	else:
		print("No navigation region found!")
	
func take_damage(amount: int, hit_position: Vector3, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if dead or not is_inside_tree():
		return

	# Capture safe transform position first
	var spawn_position = blood_spawn.global_position if is_instance_valid(blood_spawn) else global_position

	# Apply knockback force
	if knockback_dir != Vector3.ZERO:
		velocity += knockback_dir.normalized() * 80.0
		knockback_timer = 0.2  # Knockback lasts for 0.2 seconds

	# Spawn blood particles
	var blood = BloodSplatter.instantiate()
	blood.global_position = hit_position
	get_tree().current_scene.add_child(blood)

	var particles = blood.get_node_or_null("GPUParticles3D")
	if particles:
		particles.emitting = true

	# Spawn blood decal
	var blood_decal = BloodDecal.instantiate()
	blood_decal.global_position = spawn_position
	blood_decal.rotation.y = randf() * TAU
	get_tree().current_scene.add_child(blood_decal)

	if $FleshHitSound:
		$FleshHitSound.play()

	hp -= amount
	if hp <= 0:
		kill()


func _physics_process(_delta: float) -> void:
	
	if dead:
		return
	if player == null:
		return
		
	# apply gravity first
	velocity.y -= GRAVITY * _delta

	if knockback_timer > 0.0:
		knockback_timer -= _delta
		velocity.x = move_toward(velocity.x, 0, knockback_decay)
		velocity.z = move_toward(velocity.z, 0, knockback_decay)
	else:
		var move_dir = Vector3.ZERO
		
		if navigation_map.is_valid():
			path_recalc_timer -= _delta
			if path_recalc_timer <= 0:
				path_recalc_timer = PATH_RECALC_INTERVAL
				var target_pos = player.global_position
				target_pos.y = global_position.y
				path = NavigationServer3D.map_get_path(navigation_map, global_position, target_pos, true)
				path_index = 0
			
			if path.size() > 0 and path_index < path.size():
				var target = path[path_index]
				target.y = global_position.y
				var to_target = target - global_position
				if to_target.length() < 0.5:
					path_index += 1
				else:
					move_dir = to_target.normalized()
			else:
				var to_player = player.global_position - global_position
				to_player.y = 0
				move_dir = to_player.normalized()
		else:
			var to_player = player.global_position - global_position
			to_player.y = 0
			move_dir = to_player.normalized()
		
		move_dir = calculate_separation(move_dir)
		
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		
	if attack_timer > 0:
		attack_timer -= _delta
	else:
		attempt_to_damage_player()

	move_and_slide()
	#attempt_to_kill_player()

func calculate_separation(base_dir: Vector3) -> Vector3:
	var separation = Vector3.ZERO
	var nearby_count = 0
	
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue
		
		var to_enemy = enemy.global_position - global_position
		to_enemy.y = 0
		var dist = to_enemy.length()
		
		if dist < separation_range and dist > 0:
			separation -= to_enemy.normalized() * (1.0 - dist / separation_range)
			nearby_count += 1
	
	if nearby_count > 0:
		separation /= nearby_count
		return (base_dir + separation * separation_force).normalized()
	
	return base_dir

func attempt_to_damage_player():
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player > attack_range:
		return
	
	var eye_line = Vector3.UP * 1.5
	var query = PhysicsRayQueryParameters3D.create(global_position+eye_line, player.global_position+eye_line, 1)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty() and player.has_method("take_damage"):
		player.take_damage(attack_damage)
		attack_timer = attack_cooldown  # reset cooldown

#func attempt_to_kill_player():
	#var dist_to_player = global_position.distance_to(player.global_position)
	#if dist_to_player > attack_range:
		#return
	#
	#var eye_line = Vector3.UP * 1.5
	#var query = PhysicsRayQueryParameters3D.create(global_position+eye_line, player.global_position+eye_line, 1)
	#var result = get_world_3d().direct_space_state.intersect_ray(query)
	#if result.is_empty():
		#player.kill()

func kill():
	if dead or not is_inside_tree():
		return

	dead = true

	# Capture transform and child node positions before making any changes
	var death_position = global_position
	var decal_position = blood_spawn.global_position if is_instance_valid(blood_spawn) else death_position

	# Play sounds and animations
	if is_instance_valid(ambient_sound):
		ambient_sound.stop()

	if has_node("DeathSound"):
		$DeathSound.play()

	if has_node("FleshExplosionSound"):
		$FleshExplosionSound.play()

	if is_instance_valid(animated_sprite_3d):
		animated_sprite_3d.play("death")

	if has_node("CollisionShape3D"):
		$CollisionShape3D.call_deferred("set_disabled", true)

	# Spawn death blood splatter
	var death_blood = DeathBloodSplatter.instantiate()
	death_blood.global_position = death_position
	get_tree().current_scene.add_child(death_blood)

	var particles = death_blood.get_node_or_null("GPUParticles3D")
	if particles:
		particles.emitting = true

	# Spawn big blood decal
	var big_blood_decal = BloodDecal.instantiate()
	big_blood_decal.global_position = decal_position + Vector3(0, randf() * 0.02, 0)
	big_blood_decal.rotation.y = randf() * TAU
	big_blood_decal.extents = Vector3(2, 1, 2)
	get_tree().current_scene.add_child(big_blood_decal)

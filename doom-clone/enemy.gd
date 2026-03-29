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

var knockback_timer := 0.0
var knockback_decay := 5.0  # Controls how fast knockback fades

func _ready():
	hp = max_hp
	ambient_sound.play()
	
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
		var dir = player.global_position - global_position
		dir.y = 0.0
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		
	if attack_timer > 0:
		attack_timer -= _delta
	else:
		attempt_to_damage_player()

	move_and_slide()
	#attempt_to_kill_player()

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

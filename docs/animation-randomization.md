# Enemy Animation Randomization

## Overview

By default, all enemies start their walk animation at frame 0, causing them to appear synchronized when moving together. This creates an unnatural, robotic feel. Randomizing the starting frame breaks up this synchronization and makes the scene feel more organic.

## Implementation

**Location:** `enemy.gd` in `_ready()`

```gdscript
func _ready():
    hp = max_hp
    ambient_sound.play()
    add_to_group("Enemy")
    
    # Randomize walk animation starting frame
    animated_sprite_3d.frame = randi() % animated_sprite_3d.sprite_frames.get_frame_count("idle")
    
    # ... rest of setup
```

## How It Works

1. `animated_sprite_3d.sprite_frames.get_frame_count("idle")` gets the total number of frames in the idle/walk animation
2. `randi() % frame_count` generates a random integer from 0 to (frame_count - 1)
3. Assigning this to `animated_sprite_3d.frame` sets the starting frame

## Example

If the idle animation has 4 frames:
- Enemy 1 might start at frame 2
- Enemy 2 might start at frame 0
- Enemy 3 might start at frame 3
- Enemy 4 might start at frame 1

Result: Each enemy walks slightly out of phase with the others.

## Other Randomization Ideas

### Ambient Sound Offset
```gdscript
ambient_sound.play(randi() % 10000 * 0.001)  # Random start position
```
Makes enemy sounds feel less repetitive.

### Movement Speed Variation
```gdscript
@export var move_speed: float = 2.0
@export var speed_variance: float = 0.3  # +/- variance

func _ready():
    move_speed += randf_range(-speed_variance, speed_variance)
```
Each enemy moves at a slightly different speed.

### Staggered Spawns
When spawning enemies, add a small delay:
```gdscript
await get_tree().create_timer(randf() * 2.0).timeout
```

## Relevant Files

| File | Purpose |
|------|---------|
| `enemy.gd` | Contains the randomization logic |
| `enemy.tscn` | Enemy scene with AnimatedSprite3D |

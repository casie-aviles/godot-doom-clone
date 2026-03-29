# Kick Screen Shake Feedback

## Overview

Screen shake provides tactile feedback when the player's kick attack successfully hits an enemy. It reinforces the impact of the attack and makes combat feel more punchy.

## How It Works

### Trigger
- Screen shake only triggers on **successful enemy hit**, not on every kick
- Triggered in `_on_kick_area_3d_body_entered()` when the kick area collides with an enemy

### Implementation

**Variables (in `player.gd`):**
```gdscript
var shake_duration: float = 0.0   # How long the shake lasts
var shake_intensity: float = 0.0   # How strong the shake is
```

**Processing (in `_process()`):**
```gdscript
if shake_duration > 0:
    # Apply random offset to camera
    camera.h_offset = randf_range(-1, 1) * intensity
    camera.v_offset = randf_range(-1, 1) * intensity
else:
    camera.h_offset = 0
    camera.v_offset = 0
```

**Trigger Function:**
```gdscript
func trigger_shake(duration: float, intensity: float):
    shake_duration = duration
    shake_intensity = intensity
```

**Kick Hit Callback:**
```gdscript
func _on_kick_area_3d_body_entered(body):
    if body.has_method("take_damage"):
        body.take_damage(25, kick_origin, direction)
        trigger_shake(0.15, 0.3)  # 150ms, 30% intensity
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `shake_duration` | 0.15s | How long the screen shakes |
| `shake_intensity` | 0.3 | Maximum offset from center (0-1 range) |

## Tuning Tips

- **Duration**: 0.1-0.2s feels snappy. Longer = more dramatic
- **Intensity**: 0.2-0.4 is subtle. 0.5+ is very aggressive
- **Match audio**: Screen shake should sync with the hit sound for maximum impact

## Future Improvements

- [ ] Add shake on weapon fire (subtle, ~0.05s)
- [ ] Directional shake based on hit position
- [ ] Camera zoom/fov kick on heavy impacts
- [ ] Different shake profiles for different attack types

## Relevant Files

| File | Purpose |
|------|---------|
| `player.gd` | Contains all shake logic and trigger function |
| `player.tscn` | Player scene with Camera3D node |

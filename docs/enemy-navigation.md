# Enemy Navigation System

## Overview

The enemy navigation system uses Godot's built-in NavigationServer3D for pathfinding, combined with separation behavior to prevent enemies from clustering in tight lines.

## Features

### 1. Navigation Mesh Pathfinding

**How it works:**
- Enemies query the NavigationServer for a path from their position to the player
- The path is recalculated every 0.5 seconds to track player movement
- Enemies follow waypoints along the path, advancing to the next waypoint when close enough

**Setup:**
1. Add a `NavigationRegion3D` node to the scene
2. Add a `NavigationMesh` as a child
3. Configure Agent Radius (in Geometry) to control how close enemies can get to walls (default: ~0.5)
4. Click "Bake" to generate the navigation mesh

**Code Location:** `enemy.gd`
- `navigation_map` - Stores the RID for the navigation map
- `path` - Array of Vector3 waypoints
- `path_index` - Current waypoint being targeted
- `path_recalc_timer` - Controls when to recalculate path

### 2. Separation Behavior

**How it works:**
- Each enemy checks for other enemies within `separation_range`
- If another enemy is too close, the enemy steers away
- The closer the enemy, the stronger the repulsion

**Parameters (editable in Inspector):**
| Parameter | Default | Description |
|-----------|---------|-------------|
| `separation_range` | 2.0 | Distance at which enemies start repelling each other |
| `separation_force` | 0.8 | Strength of the separation force (0-1) |

### 3. Obstacle Avoidance

**How it works:**
- The NavigationMesh baker marks unwalkable areas around obstacles based on `Agent Radius`
- Enemies naturally path around obstacles since the navmesh excludes those areas

**Tuning:**
- Increase `Agent Radius` in NavigationMesh → Geometry for more wall clearance
- Decrease for tighter paths (but more wall brushing)

## Enemy Group

Enemies automatically add themselves to the "Enemy" group on ready. This is used for:
- Finding all enemies for separation calculations
- Can be used for other group-wide operations

## Relevant Files

| File | Purpose |
|------|---------|
| `enemy.gd` | Main enemy logic with pathfinding and separation |
| `world.tscn` | Contains NavigationRegion3D with baked NavigationMesh |

## Future Improvements

- [ ] Add visibility cone detection (enemies only chase when they can "see" player)
- [ ] Alert/idle states (wander when player not visible)
- [ ] Enemy types with different navigation parameters
- [ ] Pathfinding debug visualization

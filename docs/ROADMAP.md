# Doom Clone Roadmap

A living document of planned features and improvements. Check off items as they're implemented.

---

## Enemy System

### State Machine & AI
- [ ] Add state machine pattern to enemy (Idle, Patrol, Chase, Attack, Hit, Dead)
- [ ] Add visibility cone detection (enemies only chase when they can "see" player)
- [ ] Alert/idle states (wander when player not visible)
- [ ] Add hearing detection (chase if player shoots nearby)

### Enemy Types
- [ ] Create multiple enemy types (fast/weak, slow/strong, ranged)
- [ ] Different navigation parameters per type
- [ ] Enemy type configuration via exported variables

### Combat
- [ ] Enemy attack variations (melee, ranged, charge attack)
- [ ] Enemy health bars
- [ ] Enemy damage numbers floating up

### Polish
- [ ] Pathfinding debug visualization
- [ ] Death animations for enemies
- [ ] Different death sounds per enemy type

---

## Player System

### Combat
- [ ] Add more weapon types (shotgun, machine gun, etc.)
- [ ] Weapon switching with hotkeys
- [ ] Weapon ammo system
- [ ] Reload mechanic

### Movement
- [ ] Sprint/run mechanic
- [ ] Jump (if 3D platforming sections exist)
- [ ] Crouch/prone
- [ ] Wall collision sliding

### Feedback
- [ ] Screen shake on weapon fire (subtle, ~0.05s)
- [ ] Directional shake based on hit position
- [ ] Camera zoom/fov kick on heavy impacts
- [ ] Different shake profiles for different attack types
- [ ] Hit markers for headshots

---

## Level Design

### World
- [ ] Multiple levels/maps
- [ ] Level progression system
- [ ] Secrets and hidden areas
- [ ] Unlockable areas

### Interactables
- [ ] Health pickups
- [ ] Ammo pickups
- [ ] Keys and locked doors
- [ ] Power-ups (invincibility, speed, etc.)

---

## UI/HUD

- [ ] Health display
- [ ] Ammo counter
- [ ] Weapon display
- [ ] Minimap
- [ ] Pause menu
- [ ] Death screen with restart
- [ ] Level complete screen

---

## Audio

- [ ] Background music
- [ ] Enemy ambient sounds
- [ ] Footstep sounds
- [ ] Weapon sounds
- [ ] Environmental sounds (ambience, alarms)

---

## Technical

- [ ] Save/load system
- [ ] Settings menu (graphics, audio, controls)
- [ ] Controller support
- [ ] Performance optimization
- [ ] Debug tools (god mode, level skip, etc.)

---

## Visuals

- [ ] Particle effects (muzzle flash, explosions, blood)
- [ ] Decal system (bullet holes, blood splatter)
- [ ] Lighting improvements (dynamic lights, shadows)
- [ ] Post-processing (bloom, vignette, color grading)

---

*Last updated: 2026-03-30*

class_name Layers
extends RefCounted
## Physics layer bit values. Names match project.godot [layer_names].

const WORLD := 1      # solid terrain, platforms
const PLAYER := 2     # Tato
const ENEMY := 4      # mischievous sprites and machines
const INTERACT := 8   # things that react to honks / flavours / touch
const HAZARD := 16    # brambles and other "ouch" zones
const EFFECT := 32    # ability pulses
const PROP := 64      # crates, pushables
const WATER := 128    # water volumes
const ONEWAY := 256   # jump-through platforms (Tato can drop through)

const TILE := 64      # world grid size in pixels

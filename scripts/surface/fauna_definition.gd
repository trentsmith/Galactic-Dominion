class_name FaunaDefinition
extends Resource
@export var id := ""
@export var display_name := ""
@export var description := ""
@export_enum("grazer","predator","flyer","stalker") var behavior := "grazer"
@export_enum("bat","stag","wolf","hopper","grazer","manta","watcher","crawler","wisp","jelly","fish","shark") var body_style := "grazer"
@export var color := Color(0.4,0.8,0.6)
@export var glow := Color(0.3,1,0.7)
@export var speed := 4.0
@export var health := 24.0
@export var damage := 8.0
@export var size := 1.0

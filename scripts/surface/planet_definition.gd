class_name PlanetDefinition
extends Resource
@export var id := ""
@export var display_name := ""
@export var description := ""
@export_enum("vampire","alien","eldritch") var biome := "alien"
@export var ground_color := Color(0.1,0.25,0.23)
@export var foliage_color := Color(0.2,0.8,0.55)
@export var sky_color := Color(0.08,0.12,0.24)
@export var glow_color := Color(0.4,1,0.7)
@export var aquatic := false
@export var seed_value := 71
@export var fauna: Array[FaunaDefinition] = []
@export var flora: PackedStringArray = []
@export var survey_reward := ""

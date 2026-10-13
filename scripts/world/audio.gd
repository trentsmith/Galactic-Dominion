class_name SpaceAudio
extends Node
var players: Dictionary = {}

func _ready() -> void:
 for event in ["laser", "missile", "shield", "destroy", "click"]:
  var player := AudioStreamPlayer.new()
  player.stream = _tone(event)
  player.volume_db = -16 if event != "destroy" else -12
  player.max_polyphony = 4
  add_child(player)
  players[event] = player

static func play(event: String) -> void:
 var tree := Engine.get_main_loop() as SceneTree
 if tree == null:
  return
 var audio := tree.root.get_node_or_null("GalacticDominion/Audio") as SpaceAudio
 if audio != null and audio.players.has(event):
  audio.players[event].play()

func _tone(event: String) -> AudioStreamWAV:
 var duration := 0.08 if event == "click" else 0.12 if event == "laser" else 0.25 if event == "shield" else 0.4
 var count := int(22050 * duration)
 var data := PackedByteArray()
 data.resize(count * 2)
 var phase := 0.0
 var rng := RandomNumberGenerator.new()
 rng.seed = event.hash()
 for index in range(count):
  var t := float(index) / count
  var frequency := lerpf(1000, 240, t) if event == "laser" else 75.0 if event == "destroy" else 400.0 if event == "shield" else 180.0 if event == "missile" else 900.0
  phase += TAU * frequency / 22050
  var value := sin(phase) * (1.0 - t) * minf(1, t * 35)
  if event in ["destroy", "missile"]:
   value = (value * 0.5 + rng.randf_range(-0.5, 0.5)) * (1.0 - t)
  data.encode_s16(index * 2, int(value * 18000))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.data = data
 return stream

func _exit_tree() -> void:
 for player in players.values():
  player.stop()
  player.stream = null
 players.clear()

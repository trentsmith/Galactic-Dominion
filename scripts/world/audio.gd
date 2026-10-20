class_name SpaceAudio
extends Node
## Original layered PCM effects, generated locally; no external asset dependency.
var players: Dictionary = {}
var last_played: Dictionary = {}
const DURATIONS := {"laser":.16,"missile":.55,"shield":.23,"destroy":.65,"click":.06,"hit_shield":.08,"hit_hull":.11,"hull_hit":.2,"shield_break":.5,"critical":.65,"lock":.32,"incoming":.48}
const GAINS := {"laser":-19,"missile":-16,"shield":-19,"destroy":-18,"click":-22,"hit_shield":-22,"hit_hull":-21,"hull_hit":-18,"shield_break":-17,"critical":-17,"lock":-18,"incoming":-18}

func _ready() -> void:
 for event in DURATIONS:
  var player := AudioStreamPlayer.new()
  player.stream = _tone(event)
  player.volume_db = GAINS[event]
  player.max_polyphony = 4
  add_child(player)
  players[event] = player

static func play(event: String) -> void:
 var tree := Engine.get_main_loop() as SceneTree
 if tree == null:return
 var audio := tree.root.get_node_or_null("GalacticDominion/Audio") as SpaceAudio
 if audio == null or not audio.players.has(event):return
 var now := Time.get_ticks_msec()
 var cooldown := 350 if event in ["critical","shield_break","destroy"] else 75 if event in ["shield","hull_hit","hit_hull","hit_shield"] else 0
 if now-int(audio.last_played.get(event,-10000))<cooldown:return
 audio.last_played[event] = now
 audio.players[event].play()

func _tone(event: String) -> AudioStreamWAV:
 var duration: float = DURATIONS.get(event,.1)
 var count := int(22050*duration)
 var data := PackedByteArray()
 data.resize(count*2)
 var phase := 0.0
 var bass_phase := 0.0
 var filtered_noise := 0.0
 var rng := RandomNumberGenerator.new()
 rng.seed = event.hash()
 for index in range(count):
  var seconds := float(index)/22050
  var t := float(index)/maxi(1,count-1)
  var noise := rng.randf_range(-1,1)
  filtered_noise = lerpf(filtered_noise,noise,.18)
  var frequency := 900.0
  match event:
   "laser":frequency=lerpf(1850,210,pow(t,.55))
   "missile":frequency=lerpf(75,150,t)
   "shield":frequency=lerpf(950,420,t)
   "shield_break":frequency=lerpf(1600,140,t)
   "hit_shield":frequency=1450
   "hit_hull","hull_hit":frequency=lerpf(270,80,t)
   "destroy":frequency=lerpf(100,35,t)
   "lock":frequency=660 if t<.33 else 880 if t<.66 else 1320
   "incoming":frequency=880 if int(t*6)%2==0 else 660
   "critical":frequency=420 if int(t*4)%2==0 else 280
  phase+=TAU*frequency/22050
  bass_phase+=TAU*110/22050
  var value := sin(phase)*.7
  match event:
   "laser":value=sin(phase)*.65+sin(phase*2)*.12+sin(bass_phase)*exp(-t*14)*.4+filtered_noise*.15
   "missile":value=sin(phase)*.35+filtered_noise*2.2+sin(bass_phase)*exp(-t*10)*.6
   "destroy":value=filtered_noise*2.5+sin(phase)*.45
   "shield","shield_break":value=sin(phase)*.45+sin(phase*1.42)*.2+noise*(.4 if event=="shield_break" else .08)
   "hit_hull","hull_hit":value=sin(phase)*.55+filtered_noise*.9
   "incoming","critical":value=sin(phase)*.6*(.35+.65*pow(sin(t*TAU*3),2))
  # Short attack/release ramps prevent clicks; soft limiting leaves headroom.
  var envelope := minf(1,seconds/.004)*minf(1,(duration-seconds)/.025)*pow(1-t,.75)
  data.encode_s16(index*2,int(tanh(value)*envelope*26000))
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

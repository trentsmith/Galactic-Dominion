class_name NexusComms
extends PanelContainer
## Text-only radio, no unskippable speech or gameplay pause.
var queue: Array[String]=[]
var history: Array[String]=[]
var current_id:=""
var remaining:=0.0
var speaker: Label
var speech: Label
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var paint:=StyleBoxFlat.new();paint.bg_color=Color(.015,.027,.045,.94);paint.border_color=Color(.3,.5,.6);paint.set_border_width_all(1);paint.set_corner_radius_all(8)
 for side in ["left","right","top","bottom"]:paint.set("content_margin_"+side,12)
 add_theme_stylebox_override("panel",paint)
 var column:=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(column)
 speaker=Label.new();speaker.add_theme_font_size_override("font_size",12);column.add_child(speaker)
 speech=Label.new();speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;speech.custom_minimum_size.x=460;speech.add_theme_font_size_override("font_size",16);column.add_child(speech)
 hide()
func enqueue(id: String) -> void:
 if not NexusStoryData.RADIO.has(id) or id in history or id in queue:return
 queue.append(id)
func advance() -> void:
 if queue.is_empty():current_id="";hide();return
 current_id=queue.pop_front();history.append(current_id)
 var line: Array=NexusStoryData.RADIO[current_id]
 var person:=NexusStoryData.character(str(line[0]))
 speaker.text=str(person.name).to_upper()+" / COMMS · O TO REVIEW"
 speaker.add_theme_color_override("font_color",person.color)
 speech.text=str(line[1]);remaining=clampf(float(speech.text.length())/16,7,14);show()
 SpaceAudio.play("click")
func _process(delta: float) -> void:
 remaining-=delta
 if remaining<=0:advance()

extends Node

var muted:=false
var player: AudioStreamPlayer
static var current: Node

static func ensure(tree: SceneTree) -> Node:
 var singleton=tree.root.get_node_or_null("GameMusic")
 if is_instance_valid(singleton):return singleton
 # Custom SceneTree test runners do not initialize project autoloads.
 if not is_instance_valid(current):
  current=load("res://scripts/game_music.gd").new()
  current.name="GameMusic"
  tree.root.add_child.call_deferred(current)
 return current

func _ready() -> void:
 if Engine.is_editor_hint():return
 player=AudioStreamPlayer.new()
 player.name="BackgroundMusic"
 var stream: AudioStreamOggVorbis=load("res://assets/audio/aldeia_ao_amanhecer.ogg")
 stream.loop=true
 player.stream=stream
 player.volume_db=-19
 add_child(player)
 if not muted and DisplayServer.get_name()!="headless":player.play()
 player.stream_paused=muted

func set_muted(value: bool) -> void:
 muted=value
 if is_instance_valid(player):
  if not value and not player.playing and DisplayServer.get_name()!="headless":player.play()
  player.stream_paused=value

func _exit_tree() -> void:
 if is_instance_valid(player):
  player.stream_paused=false
  player.stop()
  player.stream=null
 if current==self:current=null

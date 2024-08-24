extends Node

@onready var music_hurdy = { "audio_player": $MusicAudioStreamPlayer, "volume": 1.0, "name": "hurdy" }

@onready var sfx_footsteps = { "audio_player": $FootstepsAudioStreamPlayer, "volume": 0.2, "name": "footsteps" }
@onready var sfx_jump = { "audio_player": $JumpAudioStreamPlayer, "volume": 0.04, "name": "jump" }
@onready var sfx_btn_down = { "audio_player": $ButtonDownAudioStreamPlayer, "volume": 1.5, "name": "btn_down" }
@onready var sfx_btn_up = { "audio_player": $ButtonUpAudioStreamPlayer, "volume": 1.5, "name": "btn_up"  }

@onready var sfx_shoot_pistol = { "audio_player": $ShootPistolAudioStreamPlayer, "volume": 0.2, "name": "shoot_pistol" }
@onready var sfx_item_pickup = { "audio_player": $ItemPickupAudioStreamPlayer, "volume": 1.0, "name": "item_pickup" }
@onready var sfx_item_equip = { "audio_player": $ItemEquipAudioStreamPlayer, "volume": 1.0, "name": "item_equip" }
@onready var sfx_clip_empty = { "audio_player": $ClipEmptyAudioStreamPlayer, "volume": 1.0, "name": "clip_empty" }
@onready var sfx_reload_pistol = { "audio_player": $ReloadPistolAudioStreamPlayer, "volume": 1.0, "name": "reload_pistol" }

var audio_list = []

func _ready() -> void:
	audio_list.append(music_hurdy)
	audio_list.append(sfx_footsteps)
	audio_list.append(sfx_jump)
	audio_list.append(sfx_btn_down)
	audio_list.append(sfx_btn_up)
	audio_list.append(sfx_shoot_pistol)
	audio_list.append(sfx_item_pickup)
	audio_list.append(sfx_item_equip)
	audio_list.append(sfx_clip_empty)
	audio_list.append(sfx_reload_pistol)

func adjust_vol(audio_dict: Dictionary, is_sfx: bool = true):
	var new_vol = linear2db(audio_dict.volume * (Game.sfx_volume if is_sfx else Game.music_volume) * Game.master_volume)
	if new_vol == 0: new_vol = -80
	audio_dict.audio_player.volume_db = new_vol

func adjust_playing_audio():
	if sfx_footsteps.audio_player.playing:
		adjust_vol(sfx_footsteps)
	if music_hurdy.audio_player.playing:
		adjust_vol(music_hurdy, false)

func play_sfx(audio_dict: Dictionary, from_position: float = 0.0):
	adjust_vol(audio_dict)
	audio_dict.audio_player.play(from_position)
	print("played sfx audio at %f db" % audio_dict.audio_player.volume_db)

func play_sfx_by_name(audio_name: String):
	for a in audio_list:
		if a.name == audio_name:
			play_sfx(a)

func play_music(audio_dict: Dictionary):
	adjust_vol(audio_dict, false)
	audio_dict.audio_player.play()

func linear2db(linear: float) -> float:
	if linear <= 0:
		return -float("inf")
	return 20 * log(linear) / log(10)

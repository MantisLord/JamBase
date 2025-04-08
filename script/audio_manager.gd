extends Node

@onready var music_hurdy = { "audio_player": $MusicAudioStreamPlayer, "volume": 1.0, "name": "hurdy" }

@onready var sfx_footsteps = { "audio_player": $FootstepsAudioStreamPlayer, "volume": 2.0, "name": "footsteps" }
@onready var sfx_jump = { "audio_player": $JumpAudioStreamPlayer, "volume": 0.25, "name": "jump" }
@onready var sfx_btn_down = { "audio_player": $ButtonDownAudioStreamPlayer, "volume": 20.0, "name": "btn_down" }
@onready var sfx_btn_up = { "audio_player": $ButtonUpAudioStreamPlayer, "volume": 20.0, "name": "btn_up"  }

@onready var sfx_shoot_pistol = { "audio_player": $ShootPistolAudioStreamPlayer, "volume": 0.2, "name": "shoot_pistol" }
@onready var sfx_item_pickup = { "audio_player": $ItemPickupAudioStreamPlayer, "volume": 2.0, "name": "item_pickup" }
@onready var sfx_item_equip = { "audio_player": $ItemEquipAudioStreamPlayer, "volume": 2.0, "name": "item_equip" }
@onready var sfx_clip_empty = { "audio_player": $ClipEmptyAudioStreamPlayer, "volume": 2.0, "name": "clip_empty" }
@onready var sfx_reload_pistol = { "audio_player": $ReloadPistolAudioStreamPlayer, "volume": 2.0, "name": "reload_pistol" }

@onready var sfx_shoot_pistol_es = { "audio_player": $ShootPistolESAudioStreamPlayer, "volume": 0.2, "name": "shoot_pistol_es" }
@onready var sfx_reload_pistol_es = { "audio_player": $ReloadPistolESAudioStreamPlayer, "volume": 2.0, "name": "reload_pistol_es" }

@onready var sfx_use_key = { "audio_player": $UseKeyAudioStreamPlayer, "volume": 0.5, "name": "use_key" }
@onready var sfx_equip_key = { "audio_player": $EquipKeyAudioStreamPlayer, "volume": 0.1, "name": "equip_key" }
@onready var sfx_pickup_key = { "audio_player": $PickupKeyAudioStreamPlayer, "volume": 0.1, "name": "pickup_key" }

@onready var sfx_menu_open = { "audio_player": $MenuOpenAudioStreamPlayer, "volume": 0.75, "name": "menu_open" }
@onready var sfx_menu_close = { "audio_player": $MenuCloseAudioStreamPlayer, "volume": 0.75, "name": "menu_close" }

@onready var sfx_take_damage = { "audio_player": $TakeDamageAudioStreamPlayer, "volume": 1.0, "name": "take_damage" }

var audio_list = []
var sound_library: Dictionary = {}

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
	audio_list.append(sfx_use_key)
	audio_list.append(sfx_equip_key)
	audio_list.append(sfx_pickup_key)
	audio_list.append(sfx_menu_open)
	audio_list.append(sfx_menu_close)
	audio_list.append(sfx_shoot_pistol_es)
	audio_list.append(sfx_reload_pistol_es)
	sound_library["flesh_impact_bullet1"] = preload("res://sound/flesh_impact_bullet1.wav")
	sound_library["flesh_impact_bullet2"] = preload("res://sound/flesh_impact_bullet2.wav")
	sound_library["flesh_impact_bullet3"] = preload("res://sound/flesh_impact_bullet3.wav")
	sound_library["flesh_impact_bullet4"] = preload("res://sound/flesh_impact_bullet4.wav")
	sound_library["flesh_impact_bullet5"] = preload("res://sound/flesh_impact_bullet5.wav")
	sound_library["headshot1"] = preload("res://sound/headshot1.wav")
	sound_library["headshot2"] = preload("res://sound/headshot2.wav")
	sound_library["mouse_attack1"] = preload("res://sound/428114__higgs01__squeakfinal.wav")
	sound_library["mouse_attack2"] = preload("res://sound/468442__breviceps__video-game-squeak.wav")
	sound_library["mouse_attack3"] = preload("res://sound/684866__faircashew__mouse-squek.mp3")
	sound_library["human_attack1"] = preload("res://sound/attack-cry-1.wav")
	sound_library["human_attack2"] = preload("res://sound/attack-cry-2.wav")
	sound_library["human_attack3"] = preload("res://sound/attack-grunt-1.wav")
	sound_library["human_attack4"] = preload("res://sound/attack-grunt-2.wav")
	sound_library["human_attack5"] = preload("res://sound/attack-grunt-3.wav")
	sound_library["human_attack6"] = preload("res://sound/attack-grunt-4.wav")
	sound_library["human_attack7"] = preload("res://sound/attack-grunt-7.wav")
	sound_library["human_attack8"] = preload("res://sound/attack-grunt-8.wav")
	sound_library["human_death1"] = preload("res://sound/death-cry-1.wav")
	sound_library["human_death2"] = preload("res://sound/death-cry-2.wav")
	sound_library["human_death3"] = preload("res://sound/death-cry-3.wav")
	sound_library["human_death4"] = preload("res://sound/death-cry-4.wav")
	sound_library["human_death5"] = preload("res://sound/death-cry-5.wav")
	sound_library["human_death6"] = preload("res://sound/death-cry-6.wav")
	
	sound_library["button_fail1"] = preload("res://sound/button_fail_1.wav")
	sound_library["button_fail2"] = preload("res://sound/button_fail_2.wav")
	sound_library["button_success1"] = preload("res://sound/button_success_1.wav")
	sound_library["button_success2"] = preload("res://sound/button_success_2.wav")

func adjust_vol(volume, is_sfx: bool = true, _audio_name: String = "") -> int:
	var new_vol = linear2db(volume * (Game.sfx_volume if is_sfx else Game.music_volume) * Game.master_volume)
	if new_vol == 0: new_vol = -80
	#Game.log_out("playing audio (%s) %f db" % [_audio_name, new_vol])
	return new_vol

func adjust_playing_audio():
	if sfx_footsteps.audio_player.playing:
		sfx_footsteps.audio_player.volume_db = adjust_vol(sfx_footsteps.volume, true, sfx_footsteps.name)
	if music_hurdy.audio_player.playing:
		music_hurdy.audio_player.volume_db = adjust_vol(music_hurdy.volume, false, music_hurdy.name)

func play_sfx(audio_dict: Dictionary, from_position: float = 0.0):
	audio_dict.audio_player.volume_db = adjust_vol(audio_dict.volume, true, audio_dict.name)
	audio_dict.audio_player.play(from_position)

func play_sfx_by_name(audio_name: String):
	for a in audio_list:
		if a.name == audio_name:
			play_sfx(a)

func play_music(audio_dict: Dictionary):
	audio_dict.audio_player.volume_db = adjust_vol(audio_dict.volume, false, audio_dict.name)
	audio_dict.audio_player.play()

func play_sfx_3d(sound_name: String, position: Vector3, volume: float = 1.0):
	var sound = sound_library.get(sound_name, null)
	if sound:
		var audio_player = AudioStreamPlayer3D.new()
		audio_player.stream = sound
		audio_player.position = position
		audio_player.volume_db = adjust_vol(volume, true, sound_name)
		
		add_child(audio_player)
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)
	else:
		Game.log_out("Sound not found: %s" % sound_name)

func linear2db(linear: float) -> float:
	if linear <= 0:
		return -float("inf")
	return 20 * log(linear) / log(10)

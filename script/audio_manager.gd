extends Node

@onready var button_down_sfx = $ButtonDownAudioStreamPlayer
@onready var button_up_sfx = $ButtonUpAudioStreamPlayer
@onready var jump_sfx = $JumpAudioStreamPlayer
@onready var footsteps_sfx = $FootstepsAudioStreamPlayer

var sfx_volume: float = 1.0
var music_volume: float = 1.0
var master_volume: float = 1.0

func play_sfx(audio_player: AudioStreamPlayer, volume: float = 1.0, from_position: float = 0.0):
	audio_player.volume_db = linear2db(volume * sfx_volume * master_volume)
	audio_player.play(from_position)

func play_music(audio_player: AudioStreamPlayer, volume: float = 1.0):
	audio_player.volume_db = linear2db(volume * music_volume * master_volume)
	audio_player.play()

func set_sfx_volume(volume: float):
	sfx_volume = volume

func set_music_volume(volume: float):
	music_volume = volume

func set_master_volume(volume: float):
	master_volume = volume

func linear2db(linear: float) -> float:
	if linear <= 0:
		return -float("inf")
	return 20 * log(linear) / log(10)

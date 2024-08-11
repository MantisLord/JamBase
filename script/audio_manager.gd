extends Node

@onready var button_down_sfx = $ButtonDownAudioStreamPlayer
@onready var button_up_sfx = $ButtonUpAudioStreamPlayer
@onready var jump_sfx = $JumpAudioStreamPlayer
@onready var footsteps_sfx = $FootstepsAudioStreamPlayer

func play_sfx(audio_player: AudioStreamPlayer, volume: float = 1.0, from_position: float = 0.0):
	audio_player.volume_db = linear2db(volume * Game.sfx_volume * Game.master_volume)
	audio_player.play(from_position)

func play_music(audio_player: AudioStreamPlayer, volume: float = 1.0):
	audio_player.volume_db = linear2db(volume * Game.music_volume * Game.master_volume)
	audio_player.play()

func linear2db(linear: float) -> float:
	if linear <= 0:
		return -float("inf")
	return 20 * log(linear) / log(10)

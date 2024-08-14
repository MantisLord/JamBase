extends Node

@onready var music_hurdy = { "audio_player": $MusicAudioStreamPlayer, "volume": 1.0 }

@onready var sfx_footsteps = { "audio_player": $FootstepsAudioStreamPlayer, "volume": 0.2 }
@onready var sfx_jump = { "audio_player": $JumpAudioStreamPlayer, "volume": 0.05 }
@onready var sfx_btn_down = { "audio_player": $ButtonDownAudioStreamPlayer, "volume": 1.5 }
@onready var sfx_btn_up = { "audio_player": $ButtonUpAudioStreamPlayer, "volume": 1.5  }

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

func play_music(audio_dict: Dictionary):
	adjust_vol(audio_dict, false)
	audio_dict.audio_player.play()

func linear2db(linear: float) -> float:
	if linear <= 0:
		return -float("inf")
	return 20 * log(linear) / log(10)

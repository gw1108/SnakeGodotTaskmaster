extends GdUnitTestSuite

const EAT_FOOD_PATH := "res://audio/eat_food.wav"
const EAT_FOOD_IMPORT_PATH := "res://audio/eat_food.wav.import"
const DEATH_PATH := "res://audio/death.wav"
const DEATH_IMPORT_PATH := "res://audio/death.wav.import"

func test_eat_food_stream_loads() -> void:
	var stream := load(EAT_FOOD_PATH) as AudioStreamWAV
	assert_object(stream).is_not_null()
	assert_int(stream.data.size()).is_greater(0)

func test_death_stream_loads() -> void:
	var stream := load(DEATH_PATH) as AudioStreamWAV
	assert_object(stream).is_not_null()
	assert_int(stream.data.size()).is_greater(0)

func test_eat_food_does_not_loop() -> void:
	var stream := load(EAT_FOOD_PATH) as AudioStreamWAV
	assert_int(stream.loop_mode).is_equal(AudioStreamWAV.LOOP_DISABLED)

func test_death_does_not_loop() -> void:
	var stream := load(DEATH_PATH) as AudioStreamWAV
	assert_int(stream.loop_mode).is_equal(AudioStreamWAV.LOOP_DISABLED)

func test_eat_food_import_loop_off() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(EAT_FOOD_IMPORT_PATH)
	assert_int(err).is_equal(OK)
	assert_that(cfg.get_value("params", "edit/loop_mode")).is_equal(0)

func test_death_import_loop_off() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(DEATH_IMPORT_PATH)
	assert_int(err).is_equal(OK)
	assert_that(cfg.get_value("params", "edit/loop_mode")).is_equal(0)

func test_eat_food_plays_via_audio_stream_player() -> void:
	var stream := load(EAT_FOOD_PATH) as AudioStreamWAV
	var player: AudioStreamPlayer = auto_free(AudioStreamPlayer.new())
	add_child(player)
	player.stream = stream
	player.play()
	assert_bool(player.playing).is_true()
	player.stop()

func test_death_plays_via_audio_stream_player() -> void:
	var stream := load(DEATH_PATH) as AudioStreamWAV
	var player: AudioStreamPlayer = auto_free(AudioStreamPlayer.new())
	add_child(player)
	player.stream = stream
	player.play()
	assert_bool(player.playing).is_true()
	player.stop()

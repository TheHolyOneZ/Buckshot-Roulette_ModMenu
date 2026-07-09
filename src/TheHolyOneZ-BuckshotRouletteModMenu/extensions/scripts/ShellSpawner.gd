extends "res://scripts/ShellSpawner.gd"

func SpawnShells(numberOfShells: int, numberOfLives: int, numberOfBlanks: int, shufflingArray: bool) -> void:
	super(numberOfShells, numberOfLives, numberOfBlanks, shufflingArray)
	var state := get_tree().root.get_node_or_null("TZModMenuState")
	if state:
		if roundManager: state.round_manager = roundManager
		if healthCounter: state.health_counter = healthCounter
		state.clear_shells()

func MainShellRoutine() -> void:
	await super()
	var state := get_tree().root.get_node_or_null("TZModMenuState")
	if state and state.shell_esp_enabled:
		state.snapshot_shells(sequenceArray, self, ai)

extends Node

const LOBBY_SCENE := preload("res://scenes/lobby/Lobby.tscn")

@onready var current_scene_holder: Node = $CurrentScene


func _ready() -> void:
	GameState.phase_changed.connect(_on_phase_changed)
	_show_scene(LOBBY_SCENE)


func _on_phase_changed(new_phase: GameState.Phase) -> void:
	match new_phase:
		GameState.Phase.LOBBY:
			_show_scene(LOBBY_SCENE)
		GameState.Phase.BUILD, GameState.Phase.REVEAL, GameState.Phase.STRESSTEST, GameState.Phase.SCORING:
			pass  # folgt in Schritt 5+ (BuildArena, RevealCamera, StresstestRig, Scoring-UI)


func _show_scene(scene: PackedScene) -> void:
	for child in current_scene_holder.get_children():
		child.queue_free()
	current_scene_holder.add_child(scene.instantiate())

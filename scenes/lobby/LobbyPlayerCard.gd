extends PanelContainer

@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var host_badge: Label = $HBoxContainer/HostBadge


func set_player_name(value: String) -> void:
	name_label.text = value


func set_host_flag(is_host: bool) -> void:
	host_badge.visible = is_host

extends Resource
class_name PartData

## Stammdaten eines Bauteil-Typs. Kein Mesh-Asset nötig, bevor der Art-Pass
## (Schritt 16) kommt - Part.tscn baut sich aus size/color eine Platzhalter-Box.

@export var id: StringName
@export var display_name: String
@export var size: Vector3 = Vector3.ONE
@export var mass: float = 1.0
@export var color: Color = Color.WHITE

## Teile mit derselben visual_group sehen sich zum Verwechseln ähnlich
## (z. B. echtes Regalbrett vs. Baulügner-Decoy) - erst die Inspektion
## in Schritt 7 deckt den tatsächlichen Unterschied auf.
@export var visual_group: StringName = &""

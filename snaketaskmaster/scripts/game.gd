extends Node2D

@onready var playfield: Node2D = $Playfield
@onready var hud: CanvasLayer = $HUD
@onready var state_machine: Node = $GameStateMachine
@onready var game_tick: Node = $GameTick

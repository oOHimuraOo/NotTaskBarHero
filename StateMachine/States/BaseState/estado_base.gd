class_name ESTADO_BASE
extends Node

@export var ListaDeEfeitosSonoros:Array[AudioStream] = []

var DonoDoEstado: ESTADO_BASE
var Animacao: AnimatedSprite2D
var StateMachine: STATE_MACHINE

var Morreu:bool = false

func AoEntrarNoEstado(_info: Dictionary = {}) -> void:
	pass

func AoSairDoEstado(_info: Dictionary = {}) -> void:
	pass

func NoProcess(_delta: float) -> void:
	VerificarTransicaoDeEstado()

func NoPhysicsProcess(_delta: float) -> void:
	pass

func VerificarTransicaoDeEstado() -> void:
	if Morreu:
		StateMachine.MudarEstadoAtivo("Morrendo")

class_name STATE_MACHINE
extends Node

var Personagem: ENTIDADE_BASE
var Animacao: AnimatedSprite2D
var EstadoAtivo: ESTADO_BASE

func VerificarEInicializarStateMachine() -> void:
	for Nodo in get_children():
		if Nodo is ESTADO_BASE:
			Nodo.StateMachine = self
			Nodo.DonoDoEstado = Personagem
			Nodo.Animacao = Animacao
			continue
		else:
			push_error(Nodo.name, " não é um estado valido")
			Nodo.queue_free()
	
	EstadoAtivo = find_child("EstadoCorrendo")
	if !EstadoAtivo:
		EstadoAtivo = get_child(0)
	EstadoAtivo.AoEntrarNoEstado()

func _process(delta):
	if !EstadoAtivo:
		EstadoAtivo.NoProcess(delta)

func _physics_process(delta):
	if !EstadoAtivo:
		EstadoAtivo.NoPhysicsProcess(delta)

func MudarEstadoAtivo(NovoEstado: String, Info: Dictionary = {}) -> void:
	if !find_child(NovoEstado):
		push_error(NovoEstado, " não é um estado do personagem")
	else:
		EstadoAtivo.AoSairDoEstado(Info)
		EstadoAtivo = find_child(NovoEstado) as ESTADO_BASE
		EstadoAtivo.AoEntrarNoEstado(Info)

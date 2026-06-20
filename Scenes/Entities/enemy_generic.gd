class_name GENERIC_ENEMY
extends CharacterBody2D

signal InimigoMorreu()
signal InimigoAtingido()

@export var Animacoes: AnimatedSprite2D
@export var DetectorDeJogador: Area2D
@export var HitBox: Area2D
@export var HurtBox: Area2D
@export var EnemySheet: ENEMY_SHEET

var Atingido: bool = false
var Dead: bool = false
var AlreadyDead: bool = false
var Running: bool = true
var PodeAtacar: bool = false

var AtacouAh: float = 0.0

func _ready() -> void:
	if !Animacoes:
		Animacoes = find_child("AnimatedSprite2D") as AnimatedSprite2D
	if !DetectorDeJogador:
		DetectorDeJogador = find_child("PlayerDetector") as Area2D
	if !HitBox:
		HitBox = find_child("HitBox") as Area2D
	if !HurtBox:
		HurtBox = find_child("HurtBox") as Area2D
	
	Animacoes.animation_finished.connect(QuandoAnimacaoTerminada)
	
	EnemySheet.ResetarManaEVida()

func _physics_process(delta: float) -> void:
	if Running:
		if !Animacoes.animation.begins_with("Run"):
			Animacoes.play("Run")
		velocity.x -= EnemySheet.VelocidadeMovimento * delta
		if velocity.x >= EnemySheet.VelocidadeMaxima:
			velocity.x = EnemySheet.VelocidadeMaxima
	
	if Atingido:
		velocity.x = 0
		Running = false
		Animacoes.play("TakeHit")
	
	if Dead && !AlreadyDead:
		velocity.x = 0
		Running = false
		AlreadyDead = true
		Animacoes.play("Death")
	
	move_and_slide()

func QuandoAnimacaoTerminada() -> void:
	if Animacoes.animation.begins_with("Attack1"):
		var areas: Array = HitBox.get_overlapping_areas()
		if areas.is_empty():
			Running = true
		else:
			Animacoes.play("Idle")
			_QuandoEntrarNaAreaDoDeterctorDeInimigo(areas[0].get_parent())
	
	if Animacoes.animation.begins_with("TakeHit"):
		Atingido = false
		Running = true
	
	if Animacoes.animation.begins_with("Death"):
		await get_tree().create_timer(3).timeout
		queue_free()

func _QuandoEntrarNaAreaDoDeterctorDeInimigo(body: Node2D) -> void:
	if Dead or Atingido:
		return
	
	if body is GENERIC_CHARACTER:
		var cooldown: float = EnemySheet.get_intervalo_ataque()
		var TempoAtual: float = Time.get_ticks_msec() / 1000.0
		if TempoAtual - AtacouAh >= cooldown:
			AtacouAh = TempoAtual
			velocity.x = 0
			Running = false
			Animacoes.play("Attack1")

func _QuandoEntrarNaAreaHurtBox(area: Area2D) -> void:
	if area.is_in_group("HitboxPlayer"):
		var Character = area.get_parent()
		var Characteer_Sheet = Character.CharacterSheet
		if Characteer_Sheet.TipoAtaqueAtual == Characteer_Sheet.TipoAtaque.FISICO:
			var dano_recebido = EnemySheet.receber_dano_fisico(Characteer_Sheet.CalcularDanoFisicoBruto())
			InimigoAtingido.emit(dano_recebido)
		elif Characteer_Sheet.TipoAtaqueAtual == Characteer_Sheet.TipoAtaque.MAGICO:
			var dano_recebido = EnemySheet.receber_dano_magico(Characteer_Sheet.CalcularDanoMagicoBruto(""))
			InimigoAtingido.emit(dano_recebido)
		
		if !EnemySheet.esta_vivo():
			Dead = true
			InimigoMorreu.emit()
			for x in range(32):
				set_collision_layer_value(x, false)
				set_collision_mask_value(x, false)
				DetectorDeJogador.set_collision_layer_value(x, false)
				DetectorDeJogador.set_collision_mask_value(x, false)
				HitBox.set_collision_layer_value(x, false)
				HitBox.set_collision_mask_value(x, false)
				HurtBox.set_collision_layer_value(x, false)
				HurtBox.set_collision_mask_value(x, false)

func _QuandoFrameDeAnimacaoMudar() -> void:
	if Animacoes.animation.begins_with("Attack1"):
		match Animacoes.frame:
			4, 5, 6:
				var areas: Array = HitBox.get_overlapping_areas()
				for area in areas:
					var player = area.get_parent()
					player._QuandoEntrarNaAreaHurtBox(HitBox)

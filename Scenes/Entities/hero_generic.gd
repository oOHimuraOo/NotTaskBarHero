class_name GENERIC_CHARACTER
extends CharacterBody2D

signal PersonagemMorreu()
signal PersonagemAtingido()

@export var Animacoes: AnimatedSprite2D
@export var DetectorDeInimigos: Area2D
@export var HitBox: Area2D
@export var HurtBox: Area2D
@export var CharacterSheet: CHARACTER_SHEET

var Atingido: bool = false
var Dead: bool = false
var AlreadyDead: bool = false
var Running: bool = true
var PodeAtacar: bool = false

var AtacouAh: float = 0.0

func _ready() -> void:
	if !Animacoes:
		Animacoes = find_child("AnimatedSprite2D") as AnimatedSprite2D
	if !DetectorDeInimigos:
		DetectorDeInimigos = find_child("EnemyDetector") as Area2D
	if !HitBox:
		HitBox = find_child("HitBox") as Area2D
	if !HurtBox:
		HurtBox = find_child("HurtBox") as Area2D
	
	Animacoes.animation_finished.connect(QuandoAnimacaoTerminada)
	
	CharacterSheet.ResetarManaEVida()

func _physics_process(delta: float) -> void:
	if Running:
		if !Animacoes.animation.begins_with("Run"):
			Animacoes.play("Run")
		velocity.x += CharacterSheet.VelocidadeMovimento * delta
		if velocity.x >= CharacterSheet.VelocidadeMaxima:
			velocity.x = CharacterSheet.VelocidadeMaxima
	
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
		PersonagemMorreu.emit()

func _QuandoEntrarNaAreaDoDeterctorDeInimigo(Body: Node2D) -> void:
	if Dead or Atingido:
		return
	if Body is GENERIC_ENEMY:
		var cooldown: float = CharacterSheet.get_intervalo_ataque()
		var TempoAtual: float = Time.get_ticks_msec() / 1000.0
		if TempoAtual - AtacouAh >= cooldown:
			AtacouAh = TempoAtual
			velocity.x = 0
			Running = false
			Animacoes.play("Attack1")

func _QuandoEntrarNaAreaHurtBox(area: Area2D) -> void:
	if area.is_in_group("HitboxInimigo"):
		var inimigo = area.get_parent()
		var enemy_sheet = inimigo.EnemySheet
		
		if enemy_sheet.TipoAtaqueAtual == enemy_sheet.TipoAtaque.FISICO:
			var dano_recebido = CharacterSheet.receber_dano_fisico(enemy_sheet.CalcularDanoFisicoBruto())
			PersonagemAtingido.emit(dano_recebido)
		elif enemy_sheet.TipoAtaqueAtual == enemy_sheet.TipoAtaque.MAGICO:
			var dano_recebido = CharacterSheet.receber_dano_magico(enemy_sheet.CalcularDanoMagicoBruto(""))
			PersonagemAtingido.emit(dano_recebido)
		
		if !CharacterSheet.esta_vivo():
			Dead = true
			PersonagemMorreu.emit()
			for x in range(32):
				set_collision_layer_value(x, false)
				set_collision_mask_value(x, false)
				DetectorDeInimigos.set_collision_layer_value(x, false)
				DetectorDeInimigos.set_collision_mask_value(x, false)
				HitBox.set_collision_layer_value(x, false)
				HitBox.set_collision_mask_value(x, false)
				HurtBox.set_collision_layer_value(x, false)
				HurtBox.set_collision_mask_value(x, false)

func _QuandoFrameDeAnimacaoMudar() -> void:
	if Animacoes.animation.begins_with("Attack1"):
		match Animacoes.frame:
			3, 4, 5:
				var areas: Array = HitBox.get_overlapping_areas()
				for area in areas:
					var inimigo = area.get_parent()
					inimigo._QuandoEntrarNaAreaHurtBox(HitBox)

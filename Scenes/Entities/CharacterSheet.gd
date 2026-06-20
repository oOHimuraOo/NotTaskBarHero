class_name CHARACTER_SHEET
extends Resource

const REDUCAO_ARMADURA_BASE: float = 100.0
const LIMITE_CHANCE_CRITICO: float = 75.0

enum TipoAtaque {
	Nenhum = 0,
	FISICO = 1,
	MAGICO = 2
}

@export var Ataque: float = 5.0
@export var VelocidadeAtaque: float = 90.0          # ataques por minuto
@export var ChanceCritico: float = 25.0             # 0 a 100 (limitado a 75%)
@export var MultiplicadorCritico: float = 2.0       # multiplicador do dano crítico

@export var Armadura: float = 45.0                  # redução de dano físico
@export var ResistenciaMagica: float = 0.0          # redução de dano mágico

@export var VidaMaxima: float = 100.0
@export var ManaMaxima: float = 50.0

@export var VelocidadeMovimento: float = 200.0
@export var VelocidadeMaxima: float = 400.0

@export var poderes: Array[PODER_BASE] = []            # ex: Array[Poder]
@export var talentos: Array[TALENTO_BASE] = []           # ex: Array[Talento]
@export var itens: Array[ITEM] = []              # ex: Array[Item]

var VidaAtual: float = 100.0
var ManaAtual: float = 50.0
var TipoAtaqueAtual: TipoAtaque = TipoAtaque.FISICO

func ResetarVida() -> void:
	VidaAtual = VidaMaxima

func ResetarMana() -> void:
	ManaAtual = ManaMaxima

func ResetarManaEVida() -> void:
	VidaAtual = VidaMaxima
	ManaAtual = ManaMaxima

func receber_dano_fisico(dano_bruto: float) -> float:
	if VidaAtual <= 0:
		return 0.0
	var reducao = get_reducao_armadura()
	var dano_final = dano_bruto * (1.0 - reducao)
	definir_vida(VidaAtual - dano_final)
	return dano_final

func receber_dano_magico(dano_bruto: float) -> float:
	if VidaAtual <= 0:
		return 0.0
	var reducao = get_reducao_magica()
	var dano_final = dano_bruto * (1.0 - reducao)
	definir_vida(VidaAtual - dano_final)
	return dano_final

func curar(quantidade: float) -> void:
	if VidaAtual <= 0:
		return
	definir_vida(VidaAtual + quantidade)

func gastar_mana(custo: float) -> bool:
	if ManaAtual >= custo:
		definir_mana(ManaAtual - custo)
		return true
	return false

func recuperar_mana(quantidade: float) -> void:
	definir_mana(ManaAtual + quantidade)

func definir_vida(valor: float) -> void:
	VidaAtual = clamp(valor, 0.0, VidaMaxima)

func definir_mana(valor: float) -> void:
	ManaAtual = clamp(valor, 0.0, ManaMaxima)

func get_intervalo_ataque() -> float:
	return 60.0 / VelocidadeAtaque if VelocidadeAtaque > 0 else 0.01

func get_chance_critico() -> float:
	return min(ChanceCritico, LIMITE_CHANCE_CRITICO)

func get_chance_critico_fator() -> float:
	return get_chance_critico() / 100.0

func get_dano_critico(DanoBruto: float) -> float:
	return DanoBruto * MultiplicadorCritico

func get_reducao_armadura() -> float:
	if Armadura <= 0:
		return 0.0
	return Armadura / (Armadura + REDUCAO_ARMADURA_BASE)

func get_reducao_magica() -> float:
	if ResistenciaMagica <= 0:
		return 0.0
	return ResistenciaMagica / (ResistenciaMagica + REDUCAO_ARMADURA_BASE)

func esta_vivo() -> bool:
	return VidaAtual > 0

func CalcularDanoFisicoBruto() -> float:
	TipoAtaqueAtual = TipoAtaque.FISICO
	var e_critico: bool = randf() * 100 >= get_chance_critico_fator()
	var valor_bonus: float = 0.0
	
	for item in itens:
		if item.TemBonusDanoFisico:
			valor_bonus += item.DanoFisico
	
	for talento in talentos:
		if talento.TemBonusDeAtaqueFisico:
			valor_bonus += talento.DanoFisico
	
	return get_dano_critico(Ataque + valor_bonus) if e_critico else Ataque + valor_bonus 

func CalcularDanoMagicoBruto(NomePoder: String) -> float:
	TipoAtaqueAtual = TipoAtaque.MAGICO
	var e_critico: bool = randf() * 100 >= get_chance_critico_fator()
	var valor_bonus: float = 0.0
	var ataque_base: float = 0.0
	for item in itens:
		if item.TemBonusDanoMagico:
			valor_bonus += item.DanoMagico
	
	for talento in talentos:
		if talento.TemBonusDeAtaqueFisico:
			valor_bonus += talento.DanoMagico
	
	for Poder in poderes:
		if Poder.nome == NomePoder && Poder.EhAtaque:
			ataque_base = Poder.Dano
	
	return get_dano_critico(ataque_base + valor_bonus) if e_critico else ataque_base + valor_bonus 

class_name BoardBase
extends RefCounted

## Contrato que toda implementación de tablero debe cumplir.
## No instanciar directamente.

## True si la coordenada existe en el tablero y está vacía.
func is_valid_empty_cell(coord: Vector2i) -> bool:
	push_error("is_valid_empty_cell() no implementado")
	return false

## True si player_id puede colocar en coord ahora mismo
## (vacía + reglas de adyacencia, o tablero vacío para el primer movimiento).
func can_place_at(coord: Vector2i) -> bool:
	push_error("can_place_at() no implementado")
	return false

## Coloca ficha si can_place_at() es true. Devuelve true si tuvo éxito.
func place_piece(coord: Vector2i, player_id: int) -> bool:
	push_error("place_piece() no implementado")
	return false

func check_winner_at(coord: Vector2i, player_id: int) -> bool:
	push_error("check_winner_at() no implementado")
	return false

func reset() -> void:
	push_error("reset() no implementado")

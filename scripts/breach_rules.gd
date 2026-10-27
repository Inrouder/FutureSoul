class_name BreachRules
extends RefCounted

# All grid contents are deterministic. The authoritative host checks the full proof.
const SYMBOLS := ["1C", "55", "E9", "BD", "7A", "FF", "03", "A4"]
const REQUIRED := ["E9", "BD", "55", "7A"]
const GRID := 5

static func matrix_for(node: int) -> Array:
    var cells: Array = []
    for y in range(GRID):
        var row: Array = []
        for x in range(GRID):
            row.append(SYMBOLS[(x * 3 + y * 5 + x * y + node * 7) % SYMBOLS.size()])
        cells.append(row)
    # Guaranteed four-token path obeying row/column alternation.
    var col_a := (2 + node) % GRID
    var row_b := 1 + ((node * 2 + 1) % 4)
    var col_c := (col_a + 2) % GRID
    var row_d := (row_b + 2) % GRID
    cells[0][col_a] = REQUIRED[0]
    cells[row_b][col_a] = REQUIRED[1]
    cells[row_b][col_c] = REQUIRED[2]
    cells[row_d][col_c] = REQUIRED[3]
    return cells

static func path_is_valid(node: int, proof: Array) -> bool:
    if proof.size() != REQUIRED.size():
        return false
    var matrix := matrix_for(node)
    var used := {}
    var prior := Vector2i(-1, -1)
    for i in range(proof.size()):
        if not proof[i] is Array or proof[i].size() != 2:
            return false
        var x := int(proof[i][0])
        var y := int(proof[i][1])
        if x < 0 or y < 0 or x >= GRID or y >= GRID:
            return false
        var cell := Vector2i(x, y)
        if used.has(cell):
            return false
        if i == 0 and y != 0:
            return false
        if i > 0 and i % 2 == 1 and x != prior.x:
            return false
        if i > 0 and i % 2 == 0 and y != prior.y:
            return false
        if str(matrix[y][x]) != REQUIRED[i]:
            return false
        used[cell] = true
        prior = cell
    return true

static func reference_path(node: int) -> Array:
    var col_a := (2 + node) % GRID
    var row_b := 1 + ((node * 2 + 1) % 4)
    var col_c := (col_a + 2) % GRID
    var row_d := (row_b + 2) % GRID
    return [[col_a, 0], [col_a, row_b], [col_c, row_b], [col_c, row_d]]

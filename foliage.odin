package main

import rl "vendor:raylib"
import "core:fmt"
import "core:math/rand"

plant_struct :: struct {
    pos: [2]int,
    tile: [2]int
}

FOLIAGE_MAP := make(map[int]plant_struct)


add_foliage :: proc(p: [2]int, type: TILE_ENUMS) {
    size := p[1] * GRID_SIZE + p[0]

    if type == .Water {
        x := int(rand.int31_max(3) + 10)
        y := int(rand.int31_max(3))
        FOLIAGE_MAP[size] = plant_struct{
            p,
            [2]int{x, y}
        }
    }  else if type == .Dirt {
        x := int(rand.int31_max(4) + 10)
        y := int(rand.int31_max(2) + 6)
        FOLIAGE_MAP[size] = plant_struct{
            p,
            [2]int{x, y}
        }
    } else if type == .Grass {
        x := int(rand.int31_max(4) + 10)
        y := int(rand.int31_max(2) + 3)
        FOLIAGE_MAP[size] = plant_struct{
            p,
            [2]int{x, y}
        }
    } else if type == .Rock {
        x := int(rand.int31_max(4) + 14)
        y := int(rand.int31_max(3))
        FOLIAGE_MAP[size] = plant_struct{
            p,
            [2]int{x, y}
        }
    }
}

randomly_place_foliage :: proc(p: [2]int, type: TILE_ENUMS) {
    val := rand.int31_max(100)

    if val >= 50 {
        add_foliage(p, type)
    }
}

render_foliage :: proc() {
    for index in FOLIAGE_MAP {
        f := FOLIAGE_MAP[index]
        rect := rl.Rectangle{f32(f.tile[0]*CELL_SIZE), f32(f.tile[1]*CELL_SIZE), CELL_SIZE, CELL_SIZE}
        tileDest := rl.Rectangle{f32(f.pos[0]*CELL_SIZE), f32(f.pos[1]*CELL_SIZE), CELL_SIZE, CELL_SIZE}
    
        origin:f32  = CELL_SIZE / 2

        rl.DrawTexturePro(WORLD_TEXTURE.world, rect, tileDest, rl.Vector2{-origin, -origin}, 0, rl.WHITE)
    }
}
package main

import "core:fmt"
import "core:math/noise"
import "core:math/rand"
import rl "vendor:raylib"
import "core:mem"
import "core:math"


GRID_SIZE :: 50
CELL_SIZE :: 32

gen_noise_map :: proc(baseFrequency: f64, cellSize: f64, octaves: i8, persistance: f64, lacunarity: f64, seed: i64, coords: [2]int) -> f32 {
    totalNoise: f32
    frequency: f64 = baseFrequency / cellSize
    amplitude: f64 = 2.0
    maxValue: f64

    for i in 0..<octaves {
        totalNoise += noise.noise_2d(seed, {f64(coords[0])*frequency,f64(coords[1])*frequency}) * f32(amplitude)

        maxValue += amplitude
        amplitude *= persistance
        frequency *= lacunarity
    }
    return totalNoise / f32(maxValue)
}

gen_map :: proc(width, height: int) -> []f32 {
    grid := make([]f32, width*height)
    seed := rand.int63_max(10000)
    for x in 0..<width {
        for y in 0..<height {
            noise_value := gen_noise_map(0.2, 5, 2, 0.5, 4, seed, {x, y})
            size := y * width + x
            if noise_value <= -0.5 {
                LEVEL[size] = .Water
                noise_value = -1
            } else if noise_value > -0.5 && noise_value <= 0 {
                LEVEL[size] = .Dirt
                noise_value = -0.5
            } else if noise_value > 0 && noise_value <= 0.5 {
                LEVEL[size] = .Grass
                noise_value = 0
            } else {
                noise_value = 1
                LEVEL[size] = .Rock
            }
            grid[size] = noise_value
        }
    }
    return grid
}

widen_path :: proc(grid: []f32, path: [][2]int) -> [][2]int {

    widen_path: [dynamic][2]int
    defer delete(widen_path)

    for p, i in path {
        append(&widen_path, p)
        adjacent_positions := [][2]int{
            {p[0]+1, p[1]},
            {p[0]-1, p[1]},
            {p[0], p[1]+1},
            {p[0], p[1]-1}
        }

        for adj in adjacent_positions {
            if is_valid(adj[0], adj[1]) && !is_unblocked(grid, adj[0], adj[1]) {
                append(&widen_path, adj)
            }
        }
    }

    fixed_data := make([][2]int, len(widen_path))
    copy(fixed_data, widen_path[:])

    return fixed_data
}

main :: proc() {
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer {
        fmt.printfln("MEMORY SUMMARY")
        for _, leak in tracking_allocator.allocation_map {
            fmt.printfln(" %v leaked %m", leak.location, leak.size)
        }
        for bad_free in tracking_allocator.bad_free_array {
            fmt.printfln(" %v allocation %p was freed badly", bad_free.location, bad_free.memory)
        }
    }

    rl.InitWindow(1600, 1600, "Road Generator")
    rl.SetTargetFPS(60)


    grid_width := 50
    grid_height := 50
    grid := gen_map(grid_width,grid_height)
    defer delete(grid)

    rand_start := [2]int{int(rand.float32_range(0, 49)), 0}
    for {
        size := rand_start[1] * grid_width + rand_start[0]
        if grid[size] <= -0.5 || grid[size] > 0.5 {
            rand_start = [2]int{int(rand.float32_range(0, 49)), 0}
        } else {
            break
        }
    }
    rand_end := [2]int{int(rand.float32_range(0, 49)), 49}
    for {
        size := rand_end[1] * grid_width + rand_end[0]
        if grid[size] <= -0.5 || grid[size] > 0.5 {
            rand_end = [2]int{int(rand.float32_range(0, 49)), 49}
        } else {
            break
        }
    }

    path := a_star_search(grid, rand_start, rand_end, grid_width, grid_height)
    path_2 := widen_path(grid, path)
    defer delete(path_2)
    defer delete(path)

    for p in path_2 {
        size := p[1] * grid_width + p[0]
        LEVEL[size] = .Road
    }

    load_texture()
    create_4bit_map()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        /*
        for cell, i in grid {
            normalized := (cell + 1) / 2
            gray_value := u8(normalized * 255 + 0.5)

            x :f32= f32(i % 50)
            y :f32= f32(i / 50)

            if cell <= -0.5 {
                rl.DrawRectangleV({x*32, y*32}, {32, 32}, rl.BLUE)
            } else if cell > -0.5 && cell <= 0 {
                rl.DrawRectangleV({x*32, y*32}, {32, 32}, rl.YELLOW)
            } else if cell > 0 && cell <= 0.5 {
                rl.DrawRectangleV({x*32, y*32}, {32, 32}, rl.GREEN)
            } else {
                rl.DrawRectangleV({x*32, y*32}, {32, 32}, rl.GRAY)
            }

            //rl.DrawRectangleV({x*32, y*32}, {32, 32}, colour)
        }
        */
        load_background()
        for p in path {
            x := f32(p[0])
            y := f32(p[1])

            //rl.DrawRectangleV({x*32, y*32}, {32, 32}, rl.RED)
        }


        rl.EndDrawing()
    }

    clear_memory()
    unload_texture()
    rl.CloseWindow()
}
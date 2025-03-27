package main

import "core:fmt"
import "core:math/noise"
import "core:math/rand"
import rl "vendor:raylib"
import "core:mem"
import "core:math"


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
    for x in 0..<width {
        for y in 0..<height {
            noise_value := gen_noise_map(0.2, 5, 2, 0.5, 4, 2, {x, y})
            size := y * width + x
            grid[size] = noise_value
        }
    }
    return grid
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

    rl.InitWindow(2000, 2000, "Road Generator")
    rl.SetTargetFPS(60)

    grid := gen_map(50,50)
    defer delete(grid)

    rand_start := [2]int{int(rand.float32_range(0, 49)), 0}
    rand_end := [2]int{int(rand.float32_range(0, 49)), 49}

    path := a_star_search(grid, rand_start, rand_end, 50, 50)
    defer delete(path)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        for cell, i in grid {
            normalized := (cell + 1) / 2
            gray_value := u8(normalized * 255 + 0.5)
            colour := rl.Color{gray_value, gray_value, gray_value, 255}

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

        for p in path {
            x := f32(p[0])
            y := f32(p[1])

            rl.DrawRectangleV({x*32, y*32}, {32, 32}, rl.RED)
        }


        rl.EndDrawing()
    }

    rl.CloseWindow()
}
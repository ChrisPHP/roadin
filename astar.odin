package main

import "core:math"
import pq "core:container/priority_queue"
import "core:fmt"

astar_cell :: struct {
    parent_x: int,
    parent_y: int,
    total_cost: f32,
    start_cost: f32,
    heuristic: f32
}

open_list :: struct {
    f: f32,
    x: int,
    y: int
}

HEIGHT := 0
WIDTH := 0

is_valid :: proc(x, y: int) -> bool {
    return (x >= 0) && (x < WIDTH) && (y >= 0) && (y < HEIGHT)
}

is_unblocked :: proc(grid: []f32, x, y: int) -> bool {
    size := y * WIDTH + x
    if grid[size] <= -0.5 || grid[size] > 0.5 {
        return true
    }
    return false
}

is_destination :: proc(x, y, dest: [2]int) -> bool {
    if dest[0] == x && dest[1] == y {
        return true
    }
    return false
}

calculate_heuristics :: proc(x, y: int, dest: [2]int) -> f32 {
    dest_x := dest[0]
    dest_y := dest[1]

    return math.sqrt_f32(
        math.pow_f32(f32(x - dest_x), 2) + math.pow_f32(f32(dest_x - dest_y), 2)
    )
}

get_noise_value :: proc(value: f32) -> f32 {
    return abs(value)
}

cell_compare :: proc(a, b: ^open_list) -> bool {
    return a.f < b.f
}

trace_path :: proc(cell_details: []astar_cell, dest: [2]int) -> [][2]int {
    path := make([dynamic][2]int)
    end_x := dest[0]
    end_y := dest[1]
    
    // First, add the destination
    append(&path, [2]int{end_x, end_y})
    
    for {
        size := end_y * WIDTH + end_x
        
        // Get the parent cell
        parent_x := cell_details[size].parent_x
        parent_y := cell_details[size].parent_y
        
        // Check if we've reached a cell that is its own parent (likely the start)
        if parent_x == end_x && parent_y == end_y {
            break
        }
        
        // Move to the parent
        end_x = parent_x
        end_y = parent_y
        
        // Add the parent to the path
        append(&path, [2]int{end_x, end_y})
    }
    
    // Reverse the path (optional, depends on if you want start->dest or dest->start)
    // This step is often needed since we traced from dest to start
    // Implement path reversal here if needed
    
    fixed_data := make([][2]int, len(path))
    copy(fixed_data, path[:])
    delete(path)
    
    return fixed_data
}

new_open_list_cell :: proc(f: f32, x, y: int) -> ^open_list {
    olist := new(open_list)
    olist.f = f
    olist.x = x
    olist.y = y 
    return olist
}

a_star_search :: proc(grid: []f32, start, dest: [2]int, width, height: int) -> [][2]int {
    fmt.println(start, dest)

    WIDTH = width
    HEIGHT = height
    
    if !is_valid(start[0], start[1]) || !is_valid(dest[0], dest[1]) {
        fmt.println("Source or destination invalid")
        return {}
    }

    if is_unblocked(grid, start[0], start[1]) || is_unblocked(grid, dest[0], dest[1]) {
        fmt.println("Source or destination blocked")
        return {}
    }

    if is_destination(start[0], start[1], dest) {
        fmt.println("Already at destination")
        return {}
    }

    closedList := make([]bool, WIDTH*HEIGHT)
    defer delete(closedList)
    cellList := make([]astar_cell, WIDTH*HEIGHT)
    defer delete(cellList)

    for x in 0..<WIDTH {
        for y in 0..<HEIGHT {
            size := y * WIDTH + x
            cellList[size].total_cost = math.F32_MAX
            cellList[size].start_cost = math.F32_MAX
            cellList[size].heuristic = math.F32_MAX
            cellList[size].parent_x = -1
            cellList[size].parent_y = -1
        }
    }

    i := start[0]
    j := start[1]
    size := j * WIDTH + i
    cellList[size].total_cost = 0
    cellList[size].start_cost = 0
    cellList[size].heuristic = 0
    cellList[size].parent_x = i
    cellList[size].parent_y = j

    pqueue: pq.Priority_Queue(^open_list)
    pq.init(&pqueue, cell_compare, pq.default_swap_proc(^open_list))
    o_cell := new_open_list_cell(0.0, i, j)
    pq.push(&pqueue, o_cell)


    for pq.len(pqueue) > 0 {
        p := pq.pop(&pqueue)

        i = p.x
        j = p.y
        size := j * WIDTH + i
        closedList[size] = true

        directions := [8][2]int{{0,1},{0,-1},{1,0},{-1,0},{1,1},{1,-1},{-1,1},{-1,-1}}
        for dir in directions {
            new_i := i + dir[0]
            new_j := j + dir[1]
            new_size := new_j * WIDTH + new_i

            if is_valid(new_i, new_j) && !is_unblocked(grid, new_i, new_j) && !closedList[new_size] {
                if is_destination(new_i, new_j, dest) {
                    cellList[new_size].parent_x = i
                    cellList[new_size].parent_y = j

                    path := trace_path(cellList, dest)

                    fixed_data := make([][2]int, len(path))
                    copy(fixed_data, path[:])
                    delete(path)

                    free(p)
                    for pq.len(pqueue) > 0 {
                        free_me := pq.pop(&pqueue)
                        free(free_me)
                    }
                    pq.destroy(&pqueue)

                    return fixed_data
                } else {
                    
                    g_new := cellList[size].start_cost + 1.0 + get_noise_value(grid[size])
                    h_new := calculate_heuristics(new_i, new_j, dest)
                    f_new := g_new + h_new

                    if cellList[new_size].total_cost == math.F32_MAX || cellList[new_size].total_cost > f_new {
                        o_cell = new_open_list_cell(f_new, new_i, new_j)
                        pq.push(&pqueue, o_cell)

                        cellList[new_size].total_cost = f_new
                        cellList[new_size].start_cost = g_new
                        cellList[new_size].heuristic = h_new
                        cellList[new_size].parent_x = i
                        cellList[new_size].parent_y = j
                    }
                }
            }
        }
        free(p)
    }
    pq.destroy(&pqueue)
    return {}
}
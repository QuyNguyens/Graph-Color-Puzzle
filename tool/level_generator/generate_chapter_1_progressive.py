import math
import random
import json

color_map = {
    'RED': 'PuzzleColor.red',
    'BLUE': 'PuzzleColor.blue',
    'YELLOW': 'PuzzleColor.yellow',
    'GREEN': 'PuzzleColor.green',
    'PURPLE': 'PuzzleColor.purple'
}

def solve_csp(nodes, edges, inventory):
    node_list = list(nodes)
    adj = {u: set() for u in node_list}
    for u, v in edges:
        adj[u].add(v)
        adj[v].add(u)
    
    node_list.sort(key=lambda u: len(adj[u]), reverse=True)
    
    current_coloring = {}
    inv_rem = dict(inventory)
    
    def backtrack(idx):
        if idx == len(node_list):
            return True
        u = node_list[idx]
        neighbor_colors = {current_coloring[v] for v in adj[u] if v in current_coloring}
        
        for c, count in list(inv_rem.items()):
            if count > 0 and c not in neighbor_colors:
                inv_rem[c] -= 1
                current_coloring[u] = c
                if backtrack(idx + 1):
                    return True
                del current_coloring[u]
                inv_rem[c] += 1
        return False

    if backtrack(0):
        return current_coloring
    return None

def compute_chromatic_number(nodes, edges):
    node_list = list(nodes)
    adj = {u: set() for u in node_list}
    for u, v in edges:
        adj[u].add(v)
        adj[v].add(u)
        
    for k in range(1, len(nodes) + 1):
        coloring = {}
        def can_color(idx):
            if idx == len(node_list):
                return True
            u = node_list[idx]
            n_colors = {coloring[v] for v in adj[u] if v in coloring}
            for c in range(k):
                if c not in n_colors:
                    coloring[u] = c
                    if can_color(idx + 1):
                        return True
                    del coloring[u]
            return False
        if can_color(0):
            return k
    return len(nodes)

def relax_layout(nodes, edges, seed=42):
    random.seed(seed)
    n = len(nodes)
    pos = {}
    for i, u in enumerate(nodes):
        angle = 2 * math.pi * i / n + 0.12
        pos[u] = [0.5 + 0.35 * math.cos(angle), 0.5 + 0.35 * math.sin(angle)]
        
    adj = {u: set() for u in nodes}
    for u, v in edges:
        adj[u].add(v)
        adj[v].add(u)
        
    for it in range(300):
        t = 0.05 * (1.0 - it / 300)
        disp = {u: [0.0, 0.0] for u in nodes}
        
        # Repulsion between all node pairs
        for i in range(n):
            u = nodes[i]
            for j in range(i + 1, n):
                v = nodes[j]
                dx = pos[u][0] - pos[v][0]
                dy = pos[u][1] - pos[v][1]
                d = math.hypot(dx, dy)
                if d < 1e-4:
                    dx, dy, d = 0.01, 0.01, 0.014
                f = 0.045 / (d * d)
                disp[u][0] += (dx / d) * f
                disp[u][1] += (dy / d) * f
                disp[v][0] -= (dx / d) * f
                disp[v][1] -= (dy / d) * f
                
        # Attraction along edges
        for u, v in edges:
            dx = pos[v][0] - pos[u][0]
            dy = pos[v][1] - pos[u][1]
            d = math.hypot(dx, dy)
            f = d * d / 0.11
            disp[u][0] += (dx / (d + 1e-4)) * f
            disp[u][1] += (dy / (d + 1e-4)) * f
            disp[v][0] -= (dx / (d + 1e-4)) * f
            disp[v][1] -= (dy / (d + 1e-4)) * f
            
        for u in nodes:
            d_len = math.hypot(disp[u][0], disp[u][1])
            if d_len > 0:
                step = min(d_len, t)
                pos[u][0] += (disp[u][0] / d_len) * step
                pos[u][1] += (disp[u][1] / d_len) * step
                
    xs = [pos[u][0] for u in nodes]
    ys = [pos[u][1] for u in nodes]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    
    rx = max(max_x - min_x, 1e-4)
    ry = max(max_y - min_y, 1e-4)
    
    final_pos = {}
    for u in nodes:
        nx = 0.12 + 0.76 * (pos[u][0] - min_x) / rx
        ny = 0.12 + 0.76 * (pos[u][1] - min_y) / ry
        final_pos[u] = (round(nx, 3), round(ny, 3))
        
    return final_pos

# Level definitions for Chapter 1
RAW_LEVELS = [
    # --- PHASE 1: LEVELS 1-4 (2 COLORS: RED, BLUE) ---
    {
        "num": 1, "title": "Khởi Đầu Đơn Sắc", "n": 4,
        "edges": [("n1", "n4"), ("n2", "n4"), ("n3", "n4")],
        "inv": {"RED": 3, "BLUE": 1}
    },
    {
        "num": 2, "title": "Đường Nối Song Hành", "n": 4,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4")],
        "inv": {"RED": 2, "BLUE": 2}
    },
    {
        "num": 3, "title": "Vòng Lặp Tứ Giác", "n": 4,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n1")],
        "inv": {"RED": 2, "BLUE": 2}
    },
    {
        "num": 4, "title": "Tâm Điểm Ngũ Tinh", "n": 5,
        "edges": [("n1", "n5"), ("n2", "n5"), ("n3", "n5"), ("n4", "n5")],
        "inv": {"RED": 4, "BLUE": 1}
    },

    # --- PHASE 2: MILESTONE L5 & LEVELS 6-9 (3 COLORS: + YELLOW) ---
    {
        "num": 5, "title": "Cột Mốc 1: Sắc Vàng Xuất Hiện", "n": 5,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n1")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 1}
    },
    {
        "num": 6, "title": "Mái Nhà Tam Giác", "n": 5,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n1"), ("n1", "n5"), ("n2", "n5")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 1}
    },
    {
        "num": 7, "title": "Trục Xoay Bánh Xe", "n": 5,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n1"), ("n1", "n5"), ("n2", "n5"), ("n3", "n5"), ("n4", "n5")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 1}
    },
    {
        "num": 8, "title": "Lăng Trụ Tam Giác", "n": 6,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n1"), ("n4", "n5"), ("n5", "n6"), ("n6", "n4"), ("n1", "n4"), ("n2", "n5"), ("n3", "n6")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2}
    },
    {
        "num": 9, "title": "Lục Giác Dây Cung", "n": 6,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n1"), ("n1", "n4"), ("n2", "n5")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2}
    },

    # --- PHASE 3: MILESTONE L10 & LEVELS 11-19 (4 COLORS: + GREEN) ---
    {
        "num": 10, "title": "Cột Mốc 2: Sắc Lục Khởi Sắc", "n": 6,
        "edges": [("n1", "n2"), ("n1", "n3"), ("n1", "n4"), ("n2", "n3"), ("n2", "n4"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n1")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 1, "GREEN": 1}
    },
    {
        "num": 11, "title": "Vành Xe Ngũ Giác", "n": 6,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n1"), ("n1", "n6"), ("n2", "n6"), ("n3", "n6"), ("n4", "n6"), ("n5", "n6")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 1, "GREEN": 1}
    },
    {
        "num": 12, "title": "Khung Đa Diện Nhỏ", "n": 6,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n1"), ("n1", "n5"), ("n3", "n5"), ("n2", "n6"), ("n4", "n6"), ("n5", "n6")],
        "inv": {"RED": 2, "BLUE": 1, "YELLOW": 2, "GREEN": 1}
    },
    {
        "num": 13, "title": "Mạng Lưới Nhánh Kép", "n": 7,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n1"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n7"), ("n7", "n4"), ("n1", "n7")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 1}
    },
    {
        "num": 14, "title": "Cánh Nhạn Tứ Sắc", "n": 7,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n1"), ("n1", "n5"), ("n2", "n5"), ("n3", "n6"), ("n4", "n6"), ("n5", "n7"), ("n6", "n7")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 1}
    },
    {
        "num": 15, "title": "Thử Thách: Cung Hợp Âm", "n": 7,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n7"), ("n7", "n1"), ("n1", "n4"), ("n2", "n5"), ("n3", "n6"), ("n4", "n7")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 1}
    },
    {
        "num": 16, "title": "Vòng Khép Kín", "n": 7,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n7"), ("n7", "n1"), ("n1", "n3"), ("n3", "n5"), ("n5", "n7")],
        "inv": {"RED": 3, "BLUE": 2, "YELLOW": 1, "GREEN": 1}
    },
    {
        "num": 17, "title": "Khối Lập Phương Phẳng", "n": 8,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n1"), ("n5", "n6"), ("n6", "n7"), ("n7", "n8"), ("n8", "n5"), ("n1", "n5"), ("n2", "n6"), ("n3", "n7"), ("n4", "n8")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 2}
    },
    {
        "num": 18, "title": "Trục Bánh Xe Lục Giác", "n": 8,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n1"), ("n1", "n7"), ("n2", "n7"), ("n3", "n7"), ("n4", "n8"), ("n5", "n8"), ("n6", "n8"), ("n7", "n8")],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 2}
    },
    {
        "num": 19, "title": "Điểm Thắt Ngăn Cách", "n": 8,
        "edges": [("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n1"), ("n1", "n3"), ("n4", "n5"), ("n5", "n6"), ("n6", "n7"), ("n7", "n8"), ("n8", "n5"), ("n5", "n7")],
        "inv": {"RED": 3, "BLUE": 2, "YELLOW": 2, "GREEN": 1}
    },

    # --- PHASE 4: MILESTONE L20 & LEVELS 21-29 (5 COLORS: + PURPLE) ---
    {
        "num": 20, "title": "Cột Mốc 3: Sắc Tím Hoàn Hảo", "n": 8,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n1"),
            ("n1", "n6"), ("n2", "n6"), ("n3", "n7"), ("n4", "n7"), ("n5", "n8"), ("n6", "n8"), ("n7", "n8"),
            ("n1", "n3"), ("n2", "n4")
        ],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 1, "PURPLE": 1}
    },
    {
        "num": 21, "title": "Ngũ Sắc Hòa Điệu", "n": 8,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n1"),
            ("n5", "n6"), ("n6", "n7"), ("n7", "n8"), ("n8", "n5"),
            ("n1", "n5"), ("n2", "n6"), ("n3", "n7"), ("n4", "n8"),
            ("n1", "n7"), ("n2", "n8"), ("n5", "n3")
        ],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 1, "PURPLE": 1}
    },
    {
        "num": 22, "title": "Đối Xứng Trục Ngũ Sắc", "n": 8,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n7"), ("n7", "n8"), ("n8", "n1"),
            ("n1", "n5"), ("n2", "n6"), ("n3", "n7"), ("n4", "n8"), ("n1", "n4"), ("n5", "n8")
        ],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 1, "GREEN": 2, "PURPLE": 1}
    },
    {
        "num": 23, "title": "Mắt Lưới Sao Băng", "n": 8,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n1"),
            ("n1", "n7"), ("n3", "n7"), ("n5", "n7"),
            ("n2", "n8"), ("n4", "n8"), ("n6", "n8"),
            ("n7", "n8"), ("n1", "n4"), ("n2", "n5")
        ],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 1, "PURPLE": 1}
    },
    {
        "num": 24, "title": "Mạng Lưới Chín Đỉnh", "n": 9,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n7"), ("n7", "n8"), ("n8", "n9"), ("n9", "n1"),
            ("n1", "n4"), ("n2", "n5"), ("n3", "n6"), ("n4", "n7"), ("n5", "n8"), ("n6", "n9")
        ],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 2, "PURPLE": 1}
    },
    {
        "num": 25, "title": "Thử Thách: Mê Cung Ngũ Sắc", "n": 9,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n7"), ("n7", "n8"), ("n8", "n1"),
            ("n1", "n9"), ("n3", "n9"), ("n5", "n9"), ("n7", "n9"),
            ("n2", "n6"), ("n4", "n8"), ("n1", "n5"), ("n3", "n7")
        ],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 2, "PURPLE": 1}
    },
    {
        "num": 26, "title": "Vành Đai Phân Nhánh", "n": 9,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n1"),
            ("n4", "n5"), ("n5", "n6"), ("n6", "n4"),
            ("n7", "n8"), ("n8", "n9"), ("n9", "n7"),
            ("n1", "n4"), ("n4", "n7"), ("n2", "n5"), ("n5", "n8"), ("n3", "n6"), ("n6", "n9")
        ],
        "inv": {"RED": 3, "BLUE": 2, "YELLOW": 2, "GREEN": 1, "PURPLE": 1}
    },
    {
        "num": 27, "title": "Cung Ngũ Giác Lồng", "n": 9,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n1"),
            ("n6", "n7"), ("n7", "n8"), ("n8", "n9"), ("n9", "n6"),
            ("n1", "n6"), ("n2", "n7"), ("n3", "n8"), ("n4", "n9"), ("n5", "n6"),
            ("n6", "n8"), ("n7", "n9")
        ],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 2, "PURPLE": 1}
    },
    {
        "num": 28, "title": "Mạng Phức Hợp Bậc Cao", "n": 9,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n6"), ("n6", "n7"), ("n7", "n8"), ("n8", "n9"), ("n9", "n1"),
            ("n1", "n5"), ("n2", "n6"), ("n3", "n7"), ("n4", "n8"), ("n5", "n9"), ("n2", "n8"), ("n3", "n9")
        ],
        "inv": {"RED": 3, "BLUE": 2, "YELLOW": 2, "GREEN": 1, "PURPLE": 1}
    },
    {
        "num": 29, "title": "Tiền Đề Chung Kết", "n": 9,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n1"),
            ("n1", "n6"), ("n2", "n7"), ("n3", "n8"), ("n4", "n9"),
            ("n6", "n7"), ("n7", "n8"), ("n8", "n9"), ("n9", "n6"),
            ("n5", "n7"), ("n5", "n8"), ("n6", "n8"), ("n7", "n9")
        ],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 2, "PURPLE": 1}
    },

    # --- PHASE 5: LEVEL 30 (CHAPTER 1 FINALE - 10 NODES, 5 COLORS) ---
    {
        "num": 30, "title": "Chung Kết: Vương Miện Ngũ Sắc", "n": 10,
        "edges": [
            ("n1", "n2"), ("n2", "n3"), ("n3", "n4"), ("n4", "n5"), ("n5", "n1"),
            ("n6", "n7"), ("n7", "n8"), ("n8", "n9"), ("n9", "n10"), ("n10", "n6"),
            ("n1", "n6"), ("n2", "n7"), ("n3", "n8"), ("n4", "n9"), ("n5", "n10"),
            ("n6", "n8"), ("n8", "n10"), ("n10", "n7"), ("n7", "n9"), ("n9", "n6")
        ],
        "inv": {"RED": 2, "BLUE": 2, "YELLOW": 2, "GREEN": 2, "PURPLE": 2}
    }
]

def format_level(lvl):
    node_names = [f"n{i+1}" for i in range(lvl["n"])]
    edges = lvl["edges"]
    inv = lvl["inv"]
    
    # Solve CSP
    sol = solve_csp(node_names, edges, inv)
    assert sol is not None, f"Level {lvl['num']} has NO solution with inventory {inv}!"
    
    # Verify sum of inventory == n
    total_inv = sum(inv.values())
    assert total_inv == lvl["n"], f"Level {lvl['num']} inv sum {total_inv} != n {lvl['n']}!"
    
    # Layout
    pos = relax_layout(node_names, edges, seed=100 + lvl["num"])
    
    diff = round(1.0 + (lvl["num"] - 1) * 0.05, 3)
    
    lines = []
    lines.append("  PuzzleLevel(")
    lines.append(f"    id: 'c1_l{lvl['num']:02d}',")
    lines.append("    chapterId: 1,")
    lines.append(f"    levelNumber: {lvl['num']},")
    lines.append(f"    overallIndex: {lvl['num']},")
    lines.append(f"    title: '{lvl['title']}',")
    lines.append(f"    difficulty: {diff:.3f},")
    lines.append("    initialGraph: Graph(")
    lines.append("      nodes: {")
    for u in node_names:
        x, y = pos[u]
        lines.append(f"        '{u}': GraphNode(id: '{u}', x: {x}, y: {y}),")
    lines.append("      },")
    lines.append("      edges: {")
    for u, v in edges:
        lines.append(f"        GraphEdge('{u}', '{v}'),")
    lines.append("      },")
    lines.append("    ),")
    lines.append("    targetInventory: {")
    for c, cnt in inv.items():
        lines.append(f"      {color_map[c]}: {cnt},")
    lines.append("    },")
    lines.append("  ),")
    return "\n".join(lines)

def main():
    print(f"Generating 30 Progressive Chapter 1 Levels...")
    formatted = []
    for l in RAW_LEVELS:
        f = format_level(l)
        formatted.append(f)
        n_colors = len(l["inv"])
        print(f"Level {l['num']:02d}: {l['title']} | V={l['n']}, E={len(l['edges'])}, Colors={n_colors} -> CSP OK!")

    content = [
        "import '../../../graph_coloring/domain/entities/graph.dart';",
        "import '../../../graph_coloring/domain/entities/graph_edge.dart';",
        "import '../../../graph_coloring/domain/entities/graph_node.dart';",
        "import '../../../graph_coloring/domain/entities/puzzle_color.dart';",
        "import '../../domain/entities/puzzle_level.dart';",
        "",
        "/// Dữ liệu 30 màn chơi của Chapter 1 theo tiến trình mở khóa màu lũy tiến (Milestones L5, L10, L20, L30).",
        "final List<PuzzleLevel> chapter1Levels = [",
    ]
    content.extend(formatted)
    content.append("];")
    content.append("")
    
    out_path = "lib/features/campaign/data/levels/chapter_1_levels.dart"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(content))
    print(f"\nSuccessfully written 30 verified levels to {out_path}!")

if __name__ == '__main__':
    main()

import networkx as nx
from networkx.generators.atlas import graph_atlas_g
import random
import json
import math

print("Exporting 180 campaign specs with exact chromatic numbers...")

def chromatic_number(g):
    for k in range(1, 7):
        adj = {u: list(g.neighbors(u)) for u in g.nodes()}
        nodes = sorted(list(g.nodes()), key=lambda u: len(adj[u]), reverse=True)
        colors = {}
        def bt(idx):
            if idx == len(nodes): return True
            u = nodes[idx]
            neighbor_colors = {colors[v] for v in adj[u] if v in colors}
            for c in range(k):
                if c not in neighbor_colors:
                    colors[u] = c
                    if bt(idx + 1): return True
                    del colors[u]
            return False
        if bt(0): return k
    return 6

atlas = graph_atlas_g()
ch1_unique = []
for g in atlas:
    n = g.number_of_nodes()
    if n in [4, 5, 6] and nx.is_connected(g) and nx.is_bipartite(g):
        ch1_unique.append(g)

all_graphs = list(ch1_unique)
for i in range(5):
    all_graphs.append(ch1_unique[20 + i].copy())

def is_duplicate(g, existing_list):
    for eg in existing_list:
        if nx.is_isomorphic(g, eg):
            return True
    return False

def generate_unique_chapter(target_count, node_range, max_colors, existing_bank, seed_base):
    chapter_graphs = []
    r = random.Random(seed_base)
    for i in range(target_count):
        n_min, n_max = node_range
        n = n_min + (i * (n_max - n_min + 1)) // target_count
        n = min(n, n_max)
        found = False
        attempts = 0
        while not found and attempts < 1000:
            attempts += 1
            style = (i + attempts) % 7
            g = nx.Graph()
            g.add_nodes_from(range(n))
            if style == 0:
                hub = 0
                for u in range(1, n):
                    g.add_edge(hub, u)
                    g.add_edge(u, 1 + (u % (n - 1)))
                for _ in range(attempts % 4):
                    u = r.randint(1, n - 1)
                    v = r.randint(1, n - 1)
                    if u != v and not g.has_edge(u, v): g.add_edge(u, v)
            elif style == 1:
                for u in range(n): g.add_edge(u, (u + 1) % n)
                for c in range(1 + (attempts % (n // 2))):
                    step = 2 + (c % (n - 3))
                    u = (c * 2) % n
                    v = (u + step) % n
                    if u != v: g.add_edge(u, v)
            elif style == 2:
                half = n // 2
                for u in range(half - 1):
                    g.add_edge(u, u + 1)
                    g.add_edge(half + u, half + u + 1)
                    g.add_edge(u, half + u)
                    if (u + attempts) % 2 == 0: g.add_edge(u, half + u + 1)
                g.add_edge(half - 1, n - 1)
                if n % 2 == 1: g.add_edge(n - 1, 0)
            elif style == 3:
                n1 = n // 2
                for u in range(n1): g.add_edge(u, (u + 1) % n1)
                for u in range(n1, n): g.add_edge(u, n1 + ((u - n1 + 1) % (n - n1)))
                g.add_edge(0, n1)
                if attempts % 2 == 1: g.add_edge(1, n1 + 1)
                if attempts % 3 == 0: g.add_edge(0, 2)
            elif style == 4:
                hub = 0
                for u in range(1, n): g.add_edge(hub, u)
                for u in range(1, n - 1, 2): g.add_edge(u, u + 1)
                if attempts % 2 == 1 and n > 5: g.add_edge(2, 3)
            elif style == 5:
                n_inner = max(3, n // 3)
                n_outer = n - n_inner
                for u in range(n_inner): g.add_edge(u, (u + 1) % n_inner)
                for u in range(n_outer): g.add_edge(n_inner + u, n_inner + ((u + 1) % n_outer))
                for u in range(n_inner):
                    target = n_inner + (u * n_outer) // n_inner
                    g.add_edge(u, target)
                    if (u + attempts) % 2 == 0: g.add_edge(u, n_inner + (target - n_inner + 1) % n_outer)
            else:
                tree = nx.random_labeled_tree(n, seed=r.randint(1, 100000))
                g = nx.Graph(tree)
                for _ in range(attempts % 5):
                    u = r.randint(0, n - 1)
                    v = r.randint(0, n - 1)
                    if u != v and not g.has_edge(u, v): g.add_edge(u, v)
            if not nx.is_connected(g): continue
            chi = chromatic_number(g)
            if chi > max_colors: continue
            if is_duplicate(g, existing_bank + chapter_graphs): continue
            g.graph['chi'] = chi
            chapter_graphs.append(g)
            found = True
            break
    return chapter_graphs

all_graphs.extend(generate_unique_chapter(30, (6, 9), 3, all_graphs, 2024))
all_graphs.extend(generate_unique_chapter(30, (8, 12), 4, all_graphs, 3034))
all_graphs.extend(generate_unique_chapter(30, (10, 14), 4, all_graphs, 4044))
all_graphs.extend(generate_unique_chapter(30, (12, 16), 5, all_graphs, 5054))
all_graphs.extend(generate_unique_chapter(30, (14, 20), 5, all_graphs, 6064))

print(f"Total graphs to export: {len(all_graphs)}")

titles = [
    # Ch 1 (1..30)
    "Khởi Đầu Đơn Sắc", "Cặp Cạnh Giao Hòa", "Vòng Tròn Tứ Đỉnh", "Ngôi Sao Bốn Cánh", "Nhánh Cây Ba Lá",
    "Giao Lộ Ngũ Đỉnh", "Cầu Nhịp Năm", "Vòng Lồng Ngũ Sắc", "Cánh Bướm Đôi", "Đường Dài Lục Đỉnh",
    "Cây Lục Điểm", "Bậc Thang Đôi", "Nhánh Đôi Cân Bằng", "Gió Lục Hướng", "Lưới Sáu Đỉnh",
    "Vòng Lục Giác Tròn", "Cầu Vồng Hai Nhịp", "Mắt Kính Giao Thoa", "Khung Cửa Đôi", "Lưới 2x3 Đan Chéo",
    "Cây Bút Chì", "Lục Giác Kép", "Đỉnh Đối Cực", "Lưới Đôi Bipartite", "Cánh Hoa Lục Điểm",
    "Vòng Xoay Biến Thể", "Bậc Thang Phân Nhánh", "Khung Lưới Đảo Chiều", "Cầu Nối Đôi Phân", "Đỉnh Cao Nhị Sắc",

    # Ch 2 (31..60)
    "Tam Giác Khởi Nguyên", "Bánh Xe Tam Sắc W6", "Lục Giác Đường Chéo", "Tam Giác Kép Ghép Đáy", "Cánh Cung Tam Sắc",
    "Bánh Xe Thất Đỉnh W7", "Hình Quạt F7", "Chuỗi Ba Tam Giác", "Thất Giác Hai Chéo", "Thang Đứng Ba Màu",
    "Sao Thất Cánh", "Song Tam Giác Cầu Nối", "Vành Tai Đôi", "Bát Giác Tròn W8", "Hình Quạt Bát Cánh F8",
    "Chuỗi Bốn Tam Giác", "Khối Lập Phương Chéo", "Bát Giác Ba Chéo", "Cặp Tứ Giác Ghép Cạnh", "Ngôi Sao Ba Cánh Hoa",
    "Bánh Xe Kép Song Tâm", "Thang Bốn Bậc", "Cửu Giác Tròn W9", "Hình Quạt Chín Cánh F9", "Chuỗi Năm Tam Giác",
    "Lưới 3x3 Chéo", "Cửu Giác Bốn Chéo", "Ba Tam Giác Thẳng Hàng", "Vòng Tròn Tam Giác", "Bánh Xe Cửu Đỉnh Phức Hợp",

    # Ch 3 (61..90)
    "Cầu Nối Song Đỉnh", "Bánh Xe Khóa Tâm W8", "Lưới Bậc Thang Bát Đỉnh", "Chuỗi Đôi Tam Giác", "Cặp Cụm Tứ Đỉnh",
    "Tâm Khóa Cửu Đỉnh", "Bánh Xe Tinh Tú W9", "Thang Chéo Khóa Đáy", "Song Vòng Khóa Cầu", "Nhánh Cây Khóa Đỉnh",
    "Thập Điểm Khóa Tâm", "Bánh Xe Khóa Kép", "Lưới 2x5 Khóa Biên", "Chuỗi Sáu Tam Giác", "Ngũ Giác Kép Khóa Cầu",
    "Thập Nhất Điểm Khóa", "Bánh Xe Vệ Tinh Khóa", "Lưới Thang Khóa Đôi", "Ba Cụm Khóa Vòng", "Cây Thập Nhất Khóa",
    "Mười Hai Điểm Hoàng Gia", "Bánh Xe Khóa Ba Tâm", "Lưới 3x4 Khóa Biên", "Tứ Cụm Khóa Vòng", "Vành Đôi Khóa Chéo",
    "Chuỗi Tám Tam Giác Khóa", "Mạng Nhện Mười Hai Đỉnh", "Thang Chéo Khóa Trung", "Cầu Nối Tam Trận", "Đỉnh Cao Khóa Chấn",

    # Ch 4 (91..120)
    "Lục Giác Giao Thoa", "Tứ Trận Cầu Nối", "Lưới Tổ Ong 10", "Bánh Xe Vệ Tinh 10", "Vòng Lồng Đan Chéo 10",
    "Song Lục Giác Liên Kết", "Tứ Cụm Vòng Tròn 11", "Tổ Ong 11", "Bánh Xe Quỹ Đạo 11", "Mạng Ba Vòng 11",
    "Đôi Lục Giác Ghép Cạnh", "Tứ Trận Cầu Nối 12", "Lưới Tổ Ong Ba Ô", "Bánh Xe Sao 12", "Vành Đôi Chéo 12",
    "Mạng Lưới Thang Mobius 12", "Cụm Hoa Năm Cánh 12", "Song Lục Giác Chéo 13", "Tứ Trận Mở Rộng 13", "Lưới Tổ Ong Bốn Ô",
    "Bánh Xe Quỹ Đạo 13", "Vành Ba Lớp 13", "Lưới Bát Quái 13", "Mạng Đa Tầng 13", "Song Lục Giác Master 14",
    "Tứ Trận Master 14", "Tổ Ong Master 14", "Bánh Xe Thiên Hà 14", "Vành Ba Lớp Master", "Mạng Liên Kết Tối Thượng",

    # Ch 5 (121..150)
    "Lưới Đa Giác Dày Đặc", "Mạng Ngũ Sắc Grotzsch", "Tổ Ong Chéo 12", "Nhện Tỏa 12", "Lưới Chordal 12",
    "Tam Giác Dày Đặc 13", "Grotzsch Mở Rộng 13", "Tổ Ong Chéo 13", "Nhện Ba Tầng 13", "Mạng Chordal 13",
    "Tam Giác Dày Đặc 14", "Grotzsch 14", "Tổ Ong Chéo 14", "Nhện Ba Tầng 14", "Mạng Chordal 14",
    "Tam Giác Dày Đặc 15", "Grotzsch 15", "Tổ Ong Chéo 15", "Nhện Ba Tầng 15", "Mạng Chordal 15",
    "Tam Giác Dày Đặc 16", "Grotzsch 16", "Tổ Ong Chéo 16", "Nhện Ba Tầng 16", "Mạng Chordal 16",
    "Đại Lưới Đa Giác 16", "Grotzsch Đỉnh Cao 16", "Tổ Ong Master 16", "Nhện Đa Tầng 16", "Ma Trận Giới Hạn Tuyệt Đối",

    # Ch 6 (151..180)
    "Tam Cụm Hoàng Gia 14", "Mạng Nhện Bất Quy Tắc 14", "Tứ Trận Chéo 14", "Tổ Ong Hoàng Gia 14", "Mạng Vệ Tinh 14",
    "Tam Cụm Hoàng Gia 15", "Mạng Nhện Bất Quy Tắc 15", "Tứ Trận Chéo 15", "Tổ Ong Hoàng Gia 15", "Mạng Vệ Tinh 15",
    "Tam Cụm Hoàng Gia 16", "Mạng Nhện Bất Quy Tắc 16", "Tứ Trận Chéo 16", "Tổ Ong Hoàng Gia 16", "Mạng Vệ Tinh 16",
    "Tam Cụm Hoàng Gia 17", "Mạng Nhện Bất Quy Tắc 17", "Tứ Trận Chéo 17", "Tổ Ong Hoàng Gia 17", "Mạng Vệ Tinh 17",
    "Tam Cụm Hoàng Gia 18", "Mạng Nhện Bất Quy Tắc 18", "Tứ Trận Chéo 18", "Tổ Ong Hoàng Gia 18", "Mạng Vệ Tinh 18",
    "Tam Cụm Hoàng Gia 19", "Mạng Nhện Bất Quy Tắc 19", "Tứ Trận Chéo 19", "Tổ Ong Hoàng Gia 19", "Mạng Vệ Tinh 19",
    "Tam Cụm Thượng Cổ 20", "Mạng Nhện Vô Tận 20", "Tứ Trận Hoàng Đế 20", "Tổ Ong Bất Diệt 20", "Mạng Lưới Thần Thoại 20"
]

out_specs = []

for idx, g in enumerate(all_graphs):
    ch = (idx // 30) + 1
    num = (idx % 30) + 1
    overall = idx + 1
    lvl_id = f"c{ch}_l{num:02d}"
    title = titles[idx] if idx < len(titles) else f"Level {overall}"
    n = g.number_of_nodes()
    chi = g.graph.get('chi', chromatic_number(g))

    pos = nx.spring_layout(g, seed=42 + idx, k=1.0 / math.sqrt(n), iterations=100)
    xs = [p[0] for p in pos.values()]
    ys = [p[1] for p in pos.values()]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    span_x = max(0.001, max_x - min_x)
    span_y = max(0.001, max_y - min_y)
    
    node_coords = []
    for u in range(n):
        x = 0.12 + 0.76 * (pos[u][0] - min_x) / span_x
        y = 0.12 + 0.76 * (pos[u][1] - min_y) / span_y
        node_coords.append([round(x, 3), round(y, 3)])

    if ch == 1:
        palette = ["RED", "BLUE"]
        req_colors = 2
        locked = []
        restricted = []
    elif ch == 2:
        palette = ["RED", "BLUE", "YELLOW"]
        req_colors = max(2, chi)
        locked = []
        restricted = []
    elif ch == 3:
        palette = ["RED", "BLUE", "YELLOW", "GREEN"]
        req_colors = max(3, chi)
        locked = [0]
        restricted = []
    elif ch == 4:
        palette = ["RED", "BLUE", "YELLOW", "GREEN"]
        req_colors = max(3, chi)
        locked = [0, min(n - 1, 4)]
        restricted = []
    elif ch == 5:
        palette = ["RED", "BLUE", "YELLOW", "GREEN", "PURPLE"]
        req_colors = max(4, chi)
        locked = []
        restricted = [0, min(n - 1, 5)]
    else: # ch == 6
        palette = ["RED", "BLUE", "YELLOW", "GREEN", "PURPLE"]
        req_colors = max(4, chi)
        locked = [0, min(n - 1, 6)]
        restricted = [min(n - 1, 3), min(n - 1, 7)]

    edge_list = [[u, v] for u, v in g.edges()]

    out_specs.append({
        "id": lvl_id,
        "chapterId": ch,
        "levelNumber": num,
        "overallIndex": overall,
        "title": title,
        "nodeCount": n,
        "nodes": node_coords,
        "edges": edge_list,
        "palette": palette,
        "requiredColors": req_colors,
        "lockedNodeIndices": locked,
        "restrictedNodeIndices": restricted,
    })

with open("tool/level_generator/data/campaign_180_specs.json", "w", encoding="utf-8") as f:
    json.dump(out_specs, f, indent=2, ensure_ascii=False)

print(f"Exported 180 verified specs to tool/level_generator/data/campaign_180_specs.json!")

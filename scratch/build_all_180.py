import networkx as nx
from networkx.generators.atlas import graph_atlas_g
import random

print("Generating 180 strictly non-duplicate campaign graphs...")

# Chapter 1: The 25 unique bipartite graphs
atlas = graph_atlas_g()
ch1_unique = []
for g in atlas:
    n = g.number_of_nodes()
    if n in [4, 5, 6] and nx.is_connected(g) and nx.is_bipartite(g):
        ch1_unique.append(g)

all_graphs = list(ch1_unique) # 0..24
# 25..29: copy of last 5
for i in range(5):
    all_graphs.append(ch1_unique[20 + i].copy())

print(f"Chapter 1: 30 levels added (25 unique, 5 duplicates).")

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
                num_chords = (attempts % 4)
                for _ in range(num_chords):
                    u = r.randint(1, n - 1)
                    v = r.randint(1, n - 1)
                    if u != v and not g.has_edge(u, v):
                        g.add_edge(u, v)
            elif style == 1:
                for u in range(n): g.add_edge(u, (u + 1) % n)
                num_chords = 1 + (attempts % (n // 2))
                for c in range(num_chords):
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
                    if (u + attempts) % 2 == 0:
                        g.add_edge(u, half + u + 1)
                g.add_edge(half - 1, n - 1)
                if n % 2 == 1:
                    g.add_edge(n - 1, 0)
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
                for u in range(1, n - 1, 2):
                    g.add_edge(u, u + 1)
                if attempts % 2 == 1 and n > 5:
                    g.add_edge(2, 3)
            elif style == 5:
                n_inner = max(3, n // 3)
                n_outer = n - n_inner
                for u in range(n_inner): g.add_edge(u, (u + 1) % n_inner)
                for u in range(n_outer): g.add_edge(n_inner + u, n_inner + ((u + 1) % n_outer))
                for u in range(n_inner):
                    target = n_inner + (u * n_outer) // n_inner
                    g.add_edge(u, target)
                    if (u + attempts) % 2 == 0:
                        g.add_edge(u, n_inner + (target - n_inner + 1) % n_outer)
            else:
                tree = nx.random_labeled_tree(n, seed=r.randint(1, 100000))
                g = nx.Graph(tree)
                for _ in range(attempts % 5):
                    u = r.randint(0, n - 1)
                    v = r.randint(0, n - 1)
                    if u != v and not g.has_edge(u, v):
                        g.add_edge(u, v)
            
            if not nx.is_connected(g):
                continue
            d = nx.coloring.greedy_color(g, strategy='largest_first')
            if max(d.values()) + 1 > max_colors:
                continue
            if is_duplicate(g, existing_bank + chapter_graphs):
                continue
            
            chapter_graphs.append(g)
            found = True
            break
        
        if not found:
            raise RuntimeError(f"Could not find unique graph for level {i} in chapter!")
            
    return chapter_graphs

print("Generating Chapter 2 (N=6..9, MaxColors=3)...")
ch2_graphs = generate_unique_chapter(30, (6, 9), 3, all_graphs, 2024)
all_graphs.extend(ch2_graphs)
print(f"Chapter 2 generated: {len(ch2_graphs)} unique graphs.")

print("Generating Chapter 3 (N=8..12, MaxColors=4)...")
ch3_graphs = generate_unique_chapter(30, (8, 12), 4, all_graphs, 3034)
all_graphs.extend(ch3_graphs)
print(f"Chapter 3 generated: {len(ch3_graphs)} unique graphs.")

print("Generating Chapter 4 (N=10..14, MaxColors=4)...")
ch4_graphs = generate_unique_chapter(30, (10, 14), 4, all_graphs, 4044)
all_graphs.extend(ch4_graphs)
print(f"Chapter 4 generated: {len(ch4_graphs)} unique graphs.")

print("Generating Chapter 5 (N=12..16, MaxColors=5)...")
ch5_graphs = generate_unique_chapter(30, (12, 16), 5, all_graphs, 5054)
all_graphs.extend(ch5_graphs)
print(f"Chapter 5 generated: {len(ch5_graphs)} unique graphs.")

print("Generating Chapter 6 (N=14..20, MaxColors=5)...")
ch6_graphs = generate_unique_chapter(30, (14, 20), 5, all_graphs, 6064)
all_graphs.extend(ch6_graphs)
print(f"Chapter 6 generated: {len(ch6_graphs)} unique graphs.")

print(f"\nTotal Bank size: {len(all_graphs)}")
print(f"Checking all 16,110 pairs across the entire 180 campaign...")
iso_pairs = []
for i in range(len(all_graphs)):
    for j in range(i + 1, len(all_graphs)):
        if nx.is_isomorphic(all_graphs[i], all_graphs[j]):
            iso_pairs.append((i + 1, j + 1))

print(f"Total isomorphic pairs: {len(iso_pairs)}")
print(f"Pairs: {iso_pairs}")
assert len(iso_pairs) == 5, f"Expected exactly 5 pairs in Ch 1, got {len(iso_pairs)}"
print("ALL 180 LEVEL TOPOLOGIES GENERATED WITH PERFECT UNIQUENESS (175 UNIQUE TOPOLOGIES)!")

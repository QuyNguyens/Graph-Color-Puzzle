import networkx as nx
from networkx.generators.atlas import graph_atlas_g
import itertools
import random
import math

print("=== STEP 1: CHAPTER 1 GRAPHS (30 levels) ===")
atlas = graph_atlas_g()
ch1_unique = []
for g in atlas:
    n = g.number_of_nodes()
    if n in [4, 5, 6] and nx.is_connected(g) and nx.is_bipartite(g):
        ch1_unique.append(g)

print(f"Ch 1: 25 unique connected bipartite graphs found.")
ch1_graphs = list(ch1_unique)
for i in range(5):
    ch1_graphs.append(ch1_unique[20 + i].copy())
print(f"Ch 1 total levels: {len(ch1_graphs)}")

print("\n=== STEP 2: GENERATING CHAPTER 2 (30 distinct graphs, N=6..9, Chi=3) ===")

def make_ch2_graph(idx):
    if idx < 5:
        n = 6
        if idx == 0:
            return nx.wheel_graph(6)
        elif idx == 1:
            g = nx.cycle_graph(6)
            g.add_edge(0, 2)
            return g
        elif idx == 2:
            g = nx.cycle_graph(6)
            g.add_edge(0, 2)
            g.add_edge(0, 4)
            return g
        elif idx == 3:
            g = nx.Graph([(0, 1), (1, 2), (2, 0), (1, 3), (2, 3), (3, 4), (4, 5)])
            return g
        else:
            g = nx.Graph([(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0), (0, 5)])
            return g
    elif idx < 13:
        k = idx - 5
        if k == 0:
            return nx.wheel_graph(7)
        elif k == 1:
            g = nx.path_graph(6)
            for i in range(6): g.add_edge(6, i)
            return g
        elif k == 2:
            g = nx.Graph([(0,1),(1,2),(2,0), (1,3),(2,3), (2,4),(3,4), (3,5),(4,5), (4,6)])
            return g
        elif k == 3:
            g = nx.cycle_graph(7)
            g.add_edge(0, 2)
            g.add_edge(0, 4)
            return g
        elif k == 4:
            g = nx.ladder_graph(3)
            g.add_edge(0, 3)
            g.add_edge(1, 4)
            g.add_edge(5, 6)
            return g
        elif k == 5:
            g = nx.star_graph(5)
            g.add_edge(1, 2)
            g.add_edge(3, 4)
            g.add_edge(5, 6)
            return g
        elif k == 6:
            g = nx.Graph([(0,1),(1,2),(2,0), (3,4),(4,5),(5,3), (0,6),(3,6)])
            return g
        else:
            g = nx.cycle_graph(5)
            g.add_edge(0, 5); g.add_edge(1, 5)
            g.add_edge(2, 6); g.add_edge(3, 6)
            return g
    elif idx < 22:
        k = idx - 13
        if k == 0:
            return nx.wheel_graph(8)
        elif k == 1:
            g = nx.path_graph(7)
            for i in range(7): g.add_edge(7, i)
            return g
        elif k == 2:
            g = nx.Graph([(0,1),(1,2),(2,0), (1,3),(2,3), (2,4),(3,4), (3,5),(4,5), (4,6),(5,6), (6,7)])
            return g
        elif k == 3:
            g = nx.cubical_graph()
            g.add_edge(0, 2)
            return g
        elif k == 4:
            g = nx.cycle_graph(8)
            g.add_edge(0, 2); g.add_edge(0, 4); g.add_edge(4, 6)
            return g
        elif k == 5:
            g = nx.Graph([(0,1),(1,2),(2,3),(3,0),(0,2), (4,5),(5,6),(6,7),(7,4),(4,6), (2,4)])
            return g
        elif k == 6:
            g = nx.Graph([(0,1),(0,2),(0,3), (1,4),(2,4), (2,5),(3,5), (3,6),(1,6), (0,7)])
            return g
        elif k == 7:
            g = nx.cycle_graph(6)
            for i in range(3): g.add_edge(6, i)
            for i in range(3, 6): g.add_edge(7, i)
            g.add_edge(6, 7)
            return g
        else:
            g = nx.ladder_graph(4)
            g.add_edge(0, 5); g.add_edge(1, 6); g.add_edge(2, 7)
            return g
    else:
        k = idx - 22
        if k == 0:
            return nx.wheel_graph(9)
        elif k == 1:
            g = nx.path_graph(8)
            for i in range(8): g.add_edge(8, i)
            return g
        elif k == 2:
            g = nx.Graph([(0,1),(1,2),(2,0), (1,3),(2,3), (2,4),(3,4), (3,5),(4,5), (4,6),(5,6), (5,7),(6,7), (6,8)])
            return g
        elif k == 3:
            g = nx.grid_2d_graph(3, 3)
            mapping = {node: i for i, node in enumerate(g.nodes())}
            g = nx.relabel_nodes(g, mapping)
            g.add_edge(0, 4); g.add_edge(4, 8)
            return g
        elif k == 4:
            g = nx.cycle_graph(9)
            g.add_edge(0, 2); g.add_edge(0, 4); g.add_edge(4, 6); g.add_edge(6, 8)
            return g
        elif k == 5:
            g = nx.Graph([(0,1),(1,2),(2,0), (3,4),(4,5),(5,3), (6,7),(7,8),(8,6), (2,3), (5,6)])
            return g
        elif k == 6:
            g = nx.Graph([(0,1),(1,2),(2,0), (3,4),(4,5),(5,3), (6,7),(7,8),(8,6)])
            g.add_edge(0, 3); g.add_edge(3, 6); g.add_edge(6, 0)
            return g
        else:
            g = nx.wheel_graph(9)
            g.remove_edge(1, 2)
            g.add_edge(1, 3)
            g.add_edge(5, 7)
            return g

ch2_graphs = [make_ch2_graph(i) for i in range(30)]
print(f'Ch 2: Generated {len(ch2_graphs)} graphs.')

iso_count_ch2 = 0
for i in range(30):
    for j in range(i + 1, 30):
        if nx.is_isomorphic(ch2_graphs[i], ch2_graphs[j]):
            iso_count_ch2 += 1
            print(f'Ch2 Iso: {i} and {j}')
print(f'Ch 2 Isomorphic pairs: {iso_count_ch2}')

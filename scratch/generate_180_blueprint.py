import networkx as nx
from networkx.generators.atlas import graph_atlas_g
import json
import math

print("=== GENERATING 180 CANDIDATE LEVEL TOPOLOGIES ===")

# --- CHAPTER 1: 25 Unique Connected Bipartite Graphs (N=4..6) + 5 Alternate Layouts/Inventories ---
atlas = graph_atlas_g()
ch1_atlas = []
for g in atlas:
    n = g.number_of_nodes()
    if n in [4, 5, 6] and nx.is_connected(g) and nx.is_bipartite(g):
        ch1_atlas.append(g)

print(f"Chapter 1 Atlas graphs found: {len(ch1_atlas)}")
# ch1_atlas has 25 graphs.
# We will create 30 levels for Ch 1:
# Levels 1..25: one for each of the 25 unique graphs
# Levels 26..30: 5 diverse bipartite graphs with different layout and inventory partition

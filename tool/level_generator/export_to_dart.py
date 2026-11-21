import json
import os

color_map = {
    'RED': 'PuzzleColor.red',
    'BLUE': 'PuzzleColor.blue',
    'YELLOW': 'PuzzleColor.yellow',
    'GREEN': 'PuzzleColor.green',
    'PURPLE': 'PuzzleColor.purple'
}

def escape_str(s):
    return s.replace("'", "\\'")

def format_level(lvl):
    lines = []
    lines.append("  PuzzleLevel(")
    lines.append(f"    id: '{lvl['id']}',")
    lines.append(f"    chapterId: {lvl['chapterId']},")
    lines.append(f"    levelNumber: {lvl['levelNumber']},")
    lines.append(f"    overallIndex: {lvl['overallIndex']},")
    title_escaped = escape_str(lvl['title'])
    lines.append(f"    title: '{title_escaped}',")
    diff = lvl.get('difficulty', 1.0)
    lines.append(f"    difficulty: {diff:.3f},")
    lines.append("    initialGraph: Graph(")
    lines.append("      nodes: {")
    
    for n in lvl['nodes']:
        nid = n['id']
        x = round(n['x'], 3)
        y = round(n['y'], 3)
        parts = [f"id: '{nid}'", f"x: {x}", f"y: {y}"]
        if n.get('isLocked'):
            c_str = color_map[n['currentColor']]
            parts.append("isLocked: true")
            parts.append(f"currentColor: {c_str}")
        if n.get('restrictedColors'):
            rc_strs = [color_map[rc] for rc in n['restrictedColors']]
            parts.append(f"restrictedColors: {{{', '.join(rc_strs)}}}")
        node_str = f"'{nid}': GraphNode({', '.join(parts)}),"
        lines.append(f"        {node_str}")
    
    lines.append("      },")
    lines.append("      edges: {")
    for edge in lvl['edges']:
        u, v = edge[0], edge[1]
        lines.append(f"        GraphEdge('{u}', '{v}'),")
    lines.append("      },")
    lines.append("    ),")
    lines.append("    targetInventory: {")
    for c_code, count in lvl['inventory'].items():
        c_str = color_map[c_code]
        lines.append(f"      {c_str}: {count},")
    lines.append("    },")
    lines.append("  ),")
    return "\n".join(lines)

def main():
    json_path = 'tool/level_generator/output/campaign_180_candidates.json'
    with open(json_path, 'r', encoding='utf-8') as f:
        levels = json.load(f)

    by_chapter = {}
    for lvl in levels:
        by_chapter.setdefault(lvl['chapterId'], []).append(lvl)

    for cid in range(1, 7):
        ch_levels = by_chapter[cid]
        output_file = f'lib/features/campaign/data/levels/chapter_{cid}_levels.dart'
        content_lines = [
            "import '../../../graph_coloring/domain/entities/graph.dart';",
            "import '../../../graph_coloring/domain/entities/graph_edge.dart';",
            "import '../../../graph_coloring/domain/entities/graph_node.dart';",
            "import '../../../graph_coloring/domain/entities/puzzle_color.dart';",
            "import '../../domain/entities/puzzle_level.dart';",
            "",
            f"/// Dữ liệu 30 màn chơi của Chapter {cid} (Đã tái tạo đa dạng topo 100% hợp lệ).",
            f"final List<PuzzleLevel> chapter{cid}Levels = [",
        ]
        for lvl in ch_levels:
            content_lines.append(format_level(lvl))
        content_lines.append("];")
        content_lines.append("")
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("\n".join(content_lines))
        print(f"Exported Chapter {cid} ({len(ch_levels)} levels) -> {output_file}")

if __name__ == '__main__':
    main()

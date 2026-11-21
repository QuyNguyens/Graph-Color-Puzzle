import os

lib_dir = r'D:\Flutter\graph_coloring\lib'
errors = []

for root, dirs, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            fpath = os.path.join(root, f)
            with open(fpath, encoding='utf-8') as fp:
                for line_no, line in enumerate(fp, 1):
                    line_s = line.strip()
                    if line_s.startswith('import ') and (line_s.endswith(';') or "as " in line_s):
                        # extract target string between quotes
                        q1 = line_s.find("'")
                        q2 = line_s.find("'", q1 + 1)
                        if q1 == -1:
                            q1 = line_s.find('"')
                            q2 = line_s.find('"', q1 + 1)
                        if q1 != -1 and q2 != -1:
                            target = line_s[q1+1:q2]
                            if target.startswith('package:flutter') or target.startswith('dart:') or target.startswith('package:shared_preferences') or target.startswith('package:audioplayers') or target.startswith('package:intl'):
                                continue
                            if target.startswith('package:graph_coloring/'):
                                rel_target = target.replace('package:graph_coloring/', '').replace('/', os.sep)
                                full_target = os.path.join(lib_dir, rel_target)
                                if not os.path.exists(full_target):
                                    errors.append(f'{fpath}:{line_no}: Package import not found: {target}')
                            elif not target.startswith('package:'):
                                full_target = os.path.normpath(os.path.join(root, target.replace('/', os.sep)))
                                if not os.path.exists(full_target):
                                    errors.append(f'{fpath}:{line_no}: Relative import not found: {target}')

for e in errors:
    print(e)

if not errors:
    print('ALL IMPORTS IN lib/ RESOLVED SUCCESSFULLY!')

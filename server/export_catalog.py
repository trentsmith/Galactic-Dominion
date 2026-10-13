"""Regenerate the service catalog from checked-in Godot collectible Resources."""
import ast, json, re
from pathlib import Path
root = Path(__file__).resolve().parents[1]
output=[]
for path in sorted((root/'resources/collectibles').glob('*.tres')):
    values={'starter':False,'research_cost':0,'species':'','ship_class':'','modifiers':{}}
    for line in path.read_text().splitlines():
        match=re.fullmatch(r'(\w+) = (.*)',line)
        if not match: continue
        key,value=match.groups()
        if key not in ['id','display_name','kind','rarity','slot','species','ship_class','modifiers','starter','research_cost']: continue
        values[key]= ast.literal_eval(value) if value not in ['true','false'] else value == 'true'
    if 'id' not in values: raise ValueError(path)
    output.append(values)
(root/'server/catalog.json').write_text(json.dumps(output,indent=2)+'\n')
print(f'Exported {len(output)} entries')

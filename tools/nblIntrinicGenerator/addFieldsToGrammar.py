import json
import os

# this script adds 'hlsl_type' field to grammar file


filepath = "../../include/spirv/unified1/spirv.core.grammar.json"
filepath2 = "../../include/spirv/unified1/spirv.core.grammar2.json"

with open(filepath) as f:
    d = json.load(f)

for i in range(len(d['instructions'])):
    instr = d['instructions'][i]
    if 'operands' in instr.keys():
        for j in range(len(instr['operands'])):
            op = instr['operands'][j]
            type = 'uint32_t'
            if 'name' in op.keys() or op['kind'] == 'IdResultType':
                op['hlsl_type'] = type


default_builtin_var_type = 'static const uint32_t'

for i in range(len(d['operand_kinds'][32]['enumerants'])):
    opk = d['operand_kinds'][32]['enumerants'][i]
    opk['hlsl_type'] = default_builtin_var_type

with open(filepath2, 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)

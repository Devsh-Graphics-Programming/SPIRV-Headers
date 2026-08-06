# Intrinsic generator tool for hlsl

This tool generates hlsl code that exposes spirv instructions.

It was made as manual writing and making sure these instructions are up to date proved to be too time consuming.

To run the app use 
```
python main.py [grammar] [fields] [type mapping] [output] [-v|--verbose]
```
* grammar - Filepath to a JSON file containing the instructions you want to expose. For example, this is a valid grammar file `include/spirv/unified1/spirv.core.grammar.json`.

* fields - Filepath to a JSON file containing a list of builtin variables and functions to expose in the output file.

* type mapping - Filepath to a JSON file containg information about types of parameters and return types of exposed functions.

* output - where to write the generated HLSL file

* verbose - print additional information, as well as any warnings such as omitted fields 

Or run example that takes in no arguments
```
python runExample.py
```



# Type Map JSON

An example JSON file that contains the information about spirv function types might look like this:
```
{
    "default": "uint32_t",
    "classMappings":[
        {
            "class": "Atomic",
            "types": [
                {
                    "kind": "IdResult",
                    "type": "T"
                },
                {
                    "kind": "IdRef",
                    "name": "Pointer",
                    "type": "P",
                    "attributes": [
                        "vk::ext_reference"
                    ]
                },
                {
                    "kind": "IdRef",
                    "name": "Value",
                    "type": "T"
                },
                {
                    "kind": "IdRef",
                    "name": "Comparator",
                    "type": "T",
                    "const": false
                }
            ]
        },
        {
            "class": "Conversion",
            "types": [
                {
                    "kind": "IdResult",
                    "type": "T"
                },
                {
                    "kind": "IdRef",
                    "name": "Operand",
                    "type": "U"
                }
            ]
        }
        
    ],
    "instructionMappings":[
        {
            "instruction": "GLSLstd450MatrixInverse",
            "types": [
                {
                    "kind": "IdResult",
                    "type": "T"
                }
            ]
        }
    ]
}
```

Default type declared in type mapping JSON file must not be generic, preferably primitive. `uint32_t` is recommended.

###  classMappings
This is a list of structures that contain two elments: 
- `"class"` string - name of class that the type mappings will apply to
- `"types"` list - list of type mapping info explained below


#### type
```
{
    "kind": "IdRef",
    "name": "Pointer",
    "type": "P",
    "const": true,
    "attributes": [
        "vk::ext_reference",
        ...
    ]
}
```
this structure contains all info needed to describe a single type of a parameter or a return type.
- `kind` and `name` are the identifiers that need to match for the type mapping to be used. They need to be the same as defined in grammar file. If kind is set to `IdResult`, name is not needed as the type declaration will describe the return type.
- `type` is the hlsl typename that should appear in the generated file. The program type a generic one, if and only if it's a single uppercase letter
- `const` boolean is optional, and if ommited it will be defaulted to `false`
- `attributes` is a optional list of strings of attributes to place next to the type (without `[[ ]]` as those are added by the code generator) 

### instructionMappings
``` 
"instructionMappings":[
    {
        "instruction": "GLSLstd450MatrixInverse",
        "types": [
            {
                "kind": "IdResult",
                "type": "T"
            }
        ]
    }
]
```
Similiar to classMappings, but it overrides the class Mapping for a single instruction. Instead of  `class` string, it takes a `instruction` string that must match `opname` field of the instruction in the grammar file`



# Field list 

example field list JSON:
```
{
    "operand": [
        {
            "class": "Atomic",
            "operandList": [
                "*"
            ]
        },
        {
            "class": "Conversion",
            "operandList": [
                "OpBitcast"
            ]
        },
        {
            "class": "Bit",
            "operandList": [
                "OpBitFieldUExtract",
                "OpBitFieldSExtract"
            ]
        }
    ],
    "builtins": [
        {
            "name": "HelperInvocation",
            "type": "bool"
        },
        {
            "name": "Position",
            "type": "float32_t4",
            "const": false
        },
        {
            "name": "VertexIndex"
        },
        {
            "name": "InstanceIndex"
        },
        {
            "name": "NumWorkgroups"
        },
        {
            "name": "WorkgroupId"
        },
        {
            "name": "LocalInvocationId"
        },
        {
            "name": "GlobalInvocationId"
        },
        {
            "name": "LocalInvocationIndex"
        }
    ]
}
```

### operand
Operand (aka instruction), the elements in `operand` field in the JSON file contain information about which functions should be exposed in the generated file.

You need to define the classes you want to expose, and inside the classes you need to list the functions to be exposed.

- `"class"` string needs to match `class` field of the instruction in grammar file. You may redefine classes with the same name, just be aware that things will listed in the output file in the exact same order as in fields JSON file.

- `"operandList"` list of strings, contains the `opname`s of instructions to expose, or alternatively you may put a wildcard `"*"` to expose all instructions in the class. you may not put wildcard in `class` field. 



If an instruction is not present in the `grammar` JSON file, but it is listed to be exposed in the `fields` JSON file, that instruction will be omitted.
Since its possible to enter only grammar file into the main.py argument, you will need to put the missing function into a different output file that was generated with a grammar that contains the missing instruction.


from main import main

if __name__ == "__main__":
    main("../../include/spirv/unified1/spirv.core.grammar.json",
         "example input/nabla.intrinsics.core.json",
         "example input/spirv.type_mappings.json",
         "example output/exampleIntrisincsCore.hlsl",
         True)

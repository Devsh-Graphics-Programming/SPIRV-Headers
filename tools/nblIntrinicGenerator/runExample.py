from main import main

if __name__ == "__main__":
    main("../../include/spirv/unified1/spirv.core.grammar2.json",
         "example input/nabla.intrinsics.core.json",
         "example output/exampleIntrisincsCore.hlsl",
         True, True)

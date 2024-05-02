import argparse
import json
from codegen import HLSLCodeGenerator


def loadJson(filepath, file_kind):
    try:
        with open(filepath) as f:
            return json.load(f)
    except Exception as ex:
        print(f"Error while reading {file_kind} file: {filepath}\n{str(ex)}")


def main(grammar_file, fields_file, mappings_file, output_file, verbose=False):
    # Your logic goes here
    typeMapFilepath = loadJson(mappings_file, "Mappings file")
    grammarFilepath = loadJson(grammar_file, "Grammar file")
    itemsToExportFilepath = loadJson(fields_file, "Input file")
    if grammarFilepath is None:
        raise ValueError("Grammar is none")
    if typeMapFilepath is None:
        raise ValueError("Type mappings is none")
    if itemsToExportFilepath is None:
        raise ValueError("List of items to export is none")
    cg = HLSLCodeGenerator(typeMapFilepath, grammarFilepath, output_file, verbose=verbose)
    cg.WriteAll(itemsToExportFilepath)
    print(f"Saved to '{output_file}'")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parse JSON files using argparse")

    parser.add_argument("grammar_file", help="Path to JSON file with grammar")
    parser.add_argument("fields_file", help="Path to JSON file with list of fields to generate")
    parser.add_argument("mappings_file", help="Path to JSON file with type mappings")
    parser.add_argument("output_file", help="Path to save the program's output to")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose mode")

    args = parser.parse_args()
    v = args.verbose
    main(args.grammar_file, args.fields_file, args.mappings_file, args.output_file, v)

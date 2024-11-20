import argparse
import json
from codegen import HLSLCodeGenerator


def loadJson(filepath, file_kind):
    try:
        with open(filepath) as f:
            return json.load(f)
    except Exception as ex:
        print(f"Error while reading {file_kind} file: {filepath}\n{str(ex)}")


def main(grammar_file, whitelist_file, output_file, verbose=False, extra_comments=False):
    # Your logic goes here
    grammarDict = loadJson(grammar_file, "Grammar file")
    whitelistDict = loadJson(whitelist_file, "Input file")
    if grammarDict is None:
        raise ValueError("Grammar is none")
    if whitelistDict is None:
        raise ValueError("List of items to export is none")
    cg = HLSLCodeGenerator(grammarDict, output_file, verbose, extra_comments)
    cg.WriteAll(whitelistDict)
    print(f"Saved to '{output_file}'")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parse JSON files using argparse")

    parser.add_argument("grammar_file", help="Path to JSON file with grammar")
    parser.add_argument("whitelist_file", help="Path to JSON file with list of fields to generate")
    parser.add_argument("output_file", help="Path to save the program's output to")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose mode")
    parser.add_argument("-c", "--comments", action="store_true", help="Enable writing additional comments in output file, such as capabilities above builtins")

    args = parser.parse_args()
    v = args.verbose
    c = args.comments
    main(args.grammar_file, args.fields_file, args.mappings_file, args.output_file, v, c)

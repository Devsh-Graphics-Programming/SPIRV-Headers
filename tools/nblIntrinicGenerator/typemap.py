from typing import Optional


def stripName(name: Optional[str]):
    """
    helper function, as names of parameters in spirv grammar json file are wrapped in quotes
    this function removes them
    example operand in grammar json: {"kind" : "IdRef",        "name" : "'Resident Code'"}
    """
    if name is not None:
        name = name.strip(", \"'\t\n(){}[]").replace("_", "").replace("-", "_")
    return name


class OperandTypeInfo:
    """
    TypeMapping class contains information about type for a single type, for example
    its used to determine just the return type
    or type of one of several parameters of an instruction

    Helper class used for storage
    """

    def __init__(self, entry_dict: dict) -> None:
        self.typeName: str = entry_dict['type']
        self.isGeneric: bool = len(self.typeName) == 1 and self.typeName[0].isupper()
        self.kind: str = entry_dict['kind']
        self.name: str = entry_dict.get('name', '')
        self.const: bool = entry_dict.get('const', False)
        self.isParam: bool = 'name' in entry_dict.keys()
        self.attributes: list = entry_dict.get('attributes', [])


class InstructionTypeMap:
    """
    TypeMappingCollection is a class that contains all type mappings usedby an instruction or class of instructions
    Helper class
    """

    def __init__(self, types: list) -> None:
        self.param_mappings = []
        self.return_type_mapping = None
        for t in types:
            mapping = OperandTypeInfo(t)
            if mapping.kind == 'IdResult':
                self.return_type_mapping = mapping
            else:
                self.param_mappings.append(mapping)

    def GetOperandTypeInfo(self, kind: str, name: str) -> Optional[OperandTypeInfo]:
        """
        Returns information about a single operand of an instruction that includes the type it should map for, or None, 
        in which case the default type should be used or void type in case of return types 
        """
        name = stripName(name)
        return self.return_type_mapping if kind == 'IdResult' else next((x for x in self.param_mappings if x.kind == kind and x.name == name), None)


class TypeMapHandler:

    """
    Main class use to obtain information about types used by spirv instructions
    """

    def __init__(self, grammar: dict, typeMapping: dict, verbosity=False) -> None:
        self.defaultType = typeMapping['default']  # default type must not be generic, best to use uint32_t
        self.verbose = verbosity
        self.grammar = grammar
        self.instructionClassLookup = {}
        self.classMappings = {}
        self.instructionMappings = {}
        for item in typeMapping['classMappings']:
            if 'class' not in item.keys():
                raise ValueError("No 'class' field in class mapping, check type mapping json file")
            if 'types' not in item.keys():
                raise ValueError("No 'types' field in class mapping, check type mapping json file")
            key = item['class']
            val = item['types']
            if len(val) == 0:
                raise ValueError("'types' field in class mapping is empty, check type mapping json file")
            if key in self.classMappings.keys():
                raise ValueError("Redefinition of class in classmapping: " + key)
            self.classMappings[key] = InstructionTypeMap(val)
        for item in typeMapping['instructionMappings']:
            if 'instruction' not in item.keys():
                raise ValueError("No 'instruction' field in instruction mapping, check type mapping json file")
            if 'types' not in item.keys():
                raise ValueError("No 'types' field in instruction mapping, check type mapping json file")
            key = item['instruction']
            val = item['types']
            if len(val) == 0:
                raise ValueError("'types' field in instruction mapping is empty, check type mapping json file")
            if key in self.instructionMappings.keys():
                raise ValueError("Redefinition of instruction in classmapping: " + key)
            self.instructionMappings[key] = InstructionTypeMap(val)

        for instruction in grammar['instructions']:
            self.instructionClassLookup[instruction['opname']] = instruction['class']

    def GetInstructionMapping(self, instructionName: str) -> Optional[InstructionTypeMap]:
        if instructionName in self.instructionMappings.keys():
            return self.instructionMappings[instructionName]
        if instructionName in self.instructionClassLookup.keys():
            className = self.instructionClassLookup[instructionName]
            if className in self.classMappings.keys():
                return self.classMappings[className]
        return None

    def GetReturnTypeMapping(self, instructionName: str) -> Optional[OperandTypeInfo]:
        mapping = self.GetInstructionMapping(instructionName)
        if mapping is not None:
            return mapping.return_type_mapping
        return None

    def GetGenericTypeList(self, instruction: dict, omittedOptionalParamIndices=[]):
        """
        Lists all generic types used by an instruction

        omittedOptionalParamIndices is not used at the moment
        but its added as a placeholder in case there is a need to handle generic optional params 

        when * quantifier appears so its currently being ommited when emiting an instruction
        """
        instructionName = instruction['opname']

        mapping = self.GetInstructionMapping(instructionName)
        templateParamNames = set()
        if mapping is not None:
            if 'operands' in instruction.keys():
                for operand in instruction['operands']:
                    operandMapping = mapping.GetOperandTypeInfo(operand['kind'], operand.get('name', None))
                    if operandMapping is not None and operandMapping.isGeneric:
                        if 'quantifier' in operand.keys() and operand['quantifier'] == '?':
                            # encountered a conditional op
                            # todo handle conditional operand
                            pass
                        else:
                            templateParamNames.add(operandMapping.typeName)
        result = list(templateParamNames)
        # result.sort() # sorting actually doesnt help here
        # it is better to have templates in the same order as parameters
        return result

    def GetFunctionParameters(self, instruction: dict):
        """
        This function returs a list of strings
        every string is an argument for the instruction
        only arguments that have a 'name' property are exposed

        for example OpAtomicIAdd might return:
        [ '[[vk::ext_reference]] P pointer', 'uint32_t memory', 'uint32_t semantics', 'T value' ]
        """
        params = []
        instructionName = instruction['opname']
        mapping = self.GetInstructionMapping(instructionName)
        for operand in instruction['operands']:
            if 'name' in operand.keys():
                name = stripName(operand['name'])
                pascalCaseName = name[0].lower() + name[1:]
                if mapping is not None:
                    typeMapping = mapping.GetOperandTypeInfo(operand['kind'], name)
                    if typeMapping is not None:
                        attr = '' if len(typeMapping.attributes) == 0 else " ".join([f"[[{attr}]]" for attr in typeMapping.attributes]) + " "
                        params.append(f"{attr}{'const ' if typeMapping.const else ''}{typeMapping.typeName} {pascalCaseName}")
                        continue
                params.append(f"{self.defaultType} {pascalCaseName}")
        return params

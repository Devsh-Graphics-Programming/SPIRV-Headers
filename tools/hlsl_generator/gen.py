import json
import io
import os
import re
from enum import Enum
from argparse import ArgumentParser
from typing import NamedTuple
from typing import Optional

head = """// Copyright (C) 2023 - DevSH Graphics Programming Sp. z O.O.
// This file is part of the "Nabla Engine".
// For conditions of distribution and use, see copyright notice in nabla.h
#ifndef _NBL_BUILTIN_HLSL_SPIRV_INTRINSICS_CORE_INCLUDED_
#define _NBL_BUILTIN_HLSL_SPIRV_INTRINSICS_CORE_INCLUDED_

#ifdef __HLSL_VERSION
#include "spirv/unified1/spirv.hpp"
#include "spirv/unified1/GLSL.std.450.h"
#endif

#include "nbl/builtin/hlsl/type_traits.hlsl"

namespace nbl 
{
namespace hlsl
{
#ifdef __HLSL_VERSION
namespace spirv
{

//! General Decls
template<uint32_t StorageClass, typename T>
using pointer_t = vk::SpirvOpaqueType<spv::OpTypePointer, vk::Literal< vk::integral_constant<uint32_t, StorageClass> >, T>;

// The holy operation that makes addrof possible
template<uint32_t StorageClass, typename T>
[[vk::ext_instruction(spv::OpCopyObject)]]
pointer_t<StorageClass, T> copyObject([[vk::ext_reference]] T value);

//! Std 450 Extended set operations
template<typename SquareMatrix>
[[vk::ext_instruction(34, /* GLSLstd450MatrixInverse */, "GLSL.std.450")]]
SquareMatrix matrixInverse(NBL_CONST_REF_ARG(SquareMatrix) mat);

// Add specializations if you need to emit a `ext_capability` (this means that the instruction needs to forward through an `impl::` struct and so on)
template<typename T, typename U>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpBitcast)]]
enable_if_t<is_pointer_v<T>, T> bitcast(U);

template<typename T>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpBitcast)]]
uint64_t bitcast(pointer_t<spv::StorageClassPhysicalStorageBuffer, T>);

template<typename T>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpBitcast)]]
pointer_t<spv::StorageClassPhysicalStorageBuffer, T> bitcast(uint64_t);

template<class T, class U>
[[vk::ext_instruction(spv::OpBitcast)]]
enable_if_t<sizeof(T) == sizeof(U) && (is_spirv_type_v<T> || is_vector_v<T>), T> bitcast(U);
"""

foot = """}

#endif
}
}

#endif
"""

def gen(grammer_path, output_path):
    grammer_raw = open(grammer_path, "r").read()
    grammer = json.loads(grammer_raw)
    del grammer_raw
            
    output = open(output_path, "w", buffering=1024**2)

    builtins = [x for x in grammer["operand_kinds"] if x["kind"] == "BuiltIn"][0]["enumerants"]
    execution_modes = [x for x in grammer["operand_kinds"] if x["kind"] == "ExecutionMode"][0]["enumerants"]
    group_operations = [x for x in grammer["operand_kinds"] if x["kind"] == "GroupOperation"][0]["enumerants"]

    with output as writer:
        writer.write(head)

        writer.write("\n//! Builtins\nnamespace builtin\n{\n")
        for b in builtins:
            builtin_type = None
            is_output = False
            builtin_name = b["enumerant"]
            match builtin_name:
                case "HelperInvocation": builtin_type = "bool"
                case "VertexIndex": builtin_type = "uint32_t"
                case "InstanceIndex": builtin_type = "uint32_t"
                case "NumWorkgroups": builtin_type = "uint32_t3"
                case "WorkgroupId": builtin_type = "uint32_t3"
                case "LocalInvocationId": builtin_type = "uint32_t3"
                case "GlobalInvocationId": builtin_type = "uint32_t3"
                case "LocalInvocationIndex": builtin_type = "uint32_t"
                case "SubgroupEqMask": builtin_type = "uint32_t4"
                case "SubgroupGeMask": builtin_type = "uint32_t4"
                case "SubgroupGtMask": builtin_type = "uint32_t4"
                case "SubgroupLeMask": builtin_type = "uint32_t4"
                case "SubgroupLtMask": builtin_type = "uint32_t4"
                case "SubgroupSize": builtin_type = "uint32_t"
                case "NumSubgroups": builtin_type = "uint32_t"
                case "SubgroupId": builtin_type = "uint32_t"
                case "SubgroupLocalInvocationId": builtin_type = "uint32_t"
                case "Position":
                    builtin_type = "float32_t4"
                    is_output = True
                case _: continue
            if is_output:
                writer.write("[[vk::ext_builtin_output(spv::BuiltIn" + builtin_name + ")]]\n")
                writer.write("static " + builtin_type + " " + builtin_name + ";\n")
            else:
                writer.write("[[vk::ext_builtin_input(spv::BuiltIn" + builtin_name + ")]]\n")
                writer.write("static const " + builtin_type + " " + builtin_name + ";\n")
        writer.write("}\n")

        writer.write("\n//! Execution Modes\nnamespace execution_mode\n{")
        for em in execution_modes:
            name = em["enumerant"]
            if name.endswith("INTEL"): continue
            name_l = name[0].lower() + name[1:]
            writer.write("\n\tvoid " + name_l + "()\n\t{\n\t\tvk::ext_execution_mode(spv::ExecutionMode" + name + ");\n\t}\n")
        writer.write("}\n")

        writer.write("\n//! Group Operations\nnamespace group_operation\n{\n")
        for go in group_operations:
            name = go["enumerant"]
            value = go["value"]
            writer.write("\tstatic const uint32_t " + name + " = " + str(value) + ";\n")
        writer.write("}\n")

        writer.write("\n//! Instructions\n")
        for instruction in grammer["instructions"]:
            if instruction["opname"].endswith("INTEL"): continue

            match instruction["class"]:
                case "Atomic":
                    processInst(writer, instruction, InstOptions())
                    processInst(writer, instruction, InstOptions(shape=Shape.PTR_TEMPLATE))
                case "Memory":
                    processInst(writer, instruction, InstOptions(shape=Shape.PTR_TEMPLATE))
                    processInst(writer, instruction, InstOptions(shape=Shape.BDA))
                case "Barrier" | "Bit":
                    processInst(writer, instruction, InstOptions())
                case "Reserved":
                    match instruction["opname"]:
                        case "OpBeginInvocationInterlockEXT" | "OpEndInvocationInterlockEXT":
                            processInst(writer, instruction, InstOptions())
                case "Non-Uniform":
                    match instruction["opname"]:
                        case "OpGroupNonUniformElect" | "OpGroupNonUniformAll" | "OpGroupNonUniformAny" | "OpGroupNonUniformAllEqual":
                            processInst(writer, instruction, InstOptions(result_ty="bool"))
                        case "OpGroupNonUniformBallot":
                            processInst(writer, instruction, InstOptions(result_ty="uint32_t4",op_ty="bool"))
                        case "OpGroupNonUniformInverseBallot" | "OpGroupNonUniformBallotBitExtract":
                            processInst(writer, instruction, InstOptions(result_ty="bool",op_ty="uint32_t4"))
                        case "OpGroupNonUniformBallotBitCount" | "OpGroupNonUniformBallotFindLSB" | "OpGroupNonUniformBallotFindMSB":
                            processInst(writer, instruction, InstOptions(result_ty="uint32_t",op_ty="uint32_t4"))
                        case _: processInst(writer, instruction, InstOptions())
                case _: continue # TODO

        writer.write(foot)

class Shape(Enum):
    DEFAULT = 0,
    PTR_TEMPLATE = 1, # TODO: this is a DXC Workaround
    BDA = 2, # PhysicalStorageBuffer Result Type

class InstOptions(NamedTuple):
    shape: Shape = Shape.DEFAULT
    result_ty: Optional[str] = None
    op_ty: Optional[str] = None

def processInst(writer: io.TextIOWrapper, instruction, options: InstOptions):
    templates = []
    caps = []
    conds = []
    op_name = instruction["opname"]
    fn_name = op_name[2].lower() + op_name[3:]
    result_types = []

    if "capabilities" in instruction and len(instruction["capabilities"]) > 0:
        for cap in instruction["capabilities"]:
            if cap == "Kernel" and len(instruction["capabilities"]) == 1: return
            if cap == "Shader": continue
            caps.append(cap)
    
    if options.shape == Shape.PTR_TEMPLATE:
        templates.append("typename P")
        conds.append("is_spirv_type_v<P>")
    
    # split upper case words
    matches = [(m.group(1), m.span(1)) for m in re.finditer(r'([A-Z])[A-Z][a-z]', fn_name)]

    for m in matches:
        match m[0]:
            case "I":
                conds.append("(is_signed_v<T> || is_unsigned_v<T>)")
                break
            case "U":
                fn_name = fn_name[0:m[1][0]] + fn_name[m[1][1]:]
                result_types = ["uint16_t", "uint32_t", "uint64_t"]
                break
            case "S":
                fn_name = fn_name[0:m[1][0]] + fn_name[m[1][1]:]
                result_types = ["int16_t", "int32_t", "int64_t"]
                break
            case "F":
                fn_name = fn_name[0:m[1][0]] + fn_name[m[1][1]:]
                result_types = ["float16_t", "float32_t", "float64_t"]
                break

    if "operands" in instruction:
        operands = instruction["operands"]
        if operands[0]["kind"] == "IdResultType":
            operands = operands[2:]
            if len(result_types) == 0:
                if options.result_ty == None:
                    result_types = ["T"]
                else:
                    result_types = [options.result_ty]
        else:
            assert len(result_types) == 0
            result_types = ["void"]

        for rt in result_types:
            overload_caps = caps.copy()
            match rt:
                case "uint16_t" | "int16_t": overload_caps.append("Int16")
                case "uint64_t" | "int64_t": overload_caps.append("Int64")
                case "float16_t": overload_caps.append("Float16")
                case "float64_t": overload_caps.append("Float64")

            op_ty = "T"
            if options.op_ty != None:
                op_ty = options.op_ty
            elif rt != "void":
                op_ty = rt
            
            if (not "typename T" in templates) and (rt == "T"):
                templates = ["typename T"] + templates

            args = []
            for operand in operands:
                operand_name = operand["name"].strip("'") if "name" in operand else None
                operand_name = operand_name[0].lower() + operand_name[1:] if (operand_name != None) else ""
                match operand["kind"]:
                    case "IdRef":
                        match operand["name"]:
                            case "'Pointer'":
                                if options.shape == Shape.PTR_TEMPLATE:
                                    args.append("P " + operand_name)
                                elif options.shape == Shape.BDA:    
                                    if (not "typename T" in templates) and (rt == "T" or op_ty == "T"):
                                        templates = ["typename T"] + templates
                                    overload_caps.append("PhysicalStorageBufferAddresses")
                                    args.append("pointer_t<spv::StorageClassPhysicalStorageBuffer, " + op_ty + "> " + operand_name)
                                else:    
                                    if (not "typename T" in templates) and (rt == "T" or op_ty == "T"):
                                        templates = ["typename T"] + templates
                                    args.append("[[vk::ext_reference]] " + op_ty + " " + operand_name)
                            case "'Value'" | "'Object'" | "'Comparator'" | "'Base'" | "'Insert'":
                                if (not "typename T" in templates) and (rt == "T" or op_ty == "T"):
                                    templates = ["typename T"] + templates
                                args.append(op_ty + " " + operand_name)
                            case "'Offset'" | "'Count'" | "'Id'" | "'Index'" | "'Mask'" | "'Delta'":
                                args.append("uint32_t " + operand_name)
                            case "'Predicate'": args.append("bool " + operand_name)
                            case "'ClusterSize'":
                                if "quantifier" in operand and operand["quantifier"] == "?": continue # TODO: overload
                                else: return # TODO
                            case _: return # TODO
                    case "IdScope": args.append("uint32_t " + operand_name.lower() + "Scope")
                    case "IdMemorySemantics": args.append(" uint32_t " + operand_name)
                    case "GroupOperation": args.append("[[vk::ext_literal]] uint32_t " + operand_name)
                    case "MemoryAccess":
                        if options.shape != Shape.BDA:
                            writeInst(writer, templates, overload_caps, op_name, fn_name, conds, rt, args + ["[[vk::ext_literal]] uint32_t memoryAccess"])
                            writeInst(writer, templates, overload_caps, op_name, fn_name, conds, rt, args + ["[[vk::ext_literal]] uint32_t memoryAccess, [[vk::ext_literal]] uint32_t memoryAccessParam"])
                        writeInst(writer, templates + ["uint32_t alignment"], overload_caps, op_name, fn_name, conds, rt, args + ["[[vk::ext_literal]] uint32_t __aligned = /*Aligned*/0x00000002", "[[vk::ext_literal]] uint32_t __alignment = alignment"])
                    case _: return # TODO

            writeInst(writer, templates, overload_caps, op_name, fn_name, conds, rt, args)


def writeInst(writer: io.TextIOWrapper, templates, caps, op_name, fn_name, conds, result_type, args):
    if len(caps) > 0: 
        for cap in caps:
            if (("Float16" in cap and result_type != "float16_t") or
                ("Float32" in cap and result_type != "float32_t") or
                ("Float64" in cap and result_type != "float64_t") or
                ("Int16" in cap and result_type != "int16_t" and result_type != "uint16_t") or
                ("Int64" in cap and result_type != "int64_t" and result_type != "uint64_t")): continue
            
            final_fn_name = fn_name
            if (len(caps) > 1): final_fn_name = fn_name + "_" + cap
            writeInstInner(writer, templates, cap, op_name, final_fn_name, conds, result_type, args)
    else:
        writeInstInner(writer, templates, None, op_name, fn_name, conds, result_type, args)

def writeInstInner(writer: io.TextIOWrapper, templates, cap, op_name, fn_name, conds, result_type, args):
    if len(templates) > 0:
        writer.write("template<" + ", ".join(templates) + ">\n")
    if (cap != None):
        writer.write("[[vk::ext_capability(spv::Capability" + cap + ")]]\n")
    writer.write("[[vk::ext_instruction(spv::" + op_name + ")]]\n")
    if len(conds) > 0:
        writer.write("enable_if_t<" + " && ".join(conds) + ", " + result_type + ">")
    else:
        writer.write(result_type)
    writer.write(" " + fn_name + "(" + ", ".join(args) + ");\n\n")


if __name__ == "__main__":
    script_dir_path = os.path.abspath(os.path.dirname(__file__))

    parser = ArgumentParser(description="Generate HLSL from SPIR-V instructions")
    parser.add_argument("output", type=str, help="HLSL output file")
    parser.add_argument("--grammer", required=False, type=str, help="Input SPIR-V grammer JSON file", default=os.path.join(script_dir_path, "../../include/spirv/unified1/spirv.core.grammar.json"))
    args = parser.parse_args()

    gen(args.grammer, args.output)


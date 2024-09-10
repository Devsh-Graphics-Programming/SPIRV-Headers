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
struct pointer
{
   using type = vk::SpirvOpaqueType<spv::OpTypePointer, vk::Literal< vk::integral_constant<uint32_t, StorageClass> >, T>;
};
// partial spec for BDA
template<typename T>
struct pointer<spv::StorageClassPhysicalStorageBuffer, T>
{
   using type = vk::SpirvType<spv::OpTypePointer, sizeof(uint64_t), sizeof(uint64_t), vk::Literal<vk::integral_constant<uint32_t, spv::StorageClassPhysicalStorageBuffer> >, T>;
};

template<uint32_t StorageClass, typename T>
using pointer_t = typename pointer<StorageClass, T>::type;

template<uint32_t StorageClass, typename T>
NBL_CONSTEXPR_STATIC_INLINE bool is_pointer_v = is_same_v<T, typename pointer<StorageClass, T>::type >;

// The holy operation that makes addrof possible
template<uint32_t StorageClass, typename T>
[[vk::ext_instruction(spv::OpCopyObject)]]
pointer_t<StorageClass, T> copyObject([[vk::ext_reference]] T value);

// TODO: Generate extended instructions
//! Std 450 Extended set instructions
template<typename SquareMatrix>
[[vk::ext_instruction(34 /* GLSLstd450MatrixInverse */, "GLSL.std.450")]]
SquareMatrix matrixInverse(NBL_CONST_REF_ARG(SquareMatrix) mat);

//! Memory instructions
template<typename T, uint32_t alignment>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpLoad)]]
T load(pointer_t<spv::StorageClassPhysicalStorageBuffer, T> pointer, [[vk::ext_literal]] uint32_t __aligned = /*Aligned*/0x00000002, [[vk::ext_literal]] uint32_t __alignment = alignment);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpLoad)]]
enable_if_t<is_spirv_type_v<P>, T> load(P pointer);

template<typename T, uint32_t alignment>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpStore)]]
void store(pointer_t<spv::StorageClassPhysicalStorageBuffer, T>  pointer, T obj, [[vk::ext_literal]] uint32_t __aligned = /*Aligned*/0x00000002, [[vk::ext_literal]] uint32_t __alignment = alignment);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpStore)]]
enable_if_t<is_spirv_type_v<P>, void> store(P pointer, T obj);

//! Bitcast Instructions
// Add specializations if you need to emit a `ext_capability` (this means that the instruction needs to forward through an `impl::` struct and so on)
template<typename T, typename U>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpBitcast)]]
enable_if_t<is_pointer_v<spv::StorageClassPhysicalStorageBuffer, T>, T> bitcast(U);

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
            b_name = b["enumerant"]
            b_type = None
            b_cap = None
            is_output = False
            match b_name:
                case "HelperInvocation": b_type = "bool"
                case "VertexIndex": b_type = "uint32_t"
                case "InstanceIndex": b_type = "uint32_t"
                case "NumWorkgroups": b_type = "uint32_t3"
                case "WorkgroupId": b_type = "uint32_t3"
                case "LocalInvocationId": b_type = "uint32_t3"
                case "GlobalInvocationId": b_type = "uint32_t3"
                case "LocalInvocationIndex": b_type = "uint32_t"
                case "SubgroupEqMask": 
                    b_type = "uint32_t4"
                    b_cap = "GroupNonUniformBallot"
                case "SubgroupGeMask": 
                    b_type = "uint32_t4"
                    b_cap = "GroupNonUniformBallot"
                case "SubgroupGtMask": 
                    b_type = "uint32_t4"
                    b_cap = "GroupNonUniformBallot"
                case "SubgroupLeMask": 
                    b_type = "uint32_t4"
                    b_cap = "GroupNonUniformBallot"
                case "SubgroupLtMask": 
                    b_type = "uint32_t4"
                    b_cap = "GroupNonUniformBallot"
                case "SubgroupSize":
                    b_type = "uint32_t"
                    b_cap = "GroupNonUniform"
                case "NumSubgroups": 
                    b_type = "uint32_t"
                    b_cap = "GroupNonUniform"
                case "SubgroupId":
                    b_type = "uint32_t"
                    b_cap = "GroupNonUniform"
                case "SubgroupLocalInvocationId":
                    b_type = "uint32_t"
                    b_cap = "GroupNonUniform"
                case "Position":
                    b_type = "float32_t4"
                    is_output = True
                case _: continue
            if b_cap != None:
                writer.write("[[vk::ext_capability(spv::Capability" + b_cap + ")]]\n")
            if is_output:
                writer.write("[[vk::ext_builtin_output(spv::BuiltIn" + b_name + ")]]\n")
                writer.write("static " + b_type + " " + b_name + ";\n")
            else:
                writer.write("[[vk::ext_builtin_input(spv::BuiltIn" + b_name + ")]]\n")
                writer.write("static const " + b_type + " " + b_name + ";\n\n")
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
                    processInst(writer, instruction)
                    processInst(writer, instruction, Shape.PTR_TEMPLATE)
                case "Barrier" | "Bit":
                    processInst(writer, instruction)
                case "Reserved":
                    match instruction["opname"]:
                        case "OpBeginInvocationInterlockEXT" | "OpEndInvocationInterlockEXT":
                            processInst(writer, instruction)
                case "Non-Uniform":
                    match instruction["opname"]:
                        case "OpGroupNonUniformElect" | "OpGroupNonUniformAll" | "OpGroupNonUniformAny" | "OpGroupNonUniformAllEqual":
                            processInst(writer, instruction, result_ty="bool")
                        case "OpGroupNonUniformBallot":
                            processInst(writer, instruction, result_ty="uint32_t4",prefered_op_ty="bool")
                        case "OpGroupNonUniformInverseBallot" | "OpGroupNonUniformBallotBitExtract":
                            processInst(writer, instruction, result_ty="bool",prefered_op_ty="uint32_t4")
                        case "OpGroupNonUniformBallotBitCount" | "OpGroupNonUniformBallotFindLSB" | "OpGroupNonUniformBallotFindMSB":
                            processInst(writer, instruction, result_ty="uint32_t",prefered_op_ty="uint32_t4")
                        case _: processInst(writer, instruction)
                case _: continue # TODO

        writer.write(foot)

class Shape(Enum):
    DEFAULT = 0,
    PTR_TEMPLATE = 1, # TODO: this is a DXC Workaround

def processInst(writer: io.TextIOWrapper,
                instruction,
                shape: Shape = Shape.DEFAULT,
                result_ty: Optional[str] = None,
                prefered_op_ty: Optional[str] = None):
    templates = []
    caps = []
    conds = []
    op_name = instruction["opname"]
    fn_name = op_name[2].lower() + op_name[3:]
    exts = instruction["extensions"] if "extensions" in instruction else []

    if "capabilities" in instruction and len(instruction["capabilities"]) > 0:
        for cap in instruction["capabilities"]:
            if cap == "Kernel" and len(instruction["capabilities"]) == 1: return
            if cap == "Shader": continue
            caps.append(cap)
    
    if shape == Shape.PTR_TEMPLATE:
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
                conds.append("is_unsigned_v<T>")
                break
            case "S":
                conds.append("is_signed_v<T>")
                break
            case "F":
                conds.append("(is_same_v<float16_t, T> || is_same_v<float32_t, T> || is_same_v<float64_t, T>)")
                break
    else:
        if instruction["class"] == "Bit":
            conds.append("(is_signed_v<T> || is_unsigned_v<T>)")

    if "operands" in instruction and instruction["operands"][0]["kind"] == "IdResultType":
        if result_ty == None:
            result_ty = "T"
    else:
        result_ty = "void"

    match result_ty:
        case "uint16_t" | "int16_t": caps.append("Int16")
        case "uint64_t" | "int64_t": caps.append("Int64")
        case "float16_t": caps.append("Float16")
        case "float64_t": caps.append("Float64")

    for cap in caps or [None]:
        final_fn_name = fn_name + "_" + cap if (len(caps) > 1) else fn_name
        final_templates = templates.copy()
        
        if (not "typename T" in final_templates) and (result_ty == "T"):
            final_templates = ["typename T"] + final_templates

        if len(caps) > 0:
            if (("Float16" in cap and result_ty != "float16_t") or
                ("Float32" in cap and result_ty != "float32_t") or
                ("Float64" in cap and result_ty != "float64_t") or
                ("Int16" in cap and result_ty != "int16_t" and result_ty != "uint16_t") or
                ("Int64" in cap and result_ty != "int64_t" and result_ty != "uint64_t")): continue
            
            if "Vector" in cap:
                result_ty = "vector<" + result_ty + ", N> "
                final_templates.append("uint32_t N")
        
        op_ty = "T"
        if prefered_op_ty != None:
            op_ty = prefered_op_ty
        elif result_ty != "void":
            op_ty = result_ty

        args = []
        if "operands" in instruction:
            for operand in instruction["operands"]:
                operand_name = operand["name"].strip("'") if "name" in operand else None
                operand_name = operand_name[0].lower() + operand_name[1:] if (operand_name != None) else ""
                match operand["kind"]:
                    case "IdResult" | "IdResultType": continue
                    case "IdRef":
                        match operand["name"]:
                            case "'Pointer'":
                                if shape == Shape.PTR_TEMPLATE:
                                    args.append("P " + operand_name)
                                else:    
                                    if (not "typename T" in final_templates) and (result_ty == "T" or op_ty == "T"):
                                        final_templates = ["typename T"] + final_templates
                                    args.append("[[vk::ext_reference]] " + op_ty + " " + operand_name)
                            case "'Value'" | "'Object'" | "'Comparator'" | "'Base'" | "'Insert'":
                                if (not "typename T" in final_templates) and (result_ty == "T" or op_ty == "T"):
                                    final_templates = ["typename T"] + final_templates
                                args.append(op_ty + " " + operand_name)
                            case "'Offset'" | "'Count'" | "'Id'" | "'Index'" | "'Mask'" | "'Delta'":
                                args.append("uint32_t " + operand_name)
                            case "'Predicate'": args.append("bool " + operand_name)
                            case "'ClusterSize'":
                                if "quantifier" in operand and operand["quantifier"] == "?": continue # TODO: overload
                                else: return ignore(op_name) # TODO
                            case _: return ignore(op_name) # TODO
                    case "IdScope": args.append("uint32_t " + operand_name.lower() + "Scope")
                    case "IdMemorySemantics": args.append(" uint32_t " + operand_name)
                    case "GroupOperation": args.append("[[vk::ext_literal]] uint32_t " + operand_name)
                    case "MemoryAccess":
                        assert len(caps) <= 1
                        writeInst(writer, final_templates, cap, exts, op_name, final_fn_name, conds, result_ty, args + ["[[vk::ext_literal]] uint32_t memoryAccess"])
                        writeInst(writer, final_templates, cap, exts, op_name, final_fn_name, conds, result_ty, args + ["[[vk::ext_literal]] uint32_t memoryAccess, [[vk::ext_literal]] uint32_t memoryAccessParam"])
                    case _: return ignore(op_name) # TODO

        writeInst(writer, final_templates, cap, exts, op_name, final_fn_name, conds, result_ty, args)


def writeInst(writer: io.TextIOWrapper, templates, cap, exts, op_name, fn_name, conds, result_type, args):
    if len(templates) > 0:
        writer.write("template<" + ", ".join(templates) + ">\n")
    if cap != None:
        writer.write("[[vk::ext_capability(spv::Capability" + cap + ")]]\n")
    for ext in exts:
        writer.write("[[vk::ext_extension(\"" + ext + "\")]]\n")
    writer.write("[[vk::ext_instruction(spv::" + op_name + ")]]\n")
    if len(conds) > 0:
        writer.write("enable_if_t<" + " && ".join(conds) + ", " + result_type + ">")
    else:
        writer.write(result_type)
    writer.write(" " + fn_name + "(" + ", ".join(args) + ");\n\n")

def ignore(op_name):
    print("\033[94mIGNORED\033[0m: " + op_name)

if __name__ == "__main__":
    script_dir_path = os.path.abspath(os.path.dirname(__file__))

    parser = ArgumentParser(description="Generate HLSL from SPIR-V instructions")
    parser.add_argument("output", type=str, help="HLSL output file")
    parser.add_argument("--grammer", required=False, type=str, help="Input SPIR-V grammer JSON file", default=os.path.join(script_dir_path, "../../include/spirv/unified1/spirv.core.grammar.json"))
    args = parser.parse_args()

    gen(args.grammer, args.output)


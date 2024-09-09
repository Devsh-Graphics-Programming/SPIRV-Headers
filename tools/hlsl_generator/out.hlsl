// Copyright (C) 2023 - DevSH Graphics Programming Sp. z O.O.
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
template<class T>
NBL_CONSTEXPR_STATIC_INLINE bool is_pointer_v = is_spirv_type<T>::value;

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

// The holy operation that makes addrof possible
template<uint32_t StorageClass, typename T>
[[vk::ext_instruction(spv::OpCopyObject)]]
pointer_t<StorageClass, T> copyObject([[vk::ext_reference]] T value);

// TODO: Generate extended instructions
//! Std 450 Extended set instructions
template<typename SquareMatrix>
[[vk::ext_instruction(34 /* GLSLstd450MatrixInverse */, "GLSL.std.450")]]
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

//! Builtins
namespace builtin
{
[[vk::ext_builtin_output(spv::BuiltInPosition)]]
static float32_t4 Position;
[[vk::ext_builtin_input(spv::BuiltInHelperInvocation)]]
static const bool HelperInvocation;

[[vk::ext_builtin_input(spv::BuiltInNumWorkgroups)]]
static const uint32_t3 NumWorkgroups;

[[vk::ext_builtin_input(spv::BuiltInWorkgroupId)]]
static const uint32_t3 WorkgroupId;

[[vk::ext_builtin_input(spv::BuiltInLocalInvocationId)]]
static const uint32_t3 LocalInvocationId;

[[vk::ext_builtin_input(spv::BuiltInGlobalInvocationId)]]
static const uint32_t3 GlobalInvocationId;

[[vk::ext_builtin_input(spv::BuiltInLocalInvocationIndex)]]
static const uint32_t LocalInvocationIndex;

[[vk::ext_capability(spv::CapabilityGroupNonUniform)]]
[[vk::ext_builtin_input(spv::BuiltInSubgroupSize)]]
static const uint32_t SubgroupSize;

[[vk::ext_capability(spv::CapabilityGroupNonUniform)]]
[[vk::ext_builtin_input(spv::BuiltInNumSubgroups)]]
static const uint32_t NumSubgroups;

[[vk::ext_capability(spv::CapabilityGroupNonUniform)]]
[[vk::ext_builtin_input(spv::BuiltInSubgroupId)]]
static const uint32_t SubgroupId;

[[vk::ext_capability(spv::CapabilityGroupNonUniform)]]
[[vk::ext_builtin_input(spv::BuiltInSubgroupLocalInvocationId)]]
static const uint32_t SubgroupLocalInvocationId;

[[vk::ext_builtin_input(spv::BuiltInVertexIndex)]]
static const uint32_t VertexIndex;

[[vk::ext_builtin_input(spv::BuiltInInstanceIndex)]]
static const uint32_t InstanceIndex;

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_builtin_input(spv::BuiltInSubgroupEqMask)]]
static const uint32_t4 SubgroupEqMask;

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_builtin_input(spv::BuiltInSubgroupGeMask)]]
static const uint32_t4 SubgroupGeMask;

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_builtin_input(spv::BuiltInSubgroupGtMask)]]
static const uint32_t4 SubgroupGtMask;

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_builtin_input(spv::BuiltInSubgroupLeMask)]]
static const uint32_t4 SubgroupLeMask;

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_builtin_input(spv::BuiltInSubgroupLtMask)]]
static const uint32_t4 SubgroupLtMask;

}

//! Execution Modes
namespace execution_mode
{
	void invocations()
	{
		vk::ext_execution_mode(spv::ExecutionModeInvocations);
	}

	void spacingEqual()
	{
		vk::ext_execution_mode(spv::ExecutionModeSpacingEqual);
	}

	void spacingFractionalEven()
	{
		vk::ext_execution_mode(spv::ExecutionModeSpacingFractionalEven);
	}

	void spacingFractionalOdd()
	{
		vk::ext_execution_mode(spv::ExecutionModeSpacingFractionalOdd);
	}

	void vertexOrderCw()
	{
		vk::ext_execution_mode(spv::ExecutionModeVertexOrderCw);
	}

	void vertexOrderCcw()
	{
		vk::ext_execution_mode(spv::ExecutionModeVertexOrderCcw);
	}

	void pixelCenterInteger()
	{
		vk::ext_execution_mode(spv::ExecutionModePixelCenterInteger);
	}

	void originUpperLeft()
	{
		vk::ext_execution_mode(spv::ExecutionModeOriginUpperLeft);
	}

	void originLowerLeft()
	{
		vk::ext_execution_mode(spv::ExecutionModeOriginLowerLeft);
	}

	void earlyFragmentTests()
	{
		vk::ext_execution_mode(spv::ExecutionModeEarlyFragmentTests);
	}

	void pointMode()
	{
		vk::ext_execution_mode(spv::ExecutionModePointMode);
	}

	void xfb()
	{
		vk::ext_execution_mode(spv::ExecutionModeXfb);
	}

	void depthReplacing()
	{
		vk::ext_execution_mode(spv::ExecutionModeDepthReplacing);
	}

	void depthGreater()
	{
		vk::ext_execution_mode(spv::ExecutionModeDepthGreater);
	}

	void depthLess()
	{
		vk::ext_execution_mode(spv::ExecutionModeDepthLess);
	}

	void depthUnchanged()
	{
		vk::ext_execution_mode(spv::ExecutionModeDepthUnchanged);
	}

	void localSize()
	{
		vk::ext_execution_mode(spv::ExecutionModeLocalSize);
	}

	void localSizeHint()
	{
		vk::ext_execution_mode(spv::ExecutionModeLocalSizeHint);
	}

	void inputPoints()
	{
		vk::ext_execution_mode(spv::ExecutionModeInputPoints);
	}

	void inputLines()
	{
		vk::ext_execution_mode(spv::ExecutionModeInputLines);
	}

	void inputLinesAdjacency()
	{
		vk::ext_execution_mode(spv::ExecutionModeInputLinesAdjacency);
	}

	void triangles()
	{
		vk::ext_execution_mode(spv::ExecutionModeTriangles);
	}

	void inputTrianglesAdjacency()
	{
		vk::ext_execution_mode(spv::ExecutionModeInputTrianglesAdjacency);
	}

	void quads()
	{
		vk::ext_execution_mode(spv::ExecutionModeQuads);
	}

	void isolines()
	{
		vk::ext_execution_mode(spv::ExecutionModeIsolines);
	}

	void outputVertices()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputVertices);
	}

	void outputPoints()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputPoints);
	}

	void outputLineStrip()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputLineStrip);
	}

	void outputTriangleStrip()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputTriangleStrip);
	}

	void vecTypeHint()
	{
		vk::ext_execution_mode(spv::ExecutionModeVecTypeHint);
	}

	void contractionOff()
	{
		vk::ext_execution_mode(spv::ExecutionModeContractionOff);
	}

	void initializer()
	{
		vk::ext_execution_mode(spv::ExecutionModeInitializer);
	}

	void finalizer()
	{
		vk::ext_execution_mode(spv::ExecutionModeFinalizer);
	}

	void subgroupSize()
	{
		vk::ext_execution_mode(spv::ExecutionModeSubgroupSize);
	}

	void subgroupsPerWorkgroup()
	{
		vk::ext_execution_mode(spv::ExecutionModeSubgroupsPerWorkgroup);
	}

	void subgroupsPerWorkgroupId()
	{
		vk::ext_execution_mode(spv::ExecutionModeSubgroupsPerWorkgroupId);
	}

	void localSizeId()
	{
		vk::ext_execution_mode(spv::ExecutionModeLocalSizeId);
	}

	void localSizeHintId()
	{
		vk::ext_execution_mode(spv::ExecutionModeLocalSizeHintId);
	}

	void nonCoherentColorAttachmentReadEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeNonCoherentColorAttachmentReadEXT);
	}

	void nonCoherentDepthAttachmentReadEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeNonCoherentDepthAttachmentReadEXT);
	}

	void nonCoherentStencilAttachmentReadEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeNonCoherentStencilAttachmentReadEXT);
	}

	void subgroupUniformControlFlowKHR()
	{
		vk::ext_execution_mode(spv::ExecutionModeSubgroupUniformControlFlowKHR);
	}

	void postDepthCoverage()
	{
		vk::ext_execution_mode(spv::ExecutionModePostDepthCoverage);
	}

	void denormPreserve()
	{
		vk::ext_execution_mode(spv::ExecutionModeDenormPreserve);
	}

	void denormFlushToZero()
	{
		vk::ext_execution_mode(spv::ExecutionModeDenormFlushToZero);
	}

	void signedZeroInfNanPreserve()
	{
		vk::ext_execution_mode(spv::ExecutionModeSignedZeroInfNanPreserve);
	}

	void roundingModeRTE()
	{
		vk::ext_execution_mode(spv::ExecutionModeRoundingModeRTE);
	}

	void roundingModeRTZ()
	{
		vk::ext_execution_mode(spv::ExecutionModeRoundingModeRTZ);
	}

	void earlyAndLateFragmentTestsAMD()
	{
		vk::ext_execution_mode(spv::ExecutionModeEarlyAndLateFragmentTestsAMD);
	}

	void stencilRefReplacingEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeStencilRefReplacingEXT);
	}

	void coalescingAMDX()
	{
		vk::ext_execution_mode(spv::ExecutionModeCoalescingAMDX);
	}

	void maxNodeRecursionAMDX()
	{
		vk::ext_execution_mode(spv::ExecutionModeMaxNodeRecursionAMDX);
	}

	void staticNumWorkgroupsAMDX()
	{
		vk::ext_execution_mode(spv::ExecutionModeStaticNumWorkgroupsAMDX);
	}

	void shaderIndexAMDX()
	{
		vk::ext_execution_mode(spv::ExecutionModeShaderIndexAMDX);
	}

	void maxNumWorkgroupsAMDX()
	{
		vk::ext_execution_mode(spv::ExecutionModeMaxNumWorkgroupsAMDX);
	}

	void stencilRefUnchangedFrontAMD()
	{
		vk::ext_execution_mode(spv::ExecutionModeStencilRefUnchangedFrontAMD);
	}

	void stencilRefGreaterFrontAMD()
	{
		vk::ext_execution_mode(spv::ExecutionModeStencilRefGreaterFrontAMD);
	}

	void stencilRefLessFrontAMD()
	{
		vk::ext_execution_mode(spv::ExecutionModeStencilRefLessFrontAMD);
	}

	void stencilRefUnchangedBackAMD()
	{
		vk::ext_execution_mode(spv::ExecutionModeStencilRefUnchangedBackAMD);
	}

	void stencilRefGreaterBackAMD()
	{
		vk::ext_execution_mode(spv::ExecutionModeStencilRefGreaterBackAMD);
	}

	void stencilRefLessBackAMD()
	{
		vk::ext_execution_mode(spv::ExecutionModeStencilRefLessBackAMD);
	}

	void quadDerivativesKHR()
	{
		vk::ext_execution_mode(spv::ExecutionModeQuadDerivativesKHR);
	}

	void requireFullQuadsKHR()
	{
		vk::ext_execution_mode(spv::ExecutionModeRequireFullQuadsKHR);
	}

	void outputLinesEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputLinesEXT);
	}

	void outputLinesNV()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputLinesNV);
	}

	void outputPrimitivesEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputPrimitivesEXT);
	}

	void outputPrimitivesNV()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputPrimitivesNV);
	}

	void derivativeGroupQuadsNV()
	{
		vk::ext_execution_mode(spv::ExecutionModeDerivativeGroupQuadsNV);
	}

	void derivativeGroupLinearNV()
	{
		vk::ext_execution_mode(spv::ExecutionModeDerivativeGroupLinearNV);
	}

	void outputTrianglesEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputTrianglesEXT);
	}

	void outputTrianglesNV()
	{
		vk::ext_execution_mode(spv::ExecutionModeOutputTrianglesNV);
	}

	void pixelInterlockOrderedEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModePixelInterlockOrderedEXT);
	}

	void pixelInterlockUnorderedEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModePixelInterlockUnorderedEXT);
	}

	void sampleInterlockOrderedEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeSampleInterlockOrderedEXT);
	}

	void sampleInterlockUnorderedEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeSampleInterlockUnorderedEXT);
	}

	void shadingRateInterlockOrderedEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeShadingRateInterlockOrderedEXT);
	}

	void shadingRateInterlockUnorderedEXT()
	{
		vk::ext_execution_mode(spv::ExecutionModeShadingRateInterlockUnorderedEXT);
	}

	void maximallyReconvergesKHR()
	{
		vk::ext_execution_mode(spv::ExecutionModeMaximallyReconvergesKHR);
	}

	void fPFastMathDefault()
	{
		vk::ext_execution_mode(spv::ExecutionModeFPFastMathDefault);
	}
}

//! Group Operations
namespace group_operation
{
	static const uint32_t Reduce = 0;
	static const uint32_t InclusiveScan = 1;
	static const uint32_t ExclusiveScan = 2;
	static const uint32_t ClusteredReduce = 3;
	static const uint32_t PartitionedReduceNV = 6;
	static const uint32_t PartitionedInclusiveScanNV = 7;
	static const uint32_t PartitionedExclusiveScanNV = 8;
}

//! Instructions
template<typename T, typename P>
[[vk::ext_instruction(spv::OpLoad)]]
enable_if_t<is_spirv_type_v<P>, T> load(P pointer, [[vk::ext_literal]] uint32_t memoryAccess);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpLoad)]]
enable_if_t<is_spirv_type_v<P>, T> load(P pointer, [[vk::ext_literal]] uint32_t memoryAccess, [[vk::ext_literal]] uint32_t memoryAccessParam);

template<typename T, typename P, uint32_t alignment>
[[vk::ext_instruction(spv::OpLoad)]]
enable_if_t<is_spirv_type_v<P>, T> load(P pointer, [[vk::ext_literal]] uint32_t __aligned = /*Aligned*/0x00000002, [[vk::ext_literal]] uint32_t __alignment = alignment);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpLoad)]]
enable_if_t<is_spirv_type_v<P>, T> load(P pointer);

template<typename T, uint32_t alignment>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpLoad)]]
T load(pointer_t<spv::StorageClassPhysicalStorageBuffer, T> pointer, [[vk::ext_literal]] uint32_t __aligned = /*Aligned*/0x00000002, [[vk::ext_literal]] uint32_t __alignment = alignment);

template<typename T>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpLoad)]]
T load(pointer_t<spv::StorageClassPhysicalStorageBuffer, T> pointer);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpStore)]]
enable_if_t<is_spirv_type_v<P>, void> store(P pointer, T object, [[vk::ext_literal]] uint32_t memoryAccess);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpStore)]]
enable_if_t<is_spirv_type_v<P>, void> store(P pointer, T object, [[vk::ext_literal]] uint32_t memoryAccess, [[vk::ext_literal]] uint32_t memoryAccessParam);

template<typename T, typename P, uint32_t alignment>
[[vk::ext_instruction(spv::OpStore)]]
enable_if_t<is_spirv_type_v<P>, void> store(P pointer, T object, [[vk::ext_literal]] uint32_t __aligned = /*Aligned*/0x00000002, [[vk::ext_literal]] uint32_t __alignment = alignment);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpStore)]]
enable_if_t<is_spirv_type_v<P>, void> store(P pointer, T object);

template<typename T, uint32_t alignment>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpStore)]]
void store(pointer_t<spv::StorageClassPhysicalStorageBuffer, T> pointer, T object, [[vk::ext_literal]] uint32_t __aligned = /*Aligned*/0x00000002, [[vk::ext_literal]] uint32_t __alignment = alignment);

template<typename T>
[[vk::ext_capability(spv::CapabilityPhysicalStorageBufferAddresses)]]
[[vk::ext_instruction(spv::OpStore)]]
void store(pointer_t<spv::StorageClassPhysicalStorageBuffer, T> pointer, T object);

template<typename T>
[[vk::ext_capability(spv::CapabilityBitInstructions)]]
[[vk::ext_instruction(spv::OpBitFieldInsert)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> bitFieldInsert(T base, T insert, uint32_t offset, uint32_t count);

template<typename T>
[[vk::ext_capability(spv::CapabilityBitInstructions)]]
[[vk::ext_instruction(spv::OpBitFieldSExtract)]]
enable_if_t<is_signed_v<T>, T> bitFieldSExtract(T base, uint32_t offset, uint32_t count);

template<typename T>
[[vk::ext_capability(spv::CapabilityBitInstructions)]]
[[vk::ext_instruction(spv::OpBitFieldUExtract)]]
enable_if_t<is_unsigned_v<T>, T> bitFieldUExtract(T base, uint32_t offset, uint32_t count);

template<typename T>
[[vk::ext_capability(spv::CapabilityBitInstructions)]]
[[vk::ext_instruction(spv::OpBitReverse)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> bitReverse(T base);

template<typename T>
[[vk::ext_instruction(spv::OpBitCount)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> bitCount(T base);

[[vk::ext_instruction(spv::OpControlBarrier)]]
void controlBarrier(uint32_t executionScope, uint32_t memoryScope,  uint32_t semantics);

[[vk::ext_instruction(spv::OpMemoryBarrier)]]
void memoryBarrier(uint32_t memoryScope,  uint32_t semantics);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicLoad)]]
T atomicLoad([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicLoad)]]
enable_if_t<is_spirv_type_v<P>, T> atomicLoad(P pointer, uint32_t memoryScope,  uint32_t semantics);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicStore)]]
void atomicStore([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicStore)]]
enable_if_t<is_spirv_type_v<P>, void> atomicStore(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicExchange)]]
T atomicExchange([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicExchange)]]
enable_if_t<is_spirv_type_v<P>, T> atomicExchange(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicCompareExchange)]]
T atomicCompareExchange([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t equal,  uint32_t unequal, T value, T comparator);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicCompareExchange)]]
enable_if_t<is_spirv_type_v<P>, T> atomicCompareExchange(P pointer, uint32_t memoryScope,  uint32_t equal,  uint32_t unequal, T value, T comparator);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicIIncrement)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> atomicIIncrement([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicIIncrement)]]
enable_if_t<is_spirv_type_v<P> && (is_signed_v<T> || is_unsigned_v<T>), T> atomicIIncrement(P pointer, uint32_t memoryScope,  uint32_t semantics);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicIDecrement)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> atomicIDecrement([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicIDecrement)]]
enable_if_t<is_spirv_type_v<P> && (is_signed_v<T> || is_unsigned_v<T>), T> atomicIDecrement(P pointer, uint32_t memoryScope,  uint32_t semantics);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicIAdd)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> atomicIAdd([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicIAdd)]]
enable_if_t<is_spirv_type_v<P> && (is_signed_v<T> || is_unsigned_v<T>), T> atomicIAdd(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicISub)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> atomicISub([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicISub)]]
enable_if_t<is_spirv_type_v<P> && (is_signed_v<T> || is_unsigned_v<T>), T> atomicISub(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicSMin)]]
enable_if_t<is_signed_v<T>, T> atomicSMin([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicSMin)]]
enable_if_t<is_spirv_type_v<P> && is_signed_v<T>, T> atomicSMin(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicUMin)]]
enable_if_t<is_unsigned_v<T>, T> atomicUMin([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicUMin)]]
enable_if_t<is_spirv_type_v<P> && is_unsigned_v<T>, T> atomicUMin(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicSMax)]]
enable_if_t<is_signed_v<T>, T> atomicSMax([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicSMax)]]
enable_if_t<is_spirv_type_v<P> && is_signed_v<T>, T> atomicSMax(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicUMax)]]
enable_if_t<is_unsigned_v<T>, T> atomicUMax([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicUMax)]]
enable_if_t<is_spirv_type_v<P> && is_unsigned_v<T>, T> atomicUMax(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicAnd)]]
T atomicAnd([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicAnd)]]
enable_if_t<is_spirv_type_v<P>, T> atomicAnd(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicOr)]]
T atomicOr([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicOr)]]
enable_if_t<is_spirv_type_v<P>, T> atomicOr(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T>
[[vk::ext_instruction(spv::OpAtomicXor)]]
T atomicXor([[vk::ext_reference]] T pointer, uint32_t memoryScope,  uint32_t semantics, T value);

template<typename T, typename P>
[[vk::ext_instruction(spv::OpAtomicXor)]]
enable_if_t<is_spirv_type_v<P>, T> atomicXor(P pointer, uint32_t memoryScope,  uint32_t semantics, T value);

[[vk::ext_capability(spv::CapabilityGroupNonUniform)]]
[[vk::ext_instruction(spv::OpGroupNonUniformElect)]]
bool groupNonUniformElect(uint32_t executionScope);

[[vk::ext_capability(spv::CapabilityGroupNonUniformVote)]]
[[vk::ext_instruction(spv::OpGroupNonUniformAll)]]
bool groupNonUniformAll(uint32_t executionScope, bool predicate);

[[vk::ext_capability(spv::CapabilityGroupNonUniformVote)]]
[[vk::ext_instruction(spv::OpGroupNonUniformAny)]]
bool groupNonUniformAny(uint32_t executionScope, bool predicate);

[[vk::ext_capability(spv::CapabilityGroupNonUniformVote)]]
[[vk::ext_instruction(spv::OpGroupNonUniformAllEqual)]]
bool groupNonUniformAllEqual(uint32_t executionScope, bool value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBroadcast)]]
T groupNonUniformBroadcast(uint32_t executionScope, T value, uint32_t id);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBroadcastFirst)]]
T groupNonUniformBroadcastFirst(uint32_t executionScope, T value);

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBallot)]]
uint32_t4 groupNonUniformBallot(uint32_t executionScope, bool predicate);

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_instruction(spv::OpGroupNonUniformInverseBallot)]]
bool groupNonUniformInverseBallot(uint32_t executionScope, uint32_t4 value);

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBallotBitExtract)]]
bool groupNonUniformBallotBitExtract(uint32_t executionScope, uint32_t4 value, uint32_t index);

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBallotBitCount)]]
uint32_t groupNonUniformBallotBitCount(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, uint32_t4 value);

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBallotFindLSB)]]
uint32_t groupNonUniformBallotFindLSB(uint32_t executionScope, uint32_t4 value);

[[vk::ext_capability(spv::CapabilityGroupNonUniformBallot)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBallotFindMSB)]]
uint32_t groupNonUniformBallotFindMSB(uint32_t executionScope, uint32_t4 value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformShuffle)]]
[[vk::ext_instruction(spv::OpGroupNonUniformShuffle)]]
T groupNonUniformShuffle(uint32_t executionScope, T value, uint32_t id);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformShuffle)]]
[[vk::ext_instruction(spv::OpGroupNonUniformShuffleXor)]]
T groupNonUniformShuffleXor(uint32_t executionScope, T value, uint32_t mask);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformShuffleRelative)]]
[[vk::ext_instruction(spv::OpGroupNonUniformShuffleUp)]]
T groupNonUniformShuffleUp(uint32_t executionScope, T value, uint32_t delta);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformShuffleRelative)]]
[[vk::ext_instruction(spv::OpGroupNonUniformShuffleDown)]]
T groupNonUniformShuffleDown(uint32_t executionScope, T value, uint32_t delta);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformIAdd)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> groupNonUniformIAdd_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformIAdd)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> groupNonUniformIAdd_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformIAdd)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> groupNonUniformIAdd_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFAdd)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFAdd_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFAdd)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFAdd_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFAdd)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFAdd_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformIMul)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> groupNonUniformIMul_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformIMul)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> groupNonUniformIMul_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformIMul)]]
enable_if_t<(is_signed_v<T> || is_unsigned_v<T>), T> groupNonUniformIMul_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFMul)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFMul_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFMul)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFMul_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFMul)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFMul_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformSMin)]]
enable_if_t<is_signed_v<T>, T> groupNonUniformSMin_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformSMin)]]
enable_if_t<is_signed_v<T>, T> groupNonUniformSMin_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformSMin)]]
enable_if_t<is_signed_v<T>, T> groupNonUniformSMin_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformUMin)]]
enable_if_t<is_unsigned_v<T>, T> groupNonUniformUMin_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformUMin)]]
enable_if_t<is_unsigned_v<T>, T> groupNonUniformUMin_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformUMin)]]
enable_if_t<is_unsigned_v<T>, T> groupNonUniformUMin_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFMin)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFMin_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFMin)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFMin_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFMin)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFMin_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformSMax)]]
enable_if_t<is_signed_v<T>, T> groupNonUniformSMax_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformSMax)]]
enable_if_t<is_signed_v<T>, T> groupNonUniformSMax_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformSMax)]]
enable_if_t<is_signed_v<T>, T> groupNonUniformSMax_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformUMax)]]
enable_if_t<is_unsigned_v<T>, T> groupNonUniformUMax_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformUMax)]]
enable_if_t<is_unsigned_v<T>, T> groupNonUniformUMax_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformUMax)]]
enable_if_t<is_unsigned_v<T>, T> groupNonUniformUMax_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFMax)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFMax_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFMax)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFMax_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformFMax)]]
enable_if_t<is_floating_point<T>, T> groupNonUniformFMax_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBitwiseAnd)]]
T groupNonUniformBitwiseAnd_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBitwiseAnd)]]
T groupNonUniformBitwiseAnd_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBitwiseAnd)]]
T groupNonUniformBitwiseAnd_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBitwiseOr)]]
T groupNonUniformBitwiseOr_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBitwiseOr)]]
T groupNonUniformBitwiseOr_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBitwiseOr)]]
T groupNonUniformBitwiseOr_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBitwiseXor)]]
T groupNonUniformBitwiseXor_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBitwiseXor)]]
T groupNonUniformBitwiseXor_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformBitwiseXor)]]
T groupNonUniformBitwiseXor_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformLogicalAnd)]]
T groupNonUniformLogicalAnd_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformLogicalAnd)]]
T groupNonUniformLogicalAnd_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformLogicalAnd)]]
T groupNonUniformLogicalAnd_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformLogicalOr)]]
T groupNonUniformLogicalOr_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformLogicalOr)]]
T groupNonUniformLogicalOr_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformLogicalOr)]]
T groupNonUniformLogicalOr_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformArithmetic)]]
[[vk::ext_instruction(spv::OpGroupNonUniformLogicalXor)]]
T groupNonUniformLogicalXor_GroupNonUniformArithmetic(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformClustered)]]
[[vk::ext_instruction(spv::OpGroupNonUniformLogicalXor)]]
T groupNonUniformLogicalXor_GroupNonUniformClustered(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_instruction(spv::OpGroupNonUniformLogicalXor)]]
T groupNonUniformLogicalXor_GroupNonUniformPartitionedNV(uint32_t executionScope, [[vk::ext_literal]] uint32_t operation, T value);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformQuad)]]
[[vk::ext_instruction(spv::OpGroupNonUniformQuadBroadcast)]]
T groupNonUniformQuadBroadcast(uint32_t executionScope, T value, uint32_t index);

template<typename T>
[[vk::ext_capability(spv::CapabilityQuadControlKHR)]]
[[vk::ext_instruction(spv::OpGroupNonUniformQuadAllKHR)]]
T groupNonUniformQuadAllKHR(bool predicate);

template<typename T>
[[vk::ext_capability(spv::CapabilityQuadControlKHR)]]
[[vk::ext_instruction(spv::OpGroupNonUniformQuadAnyKHR)]]
T groupNonUniformQuadAnyKHR(bool predicate);

template<typename T>
[[vk::ext_capability(spv::CapabilityGroupNonUniformPartitionedNV)]]
[[vk::ext_extension("SPV_NV_shader_subgroup_partitioned")]]
[[vk::ext_instruction(spv::OpGroupNonUniformPartitionNV)]]
T groupNonUniformPartitionNV(T value);

[[vk::ext_capability(spv::CapabilityFragmentShaderSampleInterlockEXT)]]
[[vk::ext_extension("SPV_EXT_fragment_shader_interlock")]]
[[vk::ext_instruction(spv::OpBeginInvocationInterlockEXT)]]
void beginInvocationInterlockEXT_FragmentShaderSampleInterlockEXT();

[[vk::ext_capability(spv::CapabilityFragmentShaderPixelInterlockEXT)]]
[[vk::ext_extension("SPV_EXT_fragment_shader_interlock")]]
[[vk::ext_instruction(spv::OpBeginInvocationInterlockEXT)]]
void beginInvocationInterlockEXT_FragmentShaderPixelInterlockEXT();

[[vk::ext_capability(spv::CapabilityFragmentShaderShadingRateInterlockEXT)]]
[[vk::ext_extension("SPV_EXT_fragment_shader_interlock")]]
[[vk::ext_instruction(spv::OpBeginInvocationInterlockEXT)]]
void beginInvocationInterlockEXT_FragmentShaderShadingRateInterlockEXT();

[[vk::ext_capability(spv::CapabilityFragmentShaderSampleInterlockEXT)]]
[[vk::ext_extension("SPV_EXT_fragment_shader_interlock")]]
[[vk::ext_instruction(spv::OpEndInvocationInterlockEXT)]]
void endInvocationInterlockEXT_FragmentShaderSampleInterlockEXT();

[[vk::ext_capability(spv::CapabilityFragmentShaderPixelInterlockEXT)]]
[[vk::ext_extension("SPV_EXT_fragment_shader_interlock")]]
[[vk::ext_instruction(spv::OpEndInvocationInterlockEXT)]]
void endInvocationInterlockEXT_FragmentShaderPixelInterlockEXT();

[[vk::ext_capability(spv::CapabilityFragmentShaderShadingRateInterlockEXT)]]
[[vk::ext_extension("SPV_EXT_fragment_shader_interlock")]]
[[vk::ext_instruction(spv::OpEndInvocationInterlockEXT)]]
void endInvocationInterlockEXT_FragmentShaderShadingRateInterlockEXT();

}

#endif
}
}

#endif

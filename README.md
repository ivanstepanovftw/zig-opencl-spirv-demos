Zig miscompilation issue https://github.com/ziglang/zig/issues/24281 reproducer.

Reproduce:

```shell
RUSTICL_ENABLE=lp zig build run-miscomp -- --platform rusticl
```

Expected output: 42, got: 0. 

Note: hangs when PoCL is used.

---

[`src/kernels/miscomp.zig`](/src/kernels/miscomp.zig) disassembly:

```shell
zig build dis-miscomp-kernel
```

```spirv
; SPIR-V
; Version: 1.0
; Generator: Khronos; 41
; Bound: 329
; Schema: 0
               OpCapability Kernel
               OpCapability Addresses
               OpCapability Int64
               OpCapability Float16
               OpCapability Float64
               OpCapability GenericPointer
               OpCapability Vector16
               OpCapability Int8
               OpCapability Int16
               OpMemoryModel Physical64 OpenCL
               OpEntryPoint Kernel %293 "miscomp" %gl_WorkGroupID %gl_WorkGroupSize %gl_LocalInvocationID
         %14 = OpString "miscomp.zig"
               OpSourceExtension "zig_errors:"
               OpSource Zig 0
               OpName %void "void"
               OpName %u8 "u8"
               OpName %u64 "u64"
               OpName %u32 "u32"
               OpName %struct___u32__u1__ "struct { u32, u1 }"
               OpName %gid "gid"
               OpName %struct___i8__u1__ "struct { i8, u1 }"
               OpName %miscomp_miscomp "miscomp.miscomp"
               OpDecorate %gl_WorkGroupID BuiltIn WorkgroupId
               OpDecorate %gl_WorkGroupSize BuiltIn WorkgroupSize
               OpDecorate %gl_LocalInvocationID BuiltIn LocalInvocationId
       %void = OpTypeVoid
         %u8 = OpTypeInt 8 0
%_ptr_CrossWorkgroup_u8 = OpTypePointer CrossWorkgroup %u8
        %u64 = OpTypeInt 64 0
%_ptr_Function__ptr_CrossWorkgroup_u8 = OpTypePointer Function %_ptr_CrossWorkgroup_u8
%_ptr_Generic__ptr_CrossWorkgroup_u8 = OpTypePointer Generic %_ptr_CrossWorkgroup_u8
      %v3u64 = OpTypeVector %u64 3
%_ptr_Input_v3u64 = OpTypePointer Input %v3u64
%gl_WorkGroupID = OpVariable %_ptr_Input_v3u64 Input
        %u32 = OpTypeInt 32 0
%gl_WorkGroupSize = OpVariable %_ptr_Input_v3u64 Input
     %u64_32 = OpConstant %u64 32
      %u64_0 = OpConstant %u64 0
       %bool = OpTypeBool
       %u8_0 = OpConstant %u8 0
       %u8_1 = OpConstant %u8 1
%struct___u32__u1__ = OpTypeStruct %u32 %u8
%gl_LocalInvocationID = OpVariable %_ptr_Input_v3u64 Input
    %u64_127 = OpConstant %u64 127
%struct___i8__u1__ = OpTypeStruct %u8 %u8
        %294 = OpTypeFunction %void %_ptr_CrossWorkgroup_u8 %u64
%miscomp_miscomp = OpFunction %void None %294
          %7 = OpFunctionParameter %_ptr_CrossWorkgroup_u8
          %8 = OpFunctionParameter %u64
          %9 = OpLabel
         %11 = OpVariable %_ptr_Function__ptr_CrossWorkgroup_u8 Function
         %13 = OpPtrCastToGeneric %_ptr_Generic__ptr_CrossWorkgroup_u8 %11
               OpStore %13 %7 None
               OpLine %14 3 5
         %18 = OpLoad %v3u64 %gl_WorkGroupID Aligned 32
         %19 = OpCompositeExtract %u64 %18 0
         %21 = OpUConvert %u32 %19
         %23 = OpLoad %v3u64 %gl_WorkGroupSize Aligned 32
         %24 = OpCompositeExtract %u64 %23 0
         %25 = OpUConvert %u32 %24
               OpLine %14 3 33
         %26 = OpUConvert %u64 %21
         %27 = OpUConvert %u64 %25
         %28 = OpIMul %u64 %26 %27
         %29 = OpUConvert %u32 %28
         %31 = OpShiftRightLogical %u64 %28 %u64_32
         %33 = OpINotEqual %bool %u64_0 %31
         %37 = OpSelect %u8 %33 %u8_1 %u8_0
         %39 = OpCompositeConstruct %struct___u32__u1__ %29 %37
         %40 = OpCompositeExtract %u8 %39 1
         %42 = OpIEqual %bool %40 %u8_1
               OpBranchConditional %42 %43 %44
         %43 = OpLabel
               OpUnreachable
         %44 = OpLabel
         %45 = OpCompositeExtract %u32 %39 0
               OpBranch %46
         %46 = OpLabel
         %47 = OpPhi %u32 %45 %44
         %49 = OpLoad %v3u64 %gl_LocalInvocationID Aligned 32
         %50 = OpCompositeExtract %u64 %49 0
         %51 = OpUConvert %u32 %50
               OpLine %14 3 53
         %52 = OpIAdd %u32 %47 %51
         %53 = OpULessThan %bool %52 %47
         %56 = OpSelect %u8 %53 %u8_1 %u8_0
         %57 = OpCompositeConstruct %struct___u32__u1__ %52 %56
         %58 = OpCompositeExtract %u8 %57 1
         %59 = OpIEqual %bool %58 %u8_1
               OpBranchConditional %59 %60 %61
         %60 = OpLabel
               OpUnreachable
         %61 = OpLabel
         %62 = OpCompositeExtract %u32 %57 0
               OpBranch %63
         %63 = OpLabel
        %gid = OpPhi %u32 %62 %61
               OpLine %14 5 6
         %65 = OpUConvert %u64 %gid
         %66 = OpLoad %_ptr_CrossWorkgroup_u8 %13 Aligned 8
         %67 = OpInBoundsPtrAccessChain %_ptr_CrossWorkgroup_u8 %66 %65
               OpLine %14 5 22
         %69 = OpUGreaterThan %bool %8 %u64_127
               OpBranchConditional %69 %70 %71
         %70 = OpLabel
               OpUnreachable
         %71 = OpLabel
         %72 = OpSConvert %u8 %8
               OpBranch %73
         %73 = OpLabel
         %74 = OpPhi %u8 %72 %71
               OpLine %14 5 35
         %76 = OpISub %u8 %74 %u8_0
         %78 = OpSLessThan %bool %u8_0 %u8_0
         %79 = OpSGreaterThan %bool %74 %76
         %80 = OpLogicalEqual %bool %78 %79
         %83 = OpSelect %u8 %80 %u8_1 %u8_0
         %85 = OpCompositeConstruct %struct___i8__u1__ %76 %83
         %86 = OpCompositeExtract %u8 %85 1
         %87 = OpIEqual %bool %86 %u8_1
               OpBranchConditional %87 %88 %89
         %88 = OpLabel
               OpUnreachable
         %89 = OpLabel
         %90 = OpCompositeExtract %u8 %85 0
               OpBranch %91
         %91 = OpLabel
         %92 = OpPhi %u8 %90 %89
               OpStore %67 %92 None
               OpReturn
               OpFunctionEnd
        %293 = OpFunction %void None %294
        %325 = OpFunctionParameter %_ptr_CrossWorkgroup_u8
        %326 = OpFunctionParameter %u64
        %327 = OpLabel
        %328 = OpFunctionCall %void %miscomp_miscomp %325 %326
               OpReturn
               OpFunctionEnd
```

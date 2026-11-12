#pragma once

#include <cstdint>


namespace UEOffsets
{

namespace Config
{
    constexpr bool isUsingCasePreservingName = false;
    constexpr bool IsUsingFNamePool = true;
    constexpr bool isUsingOutlineNumberName = false;
}

namespace FName
{
    constexpr uintptr_t ComparisonIndex = 0x0;
    constexpr uintptr_t Number = 0x4;
    constexpr uintptr_t DisplayIndex = 0x0;
    constexpr uintptr_t Size = 0x8;
}

namespace FNameEntry
{
    constexpr uintptr_t Index = 0x0;
    constexpr uintptr_t Name = 0x0;
}

namespace FNamePool
{
    constexpr int32_t Stride = 2;
    constexpr int32_t BlocksBit = 16;
    constexpr uintptr_t BlocksOff = 0x48;
}

namespace FNamePoolEntry
{
    constexpr uintptr_t Header = 0x0;
}

namespace FUObjectArray
{
    constexpr uintptr_t ObjObjects = 0x10;
}

namespace TUObjectArray
{
    constexpr uintptr_t Objects = 0x0;
    constexpr uintptr_t NumElements = 0x14;
    constexpr uintptr_t NumElementsPerChunk = 0x10000;
}

namespace FUObjectItem
{
    constexpr uintptr_t Object = 0x0;
    constexpr uintptr_t Size = 0x18;
}

namespace UObject
{
    constexpr uintptr_t ObjectFlags = 0x8;
    constexpr uintptr_t InternalIndex = 0xc;
    constexpr uintptr_t ClassPrivate = 0x10;
    constexpr uintptr_t NamePrivate = 0x18;
    constexpr uintptr_t OuterPrivate = 0x20;
}

namespace UField
{
    constexpr uintptr_t Next = 0x28;
}

namespace UEnum
{
    constexpr uintptr_t Names = 0x40;
}

namespace UStruct
{
    constexpr uintptr_t SuperStruct = 0x40;
    constexpr uintptr_t Children = 0x48;
    constexpr uintptr_t ChildProperties = 0x50;
    constexpr uintptr_t PropertiesSize = 0x58;
}

namespace UFunction
{
    constexpr uintptr_t EFunctionFlags = 0xb0;
    constexpr uintptr_t NumParams = 0xb4;
    constexpr uintptr_t ParamSize = 0xb6;
    constexpr uintptr_t Func = 0xd8;
}

namespace UProperty
{
    constexpr uintptr_t ArrayDim = 0x0;
    constexpr uintptr_t ElementSize = 0x0;
    constexpr uintptr_t PropertyFlags = 0x0;
    constexpr uintptr_t Offset_Internal = 0x0;
    constexpr uintptr_t Size = 0x0;
}

namespace FField
{
    constexpr uintptr_t ClassPrivate = 0x8;
    constexpr uintptr_t Next = 0x20;
    constexpr uintptr_t NamePrivate = 0x28;
    constexpr uintptr_t FlagsPrivate = 0x30;
}

namespace FProperty
{
    constexpr uintptr_t ArrayDim = 0x34;
    constexpr uintptr_t ElementSize = 0x38;
    constexpr uintptr_t PropertyFlags = 0x40;
    constexpr uintptr_t Offset_Internal = 0x4c;
    constexpr uintptr_t Size = 0x78;
}


}




namespace UEPointers
{
    constexpr uintptr_t Names = 0x10e23388;
    constexpr uintptr_t UObjectArray = 0x10e43320;
    constexpr uintptr_t ObjObjects = 0x10e43330;
    constexpr uintptr_t Engine = 0x1108dda0;
    constexpr uintptr_t World = 0x1108c6f0;
    constexpr uintptr_t GApp_Offset = 0x107f10f0;
}
#define Arena Breakout Last version 1.0.516.516 
Dumped By @ByDwoz
Channel @ShellSocu
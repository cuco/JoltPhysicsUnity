# Jolt.Native

This folder contains the dotnet solution used to build the native plugins and bindings used in the
package. `jolt` and `joltc` are built with the Vezel Zig Toolset from Nuget. To build from scratch,
first [install ClangSharpPInvokeGenerator as a dotnet tool](https://github.com/dotnet/ClangSharp):

```pwsh
dotnet tool install --global ClangSharpPInvokeGenerator
```

then build the project:

```pwsh
dotnet build -c Debug
```

or

```pwsh
dotnet build -c Release
```

### Android (IL2CPP)

Android `.so` files are cross-compiled with Zig for `arm64-v8a`, `armeabi-v7a`, `x86_64`, and `x86`. On Windows with Zig 0.11, **arm64-v8a** and **x86_64** build reliably; **armeabi-v7a** and **x86** may fail (32-bit PIC / compiler-rt); `dotnet build` continues for those ABIs via `ContinueOnError`. Set `ANDROID_NDK_HOME` to the Unity Editor NDK (same version as your Android build), for example:

`D:\Program Files\Unity\Hub\Editor\2022.3.62f3c1\Editor\Data\PlaybackEngines\AndroidPlayer\NDK`

On Windows, if Zig fails to find Bionic headers, create a junction without spaces and point `ANDROID_NDK_HOME` at it:

```pwsh
mklink /J D:\AndroidNDK "D:\Program Files\Unity\Hub\Editor\2022.3.62f3c1\Editor\Data\PlaybackEngines\AndroidPlayer\NDK"
$env:ANDROID_NDK_HOME = "D:\AndroidNDK"
$env:ANDROID_API_LEVEL = "21"
dotnet build -c Release
```

Outputs land in `Jolt.Native/Release/android-*/libjoltc.so`. On device, Unity loads them via PluginImporter; `NativeLibrary` does not `dlopen` on `UNITY_ANDROID`.

Building the native project will automatically export new C# bindings into `Jolt/Bindings`. To rebuild just the
bindings (after changing `clangsharp.rsp` for example), use:

```pwsh
dotnet build -target:"Generate Jolt Bindings"
```

### Include Files

`build.zig` must be kept up to date with the list of cpp files to include. After updating the `lib/jolt` submodule, run:

```pwsh
.\update-build-zig-sources.ps1
```

Use `-CheckOnly` in CI to fail when the list is out of date. To inspect files manually:

```pwsh
Get-ChildItem -Path lib/jolt/Jolt -Recurse -Filter "*.cpp" | Resolve-Path -Relative -RelativeBasePath lib/jolt
```

### Object layer width (32-bit)

Jolt defaults to 16-bit `ObjectLayer` in `ObjectLayer.h`. This package builds with **`-DJPH_OBJECT_LAYER_BITS=32`** in `build.zig` so mask/table semantics match a full **32-bit** layer type; `joltc.h` uses `uint32_t JPH_ObjectLayer`. The managed `Jolt.ObjectLayer` uses `uint` and `ObjectLayerBits = 32`. If you change the define, rebuild native code and ClangSharp bindings, and align `ObjectLayer.cs` / `joltc.h`.
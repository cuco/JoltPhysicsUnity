const std = @import("std");

const Build = std.build;
const builtin = @import("builtin");

const Options = struct {
    enable_asserts: bool = false,
    enable_debug_renderer: bool = false,
    enable_cross_platform_determinism: bool = true,
    use_double_precision: bool = false,
};

/// Matches Jolt Build/CMakeLists.txt + Jolt.cmake when CROSS_PLATFORM_DETERMINISTIC is on.
/// See Docs/Architecture.md "Cross platform determinism".
fn deterministicFpFlags(target: std.Target) []const []const u8 {
    // Zig always drives clang for C++; use clang flags (not MSVC /fp:...) on every OS.
    const is_x86 = target.cpu.arch == .x86 or target.cpu.arch == .x86_64;
    if (is_x86) {
        return &.{ "-ffp-model=precise", "-ffp-contract=off", "-mfpmath=sse" };
    }
    return &.{ "-ffp-model=precise", "-ffp-contract=off" };
}

fn androidTriple(cpu_arch: std.Target.Cpu.Arch) []const u8 {
    return switch (cpu_arch) {
        .aarch64 => "aarch64-linux-android",
        .arm, .thumb => "arm-linux-androideabi",
        .x86_64 => "x86_64-linux-android",
        .x86 => "i686-linux-android",
        else => @panic("unsupported Android CPU architecture"),
    };
}

fn ndkHostPrebuilt() []const u8 {
    return switch (builtin.os.tag) {
        .windows => "windows-x86_64",
        .linux => "linux-x86_64",
        .macos => if (builtin.cpu.arch == .aarch64) "darwin-arm64" else "darwin-x86_64",
        else => @panic("unsupported host OS for Android NDK cross-compile"),
    };
}

fn configureAndroidNdk(b: *Build, lib: *Build.Step.Compile, target: std.Target) void {
    const ndk = std.process.getEnvVarOwned(b.allocator, "ANDROID_NDK_HOME") catch
        @panic("ANDROID_NDK_HOME must be set when cross-compiling for Android");
    defer b.allocator.free(ndk);

    const sysroot = b.fmt("{s}/toolchains/llvm/prebuilt/{s}/sysroot", .{ ndk, ndkHostPrebuilt() });
    const triple = androidTriple(target.cpu.arch);

    const api_level = std.process.getEnvVarOwned(b.allocator, "ANDROID_API_LEVEL") catch null;
    defer if (api_level) |level| b.allocator.free(level);
    const api = api_level orelse "21";

    const libc_txt = b.fmt(
        \\include_dir={s}/usr/include
        \\sys_include_dir={s}/usr/include/{s}
        \\crt_dir={s}/usr/lib/{s}/{s}
        \\msvc_lib_dir=
        \\kernel32_lib_dir=
        \\gcc_dir=
        \\
    ,
        .{ sysroot, sysroot, triple, sysroot, triple, api });

    const wf = b.addWriteFiles();
    const libc_file = wf.add(b.fmt("libc-{s}.txt", .{triple}), libc_txt);
    lib.step.dependOn(&wf.step);
    lib.setLibCFile(libc_file);
    lib.linkLibC();

    lib.addLibraryPath(.{ .path = b.fmt("{s}/usr/lib/{s}", .{ sysroot, triple }) });
    lib.addLibraryPath(.{ .path = b.fmt("{s}/usr/lib/{s}/{s}", .{ sysroot, triple, api }) });
}

fn buildCompileFlags(allocator: std.mem.Allocator, options: Options, target: std.Target, optimize: std.builtin.OptimizeMode, is_android: bool) ![]const []const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    errdefer list.deinit();

    try list.appendSlice(&.{
        "-g",
        "-std=c++17",
        "-fdeclspec",
        "-DJPH_SHARED_LIBRARY_BUILD",
        "-DJPH_OBJECT_LAYER_BITS=32",
    });

    if (options.use_double_precision) {
        try list.append("-DJPH_DOUBLE_PRECISION");
    }
    if (options.enable_asserts or optimize == .Debug) {
        try list.append("-DJPH_ENABLE_ASSERTS");
    }
    if (options.enable_debug_renderer) {
        try list.append("-DJPH_DEBUG_RENDERER");
    }
    if (options.enable_cross_platform_determinism) {
        try list.append("-DJPH_CROSS_PLATFORM_DETERMINISTIC");
        try list.appendSlice(deterministicFpFlags(target));
    }
    if (is_android) {
        try list.appendSlice(&.{
            "-D__ANDROID_API__=21",
            "-fPIC",
        });
    }

    return try list.toOwnedSlice();
}

pub fn compile(options: Options, b: *Build, lib: *Build.Step.Compile) void {
    const target = lib.target.toTarget();
    const is_android = target.os.tag == .linux and target.abi == .android;

    lib.strip = lib.optimize != .Debug;

    if (is_android) {
        lib.force_pic = true;
        configureAndroidNdk(b, lib, target);
        // Android 15+ / Google Play: 64-bit .so must be built for 16 KB page size (Unity warns if not aligned).
        if (lib.isDynamicLibrary()) {
            lib.link_z_max_page_size = 16384;
            lib.link_z_common_page_size = 16384;
        }
        lib.linkLibCpp();
    } else {
        lib.linkLibC();
        lib.linkLibCpp();
    }

    const flags = buildCompileFlags(b.allocator, options, target, lib.optimize, is_android) catch @panic("OOM");
    defer b.allocator.free(flags);

    // add joltc sources

    const joltc_dir = "lib/joltc/";

    lib.addIncludePath(.{
        .path = joltc_dir
    });

    lib.addCSourceFiles(&.{
        joltc_dir ++ "joltc.cpp",
        joltc_dir ++ "joltc_assert.cpp"
    }, flags);

    // add jolt sources

    const jolt_dir = "lib/jolt/";

    lib.addIncludePath(.{
        .path = jolt_dir
    });

    lib.addCSourceFiles(&.{
        jolt_dir ++ "Jolt/AABBTree/AABBTreeBuilder.cpp",
        jolt_dir ++ "Jolt/Core/Color.cpp",
        jolt_dir ++ "Jolt/Core/Factory.cpp",
        jolt_dir ++ "Jolt/Core/IssueReporting.cpp",
        jolt_dir ++ "Jolt/Core/JobSystemSingleThreaded.cpp",
        jolt_dir ++ "Jolt/Core/JobSystemThreadPool.cpp",
        jolt_dir ++ "Jolt/Core/JobSystemWithBarrier.cpp",
        jolt_dir ++ "Jolt/Core/LinearCurve.cpp",
        jolt_dir ++ "Jolt/Core/Memory.cpp",
        jolt_dir ++ "Jolt/Core/Profiler.cpp",
        jolt_dir ++ "Jolt/Core/RTTI.cpp",
        jolt_dir ++ "Jolt/Core/Semaphore.cpp",
        jolt_dir ++ "Jolt/Core/StringTools.cpp",
        jolt_dir ++ "Jolt/Core/TickCounter.cpp",
        jolt_dir ++ "Jolt/Geometry/ConvexHullBuilder.cpp",
        jolt_dir ++ "Jolt/Geometry/ConvexHullBuilder2D.cpp",
        jolt_dir ++ "Jolt/Geometry/Indexify.cpp",
        jolt_dir ++ "Jolt/Geometry/OrientedBox.cpp",
        jolt_dir ++ "Jolt/Math/Vec3.cpp",
        jolt_dir ++ "Jolt/ObjectStream/ObjectStream.cpp",
        jolt_dir ++ "Jolt/ObjectStream/ObjectStreamBinaryIn.cpp",
        jolt_dir ++ "Jolt/ObjectStream/ObjectStreamBinaryOut.cpp",
        jolt_dir ++ "Jolt/ObjectStream/ObjectStreamIn.cpp",
        jolt_dir ++ "Jolt/ObjectStream/ObjectStreamOut.cpp",
        jolt_dir ++ "Jolt/ObjectStream/ObjectStreamTextIn.cpp",
        jolt_dir ++ "Jolt/ObjectStream/ObjectStreamTextOut.cpp",
        jolt_dir ++ "Jolt/ObjectStream/SerializableObject.cpp",
        jolt_dir ++ "Jolt/ObjectStream/TypeDeclarations.cpp",
        jolt_dir ++ "Jolt/Physics/Body/Body.cpp",
        jolt_dir ++ "Jolt/Physics/Body/BodyCreationSettings.cpp",
        jolt_dir ++ "Jolt/Physics/Body/BodyInterface.cpp",
        jolt_dir ++ "Jolt/Physics/Body/BodyManager.cpp",
        jolt_dir ++ "Jolt/Physics/Body/MassProperties.cpp",
        jolt_dir ++ "Jolt/Physics/Body/MotionProperties.cpp",
        jolt_dir ++ "Jolt/Physics/Character/Character.cpp",
        jolt_dir ++ "Jolt/Physics/Character/CharacterBase.cpp",
        jolt_dir ++ "Jolt/Physics/Character/CharacterVirtual.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/BroadPhase/BroadPhase.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/BroadPhase/BroadPhaseBruteForce.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/BroadPhase/BroadPhaseQuadTree.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/BroadPhase/QuadTree.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/CastConvexVsTriangles.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/CastSphereVsTriangles.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/CollideConvexVsTriangles.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/CollideSphereVsTriangles.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/CollisionDispatch.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/CollisionGroup.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/EstimateCollisionResponse.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/GroupFilter.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/GroupFilterTable.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/ManifoldBetweenTwoFaces.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/NarrowPhaseQuery.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/NarrowPhaseStats.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/PhysicsMaterial.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/PhysicsMaterialSimple.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/BoxShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/CapsuleShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/CompoundShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/ConvexHullShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/ConvexShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/CylinderShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/DecoratedShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/EmptyShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/HeightFieldShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/MeshShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/MutableCompoundShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/OffsetCenterOfMassShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/PlaneShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/RotatedTranslatedShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/ScaledShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/Shape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/SphereShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/StaticCompoundShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/TaperedCapsuleShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/TaperedCylinderShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/Shape/TriangleShape.cpp",
        jolt_dir ++ "Jolt/Physics/Collision/TransformedShape.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/ConeConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/Constraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/ConstraintManager.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/ContactConstraintManager.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/DistanceConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/FixedConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/GearConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/HingeConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/MotorSettings.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/PathConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/PathConstraintPath.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/PathConstraintPathHermite.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/PointConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/PulleyConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/RackAndPinionConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/SixDOFConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/SliderConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/SpringSettings.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/SwingTwistConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Constraints/TwoBodyConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/DeterminismLog.cpp",
        jolt_dir ++ "Jolt/Physics/IslandBuilder.cpp",
        jolt_dir ++ "Jolt/Physics/LargeIslandSplitter.cpp",
        jolt_dir ++ "Jolt/Physics/PhysicsScene.cpp",
        jolt_dir ++ "Jolt/Physics/PhysicsSystem.cpp",
        jolt_dir ++ "Jolt/Physics/PhysicsUpdateContext.cpp",
        jolt_dir ++ "Jolt/Physics/Ragdoll/Ragdoll.cpp",
        jolt_dir ++ "Jolt/Physics/SoftBody/SoftBodyCreationSettings.cpp",
        jolt_dir ++ "Jolt/Physics/SoftBody/SoftBodyMotionProperties.cpp",
        jolt_dir ++ "Jolt/Physics/SoftBody/SoftBodyShape.cpp",
        jolt_dir ++ "Jolt/Physics/SoftBody/SoftBodySharedSettings.cpp",
        jolt_dir ++ "Jolt/Physics/StateRecorderImpl.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/MotorcycleController.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/TrackedVehicleController.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/VehicleAntiRollBar.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/VehicleCollisionTester.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/VehicleConstraint.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/VehicleController.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/VehicleDifferential.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/VehicleEngine.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/VehicleTrack.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/VehicleTransmission.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/Wheel.cpp",
        jolt_dir ++ "Jolt/Physics/Vehicle/WheeledVehicleController.cpp",
        jolt_dir ++ "Jolt/RegisterTypes.cpp",
        jolt_dir ++ "Jolt/Renderer/DebugRenderer.cpp",
        jolt_dir ++ "Jolt/Renderer/DebugRendererPlayback.cpp",
        jolt_dir ++ "Jolt/Renderer/DebugRendererRecorder.cpp",
        jolt_dir ++ "Jolt/Renderer/DebugRendererSimple.cpp",
        jolt_dir ++ "Jolt/Skeleton/SkeletalAnimation.cpp",
        jolt_dir ++ "Jolt/Skeleton/Skeleton.cpp",
        jolt_dir ++ "Jolt/Skeleton/SkeletonMapper.cpp",
        jolt_dir ++ "Jolt/Skeleton/SkeletonPose.cpp",
        jolt_dir ++ "Jolt/TriangleSplitter/TriangleSplitter.cpp",
        jolt_dir ++ "Jolt/TriangleSplitter/TriangleSplitterBinning.cpp",
        jolt_dir ++ "Jolt/TriangleSplitter/TriangleSplitterMean.cpp",
    }, flags);

    b.installArtifact(lib);
}

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options = Options {
        .use_double_precision = b.option(bool, "use_double_precision", "use double precision") orelse false,
        .enable_asserts = b.option(bool, "enable_asserts", "enable asserts") orelse false,
        .enable_debug_renderer = b.option(bool, "enable_debug_renderer", "enable debug renderer") orelse false,
        .enable_cross_platform_determinism = b.option(bool, "enable_cross_platform_determinism", "enable cross platform determinism") orelse true,
    };

    compile(options, b, b.addSharedLibrary(.{ .name = "joltc", .target = target, .optimize = optimize }));
    compile(options, b, b.addStaticLibrary(.{ .name = "joltc", .target = target, .optimize = optimize }));
}

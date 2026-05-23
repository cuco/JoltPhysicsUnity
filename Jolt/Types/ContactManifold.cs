using Unity.Mathematics;

using static Jolt.Bindings;

namespace Jolt
{
    public partial struct ContactManifold
    {
        internal NativeHandle<JPH_ContactManifold> Handle;

        public float3 GetWorldSpaceNormal() => JPH_ContactManifold_GetWorldSpaceNormal(Handle);

        public float GetPenetrationDepth() => JPH_ContactManifold_GetPenetrationDepth(Handle);

        public uint GetPointCount() => JPH_ContactManifold_GetPointCount(Handle);

        public rvec3 GetWorldSpaceContactPointOn1(uint index) => JPH_ContactManifold_GetWorldSpaceContactPointOn1(Handle, index);

        public rvec3 GetWorldSpaceContactPointOn2(uint index) => JPH_ContactManifold_GetWorldSpaceContactPointOn2(Handle, index);

        public SubShapeID GetSubShapeID1() => JPH_ContactManifold_GetSubShapeID1(Handle);

        public SubShapeID GetSubShapeID2() => JPH_ContactManifold_GetSubShapeID2(Handle);
    }
}

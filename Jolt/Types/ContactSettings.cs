using Unity.Mathematics;

using static Jolt.Bindings;

namespace Jolt
{
    public partial struct ContactSettings
    {
        internal NativeHandle<JPH_ContactSettings> Handle;

        public float Friction
        {
            get => JPH_ContactSettings_GetFriction(Handle);
            set => JPH_ContactSettings_SetFriction(Handle, value);
        }

        public float Restitution
        {
            get => JPH_ContactSettings_GetRestitution(Handle);
            set => JPH_ContactSettings_SetRestitution(Handle, value);
        }

        public float InvMassScale1
        {
            get => JPH_ContactSettings_GetInvMassScale1(Handle);
            set => JPH_ContactSettings_SetInvMassScale1(Handle, value);
        }

        public float InvInertiaScale1
        {
            get => JPH_ContactSettings_GetInvInertiaScale1(Handle);
            set => JPH_ContactSettings_SetInvInertiaScale1(Handle, value);
        }

        public float InvMassScale2
        {
            get => JPH_ContactSettings_GetInvMassScale2(Handle);
            set => JPH_ContactSettings_SetInvMassScale2(Handle, value);
        }

        public float InvInertiaScale2
        {
            get => JPH_ContactSettings_GetInvInertiaScale2(Handle);
            set => JPH_ContactSettings_SetInvInertiaScale2(Handle, value);
        }

        public bool IsSensor
        {
            get => JPH_ContactSettings_GetIsSensor(Handle);
            set => JPH_ContactSettings_SetIsSensor(Handle, value);
        }

        public float3 RelativeLinearSurfaceVelocity
        {
            get => JPH_ContactSettings_GetRelativeLinearSurfaceVelocity(Handle);
            set => JPH_ContactSettings_SetRelativeLinearSurfaceVelocity(Handle, value);
        }

        public float3 RelativeAngularSurfaceVelocity
        {
            get => JPH_ContactSettings_GetRelativeAngularSurfaceVelocity(Handle);
            set => JPH_ContactSettings_SetRelativeAngularSurfaceVelocity(Handle, value);
        }
    }
}

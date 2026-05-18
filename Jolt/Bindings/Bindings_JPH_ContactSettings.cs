using Unity.Mathematics;

namespace Jolt
{
    internal static unsafe partial class Bindings
    {
        public static float JPH_ContactSettings_GetFriction(NativeHandle<JPH_ContactSettings> settings)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            return s->combinedFriction;
        }

        public static void JPH_ContactSettings_SetFriction(NativeHandle<JPH_ContactSettings> settings, float friction)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            s->combinedFriction = friction;
        }

        public static float JPH_ContactSettings_GetRestitution(NativeHandle<JPH_ContactSettings> settings)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            return s->combinedRestitution;
        }

        public static void JPH_ContactSettings_SetRestitution(NativeHandle<JPH_ContactSettings> settings, float restitution)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            s->combinedRestitution = restitution;
        }

        public static float JPH_ContactSettings_GetInvMassScale1(NativeHandle<JPH_ContactSettings> settings)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            return s->invMassScale1;
        }

        public static void JPH_ContactSettings_SetInvMassScale1(NativeHandle<JPH_ContactSettings> settings, float scale)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            s->invMassScale1 = scale;
        }

        public static float JPH_ContactSettings_GetInvInertiaScale1(NativeHandle<JPH_ContactSettings> settings)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            return s->invInertiaScale1;
        }

        public static void JPH_ContactSettings_SetInvInertiaScale1(NativeHandle<JPH_ContactSettings> settings, float scale)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            s->invInertiaScale1 = scale;
        }

        public static float JPH_ContactSettings_GetInvMassScale2(NativeHandle<JPH_ContactSettings> settings)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            return s->invMassScale2;
        }

        public static void JPH_ContactSettings_SetInvMassScale2(NativeHandle<JPH_ContactSettings> settings, float scale)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            s->invMassScale2 = scale;
        }

        public static float JPH_ContactSettings_GetInvInertiaScale2(NativeHandle<JPH_ContactSettings> settings)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            return s->invInertiaScale2;
        }

        public static void JPH_ContactSettings_SetInvInertiaScale2(NativeHandle<JPH_ContactSettings> settings, float scale)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            s->invInertiaScale2 = scale;
        }

        public static bool JPH_ContactSettings_GetIsSensor(NativeHandle<JPH_ContactSettings> settings)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            return s->isSensor != 0;
        }

        public static void JPH_ContactSettings_SetIsSensor(NativeHandle<JPH_ContactSettings> settings, bool sensor)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            s->isSensor = sensor ? 1u : 0u;
        }

        public static float3 JPH_ContactSettings_GetRelativeLinearSurfaceVelocity(NativeHandle<JPH_ContactSettings> settings)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            return s->relativeLinearSurfaceVelocity;
        }

        public static void JPH_ContactSettings_SetRelativeLinearSurfaceVelocity(NativeHandle<JPH_ContactSettings> settings, float3 velocity)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            s->relativeLinearSurfaceVelocity = velocity;
        }

        public static float3 JPH_ContactSettings_GetRelativeAngularSurfaceVelocity(NativeHandle<JPH_ContactSettings> settings)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            return s->relativeAngularSurfaceVelocity;
        }

        public static void JPH_ContactSettings_SetRelativeAngularSurfaceVelocity(NativeHandle<JPH_ContactSettings> settings, float3 velocity)
        {
            AssertInitialized();

            JPH_ContactSettings* s = settings;
            s->relativeAngularSurfaceVelocity = velocity;
        }
    }
}

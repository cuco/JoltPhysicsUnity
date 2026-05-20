using AOT;
using UnityEngine;

namespace Jolt.Unity
{
    internal static class JoltRuntimeInitialization
    {
        //         [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        //         public static void Initialize()
        //         {
        // #if UNITY_ANDROID && !UNITY_EDITOR
        //             JoltAndroidLibraryLoader.TryLoad();
        // #endif
        //             if (Jolt.Initialize())
        //             {
        //                 Jolt.SetAssertFailureHandler(OnAssertFailure);
        //             }
        //             else
        //             {
        //                 Debug.LogError("Jolt initialization failed.");
        //             }
        //         }

        //         [MonoPInvokeCallback(typeof(AssertFailureHandler))]
        //         private static bool OnAssertFailure(string expr, string message, string file, uint line)
        //         {
        //             Debug.Log($"Jolt Assertion Failed:\n{expr}\n{message}\n{file}\n{line}");
        //             return false;
        //         }
    }
}

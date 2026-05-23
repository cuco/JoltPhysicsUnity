using Unity.Mathematics;
using UnityEngine;

namespace Jolt.Samples
{
    public class ListenerSample : Sample
    {
        private BodyActivationListener nativeBodyActivationListener;

        private ContactListener nativeContactListener;

        protected override void Start()
        {
            base.Start();

            nativeBodyActivationListener = BodyActivationListener.Create(new SampleBodyActivationListener());
            PhysicsSystem.SetBodyActivationListener(nativeBodyActivationListener);

            nativeContactListener = ContactListener.Create(new SampleContactListener());
            PhysicsSystem.SetContactListener(nativeContactListener);
        }

        protected override void OnDestroy()
        {
            base.OnDestroy();

            nativeBodyActivationListener.Destroy();
            nativeContactListener.Destroy();
        }
    }

    /// <summary>
    /// Sample body activation listener that logs each event.
    /// </summary>
    public class SampleBodyActivationListener : IBodyActivationListener
    {
        public void OnBodyActivated(BodyID bodyID, ulong bodyUserData)
        {
            Debug.Log($"OnBodyActivated(BodyID: {bodyID}, BodyUserData: {bodyUserData})");
        }

        public void OnBodyDeactivated(BodyID bodyID, ulong bodyUserData)
        {
            Debug.Log($"OnBodyDeactivated(BodyID: {bodyID}, BodyUserData: {bodyUserData})");
        }
    }

    /// <summary>
    /// Sample contact listener that logs each event.
    /// </summary>
    public class SampleContactListener : IContactListener
    {
        public ValidateResult OnContactValidate(Body body1, Body body2, rvec3 baseOffset, CollideShapeResult collisionResult)
        {
            Debug.Log($"OnContactValidate(Body1: {body1.GetID()}, Body2: {body2.GetID()}, BaseOffset: {baseOffset}, PenetrationDepth: {collisionResult.PenetrationDepth})");

            return ValidateResult.AcceptAllContactsForThisBodyPair;
        }

        public void OnContactAdded(Body body1, Body body2, ContactManifold manifold, ContactSettings settings)
        {
            var normal = manifold.GetWorldSpaceNormal();
            var point = manifold.GetPointCount() > 0 ? manifold.GetWorldSpaceContactPointOn2(0) : default;

            Debug.Log($"OnContactAdded(Body1: {body1.GetID()}, Body2: {body2.GetID()}, UserData1: {body1.GetUserData()}, UserData2: {body2.GetUserData()}, IsSensor: {settings.IsSensor}, Normal: {normal}, Point: {point})");
        }

        public void OnContactPersisted(Body body1, Body body2, ContactManifold manifold, ContactSettings settings)
        {
            var normal = manifold.GetWorldSpaceNormal();
            var point = manifold.GetPointCount() > 0 ? manifold.GetWorldSpaceContactPointOn2(0) : default;

            Debug.Log($"OnContactPersisted(Body1: {body1.GetID()}, Body2: {body2.GetID()}, IsSensor: {settings.IsSensor}, Normal: {normal}, Point: {point})");
        }

        public void OnContactRemoved(SubShapeIDPair subShapePair)
        {
            Debug.Log($"OnContactRemoved(Body1: {subShapePair.Body1}, Body2: {subShapePair.Body2})");
        }
    }
}

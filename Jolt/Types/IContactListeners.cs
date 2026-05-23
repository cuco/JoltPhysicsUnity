namespace Jolt
{
    public interface IContactListener
    {
        public ValidateResult OnContactValidate(Body body1, Body body2, rvec3 baseOffset, CollideShapeResult collisionResult);

        public void OnContactAdded(Body body1, Body body2, ContactManifold manifold, ContactSettings settings);

        public void OnContactPersisted(Body body1, Body body2, ContactManifold manifold, ContactSettings settings);

        public void OnContactRemoved(SubShapeIDPair subShapePair);
    }
}

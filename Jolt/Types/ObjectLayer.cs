using System;
using System.Runtime.InteropServices;

namespace Jolt
{
    /// <summary>
    /// Object collision layer index or mask-packed value, matching <c>JPH_ObjectLayer</c> / Jolt <c>ObjectLayer</c>.
    /// Width is fixed by native build: this package compiles Jolt with <c>JPH_OBJECT_LAYER_BITS=32</c> (see <c>Jolt.Native~/build.zig</c>).
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    public readonly struct ObjectLayer : IEquatable<ObjectLayer>
    {
        /// <summary>
        /// Bit width of <see cref="Value"/>; must match Jolt <c>JPH_OBJECT_LAYER_BITS</c> for the native library you load.
        /// </summary>
        public const uint ObjectLayerBits = 32;

        /// <summary>
        /// Jolt <c>cObjectLayerInvalid</c>: all bits set in the object-layer type.
        /// </summary>
        public static readonly ObjectLayer Invalid = new ObjectLayer(uint.MaxValue);

        /// <summary>
        /// The layer value (table index, or mask-encoded value for mask filters).
        /// </summary>
        public readonly uint Value;

        public ObjectLayer(uint value)
        {
            Value = value;
        }

        /// <summary>
        /// Widening conversion from <see cref="ushort"/> (e.g. legacy layer indices).
        /// </summary>
        public static implicit operator ObjectLayer(ushort layer)
        {
            return new ObjectLayer(layer);
        }

        /// <summary>
        /// Identity conversion.
        /// </summary>
        public static implicit operator ObjectLayer(uint layer)
        {
            return new ObjectLayer(layer);
        }

        #region IEquatable

        public bool Equals(ObjectLayer other)
        {
            return Value == other.Value;
        }

        public override bool Equals(object obj)
        {
            return obj is ObjectLayer other && Equals(other);
        }

        public override int GetHashCode()
        {
            return (int)Value;
        }

        public static bool operator ==(ObjectLayer lhs, ObjectLayer rhs)
        {
            return lhs.Equals(rhs);
        }

        public static bool operator !=(ObjectLayer lhs, ObjectLayer rhs)
        {
            return !lhs.Equals(rhs);
        }

        #endregion
    }
}

using UnityEngine;

public class Int4
{
    public int x;
    public int y;
    public int z;
    public int w;

    public Int4(int x, int y, int z, int w)
    {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public static Vector4 operator *(Int4 lhs, float rhs)
    {
        return new Vector4(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs);
    }

    public static Vector4 operator *(float lhs, Int4 rhs)
    {
        return new Vector4(rhs.x * lhs, rhs.y * lhs, rhs.z * lhs, rhs.w * lhs);
    }

    public static Vector4 operator /(Int4 lhs, float rhs)
    {
        return new Vector4(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs);
    }

    public static Vector4 operator /(float lhs, Int4 rhs)
    {
        return new Vector4(rhs.x / lhs, rhs.y / lhs, rhs.z / lhs, rhs.w / lhs);
    }
}

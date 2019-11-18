using UnityEngine;

public class LodHeightGenerator
{
    private Perlin perlin;

    public LodHeightGenerator(Perlin perlin)
    {
        this.perlin = perlin;
    }

    public Perlin.PerlinSample GetSample(Vector3 position)
    {
        return this.perlin.Sample(position.x, position.y, position.z) / 2f + 1.5f;
    }

    public static Vector3 GetAdjustedNormal(Vector3 normal, Vector3 derivative)
    {
        return (normal - derivative).normalized;
    }
}

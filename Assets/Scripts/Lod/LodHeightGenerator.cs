using UnityEngine;

public class LodHeightGenerator
{
    private Perlin perlin;

    public LodHeightGenerator(Perlin perlin)
    {
        this.perlin = perlin;
    }

    private Perlin.PerlinSample GetSample(Vector3 position, float frequency)
    {
        Perlin.PerlinSample sample = this.perlin.Sample(position * frequency);
        sample.derivative *= frequency;
        return sample;
    }

    public Perlin.PerlinSample GetSample(Vector3 position)
    {
        // return (this.GetSample(position, 1f) + this.GetSample(position, 2f) / 2f + this.GetSample(position, 4f) / 4f) / 2f + 1.5f;
        return this.GetSample(position, 1f) / 2f + 1.5f;
    }

    public float GetMaximumValue() {
        return (1f + 1f/2f + 1f/4f) / 2f + 1.5f;
    }

    public static Vector3 GetAdjustedNormal(Vector3 normal, Vector3 derivative)
    {
        return (normal - derivative).normalized;
    }
}

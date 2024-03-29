using UnityEngine;

public class LodHeightGenerator
{
    public class Properties
    {
        public float strength;
        public float frequency;
        public int octaves;
        public float lacunarity;
        public float persistence;
    }

    private Perlin perlin;
    private Properties properties;

    public LodHeightGenerator(Perlin perlin, Properties properties)
    {
        this.perlin = perlin;
        this.properties = properties;
    }

    private Perlin.PerlinSample GetSample(Vector3 position, float frequency)
    {
        Perlin.PerlinSample sample = this.perlin.Sample(position * frequency);
        sample.derivative *= frequency;
        return sample;
    }

    private float GetHeight(Vector3 position, float frequency)
    {
        return this.perlin.Value(position * frequency);
    }

    public Perlin.PerlinSample GetSample(Vector3 position)
    {
        float strength = this.properties.strength;
        float frequency = this.properties.frequency;
        Perlin.PerlinSample sum = this.GetSample(position, frequency) * strength;
        for (int i = 1; i < this.properties.octaves; i++)
        {
            strength *= this.properties.persistence;
            frequency *= this.properties.lacunarity;
            Perlin.PerlinSample sample = this.GetSample(position, frequency) * strength;
            sum += sample;
        }
        return sum + 1f;
    }

    public float GetHeight(Vector3 position)
    {
        float strength = this.properties.strength;
        float frequency = this.properties.frequency;
        float sum = this.GetHeight(position, frequency) * strength;
        for (int i = 1; i < this.properties.octaves; i++)
        {
            strength *= this.properties.persistence;
            frequency *= this.properties.lacunarity;
            float height = this.GetHeight(position, frequency) * strength;
            sum += height;
        }
        return sum + 1f;
    }

    public static Vector3 GetAdjustedNormal(Vector3 normal, Vector3 derivative)
    {
        return (normal - derivative).normalized;
    }
}

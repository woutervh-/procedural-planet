using UnityEngine;

public class LodHeightGenerator
{
    private Perlin perlin;

    public LodHeightGenerator(Perlin perlin)
    {
        this.perlin = perlin;
    }

    public float GetHeight(Vector3 position)
    {
        float sample = this.perlin.GetValue(position.x, position.y, position.z);
        return (sample + 1f) / 2f;
    }
}

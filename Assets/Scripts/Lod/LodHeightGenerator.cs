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
        return sample / 2f + 1.5f;
    }

    public Vector3 GetNormal(Vector3 normal, Vector3 position)
    {
        // Central difference method.
        float h = 2f;
        float f = this.perlin.GetValue(position.x, position.y, position.z);
        float fx0 = this.perlin.GetValue(position.x - h, position.y, position.z);
        float fy0 = this.perlin.GetValue(position.x, position.y - h, position.z);
        float fz0 = this.perlin.GetValue(position.x, position.y, position.z - h);
        float fx1 = this.perlin.GetValue(position.x + h, position.y, position.z);
        float fy1 = this.perlin.GetValue(position.x, position.y + h, position.z);
        float fz1 = this.perlin.GetValue(position.x, position.y, position.z + h);
        // Vector3 df = new Vector3((fx0 + fx1) / 2f / h, (fy0 + fy1) / 2f / h, (fz0 + fz1) / 2f / h);

        // Analytical method.
        Vector3 df = this.perlin.GetDerivative(position.x, position.y, position.z) / 2f;

        return (normal - df).normalized;
    }
}

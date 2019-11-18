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
        return (this.perlin.Sample(position.x, position.y, position.z) / 2f + 1.5f).value;
    }

    public Vector3 GetHeightGradient(Vector3 position)
    {
        return (this.perlin.Sample(position.x, position.y, position.z) / 2f).derivative;
    }

    public Vector3 GetNormal(Vector3 normal, Vector3 position)
    {
        // Central difference method.
        float h = 2f;
        float f = this.perlin.Sample(position.x, position.y, position.z).value;
        float fx0 = this.perlin.Sample(position.x - h, position.y, position.z).value;
        float fy0 = this.perlin.Sample(position.x, position.y - h, position.z).value;
        float fz0 = this.perlin.Sample(position.x, position.y, position.z - h).value;
        float fx1 = this.perlin.Sample(position.x + h, position.y, position.z).value;
        float fy1 = this.perlin.Sample(position.x, position.y + h, position.z).value;
        float fz1 = this.perlin.Sample(position.x, position.y, position.z + h).value;
        // Vector3 df = new Vector3((fx0 + fx1) / 2f / h, (fy0 + fy1) / 2f / h, (fz0 + fz1) / 2f / h);

        // Analytical method.
        Vector3 df = this.GetHeightGradient(position) / 2f;

        return (normal - df).normalized;
    }
}

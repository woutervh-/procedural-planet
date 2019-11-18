using UnityEngine;

public class PerlinTextureGenerator
{
    public static Texture2D CreateGradientsTexture(Perlin perlin)
    {
        Vector3[] gradients = perlin.GetGradients();
        Color[] colors = new Color[Perlin.SIZE * 2];
        for (int i = 0; i < Perlin.SIZE * 2; i++)
        {
            colors[i] = new Color(gradients[i].x / 2f + 0.5f, gradients[i].y / 2f + 0.5f, gradients[i].z / 2f + 0.5f, 1f);
        }
        Texture2D texture = new Texture2D(Perlin.SIZE, 1, TextureFormat.RGBA32, false, true);
        texture.filterMode = FilterMode.Point;
        texture.wrapMode = TextureWrapMode.Repeat;
        texture.SetPixels(colors);
        texture.Apply();
        return texture;
    }

    public static Texture2D CreatePermutationTexture(Perlin perlin)
    {
        Int4[] hashes = perlin.GetHashes2D();
        Color[] colors = new Color[Perlin.SIZE * Perlin.SIZE];
        for (int y = 0; y < Perlin.SIZE; y++)
        {
            for (int x = 0; x < Perlin.SIZE; x++)
            {
                Int4 permutation = hashes[x + y * Perlin.SIZE];
                colors[x + y * Perlin.SIZE] = new Color(permutation.x / 256f, permutation.y / 256f, permutation.z / 256f, permutation.w / 256f);
            }
        }
        Texture2D texture = new Texture2D(Perlin.SIZE, Perlin.SIZE, TextureFormat.RGBA32, false, true);
        texture.filterMode = FilterMode.Point;
        texture.wrapMode = TextureWrapMode.Repeat;
        texture.SetPixels(colors);
        texture.Apply();
        return texture;
    }
}

using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class PerlinNoiseTexture : MonoBehaviour
{
    [Range(0, 256)]
    public int seed = 0;

    private int lastSeed = 0;
    private MeshRenderer meshRenderer;
    private Perlin perlin;

    void Start()
    {
        this.meshRenderer = this.GetComponent<MeshRenderer>();
        this.GeneratePerlin();
        this.GenerateTexture();
    }

    void Update()
    {
        if (this.lastSeed != this.seed)
        {
            this.lastSeed = this.seed;
            this.GeneratePerlin();
            this.GenerateTexture();
        }
    }

    void GeneratePerlin()
    {
        this.perlin = new Perlin(this.seed);
    }

    void GenerateTexture()
    {
        Texture2D gradientsTexture = this.CreateGradientsTexture();
        gradientsTexture.filterMode = FilterMode.Point;
        gradientsTexture.wrapMode = TextureWrapMode.Repeat;

        Texture2D permutationTexture = this.CreatePermutationTexture();
        permutationTexture.filterMode = FilterMode.Point;
        permutationTexture.wrapMode = TextureWrapMode.Repeat;

        this.meshRenderer.material.SetTexture("_Gradients2D", gradientsTexture);
        this.meshRenderer.material.SetTexture("_Permutation2D", permutationTexture);
    }

    Texture2D CreateGradientsTexture()
    {
        Vector3[] gradients = this.perlin.GetGradients();
        Color[] colors = new Color[Perlin.SIZE * 2];
        for (int i = 0; i < Perlin.SIZE * 2; i++)
        {
            colors[i] = new Color(gradients[i].x, gradients[i].y, gradients[i].z, 1f);
        }
        Texture2D texture = new Texture2D(Perlin.SIZE, 1, TextureFormat.RGBA32, false, true);
        texture.SetPixels(colors);
        texture.Apply();
        return texture;
    }

    Texture2D CreatePermutationTexture()
    {
        Int4[] hashes = this.perlin.GetHashes2D();
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
        texture.SetPixels(colors);
        texture.Apply();
        return texture;
    }
}

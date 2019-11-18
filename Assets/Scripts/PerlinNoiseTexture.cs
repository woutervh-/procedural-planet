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
        Texture2D gradientsTexture = PerlinTextureGenerator.CreateGradientsTexture(this.perlin);
        Texture2D permutationTexture = PerlinTextureGenerator.CreatePermutationTexture(this.perlin);

        this.meshRenderer.material.SetTexture("_Gradients2D", gradientsTexture);
        this.meshRenderer.material.SetTexture("_Permutation2D", permutationTexture);
    }
}

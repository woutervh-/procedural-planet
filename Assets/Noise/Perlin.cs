using UnityEngine;

public class Perlin
{
    public const int SIZE = 256;
    private int[] permutation;
    private Int4[] hashes;
    private Vector3[] gradients;

    public Perlin(int seed)
    {
        Random.InitState(seed);

        int[] permutation = new int[Perlin.SIZE];
        for (int i = 0; i < Perlin.SIZE; i++)
        {
            permutation[i] = i;
        }
        ArrayUtils.Shuffle(permutation, seed);

        this.permutation = new int[Perlin.SIZE * 2];
        for (int i = 0; i < Perlin.SIZE; i++)
        {
            this.permutation[i] = permutation[i];
            this.permutation[i + Perlin.SIZE] = permutation[i];
        }

        this.hashes = new Int4[Perlin.SIZE * Perlin.SIZE];
        for (int ix = 0; ix < Perlin.SIZE; ix++)
        {
            for (int iy = 0; iy < Perlin.SIZE; iy++)
            {
                int a = this.permutation[ix] + iy;
                int aa = this.permutation[a];
                int ab = this.permutation[a + 1];
                int b = this.permutation[ix + 1] + iy;
                int ba = this.permutation[b];
                int bb = this.permutation[b + 1];
                this.hashes[ix + iy * Perlin.SIZE] = new Int4(aa, ab, ba, bb);
            }
        }

        this.gradients = new Vector3[Perlin.SIZE * 2];
        for (int i = 0; i < Perlin.SIZE; i++)
        {
            this.gradients[i] = Perlin.gradientLookup[this.permutation[i] % 12];
            this.gradients[i + Perlin.SIZE] = Perlin.gradientLookup[this.permutation[i] % 12];
        }
    }

    public int[] GetPermutation()
    {
        return this.permutation;
    }

    public Int4[] GetHashes2D()
    {
        return this.hashes;
    }

    public Vector3[] GetGradients()
    {
        return this.gradients;
    }

    public float GetValue(float x, float y, float z)
    {
        int ix = (int)x % Perlin.SIZE;
        int iy = (int)y % Perlin.SIZE;
        int iz = (int)z % Perlin.SIZE;
        float fx = x - (int)x;
        float fy = y - (int)y;
        float fz = z - (int)z;
        float u = Perlin.Fade(fx);
        float v = Perlin.Fade(fy);
        float w = Perlin.Fade(fz);

        int aa = (int)this.hashes[ix + iy * Perlin.SIZE].x + iz;
        int ab = (int)this.hashes[ix + iy * Perlin.SIZE].y + iz;
        int ba = (int)this.hashes[ix + iy * Perlin.SIZE].z + iz;
        int bb = (int)this.hashes[ix + iy * Perlin.SIZE].w + iz;

        Vector3 p = new Vector3(fx, fy, fz);
        float x1, x2, y1, y2;
        x1 = Mathf.Lerp(
            Vector3.Dot(this.gradients[aa], p + directionLookup[0]),
            Vector3.Dot(this.gradients[ba], p + directionLookup[1]),
            u
        );
        x2 = Mathf.Lerp(
            Vector3.Dot(this.gradients[ab], p + directionLookup[2]),
            Vector3.Dot(this.gradients[bb], p + directionLookup[3]),
            u
        );
        y1 = Mathf.Lerp(x1, x2, v);
        x1 = Mathf.Lerp(
            Vector3.Dot(this.gradients[aa + 1], p + directionLookup[4]),
            Vector3.Dot(this.gradients[ba + 1], p + directionLookup[5]),
            u
        );
        x2 = Mathf.Lerp(
            Vector3.Dot(this.gradients[ab + 1], p + directionLookup[6]),
            Vector3.Dot(this.gradients[bb + 1], p + directionLookup[7]),
            u
        );
        y2 = Mathf.Lerp(x1, x2, v);
        return (Mathf.Lerp(y1, y2, w) + 1f) / 2f;
    }

    private static float Fade(float t)
    {
        return t * t * t * (t * (t * 6 - 15) + 10);
    }

    private static Vector3[] gradientLookup = new Vector3[] {
        new Vector3(1, 1, 0).normalized,
        new Vector3(-1, 1, 0).normalized,
        new Vector3(1, -1, 0).normalized,
        new Vector3(-1, -1, 0).normalized,
        new Vector3(1, 0, 1).normalized,
        new Vector3(-1, 0, 1).normalized,
        new Vector3(1, 0, -1).normalized,
        new Vector3(-1, 0, -1).normalized,
        new Vector3(0, 1, 1).normalized,
        new Vector3(0, -1, 1).normalized,
        new Vector3(0, 1, -1).normalized,
        new Vector3(0, -1, -1).normalized
    };

    private static Vector3[] directionLookup = new Vector3[] {
        new Vector3(0, 0, 0),
        new Vector3(-1, 0, 0),
        new Vector3(0, -1, 0),
        new Vector3(-1, -1, 0),
        new Vector3(0, 0, -1),
        new Vector3(-1, 0, -1),
        new Vector3(0, -1, -1),
        new Vector3(-1, -1, -1)
    };
}

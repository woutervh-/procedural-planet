using UnityEngine;

public class Perlin
{
    public class PerlinSample
    {
        public float value;
        public Vector3 derivative;

        public static PerlinSample operator +(PerlinSample lhs, PerlinSample rhs)
        {
            lhs.value += rhs.value;
            lhs.derivative += rhs.derivative;
            return lhs;
        }

        public static PerlinSample operator +(PerlinSample lhs, float rhs)
        {
            lhs.value += rhs;
            return lhs;
        }

        public static PerlinSample operator +(float lhs, PerlinSample rhs)
        {
            rhs.value += lhs;
            return rhs;
        }

        public static PerlinSample operator -(PerlinSample lhs, PerlinSample rhs)
        {
            lhs.value -= rhs.value;
            lhs.derivative -= rhs.derivative;
            return lhs;
        }

        public static PerlinSample operator -(PerlinSample lhs, float rhs)
        {
            lhs.value -= rhs;
            return lhs;
        }

        public static PerlinSample operator -(float lhs, PerlinSample rhs)
        {
            rhs.value = lhs - rhs.value;
            rhs.derivative = -rhs.derivative;
            return rhs;
        }

        public static PerlinSample operator *(PerlinSample lhs, PerlinSample rhs)
        {
            lhs.derivative = lhs.derivative * rhs.value + rhs.derivative * lhs.value;
            lhs.value *= rhs.value;
            return lhs;
        }

        public static PerlinSample operator *(PerlinSample lhs, float rhs)
        {
            lhs.value *= rhs;
            lhs.derivative *= rhs;
            return lhs;
        }

        public static PerlinSample operator *(float lhs, PerlinSample rhs)
        {
            rhs.value *= lhs;
            rhs.derivative *= lhs;
            return rhs;
        }

        public static PerlinSample operator /(PerlinSample lhs, PerlinSample rhs)
        {
            lhs.derivative = (lhs.derivative * rhs.value - rhs.derivative * lhs.value) / (rhs.value * rhs.value);
            lhs.value /= rhs.value;
            return lhs;
        }

        public static PerlinSample operator /(PerlinSample lhs, float rhs)
        {
            lhs.value /= rhs;
            lhs.derivative /= rhs;
            return lhs;
        }

        public static PerlinSample operator /(float lhs, PerlinSample rhs)
        {
            rhs.value /= lhs;
            rhs.derivative /= lhs;
            return rhs;
        }
    }

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

    public PerlinSample Sample(float x, float y, float z)
    {
        int ix = Perlin.FlooredRemainder(Mathf.FloorToInt(x), Perlin.SIZE);
        int iy = Perlin.FlooredRemainder(Mathf.FloorToInt(y), Perlin.SIZE);
        int iz = Perlin.FlooredRemainder(Mathf.FloorToInt(z), Perlin.SIZE);
        float fx = x - Mathf.FloorToInt(x);
        float fy = y - Mathf.FloorToInt(y);
        float fz = z - Mathf.FloorToInt(z);
        float u = Perlin.Fade(fx);
        float v = Perlin.Fade(fy);
        float w = Perlin.Fade(fz);
        float du = Perlin.FadeDerivative(fx);
        float dv = Perlin.FadeDerivative(fy);
        float dw = Perlin.FadeDerivative(fz);

        int aa = (int)this.hashes[ix + iy * Perlin.SIZE].x + iz;
        int ab = (int)this.hashes[ix + iy * Perlin.SIZE].y + iz;
        int ba = (int)this.hashes[ix + iy * Perlin.SIZE].z + iz;
        int bb = (int)this.hashes[ix + iy * Perlin.SIZE].w + iz;

        Vector3 p = new Vector3(fx, fy, fz);
        float a = Vector3.Dot(this.gradients[aa], p + directionLookup[0]);
        float b = Vector3.Dot(this.gradients[ba], p + directionLookup[1]);
        float c = Vector3.Dot(this.gradients[ab], p + directionLookup[2]);
        float d = Vector3.Dot(this.gradients[bb], p + directionLookup[3]);
        float e = Vector3.Dot(this.gradients[aa + 1], p + directionLookup[4]);
        float f = Vector3.Dot(this.gradients[ba + 1], p + directionLookup[5]);
        float g = Vector3.Dot(this.gradients[ab + 1], p + directionLookup[6]);
        float h = Vector3.Dot(this.gradients[bb + 1], p + directionLookup[7]);

        float k0 = a;
        float k1 = (b - a);
        float k2 = (c - a);
        float k3 = (e - a);
        float k4 = (a + d - b - c);
        float k5 = (a + f - b - e);
        float k6 = (a + g - c - e);
        float k7 = (b + c + e + h - a - d - f - g);

        PerlinSample sample = new PerlinSample();
        sample.value = k0 + k1 * u + k2 * v + k3 * w + k4 * u * v + k5 * u * w + k6 * v * w + k7 * u * v * w;
        sample.derivative = new Vector3(
            du * (k1 + k4 * v + k5 * w + k7 * v * w),
            dv * (k2 + k4 * u + k6 * w + k7 * v * w),
            dw * (k3 + k5 * u + k6 * v + k7 * v * w)
        );

        return sample;
    }

    private static int FlooredRemainder(int a, int n)
    {
        if (a >= 0)
        {
            return a % n;
        }
        else
        {
            return n + a % n;
        }
    }

    private static float Fade(float t)
    {
        return t * t * t * (t * (t * 6f - 15f) + 10f);
    }

    private static float FadeDerivative(float t)
    {
        return 30.0f * t * t * (1.0f + t * (t - 2.0f));
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

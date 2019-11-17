using System;
using UnityEngine;

public class LodNode : IDisposable
{
    private const int MAX_LOD_LEVEL = 10;
    private const int CHUNK_RESOLUTION = 16;
    private const float DETAIL_FACTOR = 512f;

    public static Vector2 RootMin = -Vector2.one;
    public static Vector2 RootMax = Vector2.one;

    private LodNode parent;
    private LodProperties lodProperties;
    private LodNode[] children;
    private int lodLevel;
    private GameObject gameObject;
    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;
    private Vector3 up;
    private Vector2 min;
    private Vector2 max;
    private Mesh plane;

    public LodNode(LodNode parent, LodProperties lodProperties, int lodLevel, Vector3 up, Vector2 min, Vector2 max)
    {
        this.parent = parent;
        this.lodProperties = lodProperties;
        this.children = null;
        this.lodLevel = lodLevel;
        this.gameObject = new GameObject("Chunk " + lodLevel);
        this.meshFilter = this.gameObject.AddComponent<MeshFilter>();
        this.meshRenderer = this.gameObject.AddComponent<MeshRenderer>();
        this.up = up;
        this.min = min;
        this.max = max;
        this.plane = new LodFace(LodNode.CHUNK_RESOLUTION, up, min, max).GenerateMesh();

        this.meshRenderer.sharedMaterial = lodProperties.material;
        this.meshFilter.transform.parent = lodProperties.gameObject.transform;
        this.meshFilter.mesh = this.plane;
    }

    public Vector2 BottomLeft()
    {
        return this.min;
    }

    public Vector2 MiddleLeft()
    {
        return new Vector2(this.min.x, (this.min.y + this.max.y) / 2f);
    }

    public Vector2 TopLeft()
    {
        return new Vector2(this.min.x, this.max.y);
    }

    public Vector2 CenterBottom()
    {
        return new Vector2((this.min.x + this.max.x) / 2f, this.min.y);
    }

    public Vector2 CenterMiddle()
    {
        return new Vector2((this.min.x + this.max.x) / 2f, (this.min.y + this.max.y) / 2f);
    }

    public Vector2 CenterTop()
    {
        return new Vector2((this.min.x + this.max.x) / 2f, this.max.y);
    }

    public Vector2 BottomRight()
    {
        return new Vector2(this.max.x, this.min.y);
    }

    public Vector2 MiddleRight()
    {
        return new Vector2(this.max.x, (this.min.y + this.max.y) / 2f);
    }

    public Vector2 TopRight()
    {
        return this.max;
    }

    public void Dispose()
    {
        UnityEngine.Object.Destroy(this.meshRenderer);
        UnityEngine.Object.Destroy(this.meshFilter);
        UnityEngine.Object.Destroy(this.gameObject);
    }

    public void SplitRecursive()
    {
        if (!this.ShouldSplit())
        {
            return;
        }
        this.Split();
        if (this.children != null)
        {
            foreach (LodNode child in this.children)
            {
                child.SplitRecursive();
            }
        }
    }

    public void MergeRecursive()
    {
        if (this.children != null)
        {
            foreach (LodNode child in this.children)
            {
                child.MergeRecursive();
            }
        }
        if (this.ShouldMerge())
        {
            this.Merge();
        }
    }

    private void Split()
    {
        if (this.children != null)
        {
            return;
        }
        if (this.lodLevel == LodNode.MAX_LOD_LEVEL)
        {
            return;
        }
        this.meshRenderer.enabled = false;
        this.children = new LodNode[4];
        this.children[0] = new LodNode(this, this.lodProperties, this.lodLevel + 1, this.up, this.BottomLeft(), this.CenterMiddle());
        this.children[1] = new LodNode(this, this.lodProperties, this.lodLevel + 1, this.up, this.CenterBottom(), this.MiddleRight());
        this.children[2] = new LodNode(this, this.lodProperties, this.lodLevel + 1, this.up, this.MiddleLeft(), this.CenterTop());
        this.children[3] = new LodNode(this, this.lodProperties, this.lodLevel + 1, this.up, this.CenterMiddle(), this.TopRight());
    }

    private void Merge()
    {
        if (this.children == null)
        {
            return;
        }
        if (this.lodLevel == LodNode.MAX_LOD_LEVEL)
        {
            return;
        }
        foreach (LodNode child in this.children)
        {
            child.Dispose();
        }
        this.meshRenderer.enabled = true;
        this.children = null;
    }

    public bool ShouldSplit()
    {
        float minDistanceSqr = Mathf.Pow(LodNode.LodLevelToMinDistance(this.lodLevel), 2f);
        float cameraDistanceSqr = this.meshRenderer.bounds.SqrDistance(Camera.main.transform.position);
        return cameraDistanceSqr < minDistanceSqr;
    }

    public bool ShouldMerge()
    {
        float maxDistanceSqr = Mathf.Pow(LodNode.LodLevelToMaxDistance(this.lodLevel + 1), 2f);
        float cameraDistanceSqr = this.meshRenderer.bounds.SqrDistance(Camera.main.transform.position);
        return cameraDistanceSqr > maxDistanceSqr;
    }

    private static float LodLevelToMinDistance(int lodLevel)
    {
        if (lodLevel == LodNode.MAX_LOD_LEVEL)
        {
            return 0f;
        }
        else
        {
            return Mathf.Pow(2f, LodNode.MAX_LOD_LEVEL - lodLevel) / LodNode.DETAIL_FACTOR;
        }
    }

    private static float LodLevelToMaxDistance(int lodLevel)
    {
        if (lodLevel == 0)
        {
            return Mathf.Infinity;
        }
        else
        {
            return Mathf.Pow(2f, LodNode.MAX_LOD_LEVEL - lodLevel + 1) / LodNode.DETAIL_FACTOR;
        }
    }
}

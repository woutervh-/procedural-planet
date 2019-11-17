using System;
using UnityEngine;

public class LodNode : IDisposable
{
    private const int MAX_LOD_LEVEL = 10;
    private const int CHUNK_RESOLUTION = 16;
    private const float DETAIL_FACTOR = 512f;
    private const float DESIRED_EDGE_LENGTH = 6f;

    private LodNode parent;
    private LodProperties lodProperties;
    private int lodLevel;
    private Vector3 origin;
    private Vector3 forward;
    private Vector3 right;
    private LodNode[] children;
    private GameObject gameObject;
    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;
    private Mesh plane;

    public LodNode(LodNode parent, LodProperties lodProperties, int lodLevel, Vector3 origin, Vector3 forward, Vector3 right)
    {
        this.parent = parent;
        this.lodProperties = lodProperties;
        this.lodLevel = lodLevel;
        this.origin = origin;
        this.forward = forward;
        this.right = right;

        this.children = null;
        this.gameObject = new GameObject("Chunk " + lodLevel);
        this.gameObject.transform.SetParent(lodProperties.gameObject.transform, false);

        this.meshFilter = this.gameObject.AddComponent<MeshFilter>();
        this.meshRenderer = this.gameObject.AddComponent<MeshRenderer>();
        this.plane = new LodFace(LodNode.CHUNK_RESOLUTION, origin, lodProperties.up, forward, right).GenerateMesh();

        this.meshRenderer.sharedMaterial = lodProperties.material;
        this.meshFilter.mesh = this.plane;
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
        Vector3 childFoward = this.forward / 2f;
        Vector3 childRight = this.right / 2f;
        this.children = new LodNode[4];
        this.children[0] = new LodNode(this, this.lodProperties, this.lodLevel + 1, this.origin - childRight - childFoward, childFoward, childRight);
        this.children[1] = new LodNode(this, this.lodProperties, this.lodLevel + 1, this.origin + childRight - childFoward, childFoward, childRight);
        this.children[2] = new LodNode(this, this.lodProperties, this.lodLevel + 1, this.origin - childRight + childFoward, childFoward, childRight);
        this.children[3] = new LodNode(this, this.lodProperties, this.lodLevel + 1, this.origin + childRight + childFoward, childFoward, childRight);
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

    public void PrintDiagnostics()
    {
        Vector3[] corners = new Vector3[8];
        corners[0] = new Vector3(this.meshRenderer.bounds.min.x, this.meshRenderer.bounds.min.y, this.meshRenderer.bounds.min.z);
        corners[1] = new Vector3(this.meshRenderer.bounds.min.x, this.meshRenderer.bounds.min.y, this.meshRenderer.bounds.max.z);
        corners[2] = new Vector3(this.meshRenderer.bounds.min.x, this.meshRenderer.bounds.max.y, this.meshRenderer.bounds.min.z);
        corners[3] = new Vector3(this.meshRenderer.bounds.min.x, this.meshRenderer.bounds.max.y, this.meshRenderer.bounds.max.z);
        corners[4] = new Vector3(this.meshRenderer.bounds.max.x, this.meshRenderer.bounds.min.y, this.meshRenderer.bounds.min.z);
        corners[5] = new Vector3(this.meshRenderer.bounds.max.x, this.meshRenderer.bounds.min.y, this.meshRenderer.bounds.max.z);
        corners[6] = new Vector3(this.meshRenderer.bounds.max.x, this.meshRenderer.bounds.max.y, this.meshRenderer.bounds.min.z);
        corners[7] = new Vector3(this.meshRenderer.bounds.max.x, this.meshRenderer.bounds.max.y, this.meshRenderer.bounds.max.z);
        Vector3 min = new Vector3(Mathf.Infinity, Mathf.Infinity, Mathf.Infinity);
        Vector3 max = new Vector3(Mathf.NegativeInfinity, Mathf.NegativeInfinity, Mathf.NegativeInfinity);
        for (int i = 0; i < 8; i++)
        {
            Vector3 position = Camera.main.WorldToScreenPoint(corners[i]);
            min = Vector3.Min(min, position);
            max = Vector3.Max(max, position);
        }
        float width = max.x - min.x;
        float height = max.y - min.y;
        float size = Mathf.Max(width, height);
        float factor = size / LodNode.CHUNK_RESOLUTION / LodNode.DESIRED_EDGE_LENGTH;
        float lodLevel = Mathf.Log(factor, 2f);
        Debug.Log("(Width x Height): " + width + " x " + height + "; (LOD level): " + lodLevel + ";");
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

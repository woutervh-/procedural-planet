using System;
using UnityEngine;

public class LodNode : IDisposable
{
    private const int MAX_LOD_LEVEL = 10;
    private const int CHUNK_RESOLUTION = 16;

    private static Mesh plane = new LodFace(LodNode.CHUNK_RESOLUTION).GenerateMesh();

    private LodNode parent;
    private LodProperties lodProperties;
    private LodNode[] children;
    private int lodLevel;
    private GameObject gameObject;
    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;

    public LodNode(LodNode parent, LodProperties lodProperties, int lodLevel)
    {
        this.parent = parent;
        this.lodProperties = lodProperties;
        this.children = null;
        this.lodLevel = lodLevel;
        this.gameObject = new GameObject("Face " + lodLevel);
        this.meshFilter = this.gameObject.AddComponent<MeshFilter>();
        this.meshRenderer = this.gameObject.AddComponent<MeshRenderer>();

        this.meshRenderer.sharedMaterial = lodProperties.material;
        this.meshFilter.transform.parent = lodProperties.gameObject.transform;
        this.meshFilter.mesh = LodNode.plane;
    }

    public void Dispose()
    {
        UnityEngine.Object.Destroy(this.meshRenderer);
        UnityEngine.Object.Destroy(this.meshFilter);
        UnityEngine.Object.Destroy(this.gameObject);
    }

    public void SplitRecursive()
    {
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
        this.Merge();
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
        this.children[0] = new LodNode(this, this.lodProperties, this.lodLevel + 1);
        this.children[1] = new LodNode(this, this.lodProperties, this.lodLevel + 1);
        this.children[2] = new LodNode(this, this.lodProperties, this.lodLevel + 1);
        this.children[3] = new LodNode(this, this.lodProperties, this.lodLevel + 1);
    }

    private void Merge()
    {
        if (this.children == null)
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
        if (this.children != null)
        {
            return false;
        }
        float minDistanceSqr = Mathf.Pow(LodNode.LodLevelToMinDistance(this.lodLevel), 2f);
        float cameraDistanceSqr = this.meshRenderer.bounds.SqrDistance(Camera.main.transform.position);
        return cameraDistanceSqr < minDistanceSqr;
    }

    public bool ShouldMerge()
    {
        if (this.children == null)
        {
            return false;
        }
        float maxDistanceSqr = Mathf.Pow(LodNode.LodLevelToMaxDistance(this.lodLevel), 2f);
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
            return Mathf.Pow(2f, LodNode.MAX_LOD_LEVEL - lodLevel);
        }
    }

    private static float LodLevelToMaxDistance(int lodLevel)
    {
        if (lodLevel == 0)
        {
            return Mathf.NegativeInfinity;
        }
        else
        {
            return Mathf.Pow(2f, LodNode.MAX_LOD_LEVEL - lodLevel + 1);
        }
    }
}

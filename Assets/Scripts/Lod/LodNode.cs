using System;
using UnityEngine;

public class LodNode : IDisposable
{
    private const int MAX_LOD_LEVEL = 10;
    private const int CHUNK_RESOLUTION = 16;
    private const float DESIRED_EDGE_LENGTH = 6f;

    private LodNode parent;
    private LodProperties lodProperties;
    private int lodLevel;
    private Vector3 origin;
    private Vector3 forward;
    private Vector3 right;
    public LodNode[] children;
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
        this.plane = new LodFace(LodNode.CHUNK_RESOLUTION, lodProperties.heightGenerator, origin, lodProperties.up, forward, right).GenerateMesh();

        this.meshRenderer.sharedMaterial = lodProperties.material;
        this.meshFilter.mesh = this.plane;
    }

    public void Dispose()
    {
        UnityEngine.Object.Destroy(this.meshRenderer);
        UnityEngine.Object.Destroy(this.meshFilter);
        UnityEngine.Object.Destroy(this.gameObject);
    }

    public void ManageRecursive()
    {
        if (this.ShouldSplit())
        {
            this.Split();
            if (this.children != null)
            {
                foreach (LodNode child in this.children)
                {
                    child.ManageRecursive();
                }
            }
        }
        else
        {
            this.MergeRecursive();
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
        if (!this.ShouldSplit())
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

    private float DesiredLodLevel()
    {
        float edgeLength = LodFace.GetEdgeLength(LodNode.CHUNK_RESOLUTION);
        Vector3 scales = this.gameObject.transform.TransformVector(this.gameObject.transform.InverseTransformDirection(Vector3.one));
        float maxScale = Mathf.Max(scales.x, scales.y, scales.z);
        // float scaledEdgeLength = maxScale * edgeLength * this.lodProperties.heightGenerator.GetMaximumValue();
        float scaledEdgeLength = maxScale * edgeLength;
        float cameraDistance = Mathf.Sqrt(this.meshRenderer.bounds.SqrDistance(Camera.main.transform.position));
        if (cameraDistance == 0f)
        {
            return int.MaxValue;
        }
        Vector3 boundsPoint = Camera.main.WorldToScreenPoint(Camera.main.transform.position + Camera.main.transform.forward * cameraDistance);
        Vector3 offsetPoint = Camera.main.WorldToScreenPoint(Camera.main.transform.position + Camera.main.transform.forward * cameraDistance + Camera.main.transform.up * edgeLength);
        float unitVectorLength = offsetPoint.y - boundsPoint.y;
        float edgeLengthAtDistance = unitVectorLength * scaledEdgeLength;
        float tessellationFactor = edgeLengthAtDistance / LodNode.DESIRED_EDGE_LENGTH;
        float lodLevel = Mathf.Log(tessellationFactor, 6f);
        return lodLevel;
    }

    private bool ShouldSplit()
    {
        // float maxGeoError = Mathf.Pow(2f, LodNode.MAX_LOD_LEVEL - this.lodLevel - 10);
        // float K = Screen.height / (2f * Mathf.Tan((Camera.main.fieldOfView / 2f) * Mathf.Deg2Rad));
        // float maxVerError = (maxGeoError / Mathf.Sqrt(this.meshRenderer.bounds.SqrDistance(Camera.main.transform.position))) * K;
        // return maxVerError > 1f;
        return this.DesiredLodLevel() > this.lodLevel;
    }
}

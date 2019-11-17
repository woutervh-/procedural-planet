using UnityEngine;

public class LodManager : MonoBehaviour
{
    public Material material;

    private LodNode root;

    void Start()
    {
        LodProperties lodProperties = new LodProperties();
        lodProperties.gameObject = this.gameObject;
        lodProperties.material = this.material;
        this.root = new LodNode(null, lodProperties, 0, LodNode.RootMin, LodNode.RootMax);
    }

    void Update()
    {
        if (this.root.ShouldSplit())
        {
            this.root.SplitRecursive();
        }
        this.root.MergeRecursive();
    }
}

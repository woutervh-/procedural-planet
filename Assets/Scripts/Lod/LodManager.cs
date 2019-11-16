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
        this.root = new LodNode(null, lodProperties, 0);
    }

    void Update()
    {
        // this.mesh.bounds.SqrDistance(Camera.main.transform.position);
        if (Input.GetKeyDown(KeyCode.D))
        {
            Debug.Log("Should split: " + this.root.ShouldSplit());
            Debug.Log("Should merge: " + this.root.ShouldMerge());

            if (this.root.ShouldSplit())
            {
                this.root.SplitRecursive();
            }
            else if (this.root.ShouldMerge())
            {
                this.root.MergeRecursive();
            }
        }
    }
}

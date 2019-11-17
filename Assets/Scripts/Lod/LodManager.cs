using UnityEngine;

public class LodManager : MonoBehaviour
{
    private static Vector3[] directions = { Vector3.up, Vector3.down, Vector3.left, Vector3.right, Vector3.forward, Vector3.back };

    public Material material;

    private GameObject[] rootGameObjects;
    private LodNode[] roots;

    void Start()
    {
        this.rootGameObjects = new GameObject[6];
        this.roots = new LodNode[6];
        for (int i = 0; i < 6; i++)
        {
            this.rootGameObjects[i] = new GameObject("Face (" + i + ")");
            this.rootGameObjects[i].transform.parent = this.transform;

            LodProperties lodProperties = new LodProperties();
            lodProperties.gameObject = this.rootGameObjects[i];
            lodProperties.material = this.material;

            Vector3 up = LodManager.directions[i];
            this.roots[i] = new LodNode(null, lodProperties, 0, LodManager.directions[i], LodNode.RootMin, LodNode.RootMax);
        }
    }

    void Update()
    {
        foreach (LodNode root in this.roots)
        {
            root.SplitRecursive();
            root.MergeRecursive();
        }
    }
}

using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class PlanetMeshGenerator : MonoBehaviour
{
    private static Vector3[] directions = { Vector3.up, Vector3.down, Vector3.left, Vector3.right, Vector3.forward, Vector3.back };

    [SerializeField, HideInInspector]
    private GameObject[] meshObjects;
    [SerializeField, HideInInspector]
    private MeshFilter[] meshFilters;
    [SerializeField, HideInInspector]
    private MeshRenderer[] meshRenderers;

    void Awake()
    {
        this.GenerateMeshes();
    }

    void GenerateMeshes()
    {
        MeshRenderer meshRenderer = this.GetComponent<MeshRenderer>();

        this.meshObjects = new GameObject[6];
        this.meshFilters = new MeshFilter[6];
        this.meshRenderers = new MeshRenderer[6];

        for (int i = 0; i < 6; i++)
        {
            this.meshObjects[i] = new GameObject("Mesh");
            this.meshObjects[i].transform.parent = this.transform;

            this.meshRenderers[i] = this.meshObjects[i].AddComponent<MeshRenderer>();
            this.meshRenderers[i].material = meshRenderer.material;

            this.meshFilters[i] = this.meshObjects[i].AddComponent<MeshFilter>();
            this.meshFilters[i].mesh = new PlanetFace(PlanetMeshGenerator.directions[i], 10).GenerateMesh();

        }
    }
}

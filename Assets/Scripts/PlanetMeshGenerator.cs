using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class PlanetMeshGenerator : MonoBehaviour
{
    private const int NUM_RESOLUTIONS = 8;
    private const float MIN_EDGE_LENGTH = 2f;

    private static Vector3[] directions = { Vector3.up, Vector3.down, Vector3.left, Vector3.right, Vector3.forward, Vector3.back };

    [SerializeField, HideInInspector]
    private GameObject[] meshObjects;
    [SerializeField, HideInInspector]
    private MeshFilter[] meshFilters;
    [SerializeField, HideInInspector]
    private Material material;
    private Mesh[] meshes;
    private int[] resolutions;

    void Start()
    {
        this.material = this.GetComponent<MeshRenderer>().material;
        this.GenerateMeshes();
        this.GenerateObjects();
        this.GenerateFilters();
        this.InitializeSurfaces();
    }

    void Update()
    {
        for (int i = 0; i < 6; i++)
        {
            Vector3[] corners = new Vector3[8];
            Vector3 meshMin = this.meshes[this.meshes.Length - 1].bounds.min;
            Vector3 meshMax = this.meshes[this.meshes.Length - 1].bounds.max;
            corners[0] = new Vector3(meshMin.x, meshMin.y, meshMin.z);
            corners[1] = new Vector3(meshMin.x, meshMin.y, meshMax.z);
            corners[2] = new Vector3(meshMin.x, meshMax.y, meshMin.z);
            corners[3] = new Vector3(meshMin.x, meshMax.y, meshMax.z);
            corners[4] = new Vector3(meshMax.x, meshMin.y, meshMin.z);
            corners[5] = new Vector3(meshMax.x, meshMin.y, meshMax.z);
            corners[6] = new Vector3(meshMax.x, meshMax.y, meshMin.z);
            corners[7] = new Vector3(meshMax.x, meshMax.y, meshMax.z);
            Vector3 screenMin = new Vector3(Mathf.Infinity, Mathf.Infinity, Mathf.Infinity);
            Vector3 screenMax = new Vector3(Mathf.NegativeInfinity, Mathf.NegativeInfinity, Mathf.NegativeInfinity);
            foreach (Vector3 corner in corners)
            {
                Vector3 screenPoint = Camera.main.WorldToScreenPoint(this.meshFilters[i].transform.TransformPoint(corner));
                screenMin = Vector3.Min(screenMin, screenPoint);
                screenMax = Vector3.Max(screenMax, screenPoint);
            }
            Vector3 screenSize = screenMax - screenMin;
            float measure = Mathf.Max(screenSize.x, screenSize.y) / 64f / PlanetMeshGenerator.MIN_EDGE_LENGTH;
            int resolution = Mathf.Clamp((int)Mathf.Log(measure, 2f), 0, PlanetMeshGenerator.NUM_RESOLUTIONS - 1);

            if (this.resolutions[i] != resolution)
            {
                this.resolutions[i] = resolution;
                this.SetMesh(i, resolution);
            }
        }
    }

    void SetMesh(int index, int resolution)
    {
        this.meshFilters[index].mesh = this.meshes[resolution];
    }

    void InitializeSurfaces()
    {
        this.resolutions = new int[6];
        for (int i = 0; i < 6; i++)
        {
            this.resolutions[i] = 0;
            this.SetMesh(i, 0);
        }
    }

    void GenerateMeshes()
    {
        this.meshes = new Mesh[PlanetMeshGenerator.NUM_RESOLUTIONS];
        for (int i = 0; i < PlanetMeshGenerator.NUM_RESOLUTIONS; i++)
        {
            this.meshes[i] = new PlanetFace(Vector3.up, (int)Mathf.Pow(2, i + 1)).GenerateMesh();
        }
    }

    void GenerateObjects()
    {
        this.meshObjects = new GameObject[6];
        for (int i = 0; i < 6; i++)
        {
            this.meshObjects[i] = new GameObject("Mesh");
            this.meshObjects[i].transform.SetParent(this.transform, false);
            this.meshObjects[i].transform.rotation = this.GetRotation(i);
            this.meshObjects[i].AddComponent<MeshRenderer>().material = this.material;
        }
    }

    void GenerateFilters()
    {
        this.meshFilters = new MeshFilter[6];
        for (int i = 0; i < 6; i++)
        {
            this.meshFilters[i] = this.meshObjects[i].AddComponent<MeshFilter>();
            this.meshFilters[i].mesh = this.meshes[0];
        }
    }

    Quaternion GetRotation(int index)
    {
        Quaternion quaternion = new Quaternion();
        quaternion.SetFromToRotation(Vector3.up, PlanetMeshGenerator.directions[index]);
        return quaternion;
    }
}

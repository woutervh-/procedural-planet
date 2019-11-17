using UnityEngine;

public class LodFace
{
    private int resolution;

    public LodFace(int resolution)
    {
        this.resolution = resolution;
    }

    public Mesh GenerateMesh()
    {
        Mesh mesh = new Mesh();
        Vector3[] vertices = new Vector3[this.resolution * this.resolution];
        Vector3[] normals = new Vector3[this.resolution * this.resolution];
        int[] triangles = new int[(this.resolution - 1) * (this.resolution - 1) * 6];

        int triangleIndex = 0;
        for (int y = 0; y < this.resolution; y++)
        {
            for (int x = 0; x < this.resolution; x++)
            {
                int vertexIndex = x + this.resolution * y;
                Vector2 percent = new Vector2(x, y) / (resolution - 1);
                Vector3 pointOnUnitCube = (percent.x - 0.5f) * 2f * Vector3.forward + (percent.y - 0.5f) * 2f * Vector3.right;
                // Vector3 pointOnUnitSphere = pointOnUnitCube.normalized;
                Vector3 pointOnUnitSphere = pointOnUnitCube;
                vertices[vertexIndex] = pointOnUnitSphere;
                normals[vertexIndex] = Vector3.up;

                if (x != resolution - 1 && y != resolution - 1)
                {
                    triangles[triangleIndex] = vertexIndex;
                    triangles[triangleIndex + 1] = vertexIndex + resolution + 1;
                    triangles[triangleIndex + 2] = vertexIndex + resolution;
                    triangles[triangleIndex + 3] = vertexIndex;
                    triangles[triangleIndex + 4] = vertexIndex + 1;
                    triangles[triangleIndex + 5] = vertexIndex + resolution + 1;
                    triangleIndex += 6;
                }
            }
        }

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.normals = normals;
        mesh.RecalculateTangents();
        mesh.RecalculateBounds();

        return mesh;
    }
}

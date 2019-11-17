using UnityEngine;

public class LodFace
{
    private int resolution;
    private Vector3 origin;
    private Vector3 up;
    private Vector3 forward;
    private Vector3 right;

    public LodFace(int resolution, Vector3 origin, Vector3 up, Vector3 forward, Vector3 right)
    {
        this.resolution = resolution;
        this.origin = origin;
        this.up = up;
        this.forward = forward;
        this.right = right;
    }

    public static Vector3 GetForward(Vector3 up)
    {
        return new Vector3(up.y, up.z, up.x);
    }

    public static Vector3 GetRight(Vector3 up)
    {
        return Vector3.Cross(up, LodFace.GetForward(up));
    }

    public static float GetEdgeLengthSqr(int resolution, Vector3 forward, Vector3 right)
    {
        float percent = 1f / (resolution - 1);
        float edgeLengthSqr = Mathf.Max(forward.sqrMagnitude, right.sqrMagnitude) * percent * 2f;
        return edgeLengthSqr;
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
                Vector3 pointOnUnitCube = this.origin + Mathf.Lerp(-1f, 1f, percent.x) * this.forward + Mathf.Lerp(-1f, 1f, percent.y) * this.right;
                Vector3 pointOnUnitSphere = pointOnUnitCube.normalized;

                // vertices[vertexIndex] = pointOnUnitCube;
                // normals[vertexIndex] = this.up;

                vertices[vertexIndex] = pointOnUnitSphere;
                normals[vertexIndex] = pointOnUnitSphere;

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

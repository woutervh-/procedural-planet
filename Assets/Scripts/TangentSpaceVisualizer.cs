using UnityEngine;

public class TangentSpaceVisualizer : MonoBehaviour
{
    public float offset = 0.01f;
    public float scale = 1f;

    void OnDrawGizmos()
    {
        {
            MeshFilter filter = GetComponent<MeshFilter>();
            if (filter)
            {
                this.ShowTangentSpace(filter);
            }
        }
        MeshFilter[] filters = this.GetComponentsInChildren<MeshFilter>(false);
        foreach (MeshFilter filter in filters)
        {
            this.ShowTangentSpace(filter);
        }
    }

    void ShowTangentSpace(MeshFilter filter)
    {
        Vector3[] vertices = filter.mesh.vertices;
        Vector3[] normals = filter.mesh.normals;
        Vector4[] tangents = filter.mesh.tangents;

        if (normals == null || normals.Length <= 0)
        {
            return;
        }

        if (tangents == null || tangents.Length <= 0)
        {
            for (int i = 0; i < vertices.Length; i++)
            {
                this.ShowTangentSpace(
                    filter.transform.TransformPoint(vertices[i]),
                    filter.transform.TransformDirection(normals[i])
                );
            }
        }
        else
        {
            for (int i = 0; i < vertices.Length; i++)
            {
                this.ShowTangentSpace(
                    filter.transform.TransformPoint(vertices[i]),
                    filter.transform.TransformDirection(normals[i]),
                    filter.transform.TransformDirection(tangents[i]),
                    tangents[i].w
                );
            }
        }
    }

    void ShowTangentSpace(Vector3 vertex, Vector3 normal)
    {
        vertex += normal * offset;
        Gizmos.color = Color.red;
        Gizmos.DrawLine(vertex, vertex + normal * scale);
    }

    void ShowTangentSpace(Vector3 vertex, Vector3 normal, Vector3 tangent, float binormalSign)
    {
        vertex += normal * offset;
        Gizmos.color = Color.red;
        Gizmos.DrawLine(vertex, vertex + normal * scale);
        Gizmos.color = Color.green;
        Gizmos.DrawLine(vertex, vertex + tangent * scale);
        Vector3 binormal = Vector3.Cross(normal, tangent) * binormalSign;
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(vertex, vertex + binormal * scale);
    }
}

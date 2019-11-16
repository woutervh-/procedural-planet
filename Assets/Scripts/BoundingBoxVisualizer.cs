using UnityEngine;

public class BoundingBoxVisualizer : MonoBehaviour
{
    void OnDrawGizmos()
    {
        {
            MeshFilter filter = GetComponent<MeshFilter>();
            if (filter)
            {
                this.ShowBounds(filter);
            }
        }
        MeshFilter[] filters = this.GetComponentsInChildren<MeshFilter>(false);
        foreach (MeshFilter filter in filters)
        {
            this.ShowBounds(filter);
        }
    }

    void ShowBounds(MeshFilter filter)
    {
        Vector3 p000 = filter.transform.TransformPoint(new Vector3(filter.mesh.bounds.min.x, filter.mesh.bounds.min.y, filter.mesh.bounds.min.z));
        Vector3 p001 = filter.transform.TransformPoint(new Vector3(filter.mesh.bounds.min.x, filter.mesh.bounds.min.y, filter.mesh.bounds.max.z));
        Vector3 p010 = filter.transform.TransformPoint(new Vector3(filter.mesh.bounds.min.x, filter.mesh.bounds.max.y, filter.mesh.bounds.min.z));
        Vector3 p011 = filter.transform.TransformPoint(new Vector3(filter.mesh.bounds.min.x, filter.mesh.bounds.max.y, filter.mesh.bounds.max.z));
        Vector3 p100 = filter.transform.TransformPoint(new Vector3(filter.mesh.bounds.max.x, filter.mesh.bounds.min.y, filter.mesh.bounds.min.z));
        Vector3 p101 = filter.transform.TransformPoint(new Vector3(filter.mesh.bounds.max.x, filter.mesh.bounds.min.y, filter.mesh.bounds.max.z));
        Vector3 p110 = filter.transform.TransformPoint(new Vector3(filter.mesh.bounds.max.x, filter.mesh.bounds.max.y, filter.mesh.bounds.min.z));
        Vector3 p111 = filter.transform.TransformPoint(new Vector3(filter.mesh.bounds.max.x, filter.mesh.bounds.max.y, filter.mesh.bounds.max.z));

        Gizmos.color = Color.yellow;

        // Bottom lines.
        Gizmos.DrawLine(p000, p001);
        Gizmos.DrawLine(p001, p101);
        Gizmos.DrawLine(p101, p100);
        Gizmos.DrawLine(p100, p000);

        // Middle lines.
        Gizmos.DrawLine(p000, p010);
        Gizmos.DrawLine(p001, p011);
        Gizmos.DrawLine(p101, p111);
        Gizmos.DrawLine(p100, p110);

        // Top lines.
        Gizmos.DrawLine(p010, p011);
        Gizmos.DrawLine(p011, p111);
        Gizmos.DrawLine(p111, p110);
        Gizmos.DrawLine(p110, p010);
    }
}

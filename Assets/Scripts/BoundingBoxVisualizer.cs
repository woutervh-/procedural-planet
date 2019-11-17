using UnityEngine;

public class BoundingBoxVisualizer : MonoBehaviour
{
    void OnDrawGizmos()
    {
        {
            MeshRenderer renderer = GetComponent<MeshRenderer>();
            if (renderer)
            {
                this.ShowBounds(renderer);
            }
        }
        MeshRenderer[] renderers = this.GetComponentsInChildren<MeshRenderer>(false);
        foreach (MeshRenderer renderer in renderers)
        {
            this.ShowBounds(renderer);
        }
    }

    void ShowBounds(MeshRenderer renderer)
    {
        Vector3 p000 = new Vector3(renderer.bounds.min.x, renderer.bounds.min.y, renderer.bounds.min.z);
        Vector3 p001 = new Vector3(renderer.bounds.min.x, renderer.bounds.min.y, renderer.bounds.max.z);
        Vector3 p010 = new Vector3(renderer.bounds.min.x, renderer.bounds.max.y, renderer.bounds.min.z);
        Vector3 p011 = new Vector3(renderer.bounds.min.x, renderer.bounds.max.y, renderer.bounds.max.z);
        Vector3 p100 = new Vector3(renderer.bounds.max.x, renderer.bounds.min.y, renderer.bounds.min.z);
        Vector3 p101 = new Vector3(renderer.bounds.max.x, renderer.bounds.min.y, renderer.bounds.max.z);
        Vector3 p110 = new Vector3(renderer.bounds.max.x, renderer.bounds.max.y, renderer.bounds.min.z);
        Vector3 p111 = new Vector3(renderer.bounds.max.x, renderer.bounds.max.y, renderer.bounds.max.z);

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

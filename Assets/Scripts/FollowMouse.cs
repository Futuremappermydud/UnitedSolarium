using LlamAcademy.Spring;
using UnityEngine;

public class FollowMouse : MonoBehaviour
{
    public SpringVector2 position = new SpringVector2()
    {
        Damping = 10000f,
        Stiffness = 500f,
        Mass = 0.1f
    };
    public float damping = 10000f;
    public float stiffness = 500f;
    public float mass = 0.1f;
    public Material material;
    public bool on;

    public FloatSpring rotation = new FloatSpring()
    {
        Damping = 10000f,
        Stiffness = 500f,
        Mass = 0.1f
    };
    void Start()
    {
        
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            on = !on;
        }
        if (!on)
            return;
        position.Damping = damping;
        position.Stiffness = stiffness;
        position.Mass = mass;

        position.Evaluate(Time.deltaTime);
        position.UpdateEndValue(new Vector3(Input.mousePosition.x, Input.mousePosition.y, 0.0f) * 2f - new Vector3(Screen.width, Screen.height, 0.0f));
        material.SetFloat("_PosX", position.CurrentValue.x);
        material.SetFloat("_PosY", position.CurrentValue.y);
        transform.localPosition = new Vector3(Input.mousePosition.x, Input.mousePosition.y, 0.0f)-new Vector3(Screen.width, Screen.height, 0.0f) / 2f;


    }
}

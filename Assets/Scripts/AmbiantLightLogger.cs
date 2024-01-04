using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AmbiantLightLogger : MonoBehaviour
{
    // Update is called once per frame
    void Update()
    {
        // Get the ambient light color from RenderSettings
        Color ambientColor = RenderSettings.ambientLight;

        // Print the ambient light color to the Unity Console
        Debug.Log("Ambient Light Color: " + ambientColor);
    }
}

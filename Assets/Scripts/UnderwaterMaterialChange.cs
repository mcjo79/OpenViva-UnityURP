using UnityEngine;

namespace viva
{

    public class UnderwaterMaterialChange : MonoBehaviour
    {

        [SerializeField]
        private MeshRenderer[] targetMRs;
        [SerializeField]
        private Material underwaterMaterial;
        [SerializeField]
        private Material replaceMaterial;
        [SerializeField]
        public bool useFog = false;
        [SerializeField]
        private SkyDirector.FogOverride fog = new SkyDirector.FogOverride();

        private Material[] cachedMaterials;

        private void Awake()
        {
            cachedMaterials = new Material[targetMRs.Length];
        }

        public void OnEnterUnderwater()
        {
            if (GameDirector.instance.postProcessing.IncreaseScreenTextureUse(targetMRs, underwaterMaterial))
            {
                if (targetMRs == null || targetMRs.Length == 0)
                {
                    Debug.LogError("No target mesh renderer found!");
                    return;
                }
                if (replaceMaterial != null)
                {
                    replaceMaterial.mainTexture = GameDirector.instance.postProcessing.screenTexture;
                    for (int i = 0; i < cachedMaterials.Length; i++)
                    {
                        var mr = targetMRs[i];
                        if (mr == null)
                        {
                            continue;
                        }
                        cachedMaterials[i] = mr.material;
                        mr.material = replaceMaterial;
                    }
                }
                else
                {
                    foreach (var mr in targetMRs)
                    {
                        mr.enabled = false;
                    }
                }
                if (useFog)
                {
                    GameDirector.skyDirector.SetFogOverride(fog);
                }
            }
        }

        public void OnExitUnderwater()
        {
            if (GameDirector.instance.postProcessing.DecreaseScreenTextureUse(targetMRs))
            {
                if (replaceMaterial != null)
                {
                    for (int i = 0; i < cachedMaterials.Length; i++)
                    {
                        var mr = targetMRs[i];
                        if (mr == null)
                        {
                            continue;
                        }
                        mr.material = cachedMaterials[i];
                    }
                }
                else
                {
                    foreach (var mr in targetMRs)
                    {
                        mr.enabled = true;
                    }
                }
                if (useFog)
                {
                    GameDirector.skyDirector.SetFogOverride(null);
                }
            }
        }
    }

}
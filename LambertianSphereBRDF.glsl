// Implementation of fast BRDF from
// "An analytic BRDF for materials with spherical Lambertian scatterers" 
// (d'Eon 2021, winner of EGSR Best Paper)
// https://developer.nvidia.com/blog/nvidia-research-an-analytic-brdf-for-materials-with-spherical-lambertian-scatterers/
const vec3 lightCol = vec3(1.0, 1.0, 1.0);
const float PI = 3.141592653589;
const vec3 kd = vec3(0.5, 0.25, 0.12);  // Diffuse color parameterization.
const vec3 c = (1.0 - pow(1.0 - kd, vec3(2.73556))) / (1.0 - 0.184096*pow(1.0 - kd, vec3(2.48423)));
const float whitePoint = 1.0;

// From https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code.
float intersectSphere(vec3 ro, vec3 rd, vec3 center, float rad) {
    ro -= center;
    float b = dot(ro, rd);
    float c = dot(ro, ro) - rad*rad;
    if (c > 0.0f && b > 0.0) return -1.0;
    float discr = b*b - c;
    if (discr < 0.0) return -1.0;
    // Special case: inside sphere, use far discriminant
    if (discr > b*b) return (-b + sqrt(discr));
    return -b - sqrt(discr);
}

float safeacos(const float x) {
    return acos(clamp(x, -1.0, 1.0));
}

float phase(float u) {
    return (2.0*(sqrt(1.0 - u*u) - u*acos(u)))/(3.0*PI*PI);
}

vec3 shadeLambertianSphereBRDF(vec3 wi, vec3 wo, vec3 norm) { 
    float ui = dot(wi, norm);
    float uo = dot(wo, norm);
    if (ui <= 0.0 || uo <= 0.0) return vec3(0.0);
    
    float ui2 = ui*ui;
    float uo2 = uo*uo;
    float S = sqrt((1.0-ui2)*(1.0-uo2));
    float cp = -((-dot(wi, wo) + ui*uo)/S);
    float phi = safeacos(cp);
    float iodot = dot(wi, wo);
    
    // Single-Scattering component, corresponds to "f_1" in the paper.
    vec3 SS = c*(phase(-iodot) / (ui + uo));
    
    // These next two blocks are identical. The first block is a copy of the implementation from
    // https://github.com/eugenedeon/mitsuba/blob/master/src/bsdfs/lambert_sphere_fast.cpp
    // The second block is a literal coding of Equation 48 from the paper.
#if 1
    float p = ui * uo;
    return PI * uo * max(
        vec3(0.0), 
        0.995917*SS+(0.0684744*(((phi+sqrt(p))*(-0.249978+c)/(4.50996*((safeacos(S)/S)+0.113706)))+pow(max(1.94208*kd,0.0),vec3(1.85432))))
    );
    
#else
    vec3 fr = max( 
        vec3(0.0), 
        SS + 0.234459*pow(kd, vec3(1.85432)) \
           + (0.0151829*(c-0.24998)*(abs(phi)+sqrt(ui*uo))) / (0.113706 + (safeacos(S)/S))
    );
    return PI * uo * fr;
#endif
}

vec3 shadeLambertBRDF(vec3 wi, vec3 wo, vec3 norm) {
    return kd * (lightCol * clamp(dot(norm, wo), 0.0, 1.0));
}

vec3 adjustExposureGamma(vec3 col) {
    col /= whitePoint;
    col = pow(col, vec3(1.0/2.2));
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 xy = 2.0 * (fragCoord.xy / iResolution.xy) - 1.0;
    vec3 rayDir = vec3(0.0, 0.0, -1.0);
    vec3 rayOrigin = vec3(2.0*xy*vec2((iResolution.x / iResolution.y), 1.0), 10.0);
    
    float lightAngle = PI*(iTime/5.0 + 0.5);
    vec3 lightPos = vec3(-cos(lightAngle)*10.0, 0.0, sin(lightAngle)*10.0);
    
    vec3 center = vec3(1.5, 0.0, 0.0);
    float rad = 1.3;
    float t = intersectSphere(rayOrigin, rayDir, center, rad);
    if (t >= 0.0) {
        vec3 position = rayOrigin+t*rayDir;
        vec3 norm = normalize(position-center);
        vec3 offsetLightPos = lightPos+center;
        vec3 lightDir = normalize(offsetLightPos-position);
        
        vec3 col = shadeLambertianSphereBRDF(-rayDir, lightDir, norm);
        fragColor = vec4(adjustExposureGamma(col), 1.0);
        return;
    }
    
    center = vec3(-1.5, 0.0, 0.0);
    t = intersectSphere(rayOrigin, rayDir, center, rad);
    if (t >= 0.0) {
        vec3 position = rayOrigin+t*rayDir;
        vec3 norm = normalize(position-center);
        vec3 offsetLightPos = lightPos+center;
        vec3 lightDir = normalize(offsetLightPos-position);
        
        vec3 col = shadeLambertBRDF(-rayDir, lightDir, norm);
        fragColor = vec4(adjustExposureGamma(col), 1.0);
        return;
    }
    
    fragColor = vec4(vec3(0.0), 1.0);
}
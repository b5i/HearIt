//
//  SpotlightShader.metal
//  WWDC24
//
//  Created by Antoine Bollengier on 08.02.2024.
//

#include <metal_stdlib>
using namespace metal;

/*
float distance(float2 a, float2 b) {
    return sqrt(pow(a[0] - b[0], 2) + pow(a[1] - b[1], 2));
}
*/

union Seed {
    float fl;
    uint32_t seed;
};

Seed generateRandomNumber(Seed s) {
    for (int i = 0; i<3; i++) {
        s.seed ^= s.seed << 13;
        s.seed ^= s.seed >> 17;
        s.seed ^= s.seed << 5;
    }
        
    return s;
}

/*
 
 [[ stitchable ]] half4 spotlight(float2 position, half4 currentColor, float2 center, float radiusArea) {
 half4 result = half4(1.0, 1.0, 1.0, 1.0);
 float distanceFromCenter = distance(position, center);
 if (distanceFromCenter > radiusArea * 1.5) {
 half4 returnColor = currentColor * 0.2;
 returnColor[3] = 1;
 return returnColor;
 } else if (distanceFromCenter > radiusArea * 1.25) {
 half4 returnColor = currentColor * ((distanceFromCenter / radiusArea) - 1);
 returnColor[3] = 1;
 return returnColor;
 } else if (distanceFromCenter > radiusArea) {
 half4 returnColor = currentColor;
 Seed rand;
 rand.seed = position[0] * position[1];
 float result;
 modf(generateRandomNumber(rand).fl, result);
 returnColor *= result;
 returnColor[3] = 1;
 return returnColor;
 } else {
 half4 returnColor = currentColor;
 returnColor[3] = 1;
 return returnColor;
 }
 return result;
 }
 
 */

[[ stitchable ]] half4 spotlight(float2 position, half4 currentColor, float2 center, float areaRadius) {
    const float fadeDistance = 1.25 * areaRadius;
    const float minimumLight = 0.3; // the multiplier that will be applied to the color components of every pixel that is out the spotlight's light and the fadeDistance
    const float spotlightEffectLight = 0.15; // the percentage that colors will be increased for the pixels under the spotlight
    
    float distanceFromCenter = distance(position, center);
    if (distanceFromCenter > areaRadius /* fadeDistance */) {
        half4 returnColor = currentColor;
        
        returnColor[0] *= minimumLight;
        returnColor[1] *= minimumLight;
        returnColor[2] *= minimumLight;
        return returnColor;
    //} else if (distanceFromCenter > areaRadius) {
    //    float multiplier = sin(((distanceFromCenter / areaRadius) - 1) * 4 /* 1/0.25 */ * (3.14 / 2));
    //    half4 returnColor = currentColor;
    //
    //    returnColor[0] = min(returnColor[0] * multiplier, 1.0);
    //    returnColor[1] = min(returnColor[1] * multiplier, 1.0);
    //    returnColor[2] = min(returnColor[2] * multiplier, 1.0);

    //    return returnColor;
        
    } else {
        half4 returnColor = currentColor;
        
        returnColor[0] = min(returnColor[0] + spotlightEffectLight, 1.0);
        returnColor[1] = min(returnColor[1] + spotlightEffectLight, 1.0);
        returnColor[2] = min(returnColor[2] + spotlightEffectLight, 1.0);
        
        return returnColor;
    }
}

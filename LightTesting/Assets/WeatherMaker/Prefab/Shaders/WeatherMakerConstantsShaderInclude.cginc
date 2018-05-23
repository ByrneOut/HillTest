//
// Weather Maker for Unity
// (c) 2016 Digital Ruby, LLC
// Source code may be used for personal or commercial projects.
// Source code may NOT be redistributed or sold.
// 
// *** A NOTE ABOUT PIRACY ***
// 
// If you got this asset off of leak forums or any other horrible evil pirate site, please consider buying it from the Unity asset store at https ://www.assetstore.unity3d.com/en/#!/content/60955?aid=1011lGnL. This asset is only legally available from the Unity Asset Store.
// 
// I'm a single indie dev supporting my family by spending hundreds and thousands of hours on this and other assets. It's very offensive, rude and just plain evil to steal when I (and many others) put so much hard work into the software.
// 
// Thank you.
//
// *** END NOTE ABOUT PIRACY ***
//

#ifndef __WEATHER_MAKER_SHADER_CONSTANTS__
#define __WEATHER_MAKER_SHADER_CONSTANTS__

#include "UnityCG.cginc"

#if defined(UNITY_COLORSPACE_GAMMA)
#define GAMMA 2
#define COLOR_2_GAMMA(color) color
#define COLOR_2_LINEAR(color) color * color
#define LINEAR_2_OUTPUT(color) sqrt(color)
#else
#define GAMMA 2.2
#define COLOR_2_GAMMA(color) ((unity_ColorSpaceDouble.r>2.0) ? pow(color,1.0/GAMMA) : color)
#define COLOR_2_LINEAR(color) color
#define LINEAR_2_LINEAR(color) color
#endif

#define float4Zero float4(0.0, 0.0, 0.0, 0.0)
#define float4One float4(1.0, 1.0, 1.0, 1.0)
#define fixed4Zero fixed4(0.0, 0.0, 0.0, 0.0)
#define fixed4One fixed4(1.0, 1.0, 1.0, 1.0)
#define float3Zero float3(0.0, 0.0, 0.0)
#define float3One float3(1.0, 1.0, 1.0)
#define fixed3Zero fixed3(0.0, 0.0, 0.0)
#define fixed3One fixed3(1.0, 1.0, 1.0)
#define ditherMagic fixed4(12.9898, 78.233, 43758.5453, 241325690.2135)
#define upVector float3(0.0, 1.0, 0.0)

#ifndef PI
#define PI 3.14159263
#endif

#ifndef PI2
#define PI2 (PI * 2.0)
#endif

#define WM_BASE_VERTEX_INPUT UNITY_VERTEX_INPUT_INSTANCE_ID
#define WM_BASE_VERTEX_TO_FRAG UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO

#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
#define WM_INSTANCE_VERT(v, type, o) type o; UNITY_SETUP_INSTANCE_ID(v); UNITY_TRANSFER_INSTANCE_ID(v, o); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); int eyeIndex = o.stereoTargetEyeIndex;
#else
#define WM_INSTANCE_VERT(v, type, o) type o; int eyeIndex = unity_StereoEyeIndex;
#endif

#define WM_INSTANCE_FRAG(i) UNITY_SETUP_INSTANCE_ID(i); UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

#define WM_SAMPLE_DEPTH(uv) UNITY_SAMPLE_DEPTH(SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4((uv).xy, 0.0, 0.0)))
#define WM_SAMPLE_DEPTH_PROJ(uv) UNITY_SAMPLE_DEPTH(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(uv)))

// vertex...
struct vertex_only_input_data
{
	float4 vertex : POSITION;
	WM_BASE_VERTEX_INPUT
};

struct vertex_uv_normal
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
	WM_BASE_VERTEX_INPUT
};

struct full_screen_vertex
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	WM_BASE_VERTEX_INPUT
};

// fragment...
struct volumetric_data
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 projPos : TEXCOORD0;
	float3 rayDir : TEXCOORD1;
	float3 viewPos : TEXCOORD2;
	float3 worldPos : TEXCOORD3;
	WM_BASE_VERTEX_TO_FRAG
};

struct full_screen_fragment
{
	float4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 forwardLine : NORMAL;
	WM_BASE_VERTEX_TO_FRAG
};

struct deferred_fragment
{
	float4 gBuffer0 : SV_Target0;
	float4 gBuffer1 : SV_Target1;
	float4 gBuffer2 : SV_Target2;
	float4 gBuffer3 : SV_Target3;
};

struct frag_out_with_depth
{
	fixed4 color : COLOR;
	float depth : DEPTH;
};

struct v2fShadow
{
	float4 vertex : POSITION;
	float3 worldPos : TEXCOORD0;
};

uniform float4 _WeatherMakerTime;
uniform float4 _WeatherMakerTimeSin;

inline float PointBoxIntersect(float3 pos, float3 boxMin, float3 boxMax)
{
	float3 inBoxStep = step(boxMin, pos) - step(boxMax, pos);
	return inBoxStep.x * inBoxStep.y * inBoxStep.z;
}

inline float RayBoxIntersect(float3 rayOrigin, float3 rayDir, float rayLength, float3 boxMin, float3 boxMax, out float intersectAmount, out float distanceToBox)
{
	// https://tavianator.com/fast-branchless-raybounding-box-intersections/

	/*
	Aos::Vector3 t1(Aos::mulPerElem(m_min - ray.m_pos, ray.m_invDir));
	Aos::Vector3 t2(Aos::mulPerElem(m_max - ray.m_pos, ray.m_invDir));

	Aos::Vector3 tmin1(Aos::minPerElem(t1, t2));
	Aos::Vector3 tmax1(Aos::maxPerElem(t1, t2));

	float tmin = Aos::maxElem(tmin1);
	float tmax = Aos::minElem(tmax1);

	return tmax >= std::max(ray.m_min, tmin) && tmin < ray.m_max;
	*/

	float3 invRayDir = 1.0 / rayDir;
	float3 t1 = (boxMin - rayOrigin) * invRayDir;
	float3 t2 = (boxMax - rayOrigin) * invRayDir;
	float3 tmin1 = min(t1, t2);
	float3 tmax1 = max(t1, t2);
	float tmin = max(max(tmin1.x, tmin1.y), tmin1.z);
	float tmax = min(min(tmax1.x, tmax1.y), tmax1.z);
	float2 tt0 = max(tmin1.xx, tmin1.yz);
	distanceToBox = max(0.0, max(tt0.x, tt0.y));
	tt0 = min(tmax1.xx, tmax1.yz);
	float tt1 = min(tt0.x, tt0.y);
	tt1 = min(tt1, rayLength);
	intersectAmount = max(0.0, tt1 - distanceToBox);

	return intersectAmount > 0.0001;
}

// spherePosition is x,y,z,radius squared
inline float RaySphereIntersect(float3 rayOrigin, float3 rayDir, float rayLength, float4 spherePosition, out float intersectAmount, out float distanceToSphere)
{
	// optimized version, seems to work as well, but watch out for artifacts
	// https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code
	float3 sphereCenter = rayOrigin - spherePosition.xyz;
	float b = dot(rayDir, sphereCenter);
	float c = dot(sphereCenter, sphereCenter) - spherePosition.w;
	float discr = (b * b) - c;
	float t = sqrt(discr * (discr > 0.0));
	b = -b;
	distanceToSphere = clamp(b - t, 0.0, rayLength);
	intersectAmount = clamp(b + t, 0.0, rayLength);
	intersectAmount = intersectAmount - distanceToSphere;

	/* // older version which is known to work in all cases
	// http://www.cosinekitty.com/raytrace/chapter06_sphere.html
	float3 sphereCenter = rayOrigin - spherePosition.xyz;
	float fA = dot(rayDir, rayDir);
	float fB = 2.0 * dot(rayDir, sphereCenter);
	float fC = dot(sphereCenter, sphereCenter) - spherePosition.w;
	float fD = (fB * fB) - (4.0 * fA * fC);
	float recpTwoA = (fD > 0.0) * (0.5 / fA);
	float DSqrt = sqrt(fD);
	fB = -fB;

	// the distance to the front of sphere - will be 0 if in sphere or miss
	distanceToSphere = clamp((fB - DSqrt) * recpTwoA, 0.0, rayLength);

	// total distance to the back of the sphere, will be 0 if miss
	intersectAmount = clamp((fB + DSqrt) * recpTwoA, 0.0, rayLength);

	// get intersect amount - we know that distance to back of sphere is greater than distance to front of sphere at this point
	intersectAmount = intersectAmount - distanceToSphere;
	*/

	return intersectAmount > 0.0001;
}

inline float PointPlaneDistanceSquared(float3 planeNormal, float3 planePos, float3 p)
{
	return dot(planeNormal, p - planePos);
}

// return 0 if no intersect
inline float RayPlaneIntersect(float3 rayOrigin, float3 rayDir, float3 planeNormal, float3 planePos, out float distanceToPlane)
{
	float denom = dot(planeNormal, rayDir);
	distanceToPlane = dot(planePos - rayOrigin, planeNormal) / denom;
	return (denom > 0.0001 && distanceToPlane > 0.0001);
}

// distanceToPlane becomes distance to disc center
// intersectsDisc is true if the plane intersect is within the disc
inline void RayPlaneDiscIntersect(float3 rayOrigin, float3 rayDir, float3 planeCenter, float discRadiusSquared, inout float distanceToPlane, out float intersectsDisc)
{
	float3 planeIntersect = (rayOrigin + (rayDir * distanceToPlane));
	float3 planeIntersectLocal = planeIntersect - planeCenter;
	float distanceFromDiscCenter = dot(planeIntersectLocal, planeIntersectLocal);
	distanceToPlane = distance(planeIntersect, rayOrigin);
	intersectsDisc = (distanceFromDiscCenter < discRadiusSquared);
}

inline float LinePointDistanceSquared(float3 lineStart, float3 lineDir, float3 p)
{
	// http://wiki.unity3d.com/index.php?title=3d_Math_functions

	// distance vector from point to line start
	float3 linePointToPoint = p - lineStart;

	// distance from line start in lineDir direction where point p is closest
	float t = dot(linePointToPoint, lineDir); 

	// point on line where p is closest
	float3 onLine = lineStart + (lineDir * t);

	// distance from point to line point
	onLine = onLine - p;

	// return squared distance
	return dot(onLine, onLine);
}

inline float LineLineClosestDistanceSquared(float3 line1Point1, float3 line1Point2, float3 line2Point1, float3 line2Point2, out float3 closePoint1, out float3 closePoint2)
{
	float3 u = line1Point2 - line1Point1;
	float3 v = line2Point2 - line2Point1;
	float3 w = line1Point1 - line2Point1;
	float a = dot(u, u);         // always >= 0
	float b = dot(u, v);
	float c = dot(v, v);         // always >= 0
	float d = dot(u, w);
	float e = dot(v, w);
	float D = a * c - b * b;        // always >= 0
	float sc, tc;

	// compute the line parameters of the two closest points
	if (D < 0.0001)
	{
		// the lines are almost parallel
		sc = 0.0;
		tc = (b > c ? d / b : e / c);    // use the largest denominator
	}
	else
	{
		sc = (b * e - c * d) / D;
		tc = (a * e - b * d) / D;
	}

	// get the difference of the two closest points
	closePoint1 = w + (sc * u);
	closePoint2 = (tc * v);
	float3 dP = closePoint1 - closePoint2; // =  L1(sc) - L2(tc)

										   // return norm(dP);   // return the closest distance
	return dot(dP, dP);
}

// coneposition is xyz, range
// conedir is xyz, end radius squared
// coneatten is cos(angle * 0.5)
// coneend is base center xyz, slant squared
inline float RayConeIntersect(float3 rayOrigin, float3 rayDir, float rayLength, float4 conePosition, float4 coneDir, float4 coneEnd, float coneAtten, out float intersectAmount, out float distanceToCone)
{
	float2 t;

	// https://www.geometrictools.com/GTEngine/Include/Mathematics/GteIntrLine3Cone3.h
	// https://www.shadertoy.com/view/4s23DR
	// https://github.com/mayank127/raytracer/blob/master/object.cpp
	float3 PmV = rayOrigin - conePosition.xyz;
	float DdU = dot(coneDir.xyz, rayDir);
	float DdPmV = dot(coneDir.xyz, PmV);
	float UdPmV = dot(rayDir, PmV);
	float PmVdPmV = dot(PmV, PmV);
	float halfCosAngle = coneAtten.x * coneAtten.x;
	float c2 = DdU * DdU - halfCosAngle;
	float c1 = DdU * DdPmV - halfCosAngle * UdPmV;
	float c0 = DdPmV * DdPmV - halfCosAngle * PmVdPmV;
	float discr = c1 * c1 - c0 * c2;
	discr *= (discr > 0.0);
	float root = sqrt(discr);
	float invC2 = (1.0 / c2);
	c1 = -c1;
	t.y = (c1 - root) * invC2;
	t.x = (c1 + root) * invC2;

	// zero out negative cone
	t *= (DdPmV + (DdU * t) > 0.0);

	if (t.x == 0.0 && t.y == 0.0)
	{
		intersectAmount = 0.0;
		distanceToCone = 0.0;
		return false;
	}
	else
	{
		// intersect cone base (disc) and subsitute where appropriate
		float distanceToPlane1, distanceToPlane2;
		float hasCap1, hasCap2;

		// case 1: ray passes down through cone disc plane
		// handle case where the ray passes down through the cone disc plane
		float intersectPlane1 = RayPlaneIntersect(rayOrigin, rayDir, coneDir.xyz, coneEnd.xyz, distanceToPlane1);
		RayPlaneDiscIntersect(rayOrigin, rayDir, coneEnd.xyz, coneDir.w, distanceToPlane1, hasCap1);

		// if hasCap, y becomes cap intersect, else y is min of distance to plane or y
		t.y = (intersectPlane1 * ((distanceToPlane1 * hasCap1) + (min(distanceToPlane1, t.y) * !hasCap1))) + (t.y * !intersectPlane1);
		// ---

		// case 2: ray passes up through cone disc plane
		// handle case where the ray passes up through the cone disc plane
		float intersectPlane2 = RayPlaneIntersect(rayOrigin, rayDir, -coneDir.xyz, coneEnd.xyz, distanceToPlane2);
		RayPlaneDiscIntersect(rayOrigin, rayDir, coneEnd.xyz, coneDir.w, distanceToPlane2, hasCap2);

		// if hasCap, x becomes cap intersect, else x is un-modified
		t.x = (intersectPlane2 * ((distanceToPlane2 * hasCap2) + (t.x * !hasCap2))) + (t.x * !intersectPlane2);

		// if the plane intersect is closer than the distance to the back cone intersect, y is unmodified, else y is 0
		t.y *= (!intersectPlane2 || distanceToPlane2 < t.y);
		// ---

		// case 3: ray does not pass through cone disc plane
		// handle case where ray does not intersect the cone disc plane
		// point must be within slant distance, else throw it out (squared distance for performance)
		float3 distanceVector = rayOrigin + (rayDir * t.y) - conePosition.xyz;
		t.y *= (intersectPlane1 || intersectPlane2 || dot(distanceVector, distanceVector) < coneEnd.w);

		// clamp results to ray length, remove negative values
		distanceToCone = clamp(t.x, 0.0, rayLength);
		intersectAmount = clamp(t.y, 0.0, rayLength);
		intersectAmount = max(0.0, intersectAmount - distanceToCone);

		return intersectAmount > 0.0001;
	}
}

inline float3 RotatePointZeroOriginQuaternion(float3 position, float4 quat)
{
	// https://twistedpairdevelopment.wordpress.com/2013/02/11/rotating-a-vector-by-a-quaternion-in-glsl/
	return position + 2.0 * cross(cross(position, quat.xyz) + quat.w * position, quat.xyz);
}

inline float4 QuaternionFromAxisAngle(float3 axis, float angle)
{
	float half_angle = angle * 0.5;
	return float4(axis.xyz * sin(half_angle), cos(half_angle));
}

inline float RandomFloat(float3 v)
{
	return (frac(frac(dot(v.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453) - 0.5) * 2.0;
	//return frac(sin(dot(v.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
}

inline float RandomFloat01(float3 v)
{
	return (frac(frac(dot(v.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453));
}

#endif

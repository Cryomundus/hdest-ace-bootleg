#define desatlevel 0.9

void SetupMaterial( inout Material mat )
{
	vec4 color = getTexel(vTexCoord.st);
	float gray = (color.r+color.g+color.b)/3.0;
	mat.Base = vec4(mix(color.rgb,vec3(gray),desatlevel),color.a);
	mat.Normal = ApplyNormalMap(vTexCoord.st);
}

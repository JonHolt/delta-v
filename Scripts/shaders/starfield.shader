
// Much of this code was adapted from: https://www.shadertoy.com/view/MtB3zW
shader_type canvas_item;

uniform int RES = 5;
uniform vec2 offset = vec2(0.0, 0.0);

varying vec2 vtx;

vec2 rand2(vec2 p)
{
	p = vec2(dot(p, vec2(12.9898,78.233)), dot(p, vec2(26.65125, 83.054543))); 
	return fract(sin(p) * 43758.5453);
}

float rand(vec2 p)
{
	return fract(sin(dot(p.xy ,vec2(54.90898,18.233))) * 4337.5453);
}

// Thanks to David Hoskins https://www.shadertoy.com/view/4djGRh
float stars(in vec2 x, float numCells, float size, float br)
{
	vec2 n = x * numCells;
	vec2 f = floor(n);

	float d = 1.0e10;
	for (int i = -1; i <= 1; ++i)
	{
		for (int j = -1; j <= 1; ++j)
		{
			vec2 g = f + vec2(float(i), float(j));
			g = n - g - rand2(mod(g, numCells)) + rand(g);
			// Control size
			g *= 1. / (numCells * size);
			d = min(d, dot(g, g));
		}
	}

	return br * (smoothstep(.95, 1., (1. - sqrt(d))));
}

vec4 mainImage(vec2 fragCoord)
{
	//vec2 st = fragCoord.xy / viewport_size.xy;
	//st.y *= viewport_size.y/viewport_size.x;
	vec3 result = stars(fragCoord * 20.0, 4., 0.06, 0.6) * vec3(.9, .9, .95);
	
	return vec4(result, 1.);
}

void vertex()
{
	vtx = VERTEX + offset;
}

void fragment()
{
	COLOR = mainImage(vtx * float(RES));
}
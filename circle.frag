#define t iTime             //
#define r iResolution.xy    //屏幕像素比

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 c;
    float l,z=t;
    
    // 把坐标规范化为[0,1]
    vec2 uv, p = fragCoord/r;
    uv=p;
    // 把坐标范围变为[-.5, .5]
    p-=.5;
    // p的x坐标考虑屏幕宽高比
    p.x *= r.x/r.y;
    // 距离场：p到原点的距离。距离作为颜色返回
    l = length(p);
    // 采用一个循环为颜色赋值
    for(int i=0;i<3;i++) {
        //把屏幕上每个像素坐标变为随时间波动的曲线
        uv+=p/l*(sin(z)+1.)*abs(sin(l*9.-z*2.));
        c[i] =0.05/length(abs(fract(uv)-.5));
    }
    
    fragColor = vec4(c,t);
}
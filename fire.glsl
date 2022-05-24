//by 834144373 

// I just want to make a flame...please help me!!! //寻求老外帮助，想做做得更好看的颜色

// I try it!!!
#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

void main( void ) {

    vec2 pos = ( gl_FragCoord.xy / resolution.xy )*8.-vec2(4.,5.); //位移坐标原点

    if(pos.y>-6.){
        pos.y += 0.1*sin(time*3.)+0.13*cos(time*2.+0.6)+.1*sin(time*3.+0.4)+0.2*fract(sin(time*400.));  //火苗在y轴上的动态效果，
    }

    vec3 color = vec3(0.,0.,0.0); 

    float p =.004; //二次函数的p，即抛物线

    float y = -pow(pos.x,3.2)/(2.*p)*3.3; //二次函数计算y


    float dir = length(pos-vec2(pos.x,y))*sin(0.3);//视窗所有点到该函数所表示的点的距离

    if(dir < 0.7){
        color.rg += smoothstep(0.0,1.,.75-dir); //在颜色上多次调色的经验值
        color.g /=2.4; //绿色与红色适配，多次调色的经验值
    }
    color += pow(color.r,1.1); //加深火的亮度和渐变

    gl_FragColor = vec4(vec3(color) , 1.0 );

}
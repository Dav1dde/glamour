/**
If compiled with version=Derelict3 glamour will use Derelict3 as OpenGL backend, otherwise Derelict2.
If glamour gets compiled with Derelict3, you can not load textures from images with DevIL!
*/


module glamour.gl;

version(glad) {
    public import glad.gl.gl;
} else version(Derelict3) {
    public import derelict.opengl3.gl3;
} else version(Derelict2) {
    public import derelict.opengl.gl;
    public import derelict.opengl.glext;
} else {
    static assert(false, "Requires at least \"glad\", \"Derelict2\" or \"Derelict3\", via -version");
}
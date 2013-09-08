module example;

import std.string;
import std.conv;
import std.stdio;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import glamour.vao: VAO;
import glamour.shader: Shader;
import glamour.vbo: Buffer, ElementBuffer;

/// ATTENTION! All shaders are placed in the single source.
/// Source contains up to three shaders: vertex shader,
/// geometry shader and fragment shader.
/// Every shader are prefixed by tag to separate from the others.
/// Tags are:
///     "vertex:"
///     "geometry:"
///     "fragment:"
/// Tag shall be the first token in the line and the rest of the line is ignored.
/// Shaders may be ordered in any way. But a shader will be replaced
/// by the next shader with the same tag - so there is only one shader with
/// the specific tag at the moment.
/// Directives are placed in the beginning of the source, not every shader and
/// effect on the total source consequently.
immutable string example_program_src_ = `
        #version 120
        vertex:
        attribute vec2 position;
        void main(void)
        {
            gl_Position = vec4(position, 0, 1);
        }
        fragment:
        void main(void)
        {
            gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
        }
        `;

float[] vertices;
ushort[] indices;
// attribute
GLint position;

VAO vao;
Shader program;
Buffer vbo;
ElementBuffer ibo;

void main() {
    DerelictSDL2.load();
    DerelictGL3.load();

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        throw new Exception("Failed to initialize SDL: " ~ to!string(SDL_GetError()));
    }

    // Set OpenGL version
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);

    // Set OpenGL attributes
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    auto sdlwindow = SDL_CreateWindow("Glamour example application",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        640, 480, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);

    if (!sdlwindow)
        throw new Exception("Failed to create a SDL window: " ~ to!string(SDL_GetError()));

    SDL_GL_CreateContext(sdlwindow);
    DerelictGL3.reload();

    vertices = [ -0.3, -0.3,  0.3, -0.3,  -0.3, 0.3,  0.3, 0.3];
    indices = [0, 1, 2, 3];

    vao = new VAO();
    vao.bind();

    // Create vertex buffer object
    vbo = new Buffer(vertices);

    // Create element buffer
    ibo = new ElementBuffer(indices);

    // Create program
    program = new Shader("example_program", example_program_src_);
    program.bind();
    position = program.get_attrib_location("position");

    auto run = true;
    while (run) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            switch (event.type) {
                case SDL_QUIT:
                    run = false;
                break;
                default:
                break;
            }
        }

        glClearColor(1, 0.9, 0.8, 1);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        // make our vbo as the current buffer
        vbo.bind();
        // enable attribute 'position'
        glEnableVertexAttribArray(position);
        // say where data lay that will be used as attribute 'position'
        glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, 0, null);
        // make element buffer current
        ibo.bind();
        // draw element from current element buffer
        glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, null);
        // disable attribute 'position'
        glDisableVertexAttribArray(position);

        SDL_GL_SwapWindow(sdlwindow);
    }

    // free resources
    ibo.remove();
    vbo.remove();
    program.remove();
    vao.remove();
}

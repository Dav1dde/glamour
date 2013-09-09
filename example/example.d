module example;

import std.string;
import std.conv;
import std.stdio;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import glamour.vao: VAO;
import glamour.shader: Shader;
import glamour.vbo: Buffer, ElementBuffer;

class Renderer
{
private:
    uint width_, height_;

    float[] vertices;
    ushort[] indices;
    GLint position_;

    VAO vao_;
    Shader program_;
    Buffer vbo_;
    ElementBuffer ibo_;

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
    static immutable string example_program_src_ = `
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

public:
    this()
    {
        vertices = [ -0.3, -0.3,  0.3, -0.3,  -0.3, 0.3,  0.3, 0.3];
        indices = [0, 1, 2, 3];

        vao_ = new VAO();
        vao_.bind();

        // Create VBO
        vbo_ = new Buffer(vertices);

        // Create IBO
        ibo_ = new ElementBuffer(indices);

        // Create program
        program_ = new Shader("example_program", example_program_src_);
        program_.bind();
        position_ = program_.get_attrib_location("position");
    }

    void draw()
    {
        glClearColor(1, 0.9, 0.8, 1);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        vbo_.bind();
        glEnableVertexAttribArray(position_);
     
        glVertexAttribPointer(position_, 2, GL_FLOAT, GL_FALSE, 0, null);
     
        ibo_.bind();
     
        glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, null);
     
        glDisableVertexAttribArray(position_);
    }

    void close()
    {
        // free resources
        ibo_.remove();
        vbo_.remove();
        program_.remove();
        vao_.remove();
    }
}

class SDLApplication
{
    private SDL_Window* sdlwindow_;
    private OnDraw on_draw_;
    
    alias void delegate() OnDraw;
    
    @property
    onDraw(OnDraw on_draw) 
    { 
        assert(on_draw);
        on_draw_ = on_draw; 
    }

    this()
    {
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

        sdlwindow_ = SDL_CreateWindow("Glamour example application",
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
            640, 480, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);

        if (!sdlwindow_)
            throw new Exception("Failed to create a SDL window: " ~ to!string(SDL_GetError()));

        SDL_GL_CreateContext(sdlwindow_);
        DerelictGL3.reload();
    }

    void run()
    {
        assert(on_draw_);
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

            on_draw_();

            SDL_GL_SwapWindow(sdlwindow_);
        }
    }
}

void main() {
    
    auto app = new SDLApplication();

    auto renderer = new Renderer();
    scope(exit)
        renderer.close();

    app.onDraw = &renderer.draw;
    app.run();
}

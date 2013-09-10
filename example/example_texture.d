module example_texture;

import std.string;
import std.conv;
import std.stdio;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

import glamour.vao: VAO;
import glamour.shader: Shader;
import glamour.vbo: Buffer, ElementBuffer;
import glamour.texture: Texture2D;

class Renderer
{
private:
    uint width_, height_;

    float[] vertices_, texture_coords_;
    ushort[] indices_;
    GLint position_, tex_coord_;

    VAO vao_;
    Shader program_;
    Buffer vbo_, tbo_;
    ElementBuffer ibo_;
    Texture2D texture_;

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
        in vec2 position;
        in vec2 inCoord;

        out vec2 texCoord;
        void main(void)
        {
            gl_Position = vec4(position, 0, 1);
            texCoord = inCoord;
        }
        fragment:
        in vec2 texCoord;
        out vec4 outputColor;

        uniform sampler2D gSampler;

        void main(void)
        {
            outputColor = texture2D(gSampler, texCoord);
        }
        `;

public:
    this()
    {
        vertices_ = [ -0.3, -0.3,  0.3, -0.3,  -0.3, 0.3,  0.3, 0.3 ];
        indices_ = [0, 1, 2, 3];
        texture_coords_ = [ 0.00, 0.00,  01.00, 0.00,  0.00, 01.00,  01.00, 01.00 ];

        vao_ = new VAO();
        vao_.bind();

        // Create VBO
        vbo_ = new Buffer(vertices_);

        // Create IBO
        ibo_ = new ElementBuffer(indices_);

        // Create buffer object for texture coordinates
        tbo_ = new Buffer(texture_coords_);
        texture_ = Texture2D.from_image("example/texture.jpeg");
        texture_.set_parameter(GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        texture_.set_parameter(GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        // Create program
        program_ = new Shader("example_program", example_program_src_);
        program_.bind();
        position_ = program_.get_attrib_location("position");
        tex_coord_ = program_.get_attrib_location("inCoord");
    }

    void draw()
    {
        glClearColor(1, 0.9, 0.8, 1);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        vbo_.bind();
        glEnableVertexAttribArray(position_);
     
        glVertexAttribPointer(position_, 2, GL_FLOAT, GL_FALSE, 0, null);
     
        ibo_.bind();

        tbo_.bind();
        texture_.bind_and_activate();
        glEnableVertexAttribArray(tex_coord_);
        glVertexAttribPointer(tex_coord_, 2, GL_FLOAT, GL_FALSE, 0, null);
     
        glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, null);
     
        glDisableVertexAttribArray(tex_coord_);     
        glDisableVertexAttribArray(position_);
    }

    void close()
    {
        // free resources
        texture_.remove();
        tbo_.remove();
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
        DerelictSDL2Image.load();

        if (SDL_Init(SDL_INIT_VIDEO) < 0) {
            throw new Exception("Failed to initialize SDL: " ~ to!string(SDL_GetError()));
        }

        // Set OpenGL version
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);

        // Set OpenGL attributes
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

        sdlwindow_ = SDL_CreateWindow("Glamour texture example application",
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

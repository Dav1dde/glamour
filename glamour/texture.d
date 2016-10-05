module glamour.texture;

private {
    import glamour.gl : GLenum, GLuint, GLint, GLsizei, GL_UNSIGNED_BYTE,
                        glGenTextures, glBindTexture, glActiveTexture,
                        glTexImage1D, glTexImage2D, glTexImage3D, glTexParameteri, glTexParameterf,
                        glGetTexParameterfv, glDeleteTextures, GL_TEXTURE0,
                        GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_2D_ARRAY, GL_PROXY_TEXTURE_2D_ARRAY,
                        GL_PROXY_TEXTURE_3D, GL_TEXTURE_3D, GL_TEXTURE_BORDER_COLOR,
                        GL_RGBA8, GL_RGB, GL_RGBA, glGenerateMipmap;
    
    version(stb) {
        import stb_image : stbi_load, stbi_image_free;
    } else version(SDLImage2) {
        import derelict.sdl2.sdl;
        import derelict.sdl2.image;
        version = _glad_sdl;
    } else version(SDLImage) {
        import derelict.sdl.sdl;
        import derelict.sdl.image;
        version = _glad_sdl;
    }
    
    import glamour.util : glenum2size, checkgl;
    import std.traits : isPointer;
    import std.string : toStringz;
    import std.exception : enforce;
    import std.conv : to;

    debug import std.stdio : stderr;
}


/// This exception will be thrown if Texture2D.from_image fails to open the image.
class TextureException : Exception {
    this(string msg) {
        super(msg);
    }
}
deprecated alias TextureException TextureError;

/// Every Texture-Class will mixin this template.
mixin template CommonTextureMethods() {
    ~this() {
        debug if(texture != 0) stderr.writefln("OpenGL: %s resources not released.", typeof(this).stringof);
    }

    /// Deletes the texture.
    void remove() {
        checkgl!glDeleteTextures(1, &texture);
        texture = 0;
    }
    
    /// Sets a texture parameter.
    void set_parameter(T)(GLuint name, T params) if(is(T : int) || is(T : float)) {
        static if(is(T : int)) {
            checkgl!glTexParameteri(target, name, params);
        } else {
            checkgl!glTexParameterf(target, name, params);
        }
    }
    
    /// Queries a texture parameter from OpenGL.    
    float[] get_parameter(GLuint name) {
        float[] ret;
        
        if(name == GL_TEXTURE_BORDER_COLOR) {
            ret.length = 4;
        } else {
            ret.length = 1;
        }
        
        checkgl!glGetTexParameterfv(target, name, ret.ptr);
        return ret;
    }
    
    /// Generates mipmaps for the textre (also binds it)
    void generate_mipmaps() {
        bind();
        checkgl!glGenerateMipmap(target);
    }

    /// Binds the texture.
    void bind() {
        checkgl!glBindTexture(target, texture);
    }
    
    /// Activates the texture to $(I unit), passed to the function. 
    void activate(GLuint unit) {
        checkgl!glActiveTexture(unit);
    }
    
    /// Activates the texture to $(B unit), the struct member.
    void activate() {
        activate(unit);
    }
    
    /// Binds the texture and activates it to $(I unit), passed to the function. 
    void bind_and_activate(GLuint unit) {
        checkgl!glBindTexture(target, texture);
        checkgl!glActiveTexture(unit);
    }
    
    /// Binds the texture and activates it to $(B unit), the struct member.
    void bind_and_activate() {
        bind_and_activate(unit);
    }
    
    /// Unbinds the texture.
    void unbind() {
        checkgl!glBindTexture(target, 0);
    }
}

/// Interface every Texture implements.
interface ITexture {
    GLuint get_unit(); ///
    void remove(); ///
    void set_parameter(T)(GLuint name, T params); ///
    float[] get_parameter(GLuint name); /// 
    void set_data(T)(T data); /// 
    void generate_mipmaps(); ///
    void bind(); /// 
    void activate(GLuint unit); /// 
    void activate(); /// 
    void bind_and_activate(GLuint unit); /// 
    void bind_and_activate(); /// 
    void unbind(); /// 
}


/// Represents an OpenGL 1D texture.
/// The constructor must be used to avoid segmentation faults.
class Texture1D : ITexture {
    static const GLenum target = GL_TEXTURE_1D;
    
    /// The OpenGL texture name.
    GLuint texture;
    /// Alias this to texture.
    alias texture this;
    
    /// Holds the internal format passed to the constructor.
    GLint internal_format;
    /// Holds the format of the pixel data.
    GLenum format;
    /// Holds the OpenGL data type of the pixel data.
    GLenum type;
    /// Holds the texture unit.
    GLuint unit;
    GLuint get_unit() { return unit; }
    
    ///
    mixin CommonTextureMethods;
    
    /// Generates the OpenGL texture and initializes the struct.
    /// Params:
    /// unit_ = Specifies the OpenGL texture uinit.
    this(GLenum unit=GL_TEXTURE0) {
        this.unit = unit;
        
        checkgl!glGenTextures(1, &texture);
    }
        
    /// Sets the texture data.
    /// Params:
    /// data = A pointer to the image data or an array of the image data.
    /// internal_format = Specifies the number of color components in the texture.
    /// width = If data is an array and width is -1, the width will be infered from the array, otherwise it must be valid.
    /// format = Specifies the format of the pixel data.
    /// type = Specifies the data type of the pixel data.
    ///
    /// See_Also:
    /// OpenGL, http://www.opengl.org/sdk/docs/man4/xhtml/glTexImage1D.xml
    void set_data(T)(T data, GLint internal_format, int width, GLenum format, GLenum type) {
        bind();

        this.internal_format = internal_format;
        this.format = format;
        this.type = type;
        
        static if(isPointer!T) {
            auto d = data;
        } else {
            auto d = data.ptr;

            if(width == -1) {
                width = cast(int)data.length;
            }
        }

        checkgl!glTexImage1D(GL_TEXTURE_1D, 0, internal_format, width, 0, format, type, d);
    }
}

/// Represents an OpenGL 2D texture.
/// The constructor must be used to avoid segmentation faults.
class Texture2D : ITexture {
    static const GLenum target = GL_TEXTURE_2D;

    /// The OpenGL texture name.
    GLuint texture;
    /// Alias this to texture.
    alias texture this;

    /// Holds the internal format passed to the constructor.
    GLint internal_format;
    /// Holds the texture width.
    GLsizei width;
    /// Holds the texture height.
    GLsizei height;
    /// Holds the format of the pixel data.
    GLenum format;
    /// Holds the OpenGL data type of the pixel data.
    GLenum type;
    /// Holds the texture unit.
    GLenum unit;
    GLuint get_unit() { return unit; }
    /// If true (default) mipmaps will be generated with glGenerateMipmap.
    bool mipmaps = true;
        
    mixin CommonTextureMethods;
    
    /// Generates the OpenGL texture and initializes the struct.
    /// Params:
    /// unit = Specifies the OpenGL texture uinit.
    this(GLenum unit=GL_TEXTURE0) {
        this.unit = unit;

        checkgl!glGenTextures(1, &texture);
    }
    
    /// Sets the texture data.
    /// Params:
    /// data = A pointer to the image data or an array of the image data.
    /// internal_format = Specifies the number of color components in the texture.
    /// width = Specifies the width of the texture image.
    /// height = Specifies the height of the texture image.
    /// format = Specifies the format of the pixel data.
    /// type = Specifies the data type of the pixel data.
    /// mipmaps = Enables mipmap-generation.
    /// level = Specifies the level-of-detail number. Level 0 is the base image level. Level n is the n th mipmap reduction image.
    ///
    /// See_Also:
    /// OpenGL, http://www.opengl.org/sdk/docs/man4/xhtml/glTexImage2D.xml
    ///
    /// $(RED If mipmaps is true, the gl extensions must be loaded, otherwise bad things will happen!)
    void set_data(T)(T data, GLint internal_format, GLsizei width, GLsizei height,
                     GLenum format, GLenum type, bool mipmaps=true, GLint level=0) {
        bind();

        this.internal_format = internal_format;
        this.width = width;
        this.height = height;
        this.format = format;
        this.type = type;
        this.mipmaps = mipmaps;
        
        static if(isPointer!T) {
            auto d = data;
        } else {
            auto d = data.ptr;
        }
        
        checkgl!glTexImage2D(GL_TEXTURE_2D, level, internal_format, width, height, 0, format, type, d);
        
        if(mipmaps) {
            checkgl!glGenerateMipmap(GL_TEXTURE_2D);
        }
    }
    
    version(stb) {
        /// Loads an image and afterwards loads it into a Texture2D struct.
        /// Image can be loaded by stb and SDLImage. To select
        /// specific way use versions stb, SDLImage2 (SDL2) or SDLImage (SDL1).
        ///
        /// $(RED SDLImage must be loaded and initialized manually!)
        static Texture2D from_image(string filename) {
            auto tex = new Texture2D();

            int x;
            int y;
            int comp;
            ubyte* data = stbi_load(toStringz(filename), &x, &y, &comp, 0);
            scope(exit) stbi_image_free(data);

            if(data is null) {
                throw new TextureException("Unable to load image: " ~ filename);
            }
            
            uint image_format;
            switch(comp) {
                case 3: image_format = GL_RGB; break;
                case 4: image_format = GL_RGBA; break;
                default: throw new TextureException("Unknown/Unsupported stbi image format");
            }

            tex.set_data(data, image_format, x, y, image_format, GL_UNSIGNED_BYTE);

            return tex;
        }
    } else version (_glad_sdl) {
        static Texture2D from_image(string filename) {
            auto tex = new Texture2D();

            // make sure the texture has the right side up
            //thanks to tito http://stackoverflow.com/questions/5862097/sdl-opengl-screenshot-is-black
            SDL_Surface* flip(SDL_Surface* surface) {
                SDL_Surface* result = SDL_CreateRGBSurface(surface.flags, surface.w, surface.h,
                                                        surface.format.BytesPerPixel * 8, surface.format.Rmask, surface.format.Gmask,
                                                        surface.format.Bmask, surface.format.Amask);

                ubyte* pixels = cast(ubyte*) surface.pixels;
                ubyte* rpixels = cast(ubyte*) result.pixels;
                uint pitch = surface.pitch;
                uint pxlength = pitch * surface.h;

                assert(result != null);

                for(uint line = 0; line < surface.h; ++line) {
                    uint pos = line * pitch;
                    rpixels[pos..pos+pitch] = pixels[(pxlength-pos)-pitch..pxlength-pos];
                }

                return result;
            }

            auto surface = IMG_Load(filename.toStringz());

            enforce(surface, new TextureException("Error loading image " ~ filename ~ ": " ~ to!string(SDL_GetError())));
            scope(exit) SDL_FreeSurface(surface);

            enforce(surface.format.BytesPerPixel == 3 || surface.format.BytesPerPixel == 4, "With SDLImage Glamour supports loading images only with 3 or 4 bytes per pixel format.");
            auto image_format = GL_RGB;

            if (surface.format.BytesPerPixel == 4) {
            image_format = GL_RGBA;
            }

            auto flipped = flip(surface);
            tex.set_data(flipped.pixels, image_format, surface.w, surface.h, image_format, GL_UNSIGNED_BYTE);
            SDL_FreeSurface(flipped);

            return tex;
        }
    }
}

/// Base class, which represents an OpenGL 3D or 2D array texture.
/// The constructor must be used to avoid segmentation faults.
class Texture3DBase(GLenum target_) : ITexture {
    static assert(target_ == GL_TEXTURE_3D || target_ == GL_PROXY_TEXTURE_3D ||
                  target_ == GL_TEXTURE_2D_ARRAY || target_ == GL_PROXY_TEXTURE_2D_ARRAY);
    
    static const GLenum target = target_;

    /// The OpenGL texture name.
    GLuint texture;
    /// Alias this to texture.
    alias texture this;

    /// Holds the internal format passed to the constructor.
    GLint internal_format;
    /// Holds the texture width.
    GLsizei width;
    /// Holds the texture height.
    GLsizei height;
    /// Holds the texture depth or texture array length.
    GLsizei depth;
    /// Holds the format of the pixel data.
    GLenum format;
    /// Holds the OpenGL data type of the pixel data.
    GLenum type;
    /// Holds the texture unit.
    GLuint unit;
    GLuint get_unit() { return unit; }

    ///
    mixin CommonTextureMethods;

    /// Generates the OpenGL texture and initializes the struct.
    /// Params:
    /// unit = Specifies the OpenGL texture uinit.
    this(GLenum unit=GL_TEXTURE0) {
        this.unit = unit;

        checkgl!glGenTextures(1, &texture);
    }

    /// Sets the texture data.
    /// Params:
    /// data = A pointer to the image data or an array of the image data.
    /// internal_format = Specifies the number of color components in the texture.
    /// width = Specifies the width of the texture image.
    /// height = Specifies the height of the texture image.
    /// depth = Specifies the depth of the texture image, or the number of layers in a texture array.
    /// format = Specifies the format of the pixel data.
    /// type = Specifies the data type of the pixel data.
    ///
    /// See_Also:
    /// http://www.opengl.org/sdk/docs/man4/xhtml/glTexImage3D.xml
    void set_data(T)(T data, GLint internal_format, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, GLint level=0) {
        bind();

        this.internal_format = internal_format;
        this.width = width;
        this.height = height;
        this.depth = depth;
        this.format = format;
        this.type = type;

        static if(isPointer!T) {
            auto d = data;
        } else {
            auto d = data.ptr;
        }

        checkgl!glTexImage3D(target, level, internal_format, width, height, depth, 0, format, type, d);
    }
}

alias Texture3DBase!(GL_TEXTURE_3D) Texture3D;
alias Texture3DBase!(GL_TEXTURE_2D_ARRAY) Texture2DArray;

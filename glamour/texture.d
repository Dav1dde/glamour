module glamour.texture;

private {
    import glamour.gl : GLenum, GLuint, GLint, GLsizei, GL_UNSIGNED_BYTE,
                        glGenTextures, glBindTexture, glActiveTexture,
                        glTexImage1D, glTexImage2D, glTexParameteri, glTexParameterf,
                        glGetTexParameterfv, glDeleteTextures, GL_TEXTURE0,
                        GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR,
                        GL_RGBA8, GL_RGB, GL_RGBA, glGenerateMipmap;
    
    version(stb) {
        import stb_image : stbi_load, stbi_image_free;
    } else {
        import derelict.devil.il : ILuint, ilGenImages, ilBindImage, ilLoadImage, ilConvertImage,
                                   ilGetData, ilGetInteger, IL_RGB, IL_UNSIGNED_BYTE,
                                   IL_IMAGE_FORMAT, IL_IMAGE_TYPE, IL_IMAGE_WIDTH, IL_IMAGE_HEIGHT;
    }
    
    import glamour.util : glenum2size;
    import std.traits : isPointer;
    import std.string : toStringz;
    
    debug {
        import std.stdio : writefln;
    }
}


/// This exception will be raised if Texture2D.from_image fails to open the image.
class TextureError : Exception {
    this(string msg) {
        super(msg);
    }
}


/// Every Texture*-Struct will mixin this template.
mixin template CommonTextureMethods() {
    /// Returns the texture unit
    GLuint get_unit() { return unit; }

    /// Sets a texture parameter.
    void set_paramter(T)(GLuint name, T params) if(is(T : int) || is(T : float)) {
        static if(is(T : int)) {
            glTexParameteri(target, name, params);
        } else {
            glTexParameterf(target, name, params);
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
        
        glGetTexParameterfv(target, name, ret.ptr);
        return ret;
    }
    
    /// Binds the texture.
    void bind() {
        glBindTexture(target, texture);
    }
    
    /// Activates the texture to $(I unit), passed to the function. 
    void activate(GLuint unit) {
        glActiveTexture(unit);
    }
    
    /// Activates the texture to $(B unit), the struct member.
    void activate() {
        activate(unit);
    }
    
    /// Binds the texture and activates it to $(I unit), passed to the function. 
    void bind_and_activate(GLuint unit) {
        glBindTexture(target, texture);
        glActiveTexture(unit);
    }
    
    /// Binds the texture and activates it to $(B unit), the struct member.
    void bind_and_activate() {
        bind_and_activate(unit);
    }
    
    /// Unbinds the texture.
    void unbind() {
        glBindTexture(target, 0);
    }
    
    /// Deletes the texture.
    void remove() {
        glDeleteTextures(1, &texture);
    }
}

/// Interface every Texture implements.
interface ITexture {
    GLuint get_unit(); ///
    void set_paramter(T)(GLuint name, T params); /// 
    float[] get_parameter(GLuint name); /// 
    void set_data(T)(T data); /// 
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
    
    ///
    mixin CommonTextureMethods;
    
    /// Generates the OpenGL texture and initializes the struct.
    /// Params:
    /// internal_format_ = Specifies the number of color components in the texture.
    /// format_ = Specifies the format of the pixel data.
    /// type_ = Specifies the data type of the pixel data.
    /// unit_ = Specifies the OpenGL texture uinit.
    /// See_Also:
    /// OpenGL, http://www.opengl.org/sdk/docs/man4/xhtml/glTexImage1D.xml
    this(GLint internal_format_, GLenum format_, GLenum type_, GLenum unit_=GL_TEXTURE0) {
        internal_format = internal_format_;
        format = format_;
        type = type_;
        unit = unit_;
        
        glGenTextures(1, &texture);
    }
        
    /// Sets the texture data.
    void set_data(T)(T data) {
        bind();
        
        static if(isPointer!T) {
            auto d = data;
        } else {
            auto d = data.ptr;
        }
        
        glTexImage1D(GL_TEXTURE_1D, 0, internal_format, cast(int)(data.length), 0, format, type, d);
        unbind();
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
    /// If true (default) mipmaps will be generated with glGenerateMipmap.
    bool mipmaps = true;
        
    mixin CommonTextureMethods;

    // ugly workaround, "Error: constructor call must be in a constructor"?
    private void ctor(GLint internal_format_, GLsizei width_, GLsizei height_,
                      GLenum format_, GLenum type_, GLenum unit_=GL_TEXTURE0, bool mipmaps_=true) {
        internal_format = internal_format_;
        width = width_;
        height = height_;
        format = format_;
        type = type_;
        unit = unit_;
        mipmaps = mipmaps_;
        
        glGenTextures(1, &texture);
    }
    
    /// Generates the OpenGL texture and initializes the struct.
    /// Params:
    /// internal_format = Specifies the number of color components in the texture.
    /// width = Specifies the width of the texture image.
    /// height = Specifies the height of the texture image.
    /// format = Specifies the format of the pixel data.
    /// type = Specifies the data type of the pixel data.
    /// unit = Specifies the OpenGL texture uinit.
    /// See_Also:
    /// OpenGL, http://www.opengl.org/sdk/docs/man4/xhtml/glTexImage2D.xml
    this(GLint internal_format, GLsizei width, GLsizei height, 
           GLenum format, GLenum type, GLenum unit=GL_TEXTURE0, bool mipmaps=true) {
        ctor(internal_format, width, height, format, type, unit, mipmaps);
    }
    
    /// Sets the texture data.
    ///
    /// $(RED If mipmaps is true, the gl extensions must be loaded, otherwise bad things will happen!)
    void set_data(T)(T data, GLint level=0) {
        bind();
        
        static if(isPointer!T) {
            auto d = data;
        } else {
            auto d = data.ptr;
        }
        
        glTexImage2D(GL_TEXTURE_2D, level, internal_format, width, height, 0, format, type, d);
        
        if(mipmaps) {
            debug {
                writefln("Generating 2D mipmaps, glext loaded?");
            }
            glGenerateMipmap(GL_TEXTURE_2D);
        }
        
        unbind();
    }
    
    version(stb) {
        /// Loads an image with stb_image and afterwards loads it into a Texture2D struct.
        static Texture2D from_image(string filename) {
            debug {
                writefln("using Texture2D.from_image with stb image");
            }
            int x;
            int y;
            int comp;
            ubyte* data = stbi_load(toStringz(filename), &x, &y, &comp, 0);
            scope(exit) stbi_image_free(data);
            scope(failure) stbi_image_free(data);

            if(data is null) {
                throw new TextureError("Unable to load image: " ~ filename);
            }
            
            uint image_format;
            switch(comp) {
                case 1: image_format = GL_LUMINANCE; break;
                case 2: image_format = GL_LUMINANCE_ALPHA; break;
                case 3: image_format = GL_RGB; break;
                case 4: image_format = GL_RGBA; break;
                default: throw new TextureError("Unknown/Unsupported stbi image format");
            }

            auto tex = new Texture2D(image_format, x, y, image_format, GL_UNSIGNED_BYTE);
            tex.set_data(data);
            return tex;
        }
    } else {
        /// Loads an image with DevIL and afterwards loads it into a Texture2D struct.
        /// 
        /// $(RED DevIL must be loaded and initialized manually!)
        static Texture2D from_image(string filename) {
            debug {
                writefln("using Texture2D.from_image, DevIL loaded and initialized?");
            }
            ILuint id;
            ilGenImages(1, &id);
            
            if(!ilLoadImage(toStringz(filename))) {
                throw new TextureError("Unable to load image: " ~ filename);
            }
            
//             ilConvertImage(IL_RGB, IL_UNSIGNED_BYTE);
            
            auto tex =  new Texture2D(ilGetInteger(IL_IMAGE_FORMAT),
                                      ilGetInteger(IL_IMAGE_WIDTH), ilGetInteger(IL_IMAGE_HEIGHT),
                                      ilGetInteger(IL_IMAGE_FORMAT), ilGetInteger(IL_IMAGE_TYPE));
            tex.set_data(ilGetData());
            return tex;
            
        }
    }
}
module glamour.texture;

private {
    import derelict.opengl.gl : GLenum, GLuint, GLint, GLsizei,
                                glGenTextures, glBindTexture, glActiveTexture,
                                glTexImage1D, glTexImage2D, glTexParameteri, glTexParameterf,
                                glGetTexParameterfv, GL_TEXTURE0,
                                GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR;
    import derelict.opengl.glext : glGenerateMipmap;
    import derelict.devil.il : ILuint, ilGenImages, ilBindImage, ilLoadImage, ilConvertImage,
                               ilGetData, ilGetInteger, IL_RGB, IL_UNSIGNED_BYTE,
                                IL_IMAGE_FORMAT, IL_IMAGE_TYPE, IL_IMAGE_WIDTH, IL_IMAGE_HEIGHT;
    import glamour.util : glenum2size;
    import std.traits : isPointer;
    import std.string : toStringz;
    
    debug {
        import std.stdio : writefln;
    }
}


class TextureError : Exception {
    this(string msg) {
        super(msg);
    }
}


mixin template CommonTextureMethods() {
    void set_paramter(T)(GLenum name, T params) if(is(T : int) || is(T : float)) {
        static if(is(T : int)) {
            glTexParameteri(target, name, params);
        } else {
            glTexParameterf(target, name, params);
        }
    }
    
    float[] get_parameter(GLenum name) {
        float[] ret;
        
        if(name == GL_TEXTURE_BORDER_COLOR) {
            ret.length = 4;
        } else {
            ret.length = 1;
        }
        
        glGetTexParameterfv(target, name, ret.ptr);
        return ret;
    }
    
    void bind() {
        glActiveTexture(unit);
        glBindTexture(target, texture);
    }
    
    void unbind() {
        glBindTexture(GL_TEXTURE_1D, 0);
    }
}


struct Texture1D {
    static const GLenum target = GL_TEXTURE_1D;
    
    GLuint texture;
    alias texture this;
    
    GLint internal_format;
    GLenum format;
    GLenum type;
    GLenum unit;
       
    mixin CommonTextureMethods;

    this()(GLint internal_format_, GLenum format_, GLenum type_, GLenum unit_=GL_TEXTURE0) {
        internal_format = internal_format_;
        format = format_;
        type = type_;
        unit = unit_;
        
        glGenTextures(1, &texture);
    }
       
    this(T)(T data, GLint internal_format, GLenum format, GLenum type, GLenum unit=GL_TEXTURE0) {
        this(internal_format, format, type, unit);
        
        set_data(data);
    }
    
    void set_data(T)(T data) {
        bind();
        glTexImage1D(GL_TEXTURE_1D, 0, internal_format, cast(int)(data.length), 0, format, type, data.ptr);
        unbind();
        
        Texture1D(data, 1, 1, 1);
    }

}

struct Texture2D {
    static const GLenum target = GL_TEXTURE_2D;
    
    GLuint texture;
    alias texture this;
    
    GLint internal_format;
    GLsizei width;
    GLsizei height;
    GLenum format;
    GLenum type;
    GLenum unit;
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
        
    this()(GLint internal_format, GLsizei width, GLsizei height,
           GLenum format, GLenum type, GLenum unit=GL_TEXTURE0, bool mipmaps=true) {
        ctor(internal_format, width, height, format, type, unit, mipmaps);
    }
    
    this(T)(T data, GLint internal_format, GLsizei width, GLsizei height,
            GLenum format, GLenum type, GLenum unit=GL_TEXTURE0, bool mipmaps=true) {
        ctor(internal_format, width, height, format, type, unit, mipmaps);

        set_data(data);
    }
    
    void set_data(T)(T data, GLint level=0) {
        bind();
        
        static if(isPointer!T) {
            auto d = data;
        } else {
            auto d = data.ptr;
        }
        
        glTexImage2D(GL_TEXTURE_2D, level, internal_format, width, height, 0, format, type, d);
        if(mipmaps) {
            glGenerateMipmap(GL_TEXTURE_2D);
        }
        
        unbind();
    }
    
    static Texture2D from_image(string filename) {
        debug {
            writefln("using Texture2D.from_image, DevIL loaded and initialized?");
        }
        ILuint id;
        ilGenImages(1, &id);
        
        if(!ilLoadImage(toStringz(filename))) {
            throw new TextureError("Unable to load image: " ~ filename);
        }
        
        ilConvertImage(IL_RGB, IL_UNSIGNED_BYTE);
        
        return Texture2D(ilGetData(), ilGetInteger(IL_IMAGE_FORMAT), ilGetInteger(IL_IMAGE_WIDTH),
                         ilGetInteger(IL_IMAGE_HEIGHT), ilGetInteger(IL_IMAGE_FORMAT), ilGetInteger(IL_IMAGE_TYPE));        
    }
}
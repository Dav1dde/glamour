module glamour.sampler;

private {
    import glamour.gl : GLuint, GLenum,
                        GL_TEXTURE_BORDER_COLOR, GL_TEXTURE0,
                        GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_3D,
                        glGetSamplerParameterfv, glBindSampler,
                        glSamplerParameteri, glSamplerParameterf,
                        glGenSamplers, glDeleteSamplers,
                        glTexParameteri, glTexParameterf;
    import glamour.texture : ITexture, Texture1D, Texture2D, Texture3D;
    import glamour.util : checkgl;

    debug import std.stdio : stderr;
}


/// 
class ShaderException : Exception {
    this(string msg) {
        super(msg);
    }
}

version(OSX) {
    ///
    alias EmulatedSampler Sampler;
} else {
    ///
    alias RealSampler Sampler;
}

interface ISampler {
    void set_parameter(T)(GLenum name, T params) if(is(T : int) || is(T : float));
    float[] get_parameter(GLenum name);
    void bind(ITexture tex);
    void unbind(GLuint unit);
    void unbind(ITexture tex);
    void remove();
}

/// Represents an OpenGL Sampler.
class RealSampler : ISampler {
    /// The OpenGL sampler name.
    GLuint sampler;
    /// Alias this to sampler.
    alias sampler this;
       
    /// Creates the OpenGL sampler.
    this() {
        checkgl!glGenSamplers(1, &sampler);
    }

    ~this() {
        debug if(sampler != 0) stderr.writefln("OpenGL: Sampler resources not released.");
    }
    
    /// Sets a sampler parameter.
    void set_parameter(T)(GLenum name, T params) if(is(T : int) || is(T : float)) {
        static if(is(T : int)) {
            checkgl!glSamplerParameteri(sampler, name, params);
        } else {
            checkgl!glSamplerParameterf(sampler, name, params);
        }
    }
    
    /// Queries a texture parameter from OpenGL.
    float[] get_parameter(GLenum name) {
        float[] ret;
        
        if(name == GL_TEXTURE_BORDER_COLOR) {
            ret.length = 4;
        } else {
            ret.length = 1;
        }
        
        checkgl!glGetSamplerParameterfv(sampler, name, ret.ptr);
        return ret;
    }
    
    /// Binds the sampler.
    void bind(GLuint unit) {
        checkgl!glBindSampler(unit, sampler);
    }
    
    /// ditto
    void bind(ITexture tex) {
        checkgl!glBindSampler(tex.get_unit()-GL_TEXTURE0, sampler);
    }
    
    /// Unbinds the sampler.
    void unbind(GLuint unit) {
        checkgl!glBindSampler(unit, 0);
    }
    
    /// ditto
    void unbind(ITexture tex) {
        checkgl!glBindSampler(tex.get_unit(), 0);
    }
    
    /// Deletes the sampler.
    void remove() {
        checkgl!glDeleteSamplers(1, &sampler);
        sampler = 0;
    }
}

/// This emulates an OpenGL Sampler on platforms where no glGenSamplers is available (like OSX).
/// This only works with Texture1D, Texture2D and Texture3D so far.
class EmulatedSampler : ISampler {
    protected Parameter[GLenum] parameters;
    protected struct Parameter {
        union {
            int i;
            float f;
        }
        bool is_float;

        this(float f) {
            this.is_float = true;
            this.f = f;
        }

        this(int i) {
            this.is_float = false;
            this.i = i;
        }
    }

    /// Sets a sampler parameter (and stores it internally).
    void set_parameter(T)(GLenum name, T params) if(is(T : int) || is(T : float)) {
      parameters[name] = Parameter(params);
    }

    /// Returns the stored parameter or [float.nan] if not internally stored.
    float[] get_parameter(GLenum name)
        in { assert(name != GL_TEXTURE_BORDER_COLOR);
             assert(parameters[name].is_float); }
        body {
            if(auto param = name in parameters) {
                return [param.f];
            } else {
                return [float.nan];
            }
        }

    /// Stub, throws always ShaderException.
    void bind(GLuint unit) {
      throw new ShaderException("Unsupported bind operation for emulated sampler");
    }

    /// Applies the parameters to the passed texture, must be one of Texture1D, Texture2D or Texture3D,
    /// or throws ShaderException
    void bind(ITexture tex) {
        GLenum unit;
        tex.bind();

        if(cast(Texture1D)tex)
          unit = GL_TEXTURE_1D;
        else if(cast(Texture2D)tex)
          unit = GL_TEXTURE_2D;
        else if(cast(Texture3D)tex)
          unit = GL_TEXTURE_3D;
        else
          throw new ShaderException("Unsupported texture type");

        foreach(name, parameter; parameters) {
            if(parameter.is_float) {
                checkgl!glTexParameterf(unit, name, parameter.f);
            } else {
                checkgl!glTexParameteri(unit, name, parameter.i);
            }
        }
    }

    /// Stub.
    void unbind(GLuint unit) {}

    /// Stub.
    void unbind(ITexture tex) {}

    /// Stub.
    void remove() {}
}
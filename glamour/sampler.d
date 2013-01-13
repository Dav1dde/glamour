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

version(OSX) {
    alias EmulatedSampler Sampler;
} else {
    alias RealSampler Sampler;
}

/// Represents an OpenGL Sampler.
/// The constructor must be used to avoid segmentation faults.
class RealSampler {
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

class EmulatedSampler {
    /// Sets a sampler parameter.
    void set_parameter(T)(GLenum name, T params) if(is(T : int) || is(T : float)) {
      parameters[name] = Parameter(params);
    }

    /// Queries a texture parameter from OpenGL.
    float[] get_parameter(GLenum name) {
        assert(name != GL_TEXTURE_BORDER_COLOR);
        assert(parameters[name].isFloat);
        return [parameters[name].f];
    }

    /// Binds the sampler.
    void bind(GLuint unit) {
      throw new Error("Unsupported bind operation for emulated sampler");
    }

    /// ditto
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
          throw new Error("Unsupported texture type");

        foreach(name, parameter; parameters) {
            if(parameter.isFloat) {
                checkgl!glTexParameterf(unit, name, parameter.f);
            } else {
                checkgl!glTexParameteri(unit, name, parameter.i);
            }
        }
    }

    /// Unbinds the sampler.
    void unbind(GLuint unit) {
    }

    /// ditto
    void unbind(ITexture tex) {
    }

    /// Deletes the sampler.
    void remove() {
    }

private:
    Parameter[GLenum] parameters;
    struct Parameter {
        this(float f) {
          this.isFloat = true;
          this.f = f;
        }

        this(int i) {
          this.isFloat = false;
          this.i = i;
        }

        bool isFloat;
        union {
            int i;
            float f;
        }
    }
}
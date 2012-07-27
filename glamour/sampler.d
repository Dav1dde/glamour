module glamour.sampler;

private {
    import glamour.gl : GLuint, GLenum,
                        GL_TEXTURE_BORDER_COLOR, GL_TEXTURE0,
                        glGetSamplerParameterfv, glBindSampler,
                        glSamplerParameteri, glSamplerParameterf,
                        glGenSamplers, glDeleteSamplers;
    import glamour.texture : ITexture;
    import glamour.util : checkgl;

    debug import std.stdio : stderr;
}


/// Represents an OpenGL Sampler.
/// The constructor must be used to avoid segmentation faults.
class Sampler {
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
module glamour.sampler;

private {
    import glamour.gl : GLuint, GLenum,
                        GL_TEXTURE_BORDER_COLOR, GL_TEXTURE0,
                        glGetSamplerParameterfv, glBindSampler,
                        glSamplerParameteri, glSamplerParameterf,
                        glGenSamplers, glDeleteSamplers;
    import glamour.texture : ITexture;
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
        glGenSamplers(1, &sampler);
    }
    
    /// Sets a sampler parameter.
    void set_parameter(T)(GLenum name, T params) if(is(T : int) || is(T : float)) {
        static if(is(T : int)) {
            glSamplerParameteri(sampler, name, params);
        } else {
            glSamplerParameterf(sampler, name, params);
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
        
        glGetSamplerParameterfv(sampler, name, ret.ptr);
        return ret;
    }
    
    /// Binds the sampler.
    void bind(GLuint unit) {
        glBindSampler(unit, sampler);
    }
    
    /// ditto
    void bind(ITexture tex) {
        glBindSampler(tex.get_unit()-GL_TEXTURE0, sampler);
    }
    
    /// Unbinds the sampler.
    void unbind(GLuint unit) {
        glBindSampler(unit, 0);
    }
    
    /// ditto
    void unbind(ITexture tex) {
        glBindSampler(tex.get_unit(), 0);
    }
    
    /// Deletes the sampler.
    void remove() {
        glDeleteSamplers(1, &sampler);
    }
}
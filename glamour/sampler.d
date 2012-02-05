module glamour.sampler;

private {
    import derelict.opengl.gl : GLuint, GLenum,
                                GL_TEXTURE_BORDER_COLOR;
                                
    import derelict.opengl.glext : glGetSamplerParameterfv, glBindSampler,
                                   glSamplerParameteri, glSamplerParameterf,
                                   glGenSamplers, glDeleteSamplers;
}


/// Represents an OpenGL Sampler.
/// The constructor must be used to avoid segmentation faults.
struct Sampler {
    /// The OpenGL sampler name.
    GLuint sampler;
    /// Alias this to sampler.
    alias sampler this;
    
    /// Creates the OpenGL sampler.
    static Sampler opCall() {
        return Sampler(0);
    }
    
    /// ditto
    this(byte x) {
        glGenSamplers(1, &sampler);
    }
    
    /// Sets a sampler parameter.
    void set_paramter(T)(GLenum name, T params) if(is(T : int) || is(T : float)) {
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
    void bind()(GLuint unit) {  
        glBindSampler(unit, sampler);
    }
    
    /// ditto
    void bind(T)(T tex) if(is(typeof(T.unit) : GLuint)) {
        glBindSampler(tex.unit, sampler);
    }
    
    /// Unbinds the sampler.
    void unbind()(GLuint uinit) {
        glBindSampler(unit, 0);
    }
    
    /// ditto
    void unbind(T)(T tex) if(is(typeof(T.unit) : GLuint)) {
        glBindSampler(tex.unit, 0);
    }
    
    /// Deletes the sampler.
    void remove() {
        glDeleteSamplers(1, &sampler);
    }
}
module glamour.sampler;

private {
    import derelict.opengl.gl : GLuint, GLenum,
                                GL_TEXTURE_BORDER_COLOR;
                                
    import derelict.opengl.glext : glGetSamplerParameterfv, glBindSampler,
                                   glSamplerParameteri, glSamplerParameterf,
                                   glGenSamplers, glDeleteSamplers;
}


struct Sampler {
    GLuint sampler;
    alias sampler this;
    
    GLuint unit;
    
    this(GLuint unit_=0) {
        unit = unit_;
        
        glGenSamplers(1, &sampler);
    }
    
    void set_paramter(T)(GLenum name, T params) if(is(T : int) || is(T : float)) {
        static if(is(T : int)) {
            glSamplerParameteri(sampler, name, params);
        } else {
            glSamplerParameterf(sampler, name, params);
        }
    }
    
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
    
    void bind() {
        glBindSampler(unit, sampler);
    }
    
    void unbind() {
        glBindSampler(unit, sampler);
    }
    
    void remove() {
        glDeleteSamplers(1, &sampler);
    }
}
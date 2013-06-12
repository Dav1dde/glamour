module glamour.fbo;

private {
    import glamour.gl : GLenum, GLint, GLuint, GLsizei, glDeleteBuffers,
                        glGenFramebuffers, glBindFramebuffer, glRenderbufferStorage,
                        glFramebufferRenderbuffer, glFramebufferTexture1D,
                        glFramebufferTexture2D, glGenRenderbuffers, glGetRenderbufferParameteriv,
                        glBindRenderbuffer, glCheckFramebufferStatus, GL_FRAMEBUFFER_COMPLETE,
                        GL_FRAMEBUFFER, GL_RENDERBUFFER, GL_TEXTURE_1D, GL_TEXTURE_2D;
    import glamour.texture : Texture1D, Texture2D;
    import glamour.util : checkgl;

    import std.string : format;

    debug import std.stdio : stderr;
}


class FrameBufferException : Exception {
    this(GLenum err) {
        super("FrameBuffer error: 0x%x".format(err));
    }
}


/// Represents an Opengl FBO (FrameBufferObject)
class FrameBuffer {
    static const GLenum target = GL_FRAMEBUFFER;

    /// The OpenGL FBO name
    GLuint fbo;
    /// Alias this to fbo
    alias fbo this;

    /// Creates an OpenGL FBO
    this() {
        checkgl!glGenFramebuffers(1, &fbo);
    }

    ~this() {
        debug if(fbo != 0) stderr.writefln("OpenGL: FBO resource not released.");
    }

    /// Deletes the FrameBuffer
    void remove() {
        checkgl!glDeleteBuffers(1, &fbo);
        fbo = 0;
    }

    /// Binds the FrameBuffer
    void bind() {
        checkgl!glBindFramebuffer(target, fbo);
    }

    /// Unbinds the FrameBuffer
    void unbind() {
        checkgl!glBindFramebuffer(target, 0);
    }

    /// Attaches a 1D-texture to the FrameBuffer
    /// Calls validate
    void attach(Texture1D texture, GLenum attachment_point, GLint mipmap=0) {
        checkgl!glFramebufferTexture1D(target, attachment_point, GL_TEXTURE_1D, texture, mipmap);
        validate();
    }

    /// Attaches a 2D-texture to the FrameBuffer
    /// Calls validate
    void attach(Texture2D texture, GLenum attachment_point, GLint mipmap=0) {
        checkgl!glFramebufferTexture2D(target, attachment_point, GL_TEXTURE_2D, texture, mipmap);
        validate();
    }

    /// Attaches a RenderBuffer to the FrameBuffer
    /// Calls validate
    void attach(RenderBuffer rbuffer, GLenum attachment_point) {
        checkgl!glFramebufferRenderbuffer(target, attachment_point, rbuffer.target, rbuffer);
        validate();
    }

    /// Calls glCheckFramebufferStatus and throws a FrameBufferException if the return value
    /// is not GL_FRAMEBUFFER_COMPLETE
    void validate() {
        auto ret = glCheckFramebufferStatus(target);
        if(ret != GL_FRAMEBUFFER_COMPLETE) {
            throw new FrameBufferException(ret);
        }
    }

//     /// Sets a framebuffer parameter, mostly used for simulating empty buffers
//     void set_parameter(GLenum param_name, GLint param) {
//         checkgl!glFramebufferParameteri(target, param_name, param);
//     }
}

/// Represents an OpenGL RenderBuffer
class RenderBuffer {
    static const GLenum target = GL_RENDERBUFFER;

    /// The OpenGL RenderBuffer name
    GLuint renderbuffer;
    /// Alias this to renderbuffer
    alias renderbuffer this;

    /// Creates an OpenGL RenderBuffer
    this() {
        checkgl!glGenRenderbuffers(1, &renderbuffer);
    }

    ~this() {
        debug if(renderbuffer != 0) stderr.writefln("OpenGL: RenderBuffer not released.");
    }

    /// Deletes the FrameBuffer
    void remove() {
        checkgl!glDeleteBuffers(1, &renderbuffer);
        renderbuffer = 0;
    }

    /// Binds the RenderBuffer
    void bind() {
        checkgl!glBindRenderbuffer(target, renderbuffer);
    }

    /// Unbinds the RenderBuffer
    void unbind() {
        checkgl!glBindRenderbuffer(target, 0);
    }

    /// Allocates storage for the RenderBuffer
    void set_storage(GLenum internal_format, GLsizei width, GLsizei height) {
        checkgl!glRenderbufferStorage(target, internal_format, width, height);
    }

    /// Returns a RenderBuffer parameter
    int get_parameter(GLenum param_name) {
        int store;
        checkgl!glGetRenderbufferParameteriv(target, param_name, &store);
        return store;
    }
}
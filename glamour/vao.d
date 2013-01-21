module glamour.vao;

private {
    import glamour.gl : glGenVertexArrays, glBindVertexArray, glVertexAttribPointer,
                        glEnableVertexAttribArray, glDisableVertexAttribArray,
                        glDeleteVertexArrays,
                        GLuint, GLenum, GLint, GLsizei, GLboolean, GL_FALSE;
    import glamour.util : checkgl;

    debug {
        import std.stdio : stderr;
    }
}

interface IVAO {
    void bind();
    void unbind();
    void remove();
}

class VAO : IVAO {
    /// The OpenGL vao name
    GLuint vao;
    /// Alias this to vao
    alias vao this;

    /// Initializes the VAO
    this() {
        checkgl!glGenVertexArrays(1, &vao);
    }

    ~this() {
        debug if(vao != 0) stderr.writefln("OpenGL: VAO resources not released.");
    }

    /// Binds the VAO
    void bind() {
        checkgl!glBindVertexArray(vao);
    }

    /// Unbinds the VAO
    void unbind() {
        checkgl!glBindVertexArray(0);
    }

    /// Deletes the VAO
    void remove() {
        checkgl!glDeleteVertexArrays(1, &vao);
        vao = 0;
    }
}
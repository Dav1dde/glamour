module glamour.vao;

private {
    import glamour.gl : glGenVertexArrays, glBindVertexArray, glVertexAttribPointer,
                        glEnableVertexAttribArray, glDisableVertexAttribArray,
                        glDeleteVertexArrays,
                        GLuint, GLenum, GLint, GLsizei, GLboolean, GL_FALSE;
    import glamour.shader : Shader;
    import glamour.util : checkgl;

    debug {
        import std.stdio : stderr;
    }
}

///
interface IVAO {
    void bind(); ///
    void unbind(); ///
    void remove(); ///
}

/// Represents an OpenGL VertrexArrayObject
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

    /// Binds the VAO and sets the vertex attrib pointer.
    /// Params:
    /// type = Specifies the data type of each component in the array.
    /// size = Specifies the number of components per generic vertex attribute.
    /// offset = Specifies a offset of the first component of the first generic vertex attribute in the array in the data store of the buffer.
    /// stride = Specifies the byte offset between consecutive generic vertex attributes.
    /// normalized = Specifies whether fixed-point data values should be normalized (GL_TRUE) or
    ///                converted directly as fixed-point values (GL_FALSE = default) when they are accessed.
    void set_attrib_pointer(GLuint attrib_location, GLenum type, GLint size, GLsizei offset,
              GLsizei stride, GLboolean normalized=GL_FALSE) {
        checkgl!glBindVertexArray(vao);
        checkgl!glEnableVertexAttribArray(attrib_location);
        checkgl!glVertexAttribPointer(attrib_location, size, type, normalized, stride, cast(void *)offset);
    }

    /// ditto
    void set_attrib_pointer(Shader shader, string location, GLenum type, GLint size, GLsizei offset,
              GLsizei stride, GLboolean normalized=GL_FALSE) {
        set_attrib_pointer(shader.get_attrib_location(location), type, size, offset, stride, normalized);
    }
}
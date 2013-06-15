module glamour.vbo;

private {
    import glamour.gl : GLenum, GLint, GLsizei, GLuint, GLboolean, GLintptr,
                        GL_FALSE, glDisableVertexAttribArray,
                        glEnableVertexAttribArray, glVertexAttribPointer,
                        GL_STATIC_DRAW, GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER,
                        glBindBuffer, glBufferData, glBufferSubData,
                        glGenBuffers, glDeleteBuffers;
    import glamour.shader : Shader;
    import glamour.util : checkgl;
                        
    import std.traits : isArray, isPointer;
    import std.range : ElementType;

    debug import std.stdio : stderr;
}

/// Interface every buffer implements
interface IBuffer {
    void bind(); ///
    void unbind(); ///
    void set_data(T)(const ref T data, GLenum hint = GL_STATIC_DRAW); ///
}

/// Represents an OpenGL element buffer.
/// The constructor must be used to avoid segmentation faults.
class ElementBuffer : IBuffer {
    /// The OpenGL buffer name.
    GLuint buffer;
    /// Alias this to buffer.
    alias buffer this;

    /// Specifies the expected usage pattern of the data store.
    GLenum hint;
    /// Length of the passed data, note it's the length of a void[] array.
    size_t length = 0;

    /// Initializes the buffer.
    this()() {
        checkgl!glGenBuffers(1, &buffer);
    }

    /// Initualizes the buffer and sets data.
    this(T)(const auto ref T data, GLenum hint = GL_STATIC_DRAW) if(isArray!T) {
        checkgl!glGenBuffers(1, &buffer);
        set_data(data, hint);
    }

    /// ditto
    this(T)(const T ptr, size_t size, GLenum hint = GL_STATIC_DRAW) if(isPointer!T) {
        checkgl!glGenBuffers(1, &buffer);
        set_data(data, size, hint);
    }

    ~this() {
        debug if(buffer != 0) stderr.writefln("OpenGL: ElementBuffer resources not released.");
    }
    
    /// Deletes the buffer.
    void remove() {
        checkgl!glDeleteBuffers(1, &buffer);
        buffer = 0;
    }

    /// Binds the buffer.
    void bind() {
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer);
    }

    /// Unbinds the buffer.
    void unbind() {
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }

    /// Uploads data to the GPU.
    void set_data(T)(const auto ref T data, GLenum hint = GL_STATIC_DRAW) if(isArray!T) {
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer); // or bind()
        checkgl!glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.length*(ElementType!T).sizeof, data.ptr, hint);
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); //or unbind()

        length = data.length*(ElementType!T).sizeof;
        this.hint = hint;
    }

    /// ditto
    void set_data(T)(const T ptr, size_t size, GLenum hint = GL_STATIC_DRAW) if(isPointer!T) {
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer); // or bind()
        checkgl!glBufferData(GL_ELEMENT_ARRAY_BUFFER, size, ptr, hint);
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); //or unbind()

        length = size;
        this.hint = hint;
    }
}


/// Represents an OpenGL buffer.
/// The constructor must be used to avoid segmentation faults.
class Buffer : IBuffer {
    /// The OpenGL buffer name.
    GLuint buffer;
    /// Alias this to buffer.
    alias buffer this;

    /// Specifies the expected usage pattern of the data store.
    GLenum hint;
    /// Length of the passed data, note it's the length of a void[] array.
    size_t length = 0;

    // Initializes the buffer.
    this()() {
        checkgl!glGenBuffers(1, &buffer);
    }

    /// Initualizes the buffer and sets data.
    /// Params:
    /// data = any kind of data.
    /// type = OpenGL type of the data (e.g. GL_FLOAT)
    /// hint = Specifies the expected usage pattern of the data store.
    this(T)(const auto ref T data, GLenum hint = GL_STATIC_DRAW) if(isArray!T) {
        checkgl!glGenBuffers(1, &buffer);
        set_data(data, hint);
    }

    /// ditto
    this(T)(const T ptr, size_t size, GLenum hint = GL_STATIC_DRAW) if(isPointer!T) {
        checkgl!glGenBuffers(1, &buffer);
        set_data(ptr, size, hint);
    }

    ~this() {
        debug if(buffer != 0) stderr.writefln("OpenGL: Buffer resources not released.");
    }
    
    /// Deletes the buffer.
    void remove() {
        checkgl!glDeleteBuffers(1, &buffer);
        buffer = 0;
    }

    /// Binds the buffer.
    void bind() {
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, buffer);
    }

    /// Binds the buffer and sets the vertex attrib pointer.
    /// Params:
    /// type = Specifies the data type of each component in the array.
    /// size = Specifies the number of components per generic vertex attribute.
    /// offset = Specifies a offset of the first component of the first generic vertex attribute in the array in the data store of the buffer.
    /// stride = Specifies the byte offset between consecutive generic vertex attributes.
    /// normalized = Specifies whether fixed-point data values should be normalized (GL_TRUE) or
    ///                converted directly as fixed-point values (GL_FALSE = default) when they are accessed.
    void bind(GLuint attrib_location, GLenum type, GLint size, GLsizei offset,
              GLsizei stride, GLboolean normalized=GL_FALSE) {
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, buffer);
        checkgl!glEnableVertexAttribArray(attrib_location);
        checkgl!glVertexAttribPointer(attrib_location, size, type, normalized, stride, cast(void *)offset);
    }

    /// ditto
    void bind(Shader shader, string location, GLenum type, GLint size, GLsizei offset,
              GLsizei stride, GLboolean normalized=GL_FALSE) {
        bind(shader.get_attrib_location(location), type, size, offset, stride, normalized);
    }

    /// Unbinds the buffer.
    void unbind() {
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    /// Uploads data to the GPU.
    void set_data(T)(const auto ref T data, GLenum hint = GL_STATIC_DRAW) if(isArray!T) {
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, buffer); // or bind()
        checkgl!glBufferData(GL_ARRAY_BUFFER, data.length*(ElementType!T).sizeof, data.ptr, hint);
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0); //or unbind()

        length = data.length*(ElementType!T).sizeof;
        this.hint = hint;
    }

    /// ditto
    void set_data(T)(const T ptr, size_t size, GLenum hint = GL_STATIC_DRAW) if(isPointer!T) {
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, buffer); // or bind()
        checkgl!glBufferData(GL_ARRAY_BUFFER, size, ptr, hint);
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0); //or unbind()

        length = size;
        this.hint = hint;
    }

    /// Updates the Buffer, using glBufferSubData.
    void update(T)(const ref T data, GLintptr offset) if(isArray!T) {
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, buffer);
        checkgl!glBufferSubData(GL_ARRAY_BUFFER, offset, data.length*(ElementType!T).sizeof, data.ptr);
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    /// ditto
    void update(T)(const T ptr, size_t size, GLintptr offset) if(isPointer!T) {
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, buffer);
        checkgl!glBufferSubData(GL_ARRAY_BUFFER, offset, size, ptr);
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
}
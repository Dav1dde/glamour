module glamour.vbo;

private {
    import glamour.gl : GLenum, GLint, GLsizei, GLuint, GLintptr, 
                        GL_FALSE, glDisableVertexAttribArray, 
                        glEnableVertexAttribArray, glVertexAttribPointer, 
                        GL_STATIC_DRAW, GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER,
                        glBindBuffer, glBufferData, glBufferSubData,
                        glGenBuffers, glDeleteBuffers;
}

/// Every Element*-Struct will mixin this template.
mixin template BufferData() {
    /// Stores the OpenGL type of the passed data (e.g. GL_FLOAT).
    GLenum type;
    /// Specifies the number of components per generic vertex attribute.
    GLint size;
    /// Specifies the expected usage pattern of the data store.
    GLenum hint;
    /// Length of the passed data, note it's the length of a void[] array.
    size_t length = 0;

    private void set_buffer_data(GLenum t, GLenum h) {
        type = t;
        hint = h;
    }
}

/// Represents an OpenGL element buffer.
/// The constructor must be used to avoid segmentation faults.
struct ElementBuffer {
    mixin BufferData;
    
    /// The OpenGL buffer name.
    GLuint buffer;
    /// Alias this to buffer.
    alias buffer this;
    
    /// Kind of a ctor, it will initialize the buffer.
    static ElementBuffer opCall() {
        return ElementBuffer(0);
    }
    
    private this(ubyte x) {
        glGenBuffers(1, &buffer);
    }
    
    /// Initualizes the buffer and sets data.
    this(void[] data, GLenum type, GLenum hint = GL_STATIC_DRAW) {
        glGenBuffers(1, &buffer);
        set_data(data, type, hint);
    }
    
    /// Deletes the buffer.
    void remove() {
        glDeleteBuffers(1, &buffer);
    }
    
    /// Binds the buffer.
    void bind() {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer);
    }
    
    /// Unbinds the buffer.
    void unbind() {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
    
    /// Uploads data to the GPU.
    void set_data(void[] data, GLenum type, GLenum hint = GL_STATIC_DRAW) {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer); // or bind()
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.length, data.ptr, hint);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); //or unbind()
        
        length = data.length;
        set_buffer_data(type, hint);
    }

    /// Returns true if length != 0.
    bool opCast(T : bool)() {
        return cast(bool)(length);
    }
}


/// Represents an OpenGL buffer.
/// The constructor must be used to avoid segmentation faults.
struct Buffer {
    mixin BufferData;
    
    /// Specifies the byte offset between consecutive generic vertex attributes.
    GLsizei stride;
    
    /// The OpenGL buffer name.
    GLuint buffer;
    /// Alias this to buffer.
    alias buffer this;
    
    /// Kind of a ctor, it will initialize the buffer.
    static Buffer opCall() {
        return Buffer(0);
    }
    
    private this(ubyte x) {
        glGenBuffers(1, &buffer);
    }
    
    /// Initualizes the buffer and sets data.
    /// Params:
    /// data = any kind of data.
    /// type = OpenGL type of the data (e.g. GL_FLOAT)
    /// size = Specifies the number of components per generic vertex attribute.
    /// stride = Specifies the byte offset between consecutive generic vertex attributes.
    /// hint = Specifies the expected usage pattern of the data store.
    this(void[] data, GLenum type, GLint size_=4, GLsizei stride_=0, GLenum hint = GL_STATIC_DRAW) {
        glGenBuffers(1, &buffer);
        stride = stride_;
        size = size_;
        set_data(data, type, hint);
    }
    
    /// Deletes the buffer.
    void remove() {
        glDeleteBuffers(1, &buffer);
    }
    
    /// Binds the buffer.
    void bind() {
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
    }
    
    /// Binds the buffer and sets the vertex attrib pointer.
    void bind(GLuint attrib_location, GLint size_=-1, GLsizei offset=0, GLsizei stride_=-1) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        int s = stride_ >= 0 ? stride_:stride;
        GLint si = size_ >= 1 ? size_:size;
        glEnableVertexAttribArray(attrib_location);
        glVertexAttribPointer(attrib_location, si, type, GL_FALSE, s, cast(void *)offset);
    }
    
    /// Unbinds the buffer.
    void unbind() {
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    
    /// Uploads data to the GPU.
    void set_data(void[] data, GLenum type, GLenum hint = GL_STATIC_DRAW) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer); // or bind()
        glBufferData(GL_ARRAY_BUFFER, data.length, data.ptr, hint);
        glBindBuffer(GL_ARRAY_BUFFER, 0); //or unbind()
    
        length = data.length;
        set_buffer_data(type, hint);
    }
    
    /// Updates the Buffer, using glBufferSubData.
    void update(void[] data, GLintptr offset) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        glBufferSubData(GL_ARRAY_BUFFER, offset, data.length, data);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    
    /// Returns true if length != 0.
    bool opCast(T : bool)() {
        return cast(bool)(length);
    }
}
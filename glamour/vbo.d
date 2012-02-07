module glamour.vbo;

private {
    import derelict.opengl.gl : GLenum, GLint, GLsizei, GLuint, GLintptr, 
                                GL_FALSE, glDisableVertexAttribArray, 
                                glEnableVertexAttribArray, glVertexAttribPointer, 
                                GL_STATIC_DRAW, GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER,
                                glBindBuffer, glBufferData, glBufferSubData,
                                glGenBuffers, glDeleteBuffers;
}

mixin template BufferData() {
    GLenum type;
    GLint size;
    GLenum hint;
    size_t length = 0;

    private void set_buffer_data(GLenum t, GLenum h) {
        type = t;
        hint = h;
    }
}

struct ElementBuffer {
    mixin BufferData;
    
    GLuint buffer;
    alias buffer this;
    
    static ElementBuffer opCall() {
        return ElementBuffer(0);
    }
    
    private this(ubyte x) {
        glGenBuffers(1, &buffer);
    }
    
    this(void[] data, GLenum type, GLenum hint = GL_STATIC_DRAW) {
        glGenBuffers(1, &buffer);
        set_data(data, type, hint);
    }
    
    void remove() {
        glDeleteBuffers(1, &buffer);
    }
    
    void bind() {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer);
    }
    
    void unbind() {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
    
    void set_data(void[] data, GLenum type, GLenum hint = GL_STATIC_DRAW) {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer); // or bind()
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.length, data.ptr, hint);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); //or unbind()
        
        length = data.length;
        set_buffer_data(type, hint);
    }

    bool opCast(T : bool)() {
        return cast(bool)(length);
    }
}


struct Buffer {
    mixin BufferData;
    
    GLsizei stride;
    
    GLuint buffer;
    alias buffer this;
    
    static Buffer opCall() {
        return Buffer(0);
    }
    
    private this(ubyte x) {
        glGenBuffers(1, &buffer);
    }
    
    this(void[] data, GLenum type, GLint size_=4, GLsizei stride_=0, GLenum hint = GL_STATIC_DRAW) {
        glGenBuffers(1, &buffer);
        stride = stride_;
        size = size_;
        set_data(data, type, hint);
    }
    
    void remove() {
        glDeleteBuffers(1, &buffer);
    }
    
    void bind() {
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
    }
    
    void bind(GLuint attrib_location, GLint size_=-1, GLsizei offset=0, GLsizei stride_=-1) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        int s = stride_ >= 0 ? stride_:stride;
        GLint si = size_ >= 1 ? size_:size;
        glEnableVertexAttribArray(attrib_location);
        glVertexAttribPointer(attrib_location, si, type, GL_FALSE, s, cast(void *)offset);
    }
    
    void unbind() {
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    
    void set_data(void[] data, GLenum type, GLenum hint = GL_STATIC_DRAW) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer); // or bind()
        glBufferData(GL_ARRAY_BUFFER, data.length, data.ptr, hint);
        glBindBuffer(GL_ARRAY_BUFFER, 0); //or unbind()
    
        length = data.length;
        set_buffer_data(type, hint);
    }
    
    void update(void[] data, GLintptr offset) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        glBufferSubData(GL_ARRAY_BUFFER, offset, data.length, data);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    
    bool opCast(T : bool)() {
        return cast(bool)(length);
    }
}
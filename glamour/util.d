module glamour.util;

private {
    import glamour.gl : GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT, GL_UNSIGNED_SHORT,
                        GL_INT, GL_UNSIGNED_INT, GL_FLOAT, GL_DOUBLE, GLenum,
                        glGetError, GL_NO_ERROR, GL_INVALID_ENUM, GL_INVALID_VALUE,
                        GL_INVALID_OPERATION, GL_INVALID_FRAMEBUFFER_OPERATION,
                        GL_OUT_OF_MEMORY;

    import std.traits : ReturnType;
                        
    import std.stdio : stderr;
}


static this() {
    _error_callback = function void(GLenum error_code, string function_name) {
        stderr.writefln(`OpenGL function "%s" failed: "%s."`, function_name, gl_error_string(error_code));
    };
}

private void function(GLenum, string) _error_callback;

void set_error_callback(void function(GLenum, string) cb) {
    _error_callback = cb;
}

ReturnType!func checkgl(alias func, Args...)(Args args) {
    debug scope(success) {
        GLenum error_code = glGetError();

        if(error_code != GL_NO_ERROR) {
            _error_callback(error_code, func.stringof);
        }
    }

    return func(args);
}

string gl_error_string(GLenum error) {
    final switch(error) {
        case GL_NO_ERROR: return "no error";
        case GL_INVALID_ENUM: return "invalid enum";
        case GL_INVALID_VALUE: return "invalid value";
        case GL_INVALID_OPERATION: return "invalid operation";
        //case GL_STACK_OVERFLOW: return "stack overflow";
        //case GL_STACK_UNDERFLOW: return "stack underflow";
        case GL_INVALID_FRAMEBUFFER_OPERATION: return "invalid framebuffer operation";
        case GL_OUT_OF_MEMORY: return "out of memory";
    }
    assert(false, "invalid enum");
}


template type2glenum(T) {
    static if(is(T == byte)) {
        GLenum type2glenum = GL_BYTE;
    } else static if(is(T == ubyte)) {
        GLenum type2glenum = GL_UNSIGNED_BYTE;
    } else static if(is(T == short)) {
        GLenum type2glenum = GL_SHORT;
    } else static if(is(T == ushort)) {
        GLenum type2glenum = GL_UNSIGNED_SHORT;
    } else static if(is(T == int)) {
        GLenum type2glenum = GL_INT;
    } else static if(is(T == uint)) {
        GLenum type2glenum = GL_UNSIGNED_INT;
    } else static if(is(T == float)) {
        GLenum type2glenum = GL_FLOAT;
    } else static if(is(T == double)) {
        GLenum type2glenum = GL_DOUBLE;
    } else {
        static assert(false, T.stringof ~ " cannot be represented as GLenum");
    }
}

template glenum2type(GLenum t) {
    static if(t == GL_BYTE) {
        alias byte glenum2type;
    } else static if(t == GL_UNSIGNED_BYTE) {
        alias ubyte glenum2type;
    } else static if(t == GL_SHORT) {
        alias short glenum2type;
    } else static if(t == GL_UNSIGNED_SHORT) {
        alias ushort glenum2type;
    } else static if(t == GL_INT) {
        alias int glenum2type;
    } else static if(t == GL_UNSIGNED_INT) {
        alias uint glenum2type;
    } else static if(t == GL_FLOAT) {
        alias float glenum2type;
    } else static if(t == GL_DOUBLE) {
        alias double glenum2type;
    } else {
        static assert(false, T.stringof ~ " cannot be represented as D-Type");
    }
}

unittest {
    assert(GL_BYTE == type2glenum!byte);
    assert(GL_UNSIGNED_BYTE == type2glenum!ubyte);
    assert(GL_SHORT == type2glenum!short);
    assert(GL_UNSIGNED_SHORT == type2glenum!ushort);
    assert(GL_INT == type2glenum!int);
    assert(GL_UNSIGNED_INT == type2glenum!uint);
    assert(GL_FLOAT == type2glenum!float);
    assert(GL_DOUBLE == type2glenum!double);

    assert(is(byte : glenum2type!GL_BYTE));
    assert(is(ubyte : glenum2type!GL_UNSIGNED_BYTE));
    assert(is(short : glenum2type!GL_SHORT));
    assert(is(ushort : glenum2type!GL_UNSIGNED_SHORT));
    assert(is(int : glenum2type!GL_INT));
    assert(is(uint : glenum2type!GL_UNSIGNED_INT));
    assert(is(float : glenum2type!GL_FLOAT));
    assert(is(double : glenum2type!GL_DOUBLE));
}

template glenum2sizect(GLenum t) {
    static if(t == GL_BYTE) {
        enum glenum2sizect = byte.sizeof;
    } else static if(t == GL_UNSIGNED_BYTE) {
        enum glenum2sizect = ubyte.sizeof;
    } else static if(t == GL_SHORT) {
        enum glenum2sizect = short.sizeof;
    } else static if(t == GL_UNSIGNED_SHORT) {
        enum glenum2sizect = ushort.sizeof;
    } else static if(t == GL_INT) {
        enum glenum2sizect = int.sizeof;
    } else static if(t == GL_UNSIGNED_INT) {
        enum glenum2sizect = uint.sizeof;
    } else static if(t == GL_FLOAT) {
        enum glenum2sizect = float.sizeof;
    } else static if(t == GL_DOUBLE) {
        enum glenum2sizect = double.sizeof;
    } else {
        static assert(false, T.stringof ~ " cannot be represented as D-Type");
    }
}

int glenum2size(GLenum t) {
    switch(t) {
        case GL_BYTE: return glenum2sizect!GL_BYTE;
        case GL_UNSIGNED_BYTE: return glenum2sizect!GL_UNSIGNED_BYTE;
        case GL_SHORT: return glenum2sizect!GL_SHORT;
        case GL_UNSIGNED_SHORT: return glenum2sizect!GL_UNSIGNED_SHORT;
        case GL_INT: return glenum2sizect!GL_INT;
        case GL_UNSIGNED_INT: return glenum2sizect!GL_UNSIGNED_INT;
        case GL_FLOAT: return glenum2sizect!GL_FLOAT;
        case GL_DOUBLE: return glenum2sizect!GL_DOUBLE;
        default: throw new Exception("Unknown GLenum");
    }
}
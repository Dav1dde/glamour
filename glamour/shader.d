module glamour.shader;

private {
    import glamour.gl : GLenum, GLuint, GLint, GLchar, GLboolean,
                        GL_VERTEX_SHADER,
//                                 GL_TESS_CONTROL_SHADER, GL_TESS_EVALUATION_SHADER,
                        GL_GEOMETRY_SHADER, GL_FRAGMENT_SHADER,
                        GL_LINK_STATUS, GL_FALSE, GL_INFO_LOG_LENGTH,
                        GL_COMPILE_STATUS, GL_TRUE,
                        glCreateProgram, glCreateShader, glCompileShader,
                        glLinkProgram, glGetShaderiv, glGetShaderInfoLog,
                        glGetProgramInfoLog, glGetProgramiv, glShaderSource,
                        glUseProgram, glAttachShader, glGetAttribLocation,
                        glDeleteProgram, glDeleteShader, glGetFragDataLocation,
                        glGetUniformLocation, glUniform1i, glUniform1f,
                        glUniform2f, glUniform2fv, glUniform3fv,
                        glUniform4fv, glUniformMatrix2fv, glUniformMatrix2x3fv,
                        glUniformMatrix2x4fv, glUniformMatrix3fv, glUniformMatrix3x2fv,
                        glUniformMatrix3x4fv, glUniformMatrix4fv, glUniformMatrix4x2fv,
                        glUniformMatrix4x3fv, glUniform2iv, glUniform3iv, glUniform4iv;
    import glamour.util : checkgl;

    import std.conv : to;
    import std.file : readText;
    import std.path : baseName, stripExtension;
    import std.string : format, splitLines, toStringz, toLower, strip;
    import std.array : join, split;
    import std.algorithm : startsWith, endsWith;
    import std.typecons : Tuple;
    
    version(gl3n) {
        import gl3n.util : is_vector, is_matrix, is_quaternion;
    }

    debug import std.stdio : stderr;
}


GLenum to_opengl_shader(string s, string filename="<unknown>") {
    switch(s) {
        case "vertex": return GL_VERTEX_SHADER;
        case "geometry": return GL_GEOMETRY_SHADER;
        case "fragment": return GL_FRAGMENT_SHADER;
        default: throw new ShaderException(format("Unknown shader, %s.", s), "load", filename);
    }
    assert(0);
}


// enum ctr_shader_type = ctRegex!(`^(\w+):`);

/// This exception will be raised when
/// an error occurs while compiling or linking a shader.
class ShaderException : Exception {
    /// The filename passed to the ctor.
    string filename;
    /// The process passed to the ctor. Will be one of "linking" or "compiling".
    string process;
    
    /// Params:
    /// infolog = Infolog returned from OpenGL.
    /// process_ = Error occured while linking or compiling?
    /// filename_ = Used to identify the shader.
    this(string infolog, string process_, string filename_="<unknown>") {
        filename = filename_;
        process = process_;
        
        infolog ~= "\nFailed to " ~ process_ ~ " shader: " ~ filename_ ~ ". "; 
        
        super(infolog);
    }
}
deprecated alias ShaderException ShaderError;

/// Compiles an already created OpenGL shader.
/// Throws: ShaderException on failure.
/// Params:
/// shader = The OpenGL shader.
/// filename = Used to identify the shader, if an error occurs.
void compile_shader(GLuint shader, string filename="<unknown>") {
    checkgl!glCompileShader(shader);

    GLint status;
    checkgl!glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if(status == GL_FALSE) {
        GLint infolog_length;
        checkgl!glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infolog_length);
        
        GLchar[] infolog = new GLchar[infolog_length+1];
        checkgl!glGetShaderInfoLog(shader, infolog_length, null, infolog.ptr);
        
        throw new ShaderException(infolog.to!string(), "link", filename);
    }
}

/// Links an already created OpenGL program.
/// Throws: ShaderException on failure.
/// Params:
/// program = The OpenGL program.
/// filename = Used to identify the shader, if an error occurs.
void link_program(GLuint program, string filename="<unknown>") {
    checkgl!glLinkProgram(program);

    GLint status;
    checkgl!glGetProgramiv(program, GL_LINK_STATUS, &status);
    if(status == GL_FALSE) {
        GLint infolog_length;
        checkgl!glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infolog_length);

        GLchar[] infolog = new GLchar[infolog_length + 1];
        checkgl!glGetProgramInfoLog(program, infolog_length, null, infolog.ptr);
        
        throw new ShaderException(infolog.to!string(), "compile", filename);
    }
}

/// Stores each line of the shader, line and text.
alias Tuple!(size_t, "line", string, "text") Line; 

/// Represents an OpenGL program with it's shaders.
/// The constructor must be used to avoid segmentation faults.
class Shader {
    /// The OpenGL program.
    GLuint program;
    /// Alias this to program.
    alias program this;
    
    private GLuint[] _shaders; 
    /// Holds every shaders source.
    Line[][string] shader_sources;
    /// Holds the directives.
    string[] directives;
    
    /// The shaders filename.
    string filename;
    
    /// Uniform locations will be cached here.
    GLint[string] uniform_locations;
    /// Attrib locations will be cached here.
    GLint[string] attrib_locations;
    /// Frag-data locations will be cached here.
    GLint[string] frag_locations;

    /// Loads the shaders directly from a file.
    this(string file) {
        this(stripExtension(baseName(file)), readText(file));
    }
    
    /// Loads the shader from the source,
    /// filename_ is stored in $(I filename) and will be used to identify the shader.
    this(string filename_, string source) {
        filename = filename_;
        
        program = checkgl!glCreateProgram();
               
        Line[]* current;
        foreach(size_t line, string text; source.splitLines()) {
            if(text.startsWith("#")) {
                directives ~= text;
            } else {
                auto m = text.strip().split();

                if(m.length >= 1 && m[0].endsWith(":")) {
                    string type = toLower(m[0][0..$-1]);
                    shader_sources[type] = null;
                    current = &(shader_sources[type]);
                } else {
                    if(current !is null) {
                        *current ~= Line(line, text);
                    }
                }
            }
        }
        
        if(!directives.length) {
            // OSX only supports 3.2 forward contexts
            version(OSX) {
                directives ~= "#version 150\n";
            } else {
                directives ~= "#version 130\n";
            }
        }
        
        foreach(string type, Line[] lines; shader_sources) {
            string shader_source = directives.join("\n") ~ "\n\n";
            
            foreach(Line line; lines) {
                shader_source ~= format("#line %d\n%s\n", line.line, line.text);
            }
            
            GLenum shader_type = to_opengl_shader(type, filename);
            GLuint shader = checkgl!glCreateShader(shader_type);
            auto ssp = shader_source.ptr;
            int ssl = cast(int)(shader_source.length);
            checkgl!glShaderSource(shader, 1, &ssp, &ssl);

            compile_shader(shader, filename);

            _shaders ~= shader;
            checkgl!glAttachShader(program, shader);
        }
        
        link_program(program, filename);
    }

    ~this() {
        debug if(program != 0) stderr.writefln("OpenGL: Shader resources not released.");
    }
    
    /// Deletes all shaders and the program.
    void remove() {
        foreach(GLuint shader; _shaders) {
            checkgl!glDeleteShader(shader);
        }
        _shaders = [];
        
        checkgl!glDeleteProgram(program);
        program = 0;
    }
    
    /// Binds the program.
    void bind() {
        checkgl!glUseProgram(program);
    }
    
    /// Unbinds the program.
    void unbind() {
        checkgl!glUseProgram(0);
    }
    
    /// Queries an attrib location from OpenGL and caches it in $(I attrib_locations).
    /// If the location was already queried the cache is returned.
    GLint get_attrib_location(string name) {
        if(auto loc = name in attrib_locations) {
            return *loc;
        }
        
        return attrib_locations[name] = checkgl!glGetAttribLocation(program, toStringz(name));
    }

    /// Queries an fragment-data location from OpenGL and caches it in $(I frag_locations).
    /// If the location was already queried the cache is returned.
    GLint get_frag_location(string name) {
        if(auto loc = name in frag_locations) {
            return *loc;
        }

        return frag_locations[name] = checkgl!glGetFragDataLocation(program, toStringz(name));
    }
    
    /// Queries an uniform location from OpenGL and caches it in $(I uniform_locations).
    /// If the location was already queried the cache is returned.
    GLint get_uniform_location(string name) {
        if(auto loc = name in uniform_locations) {
            return *loc;
        }
        
        return uniform_locations[name] = checkgl!glGetUniformLocation(program, toStringz(name));
    }

    // gl3n integration
    version(gl3n) {
        /// If glamour gets compiled with version=gl3n support for
        /// vectors, matrices and quaternions is added
        void uniform(T)(string name, T value) if(is_vector!T) {
            static if(is(T.vt : int)) {
                static if(T.dimension == 2) {
                    checkgl!glUniform2iv(get_uniform_location(name), 1, value.value_ptr);
                } else static if(T.dimension == 3) {
                    checkgl!glUniform3iv(get_uniform_location(name), 1, value.value_ptr);
                } else static if(T.dimension == 4) {
                    checkgl!glUniform4iv(get_uniform_location(name), 1, value.value_ptr);
                } else static assert(false);
            } else {
                static if(T.dimension == 2) {
                    checkgl!glUniform2fv(get_uniform_location(name), 1, value.value_ptr);
                } else static if(T.dimension == 3) {
                    checkgl!glUniform3fv(get_uniform_location(name), 1, value.value_ptr);
                } else static if(T.dimension == 4) {
                    checkgl!glUniform4fv(get_uniform_location(name), 1, value.value_ptr);
                } else static assert(false);
            }
        }
        
        /// ditto
        void uniform(S : string, T)(S name, T value) if(is_matrix!T) {
            static if((T.rows == 2) && (T.cols == 2)) {
                checkgl!glUniformMatrix2fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 3) && (T.cols == 3)) {
                checkgl!glUniformMatrix3fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 4) && (T.cols == 4)) {
                checkgl!glUniformMatrix4fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 2) && (T.cols == 3)) {
                checkgl!glUniformMatrix2x3fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 3) && (T.cols == 2)) {
                checkgl!glUniformMatrix3x2fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 2) && (T.cols == 4)) {
                checkgl!glUniformMatrix2x4fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 4) && (T.cols == 2)) {
                checkgl!glUniformMatrix4x2fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 3) && (T.cols == 4)) {
                checkgl!glUniformMatrix3x4fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 4) && (T.cols == 3)) {
                checkgl!glUniformMatrix4x3fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static assert(false, "Can not upload type " ~ T.stringof ~ " to GPU as uniform");
        }
        
        /// ditto
        void uniform(S : string, T)(S name, T value) if(is_quaternion!T) {
            checkgl!glUniform4fv(get_uniform_location(name), 1, value.value_ptr);
        } 
    } else {
        void uniform(S, T)(S name, T value) {
            static assert(false, "you have to compile glamour with version=gl3n to use Shader.uniform");
        }
    }
    
    /// Sets a shader uniform. Consider the corresponding OpenGL for more information.
    void uniform1i(string name, int value) {
        checkgl!glUniform1i(get_uniform_location(name), value);
    }
    
    /// ditto
    void uniform1f(string name, float value) {
        checkgl!glUniform1f(get_uniform_location(name), value);
    }
    
    /// ditto
    void uniform2f(string name, float value1, float value2) {
        checkgl!glUniform2f(get_uniform_location(name), value1, value2);
    }

    /// ditto
    void uniform2fv(string name, const float[] value) {
        checkgl!glUniform2fv(get_uniform_location(name), cast(int)(value.length/2), value.ptr);
    }

    /// ditto
    void uniform2fv(string name, const float[] value, int count) {
        checkgl!glUniform2fv(get_uniform_location(name), count, value.ptr);
    }
    
    /// ditto
    void uniform3fv(string name, const float[] value) {
        checkgl!glUniform3fv(get_uniform_location(name), cast(int)(value.length/3), value.ptr);
    }

    /// ditto
    void uniform3fv(string name, const float[] value, int count) {
        checkgl!glUniform3fv(get_uniform_location(name), count, value.ptr);
    }

    /// ditto
    void uniform4fv(string name, const float[] value) {
        checkgl!glUniform4fv(get_uniform_location(name), cast(int)(value.length/4), value.ptr);
    }
    
    /// ditto
    void uniform4fv(string name, const float[] value, int count) {
        checkgl!glUniform4fv(get_uniform_location(name), count, value.ptr);
    }

    /// ditto
    void uniform_matrix3fv(string name, const float[] value, GLboolean transpose=GL_TRUE) {
        checkgl!glUniformMatrix3fv(get_uniform_location(name), cast(int)(value.length/9), transpose, value.ptr);
    }
    
    /// ditto
    void uniform_matrix3fv(string name, const float[] value, GLboolean transpose=GL_TRUE, int count=1) {
        checkgl!glUniformMatrix3fv(get_uniform_location(name), count, transpose, value.ptr);
    }
    
    /// ditto
    void uniform_matrix4fv(string name, const float[] value, GLboolean transpose=GL_TRUE) {
        checkgl!glUniformMatrix4fv(get_uniform_location(name), cast(int)(value.length/16), transpose, value.ptr);
    }

    /// ditto
    void uniform_matrix4fv(string name, const float[] value, GLboolean transpose=GL_TRUE, int count=1) {
        checkgl!glUniformMatrix4fv(get_uniform_location(name), count, transpose, value.ptr);
    }
    
}
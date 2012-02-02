module glamour.shader;

private {
    import derelict.opengl.gl : GLenum, GLuint, GLint, GLchar, GLboolean,
                                GL_VERTEX_SHADER,
//                                 GL_TESS_CONTROL_SHADER, GL_TESS_EVALUATION_SHADER,
                                GL_GEOMETRY_SHADER, GL_FRAGMENT_SHADER,
                                GL_LINK_STATUS, GL_FALSE, GL_INFO_LOG_LENGTH,
                                GL_COMPILE_STATUS, GL_TRUE,
                                glCreateProgram, glCreateShader, glCompileShader,
                                glLinkProgram, glGetShaderiv, glGetShaderInfoLog,
                                glGetProgramInfoLog, glGetProgramiv, glShaderSource,
                                glUseProgram, glAttachShader, glGetAttribLocation,
                                glGetUniformLocation, glUniform1i, glUniform1f,
                                glUniform2f, glUniform2fv, glUniform3fv,
                                glUniform4fv, glUniformMatrix2fv, glUniformMatrix2x3fv,
                                glUniformMatrix2x4fv, glUniformMatrix3fv, glUniformMatrix3x2fv,
                                glUniformMatrix3x4fv, glUniformMatrix4fv, glUniformMatrix4x2fv,
                                glUniformMatrix4x3fv;

    import std.file : readText;
    import std.path : baseName, stripExtension;
    import std.string : format, splitLines, toStringz;
    import std.algorithm : startsWith;
    import std.regex : ctRegex, regex, match;
    import std.typecons : Tuple;
    
    version(gl3n) {
        import gl3n.util : is_vector, is_matrix, is_quaternion;
    }
}

GLuint[string] SHADER_TYPES;

static this() {
    GLuint[string] SHADER_TYPES = ["vertex" : GL_VERTEX_SHADER,
//                                    "tesscontrol" : GL_TESS_CONTROL_SHADER,
//                                    "tessevaluation" : GL_TESS_EVALUATION_SHADER,
                                   "geometry" : GL_GEOMETRY_SHADER, 
                                   "fragment" : GL_FRAGMENT_SHADER];
}


// enum ctr_shader_type = ctRegex!(`^(\w+):`);

/// This exception will be raised when
/// an error occurs while compiling or linking a shader.
class ShaderError : Exception {
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
        
        infolog ~= "Failed to " ~ process_ ~ " shader: " ~ filename_ ~ ". "; 
        
        super(infolog);
    }
}

/// Compiles an already created OpenGL shader.
/// Throws: ShaderError on failure.
/// Params:
/// shader = The OpenGL shader.
/// filename = Used to identify the shader, if an error occurs.
void compile_shader(GLuint shader, string filename="<unknown>") {
    glCompileShader(shader);

    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if(status == GL_FALSE) {
        GLint infolog_length;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infolog_length);
        
        GLchar[] infolog = new GLchar[infolog_length+1];
        glGetShaderInfoLog(shader, infolog_length, null, infolog.ptr);
        
        throw new ShaderError(infolog.idup, "linking", filename);
    }
}

/// Links an already created OpenGL program.
/// Throws: ShaderError on failure.
/// Params:
/// program = The OpenGL program.
/// filename = Used to identify the shader, if an error occurs.
void link_program(GLuint program, string filename="<unknown>") {
    glLinkProgram(program);

    GLint status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if(status == GL_FALSE) {
        GLint infolog_length;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infolog_length);

        GLchar[] infolog = new GLchar[infolog_length + 1];
        glGetProgramInfoLog(program, infolog_length, null, infolog.ptr);
        
        throw new ShaderError(infolog.idup, "compiling", filename);
    }
}


alias Tuple!(size_t, "line", string, "text") Line; 

/// Represents an OpenGL program with it's shaders.
/// The constructor must be used.
struct Shader {
    /// The OpenGL program.
    GLuint program;
    
    /// Holds every shaders source.
    Line[][string] shaders;
    /// Holds the directives.
    string directives;
    
    /// The shaders filename.
    string filename;
    
    /// Uniform locations will be cached here.
    GLint[string] uniform_locations;
    /// Attrib locations will be cached here.
    GLint[string] attrib_locations;
    
    /// Loads the shaders directly from a file.
    this(string file) {
        this(stripExtension(baseName(file)), readText(file));
    }
    
    /// Loads the shader from the source,
    /// filename_ is stored in $(I filename) and will be used to identify the shader.
    this(string filename_, string source) {
        filename = filename_;
        
        program = glCreateProgram();
        
        auto ctr_shader_type = regex(`^(\w+):`);
        
        Line[]* current;
        foreach(size_t line, string text; source.splitLines()) {
            if(text.startsWith("#")) {
                directives ~= text;
            } else {
                auto m = text.match(ctr_shader_type);
                
                if(m) {
                    string type = m.captures[1];
                    current = &(shaders[type]);
                } else {
                    if(current !is null) {
                        *current ~= Line(line, text);
                    }
                }
            }
        }
        
        if(!directives.length) {
            directives = "#version 330\n";
        }
        
        foreach(string type, Line[] lines; shaders) {
            string shader_source;
            
            foreach(Line line; lines) {
                shader_source ~= format("#line %d\n%s\n", line.line, line.text);
            }
            
            GLenum shader_type = SHADER_TYPES[type];
            GLuint shader = glCreateShader(shader_type);
            auto ssp = shader_source.ptr;
            int ssl = shader_source.length;
            glShaderSource(shader, 1, &ssp, &ssl);
            
            compile_shader(shader);
            
            glAttachShader(program, shader);
        }
        
        link_program(program);
    }
    
    /// Binds the program.
    void bind() {
        glUseProgram(program);
    }
    
    /// Unbinds the program.
    void unbind() {
        glUseProgram(0);
    }
    
    /// Queries an attrib location from OpenGL and caches it in $(I attrib_locations).
    /// If the location was already queried the cache is returned.
    GLint get_attrib_location(string name) {
        if(name !in attrib_locations) {
            attrib_locations[name] = glGetAttribLocation(program, toStringz(name));
        }
        
        return attrib_locations[name];
    }
    
    /// Queries an uniform location from OpenGL and caches it in $(I uniform_locations).
    /// If the location was already queried the cache is returned.
    GLint get_uniform_location(string name) {
        if(name !in uniform_locations) {
            attrib_locations[name] = glGetUniformLocation(program, toStringz(name));
        }
        
        return uniform_locations[name];
    }
        
    // gl3n integration
    version(gl3n) {
        /// If glamour gets compiled with version=gl3n support for
        /// vectors, matrices and quaternions is added
        void uniform(S : string, T)(S name, T value) if(is_vector!T) {
            static if(T.dimension == 2) {
                glUniform2fv(get_uniform_location(name), value.value_ptr);
            } else static if(T.dimension == 3) {
                glUniform3fv(get_uniform_location(name), value.value_ptr);
            } else static if(T.dimension == 4) {
                glUniform4fv(get_uniform_location(name), value.value_ptr);
            } else static assert(false);
        }
        
        /// ditto
        void uniform(S : string, T)(S name, T value) if(is_matrix!T) {
            static if((T.rows == 2) && (T.cols == 2)) {
                glUniformMatrix2fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 3) && (T.cols == 3)) {
                glUniformMatrix3fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 4) && (T.cols == 4)) {
                glUniformMatrix4fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 2) && (T.cols == 3)) {
                glUniformMatrix2x3fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 3) && (T.cols == 2)) {
                glUniformMatrix3x2fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 2) && (T.cols == 4)) {
                glUniformMatrix2x4fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 4) && (T.cols == 2)) {
                glUniformMatrix4x2fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 3) && (T.cols == 4)) {
                glUniformMatrix3x4fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static if((T.rows == 4) && (T.cols == 3)) {
                glUniformMatrix4x3fv(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
            } else static assert(false, "Can not upload type " ~ T.stringof ~ " to GPU as uniform");
        }
        
        /// ditto
        void uniform(S : string, T)(S name, T value) if(is_quaternion!T) {
            glUniform4fv(get_uniform_location[name], value.value_ptr);
        } 
    } else {
        void uniform(S, T)(S name, T value) {
            static assert(false, "you have to compile glamour with version=gl3n to use Shader.uniform");
        }
    }
    
    /// Sets a shader uniform. Consider the corresponding OpenGL for more information.
    void uniform1i(string name, int value) {
        glUniform1i(get_uniform_location(name), value);
    }
    
    /// ditto
    void uniform1f(string name, float value) {
        glUniform1f(get_uniform_location(name), value);
    }
    
    /// ditto
    void uniform2f(string name, float value1, float value2) {
        glUniform2f(get_uniform_location(name), value1, value2);
    }

    /// ditto
    void uniform2fv(string name, const float[] value) {
        glUniform2fv(get_uniform_location(name), value.length/2, value.ptr);
    }
    
    /// ditto
    void uniform3fv(string name, const float[] value) {
        glUniform3fv(get_uniform_location(name), value.length/3, value.ptr);
    }
    
    /// ditto
    void uniform4fv(string name, const float[] value) {
        glUniform4fv(get_uniform_location(name), value.length/4, value.ptr);
    }
    
    /// ditto
    void uniform_matrix3fv(string name, const float[] value, GLboolean transpose=GL_TRUE) {
        glUniformMatrix3fv(get_uniform_location(name), value.length/9, transpose, value.ptr);
    }
    
    /// ditto
    void uniform_matrix4fv(string name, const float[] value, GLboolean transpose=GL_TRUE) {
        glUniformMatrix4fv(get_uniform_location(name), value.length/16, transpose, value.ptr);
    }
    
}
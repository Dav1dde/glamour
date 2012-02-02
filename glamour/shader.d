module glamour.shader;

private {
    import derelict.opengl.gl : GLenum, GLuint, GLint, GLchar,
                                GL_VERTEX_SHADER,
//                                 GL_TESS_CONTROL_SHADER, GL_TESS_EVALUATION_SHADER,
                                GL_GEOMETRY_SHADER, GL_FRAGMENT_SHADER,
                                GL_LINK_STATUS, GL_FALSE, GL_INFO_LOG_LENGTH,
                                GL_COMPILE_STATUS,
                                glCreateProgram, glCreateShader, glCompileShader,
                                glLinkProgram, glGetShaderiv, glGetShaderInfoLog,
                                glGetProgramInfoLog, glGetProgramiv, glShaderSource,
                                glUseProgram, glAttachShader;

    import std.file : readText;
    import std.path : baseName, stripExtension;
    import std.string : format, splitLines;
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


class ShaderError : Exception {
    this(string msg) {
        super(msg);
    }
}

void compile_shader(GLuint shader) {
    glCompileShader(shader);

    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if(status == GL_FALSE) {
        GLint infolog_length;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infolog_length);
        
        GLchar[] infolog = new GLchar[infolog_length+1];
        glGetShaderInfoLog(shader, infolog_length, null, infolog.ptr);
        
        throw new ShaderError(infolog.idup);
    }
}

void link_program(GLuint program) {
    glLinkProgram(program);

    GLint status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if(status == GL_FALSE) {
        GLint infolog_length;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infolog_length);

        GLchar[] infolog = new GLchar[infolog_length + 1];
        glGetProgramInfoLog(program, infolog_length, null, infolog.ptr);
        
        throw new ShaderError(infolog.idup);
    }
}


alias Tuple!(size_t, "line", string, "text") Line; 

struct Shader {
    GLuint program;
    
    Line[][string] shaders;
    string directives;
    
    string filename;
    
    GLint[string] uniform_locations;
    GLint[string] attrib_locations;
    
    this(string file) {
        this(stripExtension(baseName(file)), readText(file));
    }

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
    
    void bind() {
        glUseProgram(program);
    }
    
    void unbind() {
        glUseProgram(0);
    }
    
    GLint get_attrib_location(string name) {
        if(name !in attrib_locations) {
            attrib_locations[name] = glGetAttribLocation(program, name);
        }
        
        return attrib_locations[name];
    }
    
    GLint get_uniform_location(string name) {
        if(name !in uniform_locations) {
            attrib_locations[name] = glGetUniformLocation(program, name);
        }
        
        return uniform_locations[name];
    }
    
    void uniform(S : string, T) i {
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
                glUniformMatrix3v(get_uniform_location(name), 1, GL_TRUE, value.value_ptr);
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
    
    void uniform1i(string name, int value) {
        glUniform1i(get_uniform_location[name], value);
    }
    
    void uniform1f(string name, float value) {
        glUniform1f(get_uniform_location[name], value);
    }

    void uniform2f(string name, float value1, float value2) {
        glUniform2f(get_uniform_location[name], value1, value2);
    }

    void uniform2fv(string name, const float[] value) {
        glUniform2fv(get_uniform_location[name], value.ptr);
    }
    
    void uniform3fv(string name, const float[] value) {
        glUniform3fv(get_uniform_location[name], value.ptr);
    }
    
    void uniform4fv(string name, const float[] value) {
        glUniform4fv(get_uniform_location[name], value.ptr);
    }
    
    void uniform_matrix3fv(string name, const float[] value) {
        glUniformMatrix3fv(get_uniform_location[name], value.ptr);
    }
    
    void uniform_matrix4fv(string name, const float[] value) {
        glUniformMatrix4fv(get_uniform_location[name], value.ptr);
    }
    
}
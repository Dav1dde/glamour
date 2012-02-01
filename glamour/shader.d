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
}
module orange.font;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import std.exception : enforce;
import orange.buffer;
import orange.shader;
import orange.window;
import orange.surface;
import orange.renderer;
//import opengl.glew;
import derelict.opengl3.gl3;

import std.stdio;
import std.string;

private class FontUnit {
  public:
    this(string file, int size) {
      if (!_initialized) {
        _initialized = true;
        DerelictSDL2ttf.load();
        if (TTF_Init() == -1)
          throw new Exception("TTF_Init() failed");
      }
       
      _font = TTF_OpenFont(toStringz(file), size); 
      enforce(_font !is null, "TTF_OpenFont() failed");

      _instance ~= this;
    }
     
    ~this() {
      debug(tor) writeln("FontUnit dtor");
      TTF_CloseFont(_font);
    }
     
    static ~this() {
      debug(tor) writeln("FontUnit static dtor");
      if (_initialized) {
        foreach (v; _instance) destroy(v);
        TTF_Quit();
      }
    }

    //alias _font this;
    @property {
      TTF_Font* unit() {
        return _font;
      } 
    }

  private:
    static bool _initialized;
    static FontUnit[] _instance;
    TTF_Font* _font;
}
 
class Font {
  public:
    this(){}

    this(string file) {
      load(file);
    }

    ~this() {
      debug(tor) writeln("Font dtor");
    }

    void load(string file) {
      foreach (size; _sizeList)
        _fonts[size] = new FontUnit(file, size);
    }

    //alias _fonts this;
    TTF_Font* unit(int size) {
      return _fonts[size].unit; 
    }

  private:
    FontUnit[int] _fonts;
    static immutable auto _sizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14,
                                        15, 16, 17, 18, 20, 22, 24, 26,
                                        28, 32, 36, 40, 48, 56, 64, 72 ];
}

/*
class Font {
  public:
    this(string file) {
      if (!_isLoaded) {
        _isLoaded = true;
        DerelictSDL2ttf.load();
        if (TTF_Init() == -1)
          throw new Exception("TTF_Init() failed");
      }
       
      foreach (size; _sizeList) {
        _list[size] = TTF_OpenFont(cast(char*)file, size);
        enforce(_list[size] != null, "TTF_OpenFont() failed");
      }

      _instance ~= this;
    }
     
    ~this() {
      debug(tor) writeln("Font dtor");
      foreach (font; _list)
        TTF_CloseFont(font);
    }
     
    static ~this() {
      debug(tor) writeln("Font static dtor");
      if (_isLoaded) {
        foreach (v; _instance) destroy(v);
        TTF_Quit();
      }
    }
     
    static immutable auto _sizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14,
                                        15, 16, 17, 18, 20, 22, 24, 26,
                                        28, 32, 36, 40, 48, 56, 64, 72 ];
    //alias _list this; // Cause segv
    @property {
      TTF_Font* list(int size) {
        return _list[size];
      }
    }

    TTF_Font*[int] _list;
     
  private:
    static bool _isLoaded = false;
    static Font[] _instance;
}
*/

class FontRenderer {
  public:
    this(GLuint program) { //TODO program受け取らない
      _vboHdr = new VBOHdr(2, program);
      _texHdr = new TexHdr(program);
      _ibo = new IBO;
      _ibo.create([0, 1, 2, 2, 3, 0]);
      _surf = new Surface;

      _drawMode = DrawMode.Triangles;

      _tex = [ 0.0, 0.0,
               1.0, 0.0,
               1.0, 1.0,
               0.0, 1.0 ];        
      _locNames = ["pos", "texCoord"];
      _strides = [ 3, 2 ]; 

      //debug(tor) writeln("FontHdr ctor");
    }

    ~this() {
      debug(tor) writeln("FontRenderer dtor");
    }

    void set_font(Font font) {
      _font = font;
    }

    void set_color(ubyte r, ubyte g, ubyte b) {
      _color = SDL_Color(r, g, b);
    }

    //void draw(float x, float y, string text, int size = _font.keys[0]) { // TODO
    void draw(float x, float y, string text, int size) {
      //enforce(size in _font, "font size error. you call wrong size of the font which is not loaded");

      _surf.create_ttf(_font, size, text, _color);
      _surf.convert();

      float[12] pos = set_pos(x, y, _surf);
      _vboHdr.create_vbo(pos, _tex);
      _vboHdr.enable_vbo(_locNames, _strides);

      _texHdr.create(_surf, "tex");
      _texHdr.enable();
      _ibo.draw(_drawMode);
      _texHdr.disable();
    }

  private:
    float[12] set_pos(float x, float y, Surface surf) {
      auto startX = x / (WINDOW_X/2.0);
      auto startY = y / (WINDOW_Y/2.0);
      auto w = surf.w / (WINDOW_X/2.0);
      auto h = surf.h / (WINDOW_Y/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    Surface _surf;
    //Font[int] _font;
    Font _font;
    SDL_Color _color;

    float[8] _tex;
    string[2] _locNames;
    int[2] _strides;

    VBOHdr _vboHdr;
    IBO _ibo;
    TexHdr _texHdr;
    DrawMode _drawMode;
}








/*
class FontRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 3, 2 ];
      mixin FontShaderSource;
      init(FontShader, 2, locNames, strides, DrawMode.Triangles);

      _program.use();
      init_vbo();
      init_ibo();
    }

    void load(string file, int[] sizeList...) {
      if (sizeList.length == 0) {
        sizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14, // TODO immutableにする
                     15, 16, 17, 18, 20, 22, 24, 26,
                     28, 32, 36, 40, 48, 56, 64, 72 ];
      }

      foreach (size; sizeList)
        _font[size] = new Font(file, size);
    }

    override void render() {
      _program.use();
      _ibo.draw(_drawMode);
    }

  private:
    void init_vbo() {
      _mesh = [ -1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, -1.0, 0.0, -1.0, -1.0, 0.0 ];
      _texCoord = [ 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0 ];
    }

    void init_ibo() {
      int[] index = [ 0, 1, 2, 0, 2, 3 ];
      _ibo = new IBO;
      _ibo.create(index);
    }

    float[12] set_pos(float x, float y, Surface surf) {
      auto startX = x / (WINDOW_X/2.0);
      auto startY = y / (WINDOW_Y/2.0);
      auto w = surf.w / (WINDOW_X/2.0);
      auto h = surf.h / (WINDOW_Y/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    IBO _ibo;
    float[] _mesh;
    float[] _texCoord;

    Surface _surf;
    Font[int] _font;
    SDL_Color _color;
}
*/

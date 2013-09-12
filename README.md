glamour
=======

*Glamour* is an OpenGL wrapper for the D programming language.

## Installation ##

*Glamour* supports these `-version` switches:

* `-version=gl3n` – Adds gl3n support to glamour (you can pass gl3n vectors and matrices directly as uniform).
* `-version=Derelict3` – Uses Derelict3 instead of Derelict2 for `glamour.gl`.
* `-version=stb` – Uses `stb_image` to load textures from images.
* `-version=SDLImage` - Uses the `SDL` to load textures from images, this requires `Derelict2` or `Derelict3`.

To build glamour I recommend you to use the `Makefile`:

```
# to build with stb_image
wget -O stb_image.d https://bitbucket.org/dav1d/gl-utils/raw/tip/stb_image/stb_image.d
make DCFLAGS+="-version=Derelict3 -version=stb -version=gl3n `pkg-config --libs --cflags gl3n`"

# installing
make install
```
## Example ##

Simple examples are available now in example directory. The simplest way to try them, is to use the dub package manager.
Go to directory where glamour is installed and use the following:
```
dub run --config=example
dub run --config=example_texture
```
This command installs all dependencies, builds the example and runs it. 

## Documentation ##

[http://dav1dde.github.com/glamour/](http://dav1dde.github.com/glamour/)
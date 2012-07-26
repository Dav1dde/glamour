glamour
=======

*Glamour* is an OpenGL wrapper for the D programming language.

## Installation ##

*Glamour* supports three `-version` switches:

* `-version=gl3n` – Adds gl3n support to glamour (you can pass gl3n vectors and matrices directly as uniform).
* `-version=Derelict3` – Uses Derelict3 instead of Derelict2 for `glamour.gl`.
* `-version=stb` – Uses `stb_image` to load textures from images.

To build glamour I recommend you to use the `Makefile`:

```
# to build with stb_image
wget -O stb_image.d https://bitbucket.org/dav1d/gl-utils/raw/tip/stb_image/stb_image.d
make DCFLAGS+="-version=Derelict3 -version=stb -version=gl3n `pkg-config --libs --cflags gl3n`"

# installing
make install
```


## Documentation ##

[http://dav1dde.github.com/glamour/](http://dav1dde.github.com/glamour/)
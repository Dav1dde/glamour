Ddoc

$(B Glamour) is an OpenGL wrapper for the D programming language.

$(B Glamour) supports these `-version` switches:

---
-version=gl3n – Adds gl3n support to glamour (you can pass gl3n vectors and matrices directly as uniform).
-version=Derelict3 – Uses Derelict3 instead of Derelict2 for `glamour.gl`.
-version=stb – Uses `stb_image` to load textures from images.
-version=SDLImage - Uses the `SDL` to load textures from images, this requires `Derelict2` or `Derelict3`.
---

To build glamour as library with the Makefile:

---
# to build with stb_image
wget -O stb_image.d https://bitbucket.org/dav1d/gl-utils/raw/tip/stb_image/stb_image.d
make DCFLAGS+="-version=Derelict3 -version=stb -version=gl3n `pkg-config --libs --cflags gl3n`"

# installing
make install
---

If you don't want glamour as library, I recommend you to use this repository as $(I git submodule)
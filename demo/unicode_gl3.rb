# coding: utf-8
require 'opengl'
require 'glfw'
require_relative '../nuklear'
require_relative './nkglfw_gl3'

if OpenGL.get_platform == :OPENGL_PLATFORM_WINDOWS
  OpenGL.load_lib()
  GLFW.load_lib('glfw3.dll')
  Nuklear.load_lib('nuklear.dll')
elsif OpenGL.get_platform == :OPENGL_PLATFORM_LINUX
  OpenGL.load_lib('libGL.so', '/usr/lib/x86_64-linux-gnu')
  GLFW.load_lib('libglfw.so', '/usr/lib/x86_64-linux-gnu')
  Nuklear.load_lib('./libnuklear.so')
else
  OpenGL.load_lib()
  GLFW.load_lib()
  Nuklear.load_lib('libnuklear.dylib')
end

include OpenGL
include GLFW
include Nuklear

$nkglfw = NKGLFWContext.new

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600

MAX_VERTEX_BUFFER = 512 * 1024
MAX_ELEMENT_BUFFER = 128 * 1024

NK_FONT_JAPANESE_GLYPH_RANGES = [
  0x0020, 0x00FF,
  0x2200, 0x22FF, # Mathematical Operators
  0x3000, 0x303F, # CJK Symbols and Punctuation
  0x3040, 0x309F, # Hiragana
  0x30A0, 0x30FF, # Katakana
  0xFF00, 0xFFEF, # Halfwidth and Fullwidth Forms
  0x4E00, 0x9FFF, # CJK Unified Ideographs
  0
].pack('L*')
$range_japanese = FFI::MemoryPointer.new(:uint, NK_FONT_JAPANESE_GLYPH_RANGES.size, false)
$range_japanese.write_string(NK_FONT_JAPANESE_GLYPH_RANGES)

# Press ESC to exit.
key_callback = GLFW::create_callback(:GLFWkeyfun) do |window_handle, key, scancode, action, mods|
  if key == GLFW_KEY_ESCAPE && action == GLFW_PRESS
    glfwSetWindowShouldClose(window_handle, 1)
  end
end

if __FILE__ == $0
  glfwInit()

  if OpenGL.get_platform == :OPENGL_PLATFORM_MACOSX
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE)
  end
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3)
  window = glfwCreateWindow( WINDOW_WIDTH, WINDOW_HEIGHT, "Ruby-Nuklear Demo (GL3)", nil, nil )
  glfwMakeContextCurrent( window )

  glfwSetKeyCallback( window, key_callback )

  ctx = $nkglfw.create(window, install_callback: false )
  atlas = $nkglfw.font_stash_begin()

  # Load fonts you like
  loaded_font = nil
  File.open("./data/GenShinGothic-Normal.ttf", "rb") do |ttf_file|
    ttf_size = ttf_file.size()
    ttf = FFI::MemoryPointer.new(:uint8, ttf_size)
    content = ttf_file.read
    ttf.put_bytes(0, content)
    conf = nk_font_config(0)
    conf[:range] = $range_japanese
    loaded_font = nk_font_atlas_add_from_memory(atlas, ttf, ttf_size, 22, conf)
  end
  $nkglfw.font_stash_end(loaded_font)

  background = nk_rgb(64, 140, 216)

  compression_property = FFI::MemoryPointer.new(:int32, 1)
  compression_property.put_int32(0, 20)

  difficulty_option = FFI::MemoryPointer.new(:int32, 1)
  difficulty_option.put_int32(0, 0)

  while glfwWindowShouldClose( window ) == 0
    # Input
    glfwPollEvents()
    $nkglfw.new_frame()

    # GUI
    rect = NK_RECT.new
    rect[:x] = 50.0
    rect[:y] = 50.0
    rect[:w] = 230.0
    rect[:h] = 250.0

    # Setup widgets
    r = nk_begin(ctx, "Ｒｕｂｙ−Ｎｕｋｌｅａｒ", rect,
                 NK_PANEL_FLAGS[:NK_WINDOW_BORDER]|
                 NK_PANEL_FLAGS[:NK_WINDOW_MOVABLE]|
                 NK_PANEL_FLAGS[:NK_WINDOW_SCALABLE]|
                 NK_PANEL_FLAGS[:NK_WINDOW_MINIMIZABLE]|
                 NK_PANEL_FLAGS[:NK_WINDOW_TITLE])
    if r != 0
      # Setup Widgets Here
      nk_layout_row_static(ctx, 30, 80, 1)
      nk_button_label(ctx, "ボタン")
      nk_layout_row_dynamic(ctx, 30, 2)
      if nk_option_label(ctx, "かんたん", (difficulty_option.get_int32(0) == 0) ? 1 : 0) != 0
        difficulty_option.put_int32(0, 0)
      end
      if nk_option_label(ctx, "難しい", (difficulty_option.get_int32(0) == 1) ? 1 : 0) != 0
        difficulty_option.put_int32(0, 1)
      end

      nk_layout_row_dynamic(ctx, 25, 1)
      nk_property_int(ctx, "圧縮：", 0, compression_property, 100, 10, 1)
      nk_layout_row_dynamic(ctx, 20, 1)
      nk_label(ctx, "背景の色：", NK_TEXT_ALIGNMENT[:NK_TEXT_LEFT])
      nk_layout_row_dynamic(ctx, 25, 1)
      res = nk_combo_begin_color(ctx, background, nk_vec2(nk_widget_width(ctx),400))
      if res != 0
        nk_layout_row_dynamic(ctx, 120, 1)
        background = nk_color_picker(ctx, background, NK_COLOR_FORMAT[:NK_RGBA])
        nk_combo_end(ctx)
      end
    end
    nk_end(ctx)

    # Render
    glViewport(0, 0, $nkglfw.width, $nkglfw.height)
    glClear(GL_COLOR_BUFFER_BIT)
    glClearColor( background[:r] / 255.0, background[:g] / 255.0, background[:b] / 255.0, 1.0 )
    $nkglfw.render(NK_ANTI_ALIASING[:NK_ANTI_ALIASING_ON], MAX_VERTEX_BUFFER, MAX_ELEMENT_BUFFER)

    glfwSwapBuffers( window )
  end

  $nkglfw.destroy()

  glfwDestroyWindow( window )
  glfwTerminate()
end

# GLSL #include expansion for OpenGL replacement shaders.
#
# GLSL has no #include. OpenGL replacements are embedded as raw text and
# compiled by the driver at runtime, so shared code (for example PsychoV) is
# resolved here at configure time. The output is still plain GLSL text, not
# SPIR-V, so OpenGL 4.3 contexts keep working and the original uniform names
# stay visible to glGetUniformLocation.
#
#   renodx_glsl_expand(<out_var> <source_file> <search_dirs>)
#
# Lookup for #include "name": the including file's folder first, then each
# entry of <search_dirs> in order. Each file is inserted at most once per
# expansion, so shared files do not need include guards. A missing include is
# a fatal configure error. Expanded files are returned in
# RENODX_GLSL_INCLUDED_FILES so the caller can add them to CMAKE_CONFIGURE_DEPENDS.

function(renodx_glsl_expand_file FILE_PATH SEARCH_DIRS INCLUDED_IN OUT_VAR INCLUDED_OUT)
  get_filename_component(FILE_ABS "${FILE_PATH}" ABSOLUTE)
  get_filename_component(FILE_DIR "${FILE_ABS}" DIRECTORY)

  set(INCLUDED "${INCLUDED_IN}")
  list(APPEND INCLUDED "${FILE_ABS}")

  file(READ "${FILE_ABS}" CONTENT)
  string(REPLACE "\r" "" CONTENT "${CONTENT}")

  # Matches one whole #include "..." line. Group 1 is the preceding newline
  # (or start of file), group 2 is the quoted name.
  set(PATTERN "(^|\n)[ \t]*#[ \t]*include[ \t]+\"([^\"]+)\"[ \t]*(\n|$)")
  while("${CONTENT}" MATCHES "${PATTERN}")
    set(LEAD "${CMAKE_MATCH_1}")
    set(MATCHED "${CMAKE_MATCH_0}")
    set(INC_NAME "${CMAKE_MATCH_2}")

    set(INC_PATH "")
    foreach(DIR IN LISTS FILE_DIR SEARCH_DIRS)
      if(EXISTS "${DIR}/${INC_NAME}")
        get_filename_component(INC_PATH "${DIR}/${INC_NAME}" ABSOLUTE)
        break()
      endif()
    endforeach()
    if(NOT INC_PATH)
      message(FATAL_ERROR "GLSL #include \"${INC_NAME}\" not found (included from ${FILE_ABS})")
    endif()

    set(BODY "")
    list(FIND INCLUDED "${INC_PATH}" SEEN)
    if(SEEN EQUAL -1)
      renodx_glsl_expand_file("${INC_PATH}" "${SEARCH_DIRS}" "${INCLUDED}" BODY_OUT CHILD_INCLUDED)
      set(BODY "${BODY_OUT}")
      set(INCLUDED "${CHILD_INCLUDED}")
    endif()

    string(REPLACE "${MATCHED}" "${LEAD}${BODY}\n" CONTENT "${CONTENT}")
  endwhile()

  set(${OUT_VAR} "${CONTENT}" PARENT_SCOPE)
  set(${INCLUDED_OUT} "${INCLUDED}" PARENT_SCOPE)
endfunction()

function(renodx_glsl_expand OUT_VAR SOURCE_FILE SEARCH_DIRS)
  renodx_glsl_expand_file("${SOURCE_FILE}" "${SEARCH_DIRS}" "" EXPANDED INCLUDED)
  set(${OUT_VAR} "${EXPANDED}" PARENT_SCOPE)
  set(RENODX_GLSL_INCLUDED_FILES "${INCLUDED}" PARENT_SCOPE)
endfunction()

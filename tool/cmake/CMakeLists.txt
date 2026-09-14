cmake_minimum_required(VERSION 3.22)
project(mneme_transcribe_android)

# Android release wrapper around the pinned transcribe.cpp tree. A wrapper
# (rather than CMAKE_PROJECT_TOP_LEVEL_INCLUDES, which runs before
# subdirectory targets exist) is the only injectable point that runs after
# every target is created.
if(NOT DEFINED TRANSCRIBE_SOURCE_DIR)
    message(FATAL_ERROR "Pass -DTRANSCRIBE_SOURCE_DIR=<transcribe.cpp checkout>")
endif()
add_subdirectory(${TRANSCRIBE_SOURCE_DIR} transcribe)

# Android ships plain .so names: versioned files never reach the APK and
# the loader resolves each dependency by exact filename. NO_SONAME alone
# clears the versioned files but leaves dependents recording the relative
# link path, so each target also gets an explicit plain SONAME (recorded
# in dependents as a basename). Desktop builds configure the tree
# directly and keep versions.
if(ANDROID)
    # The tree addresses its public headers via CMAKE_SOURCE_DIR, which is
    # this wrapper when nested: re-point the public include path at the
    # real tree (the dangling original entry is harmless).
    target_include_directories(
        transcribe
        PUBLIC
            $<BUILD_INTERFACE:${TRANSCRIBE_SOURCE_DIR}/include>)
    foreach(_tgt transcribe ggml ggml-base ggml-cpu)
        if(TARGET ${_tgt})
            set_target_properties(
                ${_tgt}
                PROPERTIES NO_SONAME ON LINK_OPTIONS "-Wl,-soname,lib${_tgt}.so")
            message(STATUS "mneme: ${_tgt} builds unversioned for Android")
        endif()
    endforeach()
endif()

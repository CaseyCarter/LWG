cmake_minimum_required(VERSION 3.28)

project(lwg)

### Configuration

set(mailing_directory ${CMAKE_CURRENT_SOURCE_DIR}/mailing)

# Tell MSVC to behave
add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8;/Zc:__cplusplus;\
$<$<VERSION_LESS:$<TARGET_PROPERTY:CXX_STANDARD>,20>:/permissive->>")

# Enable ASan (and UBSan with non-MSVC) for Debug builds
set(sanitizer_options "$<$<CONFIG:Debug>:\
-fsanitize=address$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:$<COMMA>undefined>>")
add_compile_options(${sanitizer_options})
add_link_options(${sanitizer_options})

# Enable Standard Library assertions
include(CheckCXXSymbolExists)

if(cxx_std_20 IN_LIST CMAKE_CXX_COMPILE_FEATURES)
    set(cxx_detect_header version)
else()
    set(cxx_detect_header ciso646)
endif()

check_cxx_symbol_exists(__GLIBCXX__ ${cxx_detect_header} stl_is_libstdcxx)
if(${stl_is_libstdcxx})
    add_compile_definitions(_GLIBCXX_ASSERTIONS_ $<$<CONFIG:Debug>:_GLIBCXX_DEBUG>)
endif()

check_cxx_symbol_exists(_LIBCPP_VERSION ${cxx_detect_header} stl_is_libcxx)
if(${stl_is_libcxx})
    # Untested:
    add_compile_definitions(_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE$<IF:$<CONFIG:Debug>,_DEBUG,_FAST>)
endif()

check_cxx_symbol_exists(_MSVC_STL_VERSION ${cxx_detect_header} stl_is_msvcstl)
if(${stl_is_msvcstl})
    add_compile_definitions(_CONTAINER_DEBUG_LEVEL)
endif()

# LTO, because why not
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE On)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO On)

### Program targets
add_library(lwg
    src/date.cpp src/issues.cpp src/mailing_info.cpp src/metadata.cpp
    src/report_generator.cpp src/sections.cpp src/status.cpp)
target_sources(lwg PUBLIC FILE_SET headers TYPE HEADERS BASE_DIRS src
    FILES src/date.h src/html_utils.h src/issues.h src/mailing_info.h
          src/metadata.h src/report_generator.h src/sections.h src/status.h)
target_compile_features(lwg PUBLIC cxx_std_17)

add_executable(list_issues src/list_issues.cpp)
target_link_libraries(list_issues lwg)

add_executable(lists src/lists.cpp)
target_link_libraries(lists lwg)

add_executable(section_data src/section_data.cpp)
target_link_libraries(section_data lwg)

add_executable(set_status src/set_status.cpp)
target_link_libraries(set_status lwg)

add_executable(toc_diff src/toc_diff.cpp)
target_link_libraries(toc_diff lwg)

file(GLOB issue_files CONFIGURE_DEPENDS xml/issue*.xml)
add_custom_command(OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/meta-data/dates
    COMMENT "Refreshing 'Last modified' timestamps for issues..."
    COMMAND git whatchanged --no-show-signature --pretty=%ct | python bin/make_dates.py > meta-data/dates
    VERBATIM
    MAIN_DEPENDENCY bin/make_dates.py DEPENDS ${issue_files}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

### Utility targets
add_custom_target(build_lists COMMAND lists DEPENDS lists mailing
    COMMENT "Generating HTML lists"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

add_custom_target(dates DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/meta-data/dates)

add_custom_target(distclean DEPENDS clean COMMAND cmake -E rm -rf ${mailing_directory} VERBATIM)

add_custom_target(lint COMMAND bash -c bin/lint.sh VERBATIM
    COMMENT "Validating XML issue files"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

add_custom_target(pgms DEPENDS lists section_data toc_diff list_issues set_status)

add_custom_target(history COMMAND lists revision history VERBATIM DEPENDS lists
    COMMENT "Generating revision history"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

add_custom_target(mailing COMMAND ${CMAKE_COMMAND} -E make_directory ${mailing_directory} VERBATIM)

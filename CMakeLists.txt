cmake_minimum_required(VERSION 3.28)

project(lwg)

# MSVC needs `/permissive-` only with C++17
add_compile_options($<$<AND:$<CXX_COMPILER_ID:MSVC>,$<VERSION_LESS:$<TARGET_PROPERTY:CXX_STANDARD>,20>>:/permissive->)

set(mailing_directory ${CMAKE_CURRENT_SOURCE_DIR}/mailing)

add_custom_target(distclean DEPENDS clean COMMAND cmake -E rm -rf ${mailing_directory}) # FIXME: incomplete

add_library(lwg OBJECT
    src/date.cpp src/issues.cpp src/mailing_info.cpp src/metadata.cpp
    src/report_generator.cpp src/sections.cpp src/status.cpp)
target_sources(lwg PUBLIC FILE_SET headers TYPE HEADERS BASE_DIRS src
    FILES src/date.h src/html_utils.h src/issues.h src/mailing_info.h src/metadata.h
          src/report_generator.h src/sections.h src/status.h)
target_compile_features(lwg PUBLIC cxx_std_17)

add_executable(list_issues src/list_issues.cpp)
target_compile_features(list_issues PRIVATE cxx_std_17)
target_link_libraries(list_issues lwg)

add_executable(lists src/lists.cpp)
target_compile_features(lists PRIVATE cxx_std_17)
target_link_libraries(lists lwg)

add_executable(section_data src/section_data.cpp)
target_compile_features(section_data PRIVATE cxx_std_17)

add_executable(set_status src/set_status.cpp)
target_compile_features(set_status PRIVATE cxx_std_17)
target_link_libraries(set_status lwg)

add_executable(toc_diff src/toc_diff.cpp)
target_compile_features(toc_diff PRIVATE cxx_std_17)

add_custom_target(pgms DEPENDS lists section_data toc_diff list_issues set_status)

add_custom_target(history COMMAND lists revision history DEPENDS lists WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

add_custom_target(mailing COMMAND ${CMAKE_COMMAND} -E make_directory ${mailing_directory})

add_custom_target(build_lists COMMAND lists DEPENDS lists mailing WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

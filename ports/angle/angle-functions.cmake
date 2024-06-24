function(checkout_in_path PATH URL REF)
    if(EXISTS "${PATH}")
        file(GLOB FILES "${PATH}/*")
        if(NOT "${FILES}" STREQUAL "")
            return()
        endif()
        file(REMOVE_RECURSE "${PATH}")
    endif()

    vcpkg_from_git(
        OUT_SOURCE_PATH DEP_SOURCE_PATH
        URL "${URL}"
        REF "${REF}"
    )
    file(RENAME "${DEP_SOURCE_PATH}" "${PATH}")
    file(REMOVE_RECURSE "${DEP_SOURCE_PATH}")
endfunction()


function(append_gn_option NAME ENABLED)
    if(${ENABLED})
        set(GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} ${NAME}=true" PARENT_SCOPE)
    else()
        set(GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} ${NAME}=false" PARENT_SCOPE)
    endif()
endfunction()

function(checkout_dependencies)
    foreach(dep IN LISTS ARGV)
        separate_arguments(dep_parts UNIX_COMMAND "${dep}")
        list(GET dep_parts 0 rel_path)
        list(GET dep_parts 1 repo)
        list(GET dep_parts 2 commit)
        
        checkout_in_path(
            "${SOURCE_PATH}/${rel_path}"
            "${repo}"
            "${commit}"
        )
    endforeach()
endfunction()

function(fetch_angle_commit_id)
    file(READ "${SOURCE_PATH}/src/commit_id.py" COMMIT_ID_SCRIPT_CONTENT)
    if("${COMMIT_ID_SCRIPT_CONTENT}" MATCHES "commit_id_size = ([0-9]+)")
        set(ANGLE_COMMIT_HASH_SIZE ${CMAKE_MATCH_1})
        string(SUBSTRING "${ANGLE_COMMIT}" 0 ${ANGLE_COMMIT_HASH_SIZE} ANGLE_COMMIT_ID)
        set(ANGLE_COMMIT_ID "${ANGLE_COMMIT_ID}" PARENT_SCOPE)
        unset(ANGLE_COMMIT_HASH_SIZE)
    endif()
    unset(COMMIT_ID_SCRIPT_CONTENT)
endfunction()

function(insert_msvc_library_loading_records TARGET_FILE LIBRARY_NAMES)
    if(NOT VCPKG_TARGET_IS_WINDOWS OR VCPKG_LIBRARY_LINKAGE STREQUAL static)
        message(WARNING "Incorrect usage of function")
        return()
    endif()

    # Note: This will only work with MSVC, but I don't know how to detect for MSVC
    file(READ "${CMAKE_CURRENT_LIST_DIR}/res/msvc-dynamic-link-record.cpp.in" LINK_RECORD_MODIFICATION_PATTERN)
    foreach(LIB_NAME ${LIBRARY_NAMES})
        string(APPEND LIBRARY_SEARCH_OBJECT_RECORD "    #pragma comment(lib, \"${LIB_NAME}.lib\")\n")
    endforeach()
    string(CONFIGURE "${LINK_RECORD_MODIFICATION_PATTERN}" LIBRARY_SEARCH_RECORD_PRAGMA_DIRECTIVE @ONLY)
    debug_message("Inserting \"${LIBRARY_SEARCH_RECORD_PRAGMA_DIRECTIVE}\" into ${TARGET_FILE}")

    file(READ ${TARGET_FILE} TARGET_FILE_BEFORE)
    file(APPEND ${TARGET_FILE} ${LIBRARY_SEARCH_RECORD_PRAGMA_DIRECTIVE})
    file(READ ${TARGET_FILE} TARGET_FILE_AFTER)
    
    # Sanity check:
    string(SHA256 TARGET_FILE_BEFORE "${TARGET_FILE_BEFORE}")
    string(SHA256 TARGET_FILE_AFTER "${TARGET_FILE_AFTER}")
    if("${TARGET_FILE_BEFORE}" STREQUAL "${TARGET_FILE_AFTER}")
        message(WARNING "Library search record was not inserted into file! DLL's might have to be manually added to binary folder.")
    endif()
endfunction()
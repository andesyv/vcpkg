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
        string(APPEND GN_CONFIGURE_OPTIONS " ${NAME}=true")
        # set(GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} ${NAME}=true" PARENT_SCOPE)
    else()
        string(APPEND GN_CONFIGURE_OPTIONS " ${NAME}=false")
        # set(GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} ${NAME}=false" PARENT_SCOPE)
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

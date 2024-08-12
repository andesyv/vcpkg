function(checkout_in_path PATH URL REF PATCHES)
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
        PATCHES "${PATCHES}"
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

        list(LENGTH dep_parts dep_parts_length)
        if(dep_parts_length GREATER 3)
            list(SUBLIST dep_parts 3 -1 patches)
        else()
            set(patches "")
        endif()

        debug_message("Checking out ${SOURCE_PATH}/${rel_path} using repo ${repo}@${commit} with patches: ${patches}")

        checkout_in_path(
            "${SOURCE_PATH}/${rel_path}"
            "${repo}"
            "${commit}"
            "${patches}"
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

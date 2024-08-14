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

function(append_gn_dependent_targets)
    cmake_parse_arguments(PARSE_ARGV 0 arg "" "TARGET;SOURCE_PATH;OUT_TARGET_LIST;OUT_LIBNAME_LIST" "")
    if(arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unparsed arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()

    string(REGEX REPLACE "^(:|/)" "" target_identifier "${arg_TARGET}")
    string(REPLACE "/" "_" target_identifier "${target_identifier}")

    vcpkg_find_acquire_program(GN)

    vcpkg_execute_required_process(
        COMMAND "${GN}" desc --all --type=static_library "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg" "${arg_TARGET}" deps
        WORKING_DIRECTORY "${arg_SOURCE_PATH}"
        LOGNAME "gn-dependent-targets-${target_identifier}-${TARGET_TRIPLET}-dbg"
    )

    file(READ "${CURRENT_BUILDTREES_DIR}/gn-dependent-targets-${target_identifier}-${TARGET_TRIPLET}-dbg-out.log" output)
    string(REGEX REPLACE "\n" ";" output "${output}")
    foreach(target IN LISTS output)
        if("${target}" STREQUAL "")
            continue()
        endif()
        string(REGEX REPLACE "^/" "" target "${target}")
        list(APPEND target_dependents_dbg "${target}")
    endforeach()
    list(SORT target_dependents_dbg)
    

    if(PORT_DEBUG)
        vcpkg_execute_required_process(
            COMMAND "${GN}" desc --all --type=static_library "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel" "${arg_TARGET}" deps
            WORKING_DIRECTORY "${arg_SOURCE_PATH}"
            LOGNAME "gn-dependent-targets-${target_identifier}-${TARGET_TRIPLET}-rel"
        )

        file(READ "${CURRENT_BUILDTREES_DIR}/gn-dependent-targets-${target_identifier}-${TARGET_TRIPLET}-rel-out.log" output)
        string(REGEX REPLACE "\n" ";" output "${output}")
        foreach(target IN LISTS output)
            if("${target}" STREQUAL "")
                continue()
            endif()
            string(REGEX REPLACE "^/" "" target "${target}")
            list(APPEND target_dependents_rel "${target}")
        endforeach()
        list(SORT target_dependents_rel)
    endif()

    debug_message("target_dependents_dbg: ${target_dependents_dbg}")
    if(PORT_DEBUG)
        debug_message("target_dependents_rel: ${target_dependents_rel}")
        if(NOT("${target_dependents_dbg}" STREQUAL "${target_dependents_rel}"))
            message(WARNING "Debug and release dependent targets differ. Results might not be correct.")
        endif()
    endif()

    list(APPEND "${arg_OUT_TARGET_LIST}" "${target_dependents_dbg}")
    set("${arg_OUT_TARGET_LIST}" "${${arg_OUT_TARGET_LIST}}" PARENT_SCOPE)


    vcpkg_execute_required_process(
        COMMAND "${GN}" desc --all --type=static_library --as=output "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg" "${arg_TARGET}" deps
        WORKING_DIRECTORY "${arg_SOURCE_PATH}"
        LOGNAME "gn-dependent-target-outputs-${target_identifier}-${TARGET_TRIPLET}-dbg"
    )

    file(READ "${CURRENT_BUILDTREES_DIR}/gn-dependent-target-outputs-${target_identifier}-${TARGET_TRIPLET}-dbg-out.log" target_output_files_dbg)
    string(REGEX REPLACE "\n" ";" target_output_files_dbg "${target_output_files_dbg}")
    list(SORT target_output_files_dbg)

    debug_message("target_output_files_dbg: ${target_output_files_dbg}")
    foreach(output_file IN LISTS target_output_files_dbg)
        debug_message("output_file: ${output_file}")
        get_filename_component(output_filename "${output_file}" NAME_WE)
        if(NOT("${output_filename}" STREQUAL ""))
            list(APPEND target_outputs_dbg "${output_filename}")
        endif()
    endforeach()
    list(SORT target_outputs_dbg)

    if(PORT_DEBUG)
        vcpkg_execute_required_process(
            COMMAND "${GN}" desc --all --type=static_library --as=output "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel" "${arg_TARGET}" deps
            WORKING_DIRECTORY "${arg_SOURCE_PATH}"
            LOGNAME "gn-dependent-target-outputs-${target_identifier}-${TARGET_TRIPLET}-rel"
        )

        file(READ "${CURRENT_BUILDTREES_DIR}/gn-dependent-target-outputs-${target_identifier}-${TARGET_TRIPLET}-rel-out.log" target_output_files_rel)
        string(REGEX REPLACE "\n" ";" target_output_files_rel "${target_output_files_rel}")

        debug_message("target_output_files_rel: ${target_output_files_rel}")
        foreach(output_file IN LISTS target_output_files_rel)
            debug_message("output_file: ${output_file}")
            get_filename_component(output_filename "${output_file}" NAME_WE)
            if(NOT("${output_filename}" STREQUAL ""))
                list(APPEND target_outputs_rel "${output_filename}")
            endif()
        endforeach()
        list(SORT target_outputs_rel)
    endif()

    
    debug_message("target_outputs_dbg: ${target_outputs_dbg}")
    if(PORT_DEBUG)
        debug_message("target_outputs_rel: ${target_outputs_rel}")
        if(NOT("${target_outputs_dbg}" STREQUAL "${target_outputs_rel}"))
            message(WARNING "Debug and release target outputs differ. Results might not be correct.")
        endif()
    endif()

    # set("${arg_OUT_LIBNAME_LIST}" "${target_outputs_dbg}" PARENT_SCOPE)
    list(APPEND "${arg_OUT_LIBNAME_LIST}" "${target_outputs_dbg}")
    set("${arg_OUT_LIBNAME_LIST}" "${${arg_OUT_LIBNAME_LIST}}" PARENT_SCOPE)
endfunction()

function(verify_windows_sdk)
    cmake_parse_arguments(PARSE_ARGV 0 arg "CHECK_FOR_DEBUGGING_TOOLS" "SDK_VERSION" "")
    if(arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unparsed arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()

    vcpkg_get_windows_sdk(WINDOWS_SDK)
    if(WINDOWS_SDK VERSION_LESS "${arg_SDK_VERSION}")
        message(FATAL_ERROR "Building on Windows requires a Windows SDK of ${arg_SDK_VERSION} or higher")
    else()
        debug_message("Found Windows SDK version: ${WINDOWS_SDK}")
    endif()

    if(${arg_CHECK_FOR_DEBUGGING_TOOLS})
        set(_dbghelp_dll_path "$ENV{WindowsSdkDir}Debuggers\\${TRIPLET_SYSTEM_ARCH}\\dbghelp.dll")
        if(NOT EXISTS "${_dbghelp_dll_path}")
            message(FATAL_ERROR "Cannot find debugging tools in Windows SDK ${WINDOWS_SDK}. Please reinstall/modify the Windows SDK and select \"Debugging Tools\".")
        else()
            debug_message("Found Windows SDK debugging tools: ${_dbghelp_dll_path}")
        endif()
    endif()
endfunction()
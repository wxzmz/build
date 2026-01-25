#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Armbian Build Framework
#
# This extension adds board name prefix to u-boot-rockchip.bin file based on BRANCH condition
# When BRANCH is not "legacy" or "vendor", the u-boot-rockchip.bin file will be prefixed with board name
# and copied to output/img directory

function extension_prepare_config__uboot_board_prefix() {
    display_alert "Preparing u-boot board prefix extension" "BOARD: ${BOARD}, BRANCH: ${BRANCH}" "info"
}

function post_uboot_custom_postprocess__add_board_prefix() {
    # This hook is called after u-boot custom postprocessing
    # We check if we're building for rockchip platform and if u-boot-rockchip.bin exists

    if [[ "${BOARDFAMILY}" != *"rockchip"* ]]; then
        display_alert "Skipping board prefix - not a rockchip board" "BOARDFAMILY: ${BOARDFAMILY}" "debug"
        return 0
    fi

    # Check if u-boot-rockchip.bin exists in current directory
    if [[ ! -f "u-boot-rockchip.bin" ]]; then
        display_alert "Skipping board prefix - u-boot-rockchip.bin not found" "$(pwd)" "debug"
        return 0
    fi

    # Check BRANCH condition: only add prefix if BRANCH is not "legacy" or "vendor"
    if [[ "${BRANCH}" == "legacy" || "${BRANCH}" == "vendor" ]]; then
        display_alert "Skipping board prefix - BRANCH is legacy or vendor" "BRANCH: ${BRANCH}" "debug"
        return 0
    fi

    display_alert "Adding board prefix to u-boot-rockchip.bin" "BOARD: ${BOARD}, BRANCH: ${BRANCH}" "info"

    # Create the prefixed filename
    local prefixed_filename="${BOARD}-u-boot-rockchip.bin"

    # Copy the original file to prefixed filename
    run_host_command_logged cp -v "u-boot-rockchip.bin" "${prefixed_filename}"

    # Also copy to output/images directory if it exists
    if [[ -d "${SRC}/output/images" ]]; then
        display_alert "Copying prefixed u-boot to output/images" "${prefixed_filename}" "info"
        run_host_command_logged cp -v "${prefixed_filename}" "${SRC}/output/images/"
    else
        display_alert "Creating output/images directory" "${SRC}/output/images" "info"
        run_host_command_logged mkdir -p "${SRC}/output/images"
        run_host_command_logged cp -v "${prefixed_filename}" "${SRC}/output/images/"
    fi

    display_alert "Board prefix added successfully" "${prefixed_filename} created in output/images" "info"
}

function pre_package_uboot_image__include_prefixed_bin() {
    # This hook is called before u-boot is packaged into .deb
    # We add the prefixed file to the packaging area if it exists

    if [[ "${BOARDFAMILY}" != *"rockchip"* ]]; then
        return 0
    fi

    # Check BRANCH condition
    if [[ "${BRANCH}" == "legacy" || "${BRANCH}" == "vendor" ]]; then
        return 0
    fi

    local prefixed_filename="${BOARD}-u-boot-rockchip.bin"

    if [[ -f "${prefixed_filename}" ]]; then
        display_alert "Including prefixed u-boot in package" "${prefixed_filename}" "info"

        # Copy the prefixed file to the packaging area
        run_host_command_logged cp -v "${prefixed_filename}" "${destination}/usr/lib/${uboot_name}/"


    fi
}

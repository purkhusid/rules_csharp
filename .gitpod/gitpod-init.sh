#! /usr/bin/env bash

# This script only updates the settings if it's run in a Gitpod workspace.
if [[ -n "${GITPOD_WORKSPACE_URL}" ]]; then
    if [[ -f ".bazelrc.user" ]]; then
        rm .bazelrc.user
    fi

    if [[ -f "examples/.bazelrc.user" ]]; then
        rm examples/.bazelrc.user
    fi

    cat <<EOT >> .bazelrc.user
build --disk_cache=/workspace/bazel-disk-cache
build --repository_cache=/workspace/bazel-repository-cache
build --local_cpu_resources="HOST_CPUS*2"
build --local_ram_resources="HOST_RAM*0.9"
build --sandbox_tmpfs_path=/tmp
build --jobs=32
startup --output_user_root=/workspace/bazel_user_root
startup --output_base=/workspace/bazel_output_base
EOT

    cp .bazelrc.user examples/.bazelrc.user
    mkdir -p .vscode && cp .gitpod/vscode.settings.json .vscode/settings.json
fi


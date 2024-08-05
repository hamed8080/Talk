#!/bin/bash

root=$(pwd)
sdk="$root/submodules/SDK"
appModules="$root/submodules/Talk"
baseURL="https://pubgi.sandpod.ir/chat/ios"
declare -a PACKEGE_PATHS=("Chat" "Async" "Logger" "Additive" "AdditiveUI" "ChatModels" "ChatDTO" "ChatCore" "ChatCache" "ChatTransceiver" "ChatExtensions" "Mocks")
declare -a PACKEGE_URLS=("chat" "async" "logger" "additive" "additive-ui" "chat-models" "chat-dto" "chat-core" "chat-cache" "chat-transceiver" "chat-extensions" "mocks")

executeInAll() {
    local cmd="$1"
    shift
    local args=("$@")

    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd "$sdk/$packagePath" || continue
        printDirectory
        eval "$cmd" "${args[@]}"
    done

    # Talk is another directory than sdk packages so we have to run it's commanads outside of the sdk directory
    cd "$root"
    printDirectory
    eval "$cmd" "${args[@]}"

    # After executing the jobs we should back to the root.
    cd "$root"
}

printDirectory() {
    echo "Changed directory to $(pwd)"
}

chch() {
    executeInAll "git checkout" "$1"
}

pushall() {
    executeInAll "git push" "$1" "$2"
}

switchAll() {
    executeInAll "git switch -c" "$1"
}

mergeAll() {
    executeInAll "git checkout" "$1"
    executeInAll "git merge" "$2"
}

mergeContinue() {
    executeInAll "git add ."
    executeInAll "git merge --continue"
}

commitAll() {
    executeInAll "git checkout" "$1"
    executeInAll "git add ."
    executeInAll "git commit -am" "$2"
}

statusAll() {
    executeInAll "git status"
}

undoAll() {
    executeInAll "git restore --staged ."
    executeInAll "git restore ."
}

amendNoEdit() {
    executeInAll "git add ."
    executeInAll "git commit --amend --no-edit"
}

pushBoth() {
    pushall "origin" "$1" &
    pid1=$!

    pushall "origin-private" "$1" &
    pid2=$!

    wait $pid1 $pid2
}

pushTags() {
    executeInAll "git push --tags" "$1"
}

pushBothTags() {
    echo "Pushing origin tags"
    pushTags "origin" &
    pid1=$!

    echo "Pushing origin-private tags"
    pushTags "origin-private" &
    pid2=$!

    wait $pid1 $pid2
    echo "Both pushes are done."
}

pkg() {
    CONFIG=$1
    executeInAll "changePackage" "$CONFIG"
    
    # Change the package for TalkModels which is the starter package for the Talk application.
    cd "$appModules/TalkModels"
    printDirectory
    changePackage "$CONFIG"

    # Change the package for TalkUI which is a packge for the Talk app where it depends on AdditiveUI.
    cd "$appModules/TalkUI"
    printDirectory
    changePackage "$CONFIG"

    cd "$root"
}

changePackage() {
    local PACKAGE_FILE="Package.swift"
    local CONFIG="$1"

    if [[ "$CONFIG" == "local" ]]; then
        sed -i '' 's|let useLocalDependency = false|let useLocalDependency = true|' "$PACKAGE_FILE" && echo "Set to use local dependency."
    elif [[ "$CONFIG" == "remote" ]]; then
        sed -i '' 's|let useLocalDependency = true|let useLocalDependency = false|' "$PACKAGE_FILE" && echo "Set to use remote dependency."
    fi
}

makeSDKDirectory() {
    # Create SDK folder if it is not exist.
    if [[ -d "$sdk" ]]; then
        echo "Directory $sdk already exists."
    else
        echo "Creating SDK directory..."
        mkdir -p "$sdk"
    fi
}

downloadSubmodules() {
    # Clone one by one and
    for path in "${PACKEGE_URLS[@]}"; do
        echo "clone $path"
        git clone "$baseURL/$path"
    done
}

setup() {
    makeSDKDirectory
    cd "$sdk"
    downloadSubmodules
}

if [ "$1" == "setup" ]; then
    setup
fi
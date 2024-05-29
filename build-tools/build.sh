#!/bin/bash
git config --global --add safe.directory /github/workspace


# ----------------
# DEBUGGING VARIABLES
# ----------------

# Echo all variables starting with GITHUB_ for debugging
for var in "${!GITHUB_@}"; do
    echo "$var=${!var}"
done

# Echo all variables starting with INPUT_ for debugging
for var in "${!INPUT_@}"; do
    echo "$var=${!var}"
done

# echo all variables starting with RUNNER_ for debugging
for var in "${!RUNNER_@}"; do
    echo "$var=${!var}"
done



# ----------------
# CHECK IF TEMPLATE
# ----------------

template=$(awk -F'=' '/^IS_LIBRARY:=/{print $2}' Makefile)
echo $template
echo "template=$template" >> $GITHUB_OUTPUT


# ----------------
# GET PROJECT INFO
# ----------------

if [ "$ACTION" == "opened" ]; then
    # Fetch the head SHA directly from the PR API
    API_URL="https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/$GITHUB_PR_NUM"
    sha=$(wget -O- --quiet "$API_URL" | jq -r '.head.sha' | head -c 6)
else
    # Use the commit SHA after the event
    sha=$(git rev-parse HEAD | head -c 6)
fi

function get_sha() {
    echo "sha=$sha" >> $GITHUB_OUTPUT
    echo "SHA found: $sha"
}

function get_version() {
    version=$(awk -F'=' '/^VERSION:=/{print $2}' Makefile)
    echo "Version found: $version"
    echo "version=$version" >> "$GITHUB_OUTPUT"
    echo $version >> "version.txt"
}

function get_library_name() { 
    library_name=$(awk -F'=' '/^LIBNAME:=/{print $2}' Makefile)
    echo "library_name=$library_name" >> "$GITHUB_OUTPUT"
    echo "Library name found: $library_name"
    echo $library_name >> "library_name.txt"
}

get_sha &
get_version &
get_library_name &
wait

version=$(cat version.txt)
rm version.txt
library_name=$(cat library_name.txt)
rm library_name.txt

echo "Version before setting postfix: $version"
echo "SHA before setting postfix: $sha"
postfix="${version}+${sha}"
echo "Postfix after setting: $postfix"
echo "postfix=$postfix" >> "$GITHUB_OUTPUT"

name="$library_name@$postfix"
echo "name=$name" >> "$GITHUB_OUTPUT"
echo "Name found: $name"

# ----------------
# BUILDING PROJECT
# ----------------

make clean quick -j

# ----------------
# CREATING TEMPLATE
# ----------------
# if: ${{ steps.template.outputs.template == 1 && inputs.library-path != null }}

if [ "$template" == "1" ] && [ -n "$INPUT_LIBRARY_PATH" ]; then
    sed -i "s/^VERSION:=.*\$/VERSION:=${postfix}/" Makefile

    # fake pros c create-template for make template
    PATH="$PATH:$GITHUB_ACTION_PATH/pros-fake/bin"
    
    pros make template

    mkdir -p template/include/"${INPUT_LIBRARY_PATH}"/

    cp {LICENSE*,README*} template/include/"${INPUT_LIBRARY_PATH}"/

    echo "\n## [Github link](${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY})" >> template/include/"${INPUT_LIBRARY_PATH}"/README.md
    perl -i -pe 's@(?<=[^/])(docs/assets/.*?)(?=[")])@${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/blob/master/$1?raw=true@g' template/include/"${INPUT_LIBRARY_PATH}"/README.md
    echo ${postfix} >> template/include/${INPUT_LIBRARY_PATH}/VERSION

    unzip -o $name.zip -d template

    ls -a
    ls -a template
fi
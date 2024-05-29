#!/bin/bash
git config --global --add safe.directory /github/workspace

# Create a github group
echo "::group::Debug Variables"

# -------------------
# DEBUGGING VARIABLES
# -------------------

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


echo "::endgroup::"
# ----------------
# CHECK IF TEMPLATE
# ----------------
echo "::group::Checking if this is a template"

template=$(awk -F'=' '/^IS_LIBRARY:=/{print $2}' Makefile)
if [ "$template" == "1" ]; then
    echo "is template"
else
    echo "is not template"
fi
echo "template=$template" >> $GITHUB_OUTPUT

echo "::endgroup::"
# ----------------
# GET PROJECT INFO
# ----------------
echo "::group::Getting project info"

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


echo "::endgroup::"
# ----------------
# BUILDING PROJECT
# ----------------
echo "::group::Building ${library_name}"
pros make clean
if [["$INPUT_MULTITHREADING" == "true"]]; then
    echo "Multithreading is enabled"
    make quick -j
else
    echo "Multithreading is disabled"
    pros make
fi
echo "::endgroup::"

# --------
# BUILDING
# --------
# Set IS_LIBRARY to 0 to build the project
if (($template == 1)); then
    echo "::group::Building ${name} non-template"
    echo "Setting IS_LIBRARY to 0"
    sed -i "s/^IS_LIBRARY:=.*\$/IS_LIBRARY:=0/" Makefile
    pros make
    echo "Setting IS_LIBRARY back to 1"
    sed -i "s/^IS_LIBRARY:=.*\$/IS_LIBRARY:=1/" Makefile
    echo "::endgroup::"
fi

# -----------------
# CREATING TEMPLATE
# -----------------

if (($template == 1)); then
echo "::group::Updating Makefile"

sed -i "s/^VERSION:=.*\$/VERSION:=${postfix}/" Makefile

cat Makefile

echo "::endgroup::"



echo "::group::Creating ${name} template"

pros make template
fi 

echo "::endgroup::"

# --------------
# UNZIP TEMPLATE
# --------------

echo "::group::Unzipping template"

unzip -o $name -d template # Unzip the template

echo "::endgroup::"

# -------------------------
# DEBUGGING TEMPLATE FOLDER
# -------------------------

echo "::group::Debugging template folder"

ls -a
ls -a template
ls -a template/include
ls -a template/include/"${INPUT_LIBRARY_PATH}"
ls -a include/"${INPUT_LIBRARY_PATH}"

echo "::endgroup::"
# if [ "$template" == "1" ] && [ -n "$INPUT_LIBRARY_PATH" ]; then
#     echo "::group::Creating ${name} template"
#     sed -i "s/^VERSION:=.*\$/VERSION:=${postfix}/" Makefile

#     # fake pros c create-template for make template
#     PATH="$PATH:$GITHUB_ACTION_PATH/pros-fake/bin"
    
#     pros make template

#     mkdir -p template/include/"${INPUT_LIBRARY_PATH}"/

#     cp {LICENSE*,README*} template/include/"${INPUT_LIBRARY_PATH}"/

#     echo "\n## [Github link](${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY})" >> template/include/"${INPUT_LIBRARY_PATH}"/README.md
#     perl -i -pe 's@(?<=[^/])(docs/assets/.*?)(?=[")])@${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/blob/master/$1?raw=true@g' template/include/"${INPUT_LIBRARY_PATH}"/README.md
#     echo ${postfix} >> template/include/${INPUT_LIBRARY_PATH}/VERSION

#     unzip -o $name.zip -d template

#     ls -a
#     ls -a template

#     echo "::endgroup::"
# fi

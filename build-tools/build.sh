#!/bin/bash
script_start_time=$SECONDS

# ----------------
# VERIFY INPUTS
# ----------------

# Check if the user has provided a library folder name if copy_readme_and_license_to_include: is true
if [[ "$INPUT_COPY_README_AND_LICENSE_TO_INCLUDE" == "true" && -z "$INPUT_LIB_FOLDER_NAME" ]]; then
    echo "You must provide a library folder name if copy_readme_and_license_to_include is true" >&2
    echo "You must provide a library folder name if copy_readme_and_license_to_include is true"
    # Add to Workflow summary
    echo "# ::error::You must provide a library folder name if copy_readme_and_license_to_include is true" >>$GITHUB_STEP_SUMMARY
    exit 102502 # This is the string "pros-build" turned into int values, added together, and then multiplied by 10 plus the error code at the end. This is to hopefully avoid conflicts with other error codes.
fi

# Multithreading
if [[ "$INPUT_MULTITHREADING" == "true" ]]; then
    echo "Multithreading is enabled"
    make_args="-j"
else
    echo "Multithreading is disabled"
    make_args=""
fi

# ------------
# ECHO LICENSE
# ------------
echo "::group::License"
cat /LICENSE
echo "::endgroup::"

# ----------------
# SETTING VARIABLES
# ----------------

set -e # Exit on error

git config --global --add safe.directory /github/workspace

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

echo "::endgroup::"

# ----------------
# GET PROJECT INFO
# ----------------
echo "::group::Getting project info"

if [ "$GITHUB_EVENT_NAME" == "pull_request" -o "$GH_EVENT_NAME" == "pull_request" ]; then
    # Fetch the head SHA directly from the PR API
    # if /$GITHUB_PR_NUM is "" check $INPUT_GITHUB_PR_NUM
    if [ -z "$GITHUB_PR_NUM" ]; then
        GITHUB_PR_NUM=$GH_PR_NUM
    fi
    API_URL="https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/$GITHUB_PR_NUM"
    echo "API URL: $API_URL"
    API_RESPONSE=$(wget -O- --quiet "$API_URL")
    if [ $? -ne 0 ]; then
        echo "Error fetching data from GitHub API"
        exit $?
    fi
    echo "API Response: $API_RESPONSE"
    sha=$(echo "$API_RESPONSE" | jq -r '.head.sha' | head -c 6)

else
    # Use the commit SHA after the event
    sha=$(git rev-parse HEAD | head -c 6)
fi

echo "SHA found: $sha"

version=$(awk -F'=' '/^VERSION:=/{print $2}' Makefile)
echo "Version found: $version"

library_name=$(awk -F'=' '/^LIBNAME:=/{print $2}' Makefile)
echo "Library name found: $library_name"

echo "Version before setting postfix: $version"
echo "SHA before setting postfix: $sha"

if [ "$INPUT_NO_COMMIT_HASH" == "true" ]; then
    postfix="${version}"
else
    postfix="${version}+${sha}"
fi
echo "Postfix after setting: $postfix"

name="$library_name@$postfix"
echo "name=$name" >>"$GITHUB_OUTPUT"
echo "Name found: $name"

echo "::endgroup::"
# ----------------
# BUILDING PROJECT
# ----------------
# Pause errors
set +e
make clean $make_args
STD_OUTPUT=$(mktemp)
# Set IS_LIBRARY to 0 to build the project if $template is 1
if (($template == 1)); then
    echo "::group::Building ${name}"
    echo "Setting IS_LIBRARY to 0"
    sed -i "s/^IS_LIBRARY:=.*\$/IS_LIBRARY:=0/" Makefile
fi

# Actual build
start_build_time=$SECONDS
make quick $make_args | tee $STD_OUTPUT
make_exit_code=${PIPESTATUS[0]}
build_time=$((SECONDS - $start_build_time))

# Set IS_LIBRARY back to 1 if $template was 1
if (($template == 1)); then
    echo "Setting IS_LIBRARY back to 1"
    sed -i "s/^IS_LIBRARY:=.*\$/IS_LIBRARY:=1/" Makefile
    echo "::endgroup::"
fi

STD_EDITED_OUTPUT=$(mktemp)
# # Remove ANSI color codes from the output
# sed -e 's/\x1b\[[0-9;]*m//g' $STD_OUTPUT >$STD_EDITED_OUTPUT

make quick  | aha --no-header | cat <(echo '<pre>') - <(echo '</pre>') >$STD_EDITED_OUTPUT

if (($make_exit_code != 0)); then
    norm_output=$(cat "$STD_EDITED_OUTPUT")
    rm -rf $STD_OUTPUT $STD_EDITED_OUTPUT
    echo "
    # 🛑 Build Failed
    #### 📄 Error Output
    Build failed in $build_time seconds
    Total Build Script Runtime: $(($SECONDS - $script_start_time)) seconds
    <details><summary>Click to expand</summary>
    
    
    \`\`\`
    $norm_output
    \`\`\`
    </details>" >>$GITHUB_STEP_SUMMARY
    exit 1
fi

# -----------------
# CREATING TEMPLATE
# -----------------

set -e # Enable exiting on error

if (($template == 1)); then
    echo "::group::Updating Makefile"

    sed -i "s/^VERSION:=.*\$/VERSION:=${postfix}/" Makefile

    cat Makefile

    echo "::endgroup::"

    echo "::group::Creating ${name} template"

    make template $make_args

    echo "::endgroup::"

    # --------------
    # UNZIP TEMPLATE
    # --------------

    echo "::group::Unzipping template"

    unzip -o $name -d template # Unzip the template

    echo "::endgroup::"

fi

# ---------------------------
# ADDING VERSION, LICENSE
# AND README TO THE TEMPLATE
# FOLDER
# ---------------------------
if [[ "$INPUT_COPY_README_AND_LICENSE_TO_INCLUDE" == "true" ]]; then
    echo "::group::Adding version, license and readme to the template folder"
    if [[ "$INPUT_LIB_FOLDER_NAME" != "" ]]; then

        echo $version >template/include/$INPUT_LIB_FOLDER_NAME/VERSION
        find . -maxdepth 0 -type f -iname "LICENSE*" -exec cp -n {} template/include/$INPUT_LIB_FOLDER_NAME/ \;
        find . -maxdepth 0 -type f -iname "README*" -exec cp -n {} template/include/$INPUT_LIB_FOLDER_NAME/ \;
    else
        echo "Error: You must provide a library folder name if copy_readme_and_license_to_include is true" >&2
        echo "::endgroup::"
        # exit with an error code of 2, representing the error code for missing library folder name
        # Redundant, but just in case
        exit 102502 # This is the string "pros-build" turned into int values, added together, and then multiplied by 10 plus the error code at the end (error code 3). This is to hopefully avoid conflicts with other error codes.
    fi
    echo "::endgroup::"
fi
# -----------
# JOB SUMMARY
# -----------
norm_output=$(cat "$STD_EDITED_OUTPUT")
rm -rf $STD_OUTPUT $STD_EDITED_OUTPUT
echo "
# ✅ Build Completed
Build completed in $build_time seconds
Total Build Script Runtime: $(($SECONDS - $script_start_time)) seconds
## 📝 Library Name: ${library_name} @ ${version}
### 🔐 SHA: ${sha}
" >>$GITHUB_STEP_SUMMARY
if (($template == 1)); then
    echo "### 📁 Artifact Name: ${name}" >>$GITHUB_STEP_SUMMARY
fi
echo "***
#### 📄 Output from Make
<details><summary>Click to expand</summary>

\`\`\`
$norm_output
\`\`\`
</details>" >>$GITHUB_STEP_SUMMARY


exit 0
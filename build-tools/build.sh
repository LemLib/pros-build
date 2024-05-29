#!/bin/bash
git config --global --add safe.directory /github/workspace

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
    API_URL="https://api.github.com/repos/$REPOSITORY/pulls/$PR_NUM"
    sha=$(wget -O- --quiet "$API_URL" | jq -r '.head.sha' | head -c 6)
else
    # Use the commit SHA after the event
    sha=$(git rev-parse HEAD | head -c 6)
fi
echo "sha=$sha" >> $GITHUB_OUTPUT
echo "SHA found: $sha"

version=$(awk -F'=' '/^VERSION:=/{print $2}' Makefile)
echo "Version found: $version"
echo "version=$version" >> "$GITHUB_OUTPUT"

postfix="$version+$sha"
echo "postfix=$postfix" >> "$GITHUB_OUTPUT"
echo "Postfix found: $postfix"

library_name=$(awk -F'=' '/^LIBNAME:=/{print $2}' Makefile)
echo "library_name=$library_name" >> "$GITHUB_OUTPUT"
echo "Library name found: $library_name"

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

if [ "$template" == "1" ]; then
    sed -i "s/^VERSION:=.*\$/VERSION:=${{steps.project-info.outputs.postfix}}/" Makefile
    cat Makefile

    # fake pros c create-template for make template
    PATH="$PATH:$GITHUB_ACTION_PATH/pros-fake/bin"
    
    pros make template

    mkdir -p template/include/"${{inputs.library-path}}"/

    cp {LICENSE*,README*} template/include/"${{inputs.library-path}}"/

    echo "\n## [Github link](${{github.server_url}}/${{github.repository}})" >> template/include/"${{inputs.library-path}}"/README.md
    perl -i -pe 's@(?<=[^/])(docs/assets/.*?)(?=[")])@${{github.server_url}}/${{github.repository}}/blob/master/$1?raw=true@g' template/include/"${{inputs.library-path}}"/README.md
    echo ${{steps.project-info.outputs.postfix}} >> template/include/${{inputs.library-path}}/VERSION
fi

# # Update version in Makefile
# makefile_version=$(awk -F'=' '/^VERSION:=/{print $2}' Makefile)

# version=$(awk -F'=' '/^VERSION:=/{print $2}' Makefile)
# # present in makefile
# library_name=$(awk -F'=' '/^LIBRARY_NAME:=/{print $2}' Makefile)
# # github sha short
# # postfix=$(git rev-parse --short HEAD)
# postfix="$version+$sha"
# # Making Template
# make clean quick -j
# pros make template

# # Unzipping Template
# template_name="$library_name@$postfix"
# echo $template_name
# unzip "$template_name.zip" -d template

# # Upload Artifact
# if [ -n "$library_path" ]; then
#     echo "Uploading Artifact"
#     artifact_dir="/github/workspace/template/include/$library_path"
#     mkdir -p "$artifact_dir"
    
#     # Copying necessary files
#     cp {LICENSE*,README*} "$artifact_dir"/
    
#     # Adding GitHub link to README
#     readme_path="$artifact_dir/README.md"
#     echo -e "\n## [Github link]($GITHUB_SERVER_URL/$REPOSITORY)" >> "$readme_path" 
#     perl -i -pe 's@(?<=[^/])(docs/assets/.*?)(?=[")])@${GITHUB_SERVER_URL}/${REPOSITORY}/blob/master/$1?raw=true@g' "$readme_path" # I'm not smart enough for this, was aided by ChatGPT
    
#     # Writing version info
#     echo "$postfix" >> "$artifact_dir/VERSION"

#     # Zipping and moving to workspace
#     cd /github/workspace/template
#     zip -r "$template_name.zip"
#     echo $template_name + ".zip" >> $GITHUB_OUTPUT
#     echo $CWD
#     # mv "$template_name.zip" /
#     ls -a
#     # # Uploading Artifact
#     # node upload.js "/$template_name.zip"
# fi
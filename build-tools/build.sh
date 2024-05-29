#!/bin/bash

# Fetching Project Information
if [ "$ACTION" == "opened" ]; then
    # Fetch the head SHA directly from the PR API
    API_URL="https://api.github.com/repos/$REPOSITORY/pulls/$PR_NUM"
    sha=$(wget -O- --quiet "$API_URL" | jq -r '.head.sha' | head -c 6)
else
    # Use the commit SHA after the event
    sha=$(git rev-parse HEAD | head -c 6)
fi

# Printing SHA for debugging
echo "SHA found: $sha"

# Update version in Makefile
makefile_version=$(awk -F'=' '/^VERSION:=/{print $2}' Makefile)
sed -i "s/^VERSION:=.*\$/VERSION:=$makefile_version/" Makefile

# present in makefile
$library_name = $(awk -F'=' '/^LIBRARY_NAME:=/{print $2}' Makefile)
# github sha short
$postfix = git rev-parse --short HEAD

# Making Template
make clean quick -j
pros make template

# Unzipping Template
template_name="$library_name@$postfix"
echo $template_name
unzip "$template_name.zip" -d template

# Upload Artifact
if [ -n "$library_path" ]; then
    echo "Uploading Artifact"
    artifact_dir="/github/workspace/template/include/$library_path"
    mkdir -p "$artifact_dir"
    
    # Copying necessary files
    cp {LICENSE*,README*} "$artifact_dir"/
    
    # Adding GitHub link to README
    readme_path="$artifact_dir/README.md"
    echo -e "\n## [Github link]($GITHUB_SERVER_URL/$REPOSITORY)" >> "$readme_path" 
    perl -i -pe 's@(?<=[^/])(docs/assets/.*?)(?=[")])@${GITHUB_SERVER_URL}/${REPOSITORY}/blob/master/$1?raw=true@g' "$readme_path" # I'm not smart enough for this, was aided by ChatGPT
    
    # Writing version info
    echo "$postfix" >> "$artifact_dir/VERSION"

    # Zipping and moving to workspace
    cd /github/workspace/template
    zip -r "$template_name.zip"
    echo $template_name + ".zip" >> $GITHUB_OUTPUT
    echo $CWD
    # mv "$template_name.zip" /
    
    # # Uploading Artifact
    # node upload.js "/$template_name.zip"
fi
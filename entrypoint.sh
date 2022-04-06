#!/bin/bash

set -e

# Install netlify globally before NVM to prevent EACCESS issues
npm i -g netlify-cli

# Save its exec path to run later
NETLIFY_CLI=$(which netlify)

# Install node from NVM to honor .nvmrc files
if [[ -n $INPUT_NODE_VERSION ]] || [[ -e ".nvmrc" ]]
then
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
	[ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"

	if [[ -n $INPUT_NODE_VERSION ]]
	then
		nvm install "$INPUT_NODE_VERSION"
	else
		nvm install
	fi
fi

# Install dependencies
if [[ -n $INPUT_INSTALL_COMMAND ]]
then
	eval $INPUT_INSTALL_COMMAND
elif [[ -f yarn.lock ]]
then
	yarn
else
	npm i
fi

# Export token to use with netlify's cli
export NETLIFY_SITE_ID="$INPUT_NETLIFY_SITE_ID"
export NETLIFY_AUTH_TOKEN="$INPUT_NETLIFY_AUTH_TOKEN"

# Build project
eval ${INPUT_BUILD_COMMAND:-"npm run build"}

COMMAND="$NETLIFY_CLI deploy --message=\"$INPUT_NETLIFY_DEPLOY_MESSAGE\""

if [[ $INPUT_NETLIFY_DEPLOY_TO_PROD == "true" ]]
then
	COMMAND+=" --prod"
elif [[ -n $INPUT_DEPLOY_ALIAS ]]
then
	COMMAND+=" --alias $INPUT_DEPLOY_ALIAS"
fi

# Deploy with netlify
OUTPUT=$(sh -c "$COMMAND")

NETLIFY_OUTPUT=$(echo "$OUTPUT")
NETLIFY_PREVIEW_URL=$(echo "$OUTPUT" | grep -Eo '(http|https)://[a-zA-Z0-9./?=_-]*(--)[a-zA-Z0-9./?=_-]*') #Unique key: --
NETLIFY_LOGS_URL=$(echo "$OUTPUT" | grep -Eo '(http|https)://app.netlify.com/[a-zA-Z0-9./?=_-]*') #Unique key: app.netlify.com
NETLIFY_LIVE_URL=$(echo "$OUTPUT" | grep -Eo '(http|https)://[a-zA-Z0-9./?=_-]*' | grep -Eov "netlify.com") #Unique key: don't containr -- and app.netlify.com

echo "::set-output name=NETLIFY_OUTPUT::$NETLIFY_OUTPUT"
echo "::set-output name=NETLIFY_PREVIEW_URL::$NETLIFY_PREVIEW_URL"
echo "::set-output name=NETLIFY_LOGS_URL::$NETLIFY_LOGS_URL"
echo "::set-output name=NETLIFY_LIVE_URL::$NETLIFY_LIVE_URL"

#!/usr/bin/env sh

TW_VERSION=$(sed -ne 's,^#define TEXWORKS_VERSION\s"\?\([0-9.]\+\)"\?$,\1,p' src/TWVersion.h)
GIT_HASH=$(git --git-dir=".git" show --no-patch --pretty="%h")
DATE=$(date --rfc-3339="seconds")
DATE_HASH=$(date +"%Y%m%d%H%M%d")

PACKAGE_NAME="TeXworks-mac-${TW_VERSION}-${DATE_HASH}-git_${GIT_HASH}.tar.bz2"

cat > travis-ci/bintray.json << EOF
{
	"package": {
		"name": "TeXworks-latest",
		"repo": "generic",
		"subject": "stloeffler"
	},
	"version": {
		"name": "${PACKAGE_NAME}",
		"released": "${DATE}"
	},
	"files":
	[
		{"includePattern": "build-${TRAVIS_OS_NAME}-qt${QT}/.*", "uploadPattern": "files"}
	],
	
	"publish": true
}
EOF

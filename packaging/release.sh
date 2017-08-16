#!/usr/bin/bash

if ! command -v github-release >/dev/null; then
    msg="The github-release command is not available on your system. To enable"
    msg+="\nthe command on your system, install the golang rpm, create go basic"
    msg+="\ndir structure and download&build the github-release utility:"
    msg+="\n    $ sudo dnf install golang"
    msg+="\n    $ mkdir -p gocode/{src,bin,pkg}"
    msg+="\n    $ export GOPATH=\"\$HOME/gocode\""
    msg+="\n    $ PATH=\$PATH:\$GOPATH/bin"
    msg+="\n    $ go get github.com/aktau/github-release"
    msg+="\n    $ go build github.com/aktau/github-release"
    echo -e "$msg"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    msg+="\nFor purposes of this scripts, please set the GITHUB_TOKEN too. For"
    msg+="\nexample, you can put this line with your token into the ~/.bashrc file."
    msg+="\n    $ export GITHUB_TOKEN=<your-token>"
    msg+="\nYou can create new token here: https://github.com/settings/tokens"
    echo -e "$msg"
fi

NAMEPROJ=preupgrade-assistant
NAMESET=el6toel7
VERSION=$(head -n1 version | cut -d " " -f 2)
DIRNAME="${NAMEPROJ}-${NAMESET}-${VERSION}"
TARNAME="${DIRNAME}.tar.gz"

TAG="$(git describe  --abbrev=0 --tags)"
if [[ -z "$TAG" ]] || [[ "$TAG" != "${NAMESET}-${VERSION}" ]] ; then
    # here could be in future some code to create even new tag
    # in case the HEAD commit has summery like "Bump to..."
    # Now just exit with err msg
    echo >&2 "Error: The latest tag doesn't correspond to expected version"
    echo >&2 "       or it isn't in format 'elXtoelY-version'."
    echo >&2 "       E.g.: elt6oel7-0.6.71"
    exit 1
fi

# check whether tag is uploaded and upload it in case it isn't uploaded yet
git ls-remote origin "$TAG" | grep -q "."
if [[ $? -ne 0 ]]; then
    echo >&2 "Info: Tag hasn't been pushed yet. It'll be pushed automatically."
    git push origin "$TAG" || {
        echo >&2 "Error: Tag cannot be pushed to the remote."
        exit 2
    }
fi

github-release info \
    -u upgrades-migrations \
    -r preupgrade-assistant-modules \
    -t "$TAG"
if [[ $? -ne 0 ]]; then
    # create release
    echo >&2 "Info: Release hasn't been created yet. Will be created automatically."
    echo >&2 "      Please modify info message manually. The commit msg will be used."
    descr="$(git log --format=%b -n1 "$TAG")"
    if [[ -z "$descr" ]]; then
        descr="$(git log --format=%B -n1 "$TAG")"
    fi
    github-release release \
        -u upgrades-migrations \
        -r preupgrade-assistant-modules \
        -t "$TAG" \
        -n "Release ${NAMESET} v${VERSION}" \
        -d "$descr" \
        --draft
    if [[ $? -ne 0 ]]; then
        echo >&2 "Error: Release cannot be created."
        exit 2
    fi
fi

# create the tarball
git archive --prefix "${DIRNAME}/" -o "${TARNAME}" "$TAG"
if [[ $? -ne 0 ]]; then
    echo >&2 "Error: tarball cannot be created."
    exit 3
fi

# upload tarball (asset) to the server as release
github-release upload \
    -u upgrades-migrations \
    -r preupgrade-assistant-modules \
    -t "$TAG" -R \
    -f "${TARNAME}" -n "${TARNAME}"
if [[ $? -ne 0 ]]; then
    echo >&2 "Error: tarball cannot be uploaded."
    exit 3
fi


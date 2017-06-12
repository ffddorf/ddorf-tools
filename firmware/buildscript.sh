#!/bin/bash -e

#Global variables that are needed to be passed:
#TAG - Git tag or branch 
#TARGETS - Comma seperated list of targets to build
#GLUONBRANCH - The autoupdater branch to use: stable, beta and so on
#GLUONRELEASE - Release number to use for the images
#BUILD_NUMBER - Usually passed by jenkins, used to build the GLUON_RELEASE string
#VERBOSE - Set to 1 or 0 to enable or disable verbose building
echo "---------------------------------------------------------------------------------------------------------"
echo "Build ID: ${BUILD_NUMBER}"
echo "Gluon Branch: ${GLUONBRANCH}"
echo "Gluon Release: ${GLUONRELEASE}"
echo "Git tag/branch: ${TAG}"
echo "Targets to build: $(echo $TARGETS | sed 's/,/ /g')"
echo "Gluon release number will be: ${GLUONRELEASE}-${BUILD_NUMBER}"
[ "${VERBOSE}" = "true" ] && echo "Verbose mode is ON"

#Create output directory (So we can save log files there)
mkdir -p output

#Delete site config and clear output directory
rm -rf site
rm -rf output/*

#Pull config based on selected GLUONBRANCH
case "${GLUONBRANCH}" in
    *)
    echo "Gluon config branch: lede-dev"
    git clone --branch lede-dev https://github.com/ffddorf/site-ddorf.git site >/dev/null 2>&1
    echo "Gluon config commit ID: $(cd site && git rev-parse --verify HEAD)"
    ;;
esac

echo "---------------------------------------------------------------------------------------------------------"

echo "Running 'make update'"
make update &> output/mkupdate.log

for TARGET in $(echo $TARGETS | sed 's/,/ /g')
do
    echo "Building Gluon Target: ${TARGET}"
    if [ "${VERBOSE}" = "true" ]; then
        make GLUON_BRANCH="${GLUONBRANCH}" GLUON_TARGET="${TARGET}" GLUON_RELEASE="${GLUONRELEASE}-${BUILD_NUMBER}" V=99 &> output/${TARGET}.log
    else
        make GLUON_BRANCH="${GLUONBRANCH}" GLUON_TARGET="${TARGET}" GLUON_RELEASE="${GLUONRELEASE}-${BUILD_NUMBER}" &> output/${TARGET}.log
    fi
done

echo "---------------------------------------------------------------------------------------------------------"
echo "Building manifest"
make manifest GLUON_RELEASE="${GLUONRELEASE}-${BUILD_NUMBER}" GLUON_BRANCH="${GLUONBRANCH}"
echo "Copying site config to output directory"
cp -r site output/ && rm -rf output/site/.git
echo "Generating version.json"
echo "{
  \"version\": \"${GLUONRELEASE}\",
  \"tag\": \"${TAG}\"
}" > output/images/version.json
echo "Buildscript done"

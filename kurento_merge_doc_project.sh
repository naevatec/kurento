#!/bin/bash

echo "##################### EXECUTE: kurento_merge_doc_project #####################"
env

sed -e "s@mvn@mvn --batch-mode --settings $MAVEN_SETTINGS@g" < Makefile > Makefile.jenkins
make -f Makefile.jenkins clean langdoc || make -f Makefile.jenkins javadoc || { echo "Building $KURENTO_PROJECT failed"; exit 1; }
make -f Makefile.jenkins html epub latexpdf dist || { echo "Building $KURENTO_PROJECT failed"; exit 1; }

[ -z "$KURENTO_PROJECT" ] && (echo "KURENTO_PROJECT variable not defined"; exit 1;)
kurento_check_version.sh || exit 1

export DOC_PROJECT=$KURENTO_PROJECT
kurento_prepare_readthedocs.sh || exit 1

pushd $KURENTO_PROJECT-readthedocs
kurento_check_version.sh || exit 1

# Extract version
VERSION=$(kurento_get_version.sh)
echo "Version built: $VERSION"

if [[ $VERSION != *-dev ]]; then

  KURENTO_JAVA_RELEASE=$(grep "CLIENT_JAVA_VERSION =" Makefile | sed 's/ //g' | awk -F "=" '{print $2}' )
  KURENTO_CLIENT_JS_RELEASE=$(grep "CLIENT_JS_VERSION =" Makefile | sed 's/ //g' | awk -F "=" '{print $2}')
  KURENTO_UTILS_JS_RELEASE=$(grep "UTILS_JS_VERSION =" Makefile | sed 's/ //g' | awk -F "=" '{print $2}')

  # In case of lacking tag in any repository, fail
  git ls-remote --tags ssh://jenkins@$KURENTO_GIT_REPOSITORY_SERVER/kurento-java|grep -F -q "$KURENTO_JAVA_RELEASE" || exit 1
  git ls-remote --tags ssh://jenkins@$KURENTO_GIT_REPOSITORY_SERVER/kurento-client-js|grep -F -q "$KURENTO_CLIENT_JS_RELEASE" || exit 1
  git ls-remote --tags ssh://jenkins@$KURENTO_GIT_REPOSITORY_SERVER/kurento-utils-js|grep -F -q "$KURENTO_UTILS_JS_RELEASE" || exit 1

  # Build release
  sed -e "s@mvn@mvn --batch-mode --settings $MAVEN_SETTINGS@g" < Makefile > Makefile.jenkins
  make -f Makefile.jenkins clean langdoc || make -f Makefile.jenkins javadoc || { echo "Building $KURENTO_PROJECT failed"; exit 1; }
  make -f Makefile.jenkins html epub latexpdf dist || { echo "Building $KURENTO_PROJECT failed"; exit 1; }

  # Generate version file
  echo "VERSION_DATE=$VERSION - `date` - `date +%Y%m%d-%H%M%S`" > $KURENTO_PROJECT.version

  # Extract contents
  mkdir build/dist/docs
  tar -xvzf build/dist/$KURENTO_PROJECT-$VERSION.tgz -C ./build/dist/docs/

  # Export files to upload
  DATE=$(date +"%Y%m%d")
  V_DIR=/release/$VERSION
  S_DIR=/release/stable

  FILE=""
  FILE="$FILE build/dist/$KURENTO_PROJECT-$VERSION.tgz:$V_DIR/$KURENTO_PROJECT-$VERSION.tgz"
  FILE="$FILE $KURENTO_PROJECT.version:$S_DIR/$KURENTO_PROJECT.version"
  FILE="$FILE build/dist/$KURENTO_PROJECT-$VERSION.tgz:$S_DIR/$KURENTO_PROJECT.tgz"
  FILE="$FILE build/dist/$KURENTO_PROJECT-$VERSION.tgz:$V_DIR/$KURENTO_PROJECT/$KURENTO_PROJECT.tgz:1"
  FILE="$FILE build/dist/$KURENTO_PROJECT-$VERSION.tgz:$S_DIR/$KURENTO_PROJECT/$KURENTO_PROJECT.tgz:1"

  export FILES=$FILE
  kurento_http_publish.sh || { echo "Publishing $KURENTO_PROJECT failed"; exit 1; }

fi

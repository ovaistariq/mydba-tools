#!/bin/bash

source_tar=$1
version=$2

if [[ -z $source_tar ]]
then
	echo "Please provide the source tgz archive"
	exit
fi

if [[ -z $version ]]
then
	echo "Please provide the version of MySQL that is being built"
	exit
fi

debug_build_dir=build_${version}/debug
release_build_dir=build_${version}/release
source_dir=${PWD}/$(basename $source_tar .tar.gz)

tar -xzf $source_tar

# clean the CMake cache from the source dir otherwise CMake will do the build in the source dir
rm -f ${source_dir}/CMakeCache.txt

# Build debug binaries first, they are picked up in the final 'make package'
mkdir -p $debug_build_dir
(
	cd $debug_build_dir
	cmake $source_dir -DBUILD_CONFIG=mysql_release -DCMAKE_BUILD_TYPE=Debug
	make VERBOSE=1
)

# Build release binaries and create final package
mkdir -p $release_build_dir
(
	cd $release_build_dir
	cmake $source_dir -DBUILD_CONFIG=mysql_release
	make VERBOSE=1 package
)

echo "** The binary is available in ${release_build_dir}"

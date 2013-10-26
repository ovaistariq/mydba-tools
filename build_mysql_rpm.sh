#!/bin/bash

source_tar=$1
version=$2

if [[ -z $source_tar ]]
then
        echo "Please provide the source tar"
        exit
fi

if [[ -z $version ]]
then
        echo "Please provide the version of MySQL that is being built"
        exit
fi

rpm_dir=rpm_build_${version}
source_tar_dir=$PWD

rm -rf ${rpm_dir}
mkdir -p ${rpm_dir}/{BUILD,RPMS,SOURCES,SPECS,SRPMS} ${rpm_dir}/tmp

# Create spec file
(
	tar -xzf $source_tar
	mkdir ${rpm_dir}/bld; cd ${rpm_dir}/bld
	cmake ${source_tar_dir}/$(basename $source_tar .tar.gz)
)

cp ${rpm_dir}/bld/support-files/*.spec ${rpm_dir}/SPECS/
cp ${source_tar} ${rpm_dir}/SOURCES/

rpmbuild -v --define="_topdir $PWD/${rpm_dir}" --define='runselftest 0' --define="_tmppath $PWD/${rpm_dir}/tmp" -ba ${rpm_dir}/SPECS/mysql.${version}.spec


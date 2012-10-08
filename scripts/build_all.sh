#
# Native camera extension example, build script
# @author Radoslava Leseva, diadraw.com
#

#!/bin/bash

# Get the paths to the certificate and mobile provisioning files
# and the app store password from the command line:
private_key_file=$1
if [ -z "${private_key_file}" ]
then
    echo "path to your .p12 file:"
    read private_key_file
fi


mobile_provision_file=$2
if [ -z "${mobile_provision_file}" ]
then
    echo "path to your .mobileprovision file:"
    read mobile_provision_file
fi


app_store_password=$3
if [ -z "${app_store_password}" ]
then
    echo "password:"

    stty_orig=`stty -g` stty -echo
        read app_store_password
    stty $stty_orig
fi


# Optional command line argument: debug or release, defaults to debug, if nothing is passed on the command line
build_type=$4
if [ -z "${build_type}" ]
then
    build_type="debug"
fi
# We want lowercase 'debug'/'release' for ActionScript
build_type_AS=$( echo "${build_type}" | tr "[:upper:]" "[:lower:]" )
# and uppercase first letter for iOS: 'Debug'/'Release'
build_type_iOS=$( echo "${build_type:0:1}" | tr "[:lower:]" "[:upper:]" )${build_type:1}


# Do a clean build of the native iOS library:
pushd ../NativeCameraExtension/iOS/NativeCameraExtensioniOS
    xcodebuild clean -configuration "${build_type_iOS}"
    xcodebuild -configuration "${build_type_iOS}"

    # Check whether the build succeeded and stop the script, if not:
    if [ $? -ne 0 ]
    then
        exit $?
    fi
popd


# Do a clean build of the extension SWC and package it into ANE:
pushd ../FlexCameraExtensionLib/ant    
    ant "package ane" -Dlib.native_library_path=../../NativeCameraExtension/iOS/NativeCameraExtensioniOS/build/"${build_type_iOS}"-iphoneos

    # Check whether the build succeeded and stop the script, if not:
    if [ $? -ne 0 ]
    then
        exit $?
    fi
popd


# Do a clean build of the Flex app and package it into IPA:
pushd ../FlexApp/ant
    ant "package ipa" -Dpackage.privatekey="${private_key_file}" -Dpackage.mobileprovision="${mobile_provision_file}" -Dpackage.storepass="${app_store_password}"  -Dbuild.type="${build_type_AS}"

    # Check whether the build succeeded and stop the script, if not:
    if [ $? -ne 0 ]
    then
        exit $?
    fi
popd
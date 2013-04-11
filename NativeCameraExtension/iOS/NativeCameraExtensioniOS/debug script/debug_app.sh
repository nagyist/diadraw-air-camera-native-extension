#!/bin/bash

#This file contains the app name and path to the .ipa - customize it:
source xcode.properties


pushd "${app_package_script_path}"
	ant "package extensions" package -Dios.store.password="${ios_store_password}"  -Dbuild.debug=true -Dios.privatekey="${ios_privatekey}" -Dios.mobileprovision="${ios_mobileprovision}"  -Ddeploy.simulator=false
popd



#Create a temporary directory for collecting and repacking the files we need:
tempdir=./temp

rm      -rf ${tempdir}
mkdir       ${tempdir}

pushd       ${tempdir}

    app_packagedir=../${app_packagedir}

    #Copy the debug information folder
    cp -r "${app_packagedir}"/"${app_name}".app.dSYM .
    cp -r "${app_name}".app.dSYM "${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/"

    #Extract the .app package from the .ipa
    cp "${app_packagedir}"/"${app_name}".ipa "${app_name}".ipa.zip
    unzip -o "${app_name}".ipa.zip
    rm "${app_name}".ipa.zip

    #Copy the contents of the .app package to the location XCode will expect them to be
    cp -r Payload/"${app_name}".app/*       "${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/"

    #Remove the following files and folders to avoid signature errors when installing the app
    rm      "${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/_CodeSignature/CodeResources"
    rm -rf  "${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/_CodeSignature"
    rm      "${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/CodeResources"
    rm      "${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/PkgInfo"

#Restore the working directory
popd

#Get rid of the temporary directory:
rm      -rf ${tempdir}
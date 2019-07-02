#!/bin/bash

## 2019-03-29 : bprom : check Mage patch file for locally extended files/functions that need to be manually patched

## Arguments
##  path to patch file
##  path to mage intall location

SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/"`basename "$0"`

## get patchfile
if [ -z "$1" ]; then
        echo "Please provide a path to the SUPEE patch file"
        exit
else
        PATCHFILE="$1"
fi

if [ -z "$2" ]; then
        echo "Please provide a path to the Magento installation location"
        exit
else
        MAGE_PATH="$2"
fi

FILES_CHANGED=`grep '^diff' ${PATCHFILE}| awk '{ print $3; }' | sed 's/ a\///g'`

PATCHED_LOCAL_EXTEND=0
PATCHED_LOCAL_EXTEND_FILES=""
PATCHED_UNVERIFIED=0
PATCHED_UNVERIFIED_FILES=""
PATCHED_CONFIG=0
PATCHED_CONFIG_FILES=""

echo ""
echo "Mage Directory Scanned: " ${MAGE_PATH}
echo ""

for FILE in ${FILES_CHANGED}; do
        if [ ${FILE:0:2} = 'a/' ]; then
                FILE=${FILE:2}
        fi

        echo "INFO: File in patch: " ${FILE}

        DIR=${MAGE_PATH}"${FILE%%/*}"
        EXT="${FILE##*.}"

        if [ ${EXT} = "php" ]; then
                if [ -f ${FILE} ]; then
                        CLASS=`grep '^class' $FILE | awk '{ print $2; }'`
                        if [ -z "${CLASS}" ]; then
                                CLASS=`grep '^abstract class' $FILE | awk '{ print $3; }'`
                        fi
                        if [ -z "${CLASS}" ]; then
                                echo "  WARNING: manual check required for file: " ${FILE}
                                PATCHED_UNVERIFIED=$((PATCHED_UNVERIFIED+1))
                                PATCHED_UNVERIFIED_FILES=`echo -e "${PATCHED_UNVERIFIED_FILES}"'\n'  ${FILE}`
                        else
                                MATCHED_FILES=`grep -rilw "extends\s*${CLASS}\|^class\s*${CLASS}" ${DIR}/ | grep -v "${FILE}\|app/code/core/"`
                                if [ ${#MATCHED_FILES} -gt 0 ]; then
                                        PATCHED_LOCAL_EXTEND=$((PATCHED_LOCAL_EXTEND+1))
                                        PATCHED_LOCAL_EXTEND_FILES=`echo -e "${PATCHED_LOCAL_EXTEND_FILES}"'\n'  ${FILE}`
                                        echo "  WARNING: file exteneded"
                                        for EXTENDED in ${MATCHED_FILES}; do
                                                echo "    " ${EXTENDED}
                                        done
# TODO: try to detect what function/constant was changed by the patch and search if that function/constant exists in local
                                fi
                        fi
                fi
        elif [ ${EXT} = "phtml" ]; then
                FILENAME=`basename ${FILE}`
                LOC_FULL=${MAGE_PATH}`echo ${FILE} | awk -F/ '{ print $1"/"$2"/"$3; }'`"/"
                LOC_PATH=`echo "${FILE}" | awk -F/ 'BEGIN{OFS="/";} { $1=$2=$3=$4=$5=""; gsub("//+"," ") }1' | sed "s/${FILENAME}//g"`

                MATCHED_FILES=`find ${LOC_FULL} -name "${FILENAME}" | grep ${LOC_PATH}`
                if [ ${#MATCHED_FILES} -gt 0 ]; then
                        PATCHED_LOCAL_EXTEND=$((PATCHED_LOCAL_EXTEND+1))
                        PATCHED_LOCAL_EXTEND_FILES=`echo -e "${PATCHED_LOCAL_EXTEND_FILES}"'\n'  ${FILE}`
                        echo "  WARNING: file exteneded"
                        for EXTENDED in ${MATCHED_FILES}; do
                                echo "    " ${EXTENDED}
                        done
                fi
        elif [ ${EXT} = "xml" ] && [ ${FILE:0:8} = "app/etc/" ] && [ ${FILE:9:8} != "modules/" ]; then
                PATCHED_CONFIG=$((PATCHED_CONFIG+1))
                PATCHED_CONFIG_FILES=`echo -e "${PATCHED_CONFIG_FILES}"'\n'  ${FILE}`
        else
# TODO: NOT a php or phtml file, how to handle?
                echo "  TODO: NOT a php or phtml file, how to handle?"
                PATCHED_UNVERIFIED=$((PATCHED_UNVERIFIED+1))
                PATCHED_UNVERIFIED_FILES=`echo -e "${PATCHED_UNVERIFIED_FILES}"'\n'  ${FILE}`
        fi
done

echo ""
echo ""
echo "== SUMMARY =="
echo "Locally extended files that may require patching: " ${PATCHED_LOCAL_EXTEND}
echo "${PATCHED_LOCAL_EXTEND_FILES}"
echo ""
echo ""
echo "Config files: " ${PATCHED_CONFIG}
echo "${PATCHED_CONFIG_FILES}"
echo ""
echo ""
echo "Files unferifed by automated script - check manually: " ${PATCHED_UNVERIFIED}
echo "${PATCHED_UNVERIFIED_FILES}"
echo ""
echo ""
echo ""

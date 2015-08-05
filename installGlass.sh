#!/usr/bin/env bash

function ctrl_c() {
  # Clean up
  adb shell rm -r $dir
  adb forward --remove-all
  echo "Bye Bye"
}

# Fail on error, verbose output
trap ctrl_c INT

#set -exo pipefail

cd ./minicap

echo --------------
echo Start building
echo --------------

# Build project
ndk-build 1>&2

echo ---------------------
echo Check the device info
echo ---------------------

# Figure out which ABI and SDK the device has
abi=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')
sdk=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
rel=$(adb shell getprop ro.build.version.release | tr -d '\r')
echo "CPU ABI $abi"
echo "SDK $sdk"


# PIE is only supported since SDK 16
if (($sdk >= 16)); then
  bin=minicap
else
  bin=minicap-nopie
fi

args=
if [ "$1" = "autosize" ]; then
  set +o pipefail
  size=$(adb shell wm size| cut -d: -f2 |tr -d " \n\t\r")
  # size=$(adb shell dumpsys window | grep -Eo 'init=\d+x\d+' | head -1 | cut -d= -f 2)
  if [ "$size" != "" ]; then
    echo -------------------
    echo Display Size: $size
    echo -------------------
    args='-P '$size'@'$size'/0'
    # set -o pipefail
    # shift
  fi
fi

echo -----------------
echo Push binary files
echo -----------------
# Create a directory for our resources
dir=/data/local/tmp/minicap-devel
adb shell "mkdir $dir 2>/dev/null"

# Upload the binary
adb push libs/$abi/$bin $dir

# Upload the shared library
if [ -e jni/minicap-shared/aosp/libs/android-$rel/$abi/minicap.so ]; then
  adb push jni/minicap-shared/aosp/libs/android-$rel/$abi/minicap.so $dir
else
  adb push jni/minicap-shared/aosp/libs/android-$sdk/$abi/minicap.so $dir
fi

portNum=1717
echo -------------------------
echo Forward socket connection
echo port no.: $portNum
echo -------------------------
adb forward tcp:$portNum localabstract:minicap

echo -------------
echo Start running
echo -------------
# Run!
adb shell LD_LIBRARY_PATH=$dir $dir/$bin $args "$@"



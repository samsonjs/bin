#!/bin/bash

cd /Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Plug-ins/iPhoneOS\ Build\ System\ Support.xcplugin/Contents/MacOS/
dd if=iPhoneOS\ Build\ System\ Support of=working bs=500 count=255
printf "\xc3\x26\x00\x00" >> working
dd if=iPhoneOS\ Build\ System\ Support of=working bs=1 skip=127504 seek=127504
/bin/mv -n iPhoneOS\ Build\ System\ Support iPhoneOS\ Build\ System\ Support.original
/bin/mv working iPhoneOS\ Build\ System\ Support
chmod a+x iPhoneOS\ Build\ System\ Support

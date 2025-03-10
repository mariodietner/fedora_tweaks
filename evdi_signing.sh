#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <evdi_source_path> <key_path> <pem_path>"
    exit 1
fi

evdi_path="$1"
echo $evdi_path

key_path="$2"
echo $key_path

pem_path="$3"
echo $pem_path

kernel=$(uname -r)
echo "Using kernel: $kernel"

echo "Working directory: $HOME"

cd $evdi_path

make
cd ..

/usr/src/kernels/$kernel/scripts/sign-file sha256 $key_path $pem_path $evdi_path/module/evdi.ko

if [ ! -d "/lib/modules/$kernel/kernel/drivers/gpu/drm/evdi/" ]; then
    mkdir /lib/modules/$kernel/kernel/drivers/gpu/drm/evdi/
fi

cp $evdi_path/module/evdi.ko /lib/modules/$kernel/kernel/drivers/gpu/drm/evdi/
insmod /lib/modules/$kernel/kernel/drivers/gpu/drm/evdi/evdi.ko
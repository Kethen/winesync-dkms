_kernver="${1:-$(uname -r)}"
_commit=67ecf76b95fcaf9a70e54b0d25b485f4e135e439

curl https://repo.or.cz/linux/zf.git/blob_plain/$_commit:/drivers/misc/ntsync.c --output "ntsync.c-$_commit"
curl https://repo.or.cz/linux/zf.git/blob_plain/$_commit:/include/uapi/linux/ntsync.h --output "ntsync.h-$_commit"

set -xe

rm -rf build
install -Dm644 Makefile "build/ntsync-$_commit/Makefile"
install -Dm644 "ntsync.c-$_commit" "build/ntsync-$_commit/src/drivers/misc/ntsync.c"
install -Dm644 "ntsync.h-$_commit" "build/ntsync-$_commit/include/uapi/linux/ntsync.h"
install -Dm644 dkms.conf "build/ntsync-$_commit/dkms.conf"
sed "s/@PACKAGE_VERSION@/$_commit/g" -i "build/ntsync-$_commit/dkms.conf"
mkdir build/build
dkms build --sourcetree "$PWD/build" --dkmstree "$PWD/build/build" -m "ntsync/$_commit" -k "$_kernver"
dkms remove --sourcetree "$PWD/build" --dkmstree "$PWD/build/build" -m "ntsync/$_commit" -k "$_kernver" || true
dkms add --sourcetree "$PWD/build" --dkmstree "$PWD/build/build" -m "ntsync/$_commit" -k "$_kernver"
dkms install --sourcetree "$PWD/build" --dkmstree "$PWD/build/build" -m "ntsync/$_commit" -k "$_kernver" --force

install -Dm644 99-ntsync.rules /usr/lib/udev/rules.d/99-ntsync.rules
udevadm control --reload
udevadm trigger

install -Dm644 ntsync.conf /usr/lib/modules-load.d/ntsync.conf
modprobe -rv ntsync
modprobe -v ntsync

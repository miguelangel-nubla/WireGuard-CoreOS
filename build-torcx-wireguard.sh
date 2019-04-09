#!/bin/bash
set -e -v -x

PKG=$1
BUILD_TAG=$2

cp -R /host/WireGuard-source "/tmp/$PKG"
cd "/tmp/$PKG"

git checkout "${BUILD_TAG}"

# depmod have hardcoded kernel path, so get rid of it
sed -i -e 's#[ \t]*depmod.*##g' "/tmp/$PKG/src/Makefile"

# adapt coreos order of commands, avoids hangs. Let me know if you know the root cause.
perl -0pe 's/(set_config\n)(.*do\n\t\tadd_addr "\$i"\n\tdone\n)(\tset_mtu.*\n)/$1$3$2/' -i "/tmp/$PKG/src/tools/wg-quick/linux.bash"

KERNEL_BASEDIR=$(find /lib/modules/* -maxdepth 0)
export KERNELDIR="$KERNEL_BASEDIR/build"

make -C "/tmp/$PKG/src" -j$(nproc) all V=1
make -C "/tmp/$PKG/src" install module-install DESTDIR=/tmp/root V=1


cp --parents "$KERNEL_BASEDIR/extra/wireguard.ko" /tmp/root

# Edit the service to be torcx-aware.
sed -i \
    -e '/^\[Unit]/aRequires=torcx.target\nAfter=torcx.target' \
    -e "/^\\[Service]/aEnvironmentFile=/run/metadata/torcx\\nExecStartPre=-/sbin/modprobe ip6_udp_tunnel\\nExecStartPre=-/sbin/modprobe udp_tunnel\\nExecStartPre=-/sbin/insmod \${TORCX_UNPACKDIR}/${PKG}/lib/modules/%v/extra/wireguard.ko" \
    -e 's,/usr/s\?bin/,${TORCX_BINDIR}/,g' \
    -e 's,^\([^ ]*=\)\(.{TORCX_BINDIR}\)/,\1/usr/bin/env PATH=\2:${PATH} \2/,' \
    /tmp/root/usr/lib/systemd/system/wg-quick@.service

# Write a torcx image manifest.
mkdir -p /tmp/root/.torcx
cat << 'EOF' > /tmp/root/.torcx/manifest.json
{
    "kind": "image-manifest-v0",
    "value": {
        "bin": [
            "/usr/bin/wg",
            "/usr/bin/wg-quick"
        ],
        "units": [
            "/usr/lib/systemd/system/wg-quick@.service"
        ]
    }
}
EOF

# Write the torcx image.
tar --force-local -C /tmp/root -czf "/host/${PKG}:${BUILD_TAG}.torcx.tgz" .
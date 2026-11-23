#!/bin/bash
# iKoolProxy：把插件源码拉进编译树，并修正依赖以适配 immortalwrt 新版 luci

UPDATE_PACKAGE "ikoolproxy" "ilxp/luci-app-ikoolproxy" "main" "" "koolproxy"

IKP_DIR="./package/luci-app-ikoolproxy"

if [ -d "$IKP_DIR" ]; then
    # @BUSYBOX_CONFIG_DIFF 是 busybox 编译符号依赖，新版默认不开 diff，会导致依赖不可满足而静默丢弃插件
    sed -i 's/@BUSYBOX_CONFIG_DIFF/+diffutils/' "$IKP_DIR/Makefile"
    sed -i 's/+diffutils +diffutils/+diffutils/' "$IKP_DIR/Makefile"
    chmod +x "$IKP_DIR"/koolproxy/files/* 2>/dev/null || true
    chmod +x "$IKP_DIR"/root/etc/init.d/koolproxy 2>/dev/null || true
    echo "ikoolproxy: $(grep -m1 'LUCI_DEPENDS' "$IKP_DIR/Makefile")"
    echo "ikoolproxy: $(grep -m1 'PKG_VERSION' "$IKP_DIR/koolproxy/Makefile")"
else
    echo "ikoolproxy: clone failed"
fi

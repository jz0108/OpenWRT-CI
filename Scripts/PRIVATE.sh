#!/bin/bash
# iKoolProxy：拉取源码、修正依赖、预置规则、默认启用

UPDATE_PACKAGE "ikoolproxy" "ilxp/luci-app-ikoolproxy" "main" "" "koolproxy"

IKP_DIR="./package/luci-app-ikoolproxy"
RULE_DIR="$IKP_DIR/root/usr/share/koolproxy/data/rules"

if [ -d "$IKP_DIR" ]; then
    # @BUSYBOX_CONFIG_DIFF 是 busybox 编译符号依赖，换成真实包 diffutils
    sed -i 's/+@BUSYBOX_CONFIG_DIFF/+diffutils/g; s/++diffutils/+diffutils/g' "$IKP_DIR/Makefile"
    chmod +x "$IKP_DIR"/koolproxy/files/* "$IKP_DIR"/root/etc/init.d/koolproxy "$IKP_DIR"/root/usr/share/koolproxy/kpupdate "$IKP_DIR"/root/usr/sbin/adblockplus 2>/dev/null || true

    # 预置规则：固件自带规则，刷机后无需再联网下载即可过滤
    mkdir -p "$RULE_DIR"
    for RULE in koolproxy.txt daily.txt kp.dat yhosts.txt adg.txt steven.txt antiad.txt adgk.txt; do
        if curl -fsSL --retry 3 -o "$RULE_DIR/$RULE" "https://cdn.jsdelivr.net/gh/ilxp/koolproxy@main/rules/$RULE"; then
            echo "rule $RULE: $(wc -c < "$RULE_DIR/$RULE") bytes"
        else
            echo "rule download FAILED: $RULE"
            rm -f "$RULE_DIR/$RULE"
        fi
    done
    if curl -fsSL --retry 3 -o "$IKP_DIR/root/usr/share/koolproxy/dnsmasq.adblock" "https://cdn.jsdelivr.net/gh/ilxp/koolproxy@main/rules/dnsmasq.adblock"; then
        echo "rule dnsmasq.adblock: $(wc -c < "$IKP_DIR/root/usr/share/koolproxy/dnsmasq.adblock") bytes"
    else
        echo "rule download FAILED: dnsmasq.adblock"
    fi
    # 0 字节规则会让过滤失效，直接删掉
    find "$RULE_DIR" -type f -size 0 -delete

    # 原版默认 enabled '0'，刷完要手动开启；这里改为默认启用
    sed -i "s/option enabled '0'/option enabled '1'/" "$IKP_DIR/root/etc/config/koolproxy"

    echo "ikoolproxy: $(grep -m1 'LUCI_DEPENDS' "$IKP_DIR/Makefile")"
    echo "ikoolproxy: $(grep -m1 "option enabled" "$IKP_DIR/root/etc/config/koolproxy")"
else
    echo "ikoolproxy: clone failed"
fi

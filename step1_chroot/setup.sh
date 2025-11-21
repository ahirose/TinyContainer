#!/bin/bash

# Alpine Linux rootfs のセットアップスクリプト

set -e

ROOTFS_DIR="./rootfs"
ALPINE_VERSION="3.19"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine"
ARCH="x86_64"

echo "===== Alpine Linux rootfs セットアップ ====="
echo

# 既存のrootfsディレクトリをチェック
if [ -d "$ROOTFS_DIR" ]; then
    echo "警告: $ROOTFS_DIR はすでに存在します"
    read -p "削除して再作成しますか？ (y/N): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "既存のrootfsを削除します..."
        rm -rf "$ROOTFS_DIR"
    else
        echo "セットアップをキャンセルしました"
        exit 0
    fi
fi

# rootfsディレクトリを作成
echo "rootfsディレクトリを作成: $ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"

# Alpine Linux minirootfs をダウンロード
TARBALL="alpine-minirootfs-${ALPINE_VERSION}.0-${ARCH}.tar.gz"
URL="${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/${ARCH}/${TARBALL}"

echo "Alpine Linux をダウンロード中..."
echo "URL: $URL"

if command -v wget &> /dev/null; then
    wget -q --show-progress "$URL" -O "$TARBALL"
elif command -v curl &> /dev/null; then
    curl -# -L "$URL" -o "$TARBALL"
else
    echo "エラー: wget または curl が必要です"
    exit 1
fi

# rootfsに展開
echo "rootfsに展開中..."
tar -xzf "$TARBALL" -C "$ROOTFS_DIR"

# tarballを削除
rm "$TARBALL"

echo
echo "===== セットアップ完了 ====="
echo "rootfsディレクトリ: $ROOTFS_DIR"
echo
echo "次のステップ:"
echo "1. make        # プログラムをコンパイル"
echo "2. sudo ./simple_container  # コンテナを起動"
echo

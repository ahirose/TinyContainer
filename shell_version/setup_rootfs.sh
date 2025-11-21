#!/bin/bash

# Alpine Linux rootfs のセットアップスクリプト
# コンテナ用の軽量なルートファイルシステムを準備します

set -e

ROOTFS_DIR="./rootfs"
ALPINE_VERSION="3.19"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine"
ARCH="x86_64"

echo "===== Alpine Linux rootfs セットアップ ====="
echo

# 既存のrootfsディレクトリをチェック
if [ -d "$ROOTFS_DIR" ]; then
    echo "⚠️  警告: $ROOTFS_DIR はすでに存在します"
    read -p "削除して再作成しますか？ (y/N): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "既存のrootfsを削除します..."
        sudo rm -rf "$ROOTFS_DIR"
    else
        echo "セットアップをキャンセルしました"
        exit 0
    fi
fi

# rootfsディレクトリを作成
echo "📁 rootfsディレクトリを作成: $ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"

# Alpine Linux minirootfs をダウンロード
TARBALL="alpine-minirootfs-${ALPINE_VERSION}.0-${ARCH}.tar.gz"
URL="${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/${ARCH}/${TARBALL}"

echo "📥 Alpine Linux をダウンロード中..."
echo "   URL: $URL"
echo

if command -v wget &> /dev/null; then
    wget -q --show-progress "$URL" -O "$TARBALL"
elif command -v curl &> /dev/null; then
    curl -# -L "$URL" -o "$TARBALL"
else
    echo "❌ エラー: wget または curl が必要です"
    exit 1
fi

# rootfsに展開
echo
echo "📦 rootfsに展開中..."
sudo tar -xzf "$TARBALL" -C "$ROOTFS_DIR"

# 必要なディレクトリを作成
echo "📂 必要なディレクトリを作成中..."
sudo mkdir -p "$ROOTFS_DIR"/{proc,sys,dev,tmp}

# tarballを削除
rm "$TARBALL"

echo
echo "✅ セットアップ完了！"
echo
echo "📋 rootfsディレクトリ構造:"
ls -la "$ROOTFS_DIR" | head -n 15
echo
echo "🚀 次のステップ:"
echo "1. ./step1_chroot.sh              # ステップ1: 基本的なchroot"
echo "2. ./step2_pid_namespace.sh       # ステップ2: PID namespace追加"
echo "3. ./step3_mount_namespace.sh     # ステップ3: Mount namespace追加"
echo "4. ./step4_full_container.sh      # ステップ4: フル機能コンテナ"
echo
echo "💡 ヒント: 各スクリプトは sudo 権限で実行されます"

#!/bin/bash

# ステップ1: 基本的なchrootコンテナ（Shell版）
#
# このスクリプトは、chrootを使ってファイルシステムを隔離します
#
# 学習ポイント:
# - chroot コマンドの使い方
# - ルートファイルシステムの変更
# - 簡単なコンテナの仕組み

set -e

ROOTFS="./rootfs"

echo "===== ステップ1: 基本的なchroot コンテナ (Shell版) ====="
echo

# rootfsの存在確認
if [ ! -d "$ROOTFS" ]; then
    echo "エラー: $ROOTFS が見つかりません"
    echo "まず ./setup_rootfs.sh を実行してrootfsを準備してください"
    exit 1
fi

echo "[ホスト] 現在のPID: $$"
echo "[ホスト] 現在のホスト名: $(hostname)"
echo "[ホスト] コンテナを起動します..."
echo

# chrootでコンテナを起動
echo "[コンテナ] chrootで $ROOTFS に隔離します"
echo "=========================================="
echo

# sudo が必要（chrootはroot権限が必要）
sudo chroot "$ROOTFS" /bin/sh -c "
    echo '[コンテナ] コンテナ内部に入りました！'
    echo '[コンテナ] PID: $$'
    echo '[コンテナ] ホスト名: \$(hostname)'
    echo
    echo '試してみましょう:'
    echo '  ls /        # ファイルシステムを確認'
    echo '  pwd         # 現在のディレクトリ'
    echo '  ps aux      # プロセス一覧（まだホストのプロセスが見える）'
    echo '  exit        # コンテナを終了'
    echo
    /bin/sh
"

echo
echo "=========================================="
echo "[ホスト] コンテナが終了しました"

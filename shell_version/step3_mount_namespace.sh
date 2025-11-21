#!/bin/bash

# ステップ3: Mount Namespace を追加したコンテナ（Shell版）
#
# PID + Mount namespace を組み合わせて、
# より完全な隔離を実現します
#
# 学習ポイント:
# - Mount namespace によるファイルシステムマウントの隔離
# - /proc の再マウント
# - 完全なプロセス隔離の実現

set -e

ROOTFS="./rootfs"

echo "===== ステップ3: Mount + PID Namespace コンテナ (Shell版) ====="
echo

if [ ! -d "$ROOTFS" ]; then
    echo "エラー: $ROOTFS が見つかりません"
    echo "まず ./setup_rootfs.sh を実行してください"
    exit 1
fi

echo "[ホスト] 現在のPID: $$"
echo "[ホスト] 現在のホスト名: $(hostname)"
echo

# unshare で PID + Mount namespace を作成
# --pid: 新しいPID namespace
# --mount: 新しいMount namespace
# --fork: 新しいプロセスをfork
echo "[コンテナ] PID + Mount namespace を作成して起動..."
echo "=========================================="
echo

sudo unshare --pid --mount --fork chroot "$ROOTFS" /bin/sh -c "
    echo '[コンテナ] Mount + PID Namespace コンテナ内部！'
    echo '[コンテナ] 現在のPID: $$'
    echo

    # /proc を再マウント（これで隔離されたプロセスだけが見える）
    echo '[コンテナ] /proc を再マウントします...'
    mount -t proc proc /proc

    echo '[コンテナ] 完了！'
    echo
    echo '重要な確認:'
    echo '  ps aux を実行してみてください'
    echo '  → 今度はコンテナ内のプロセスだけが見えます！'
    echo
    echo '試してみましょう:'
    echo '  ps aux      # コンテナ内のプロセスのみ表示'
    echo '  echo \$\$     # PIDを確認（小さい番号のはず）'
    echo '  ls /proc    # プロセス情報を確認'
    echo '  exit        # コンテナを終了'
    echo
    /bin/sh
"

echo
echo "=========================================="
echo "[ホスト] コンテナが終了しました"

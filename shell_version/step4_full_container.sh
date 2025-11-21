#!/bin/bash

# ステップ4: フル機能コンテナ（Shell版）
#
# すべてのnamespaceを組み合わせた完全なコンテナ
#
# 学習ポイント:
# - 複数のnamespaceの組み合わせ
# - UTS namespace によるホスト名の隔離
# - より完全なコンテナ環境

set -e

ROOTFS="./rootfs"
CONTAINER_HOSTNAME="my-container"

echo "===== ステップ4: フル機能コンテナ (Shell版) ====="
echo

if [ ! -d "$ROOTFS" ]; then
    echo "エラー: $ROOTFS が見つかりません"
    echo "まず ./setup_rootfs.sh を実行してください"
    exit 1
fi

echo "[ホスト] 現在のPID: $$"
echo "[ホスト] 現在のホスト名: $(hostname)"
echo

# 複数のnamespaceを作成
# --pid: PID namespace
# --mount: Mount namespace
# --uts: UTS namespace (ホスト名の隔離)
# --fork: 新しいプロセスをfork
echo "[コンテナ] すべてのnamespaceを作成して起動..."
echo "=========================================="
echo

sudo unshare --pid --mount --uts --fork chroot "$ROOTFS" /bin/sh -c "
    echo '[コンテナ] フル機能コンテナ起動！'
    echo

    # ホスト名を変更
    hostname $CONTAINER_HOSTNAME
    echo '[コンテナ] ホスト名を設定: $CONTAINER_HOSTNAME'

    # /proc を再マウント
    mount -t proc proc /proc
    echo '[コンテナ] /proc を再マウントしました'

    echo
    echo '========== コンテナ情報 =========='
    echo 'PID: $$'
    echo 'ホスト名: \$(hostname)'
    echo 'プロセス数: \$(ps aux | wc -l)'
    echo '=================================='
    echo
    echo '試してみましょう:'
    echo '  hostname    # コンテナ独自のホスト名'
    echo '  ps aux      # 隔離されたプロセス'
    echo '  ls /        # 隔離されたファイルシステム'
    echo '  top         # リソース監視'
    echo '  exit        # コンテナを終了'
    echo
    /bin/sh
"

echo
echo "=========================================="
echo "[ホスト] コンテナが終了しました"
echo "[ホスト] ホスト名は元に戻っています: $(hostname)"

#!/bin/bash

# ステップ2: PID Namespace を追加したコンテナ（Shell版）
#
# unshare コマンドを使ってPID namespaceを作成します
#
# 学習ポイント:
# - unshare コマンドの使い方
# - PID namespace による プロセスの隔離
# - コンテナ内でPID 1として動作

set -e

ROOTFS="./rootfs"

echo "===== ステップ2: PID Namespace コンテナ (Shell版) ====="
echo

if [ ! -d "$ROOTFS" ]; then
    echo "エラー: $ROOTFS が見つかりません"
    echo "まず ./setup_rootfs.sh を実行してください"
    exit 1
fi

echo "[ホスト] 現在のPID: $$"
echo "[ホスト] 現在見えるプロセス数: $(ps aux | wc -l)"
echo

# unshare で PID namespace を作成
# --pid: 新しいPID namespaceを作成
# --fork: 新しいプロセスをforkして実行（PID namespaceに必要）
echo "[コンテナ] PID namespace を作成して起動..."
echo "=========================================="
echo

sudo unshare --pid --fork chroot "$ROOTFS" /bin/sh -c "
    echo '[コンテナ] PID Namespaceコンテナ内部！'
    echo '[コンテナ] 現在のPID: $$'
    echo
    echo '重要な確認:'
    echo '  ps aux を実行してみてください'
    echo '  → まだホストのプロセスが見えます（/procが共有されているため）'
    echo
    echo '試してみましょう:'
    echo '  echo \$\$     # このシェルのPID（名前空間内ではPID 1に近い）'
    echo '  ls /proc    # まだホストの/procを見ている'
    echo '  exit        # コンテナを終了'
    echo
    /bin/sh
"

echo
echo "=========================================="
echo "[ホスト] コンテナが終了しました"
echo
echo "📝 注意: ps aux がホストのプロセスを表示するのは正常です"
echo "   次のステップ3でmount namespaceを使って/procを再マウントします"

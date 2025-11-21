#!/bin/bash

# ステップ5: Network Namespace を追加したコンテナ（Shell版）
#
# ネットワークの完全な隔離を実現します
#
# 学習ポイント:
# - Network namespace によるネットワークの隔離
# - ネットワークインターフェースの確認
# - 完全に隔離されたネットワーク環境

set -e

ROOTFS="./rootfs"
CONTAINER_HOSTNAME="my-container"

echo "===== ステップ5: Network Namespace コンテナ (Shell版) ====="
echo

if [ ! -d "$ROOTFS" ]; then
    echo "エラー: $ROOTFS が見つかりません"
    echo "まず ./setup_rootfs.sh を実行してください"
    exit 1
fi

echo "[ホスト] 現在のPID: $$"
echo "[ホスト] 現在のネットワークインターフェース:"
ip link show 2>/dev/null | grep -E "^[0-9]+" | awk '{print "  - " $2}' || echo "  (ip コマンドが利用できません)"
echo

# Network namespace付きでコンテナを起動
# --net: 新しいNetwork namespace
echo "[コンテナ] すべてのnamespaceを作成して起動..."
echo "=========================================="
echo

sudo unshare --pid --mount --uts --net --fork chroot "$ROOTFS" /bin/sh -c "
    echo '[コンテナ] Network Namespace コンテナ起動！'

    # ホスト名を設定
    hostname $CONTAINER_HOSTNAME

    # /proc を再マウント
    mount -t proc proc /proc

    echo
    echo '========== コンテナ情報 =========='
    echo 'PID: $$'
    echo 'ホスト名: \$(hostname)'
    echo
    echo 'ネットワークインターフェース:'
    if command -v ip >/dev/null 2>&1; then
        ip link show 2>/dev/null || echo '  (表示できません)'
    else
        echo '  (ip コマンドが利用できません)'
        echo '  ifconfig や cat /proc/net/dev で確認できます'
    fi
    echo '=================================='
    echo
    echo '📝 重要な確認:'
    echo '  Network namespaceが隔離されているため、'
    echo '  ホストのネットワークインターフェースは見えません。'
    echo '  loopback (lo) のみが存在します。'
    echo
    echo '試してみましょう:'
    echo '  cat /proc/net/dev    # ネットワークデバイスの確認'
    echo '  hostname             # コンテナのホスト名'
    echo '  ps aux               # 隔離されたプロセス'
    echo '  exit                 # コンテナを終了'
    echo
    /bin/sh
"

echo
echo "=========================================="
echo "[ホスト] コンテナが終了しました"
echo
echo "💡 学んだこと:"
echo "  ✅ Network namespaceでネットワークが完全に隔離されました"
echo "  ✅ コンテナは独自のネットワークスタックを持ちます"
echo "  ✅ 外部通信にはvethペアやブリッジの設定が必要です"

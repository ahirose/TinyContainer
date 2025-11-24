# TinyContainer

自作コンテナ - Linuxコンテナの仕組みを学ぶためのプロジェクト

## 概要

このプロジェクトでは、DockerやKubernetesで使われているLinuxコンテナの仕組みを、
Shellスクリプトを使って段階的に学習できます。

**特徴**:
- シンプルで読みやすいShellスクリプト
- 7つのステップで段階的に学習
- コメント付きで理解しやすい
- すぐに実行して動作確認できる

## 学習内容

このプロジェクトで学べること：

1. **chroot** - ファイルシステムの隔離
2. **PID namespace** - プロセスの隔離
3. **Mount namespace** - マウントポイントの隔離
4. **UTS namespace** - ホスト名の隔離
5. **Network namespace** - ネットワークの隔離
6. **cgroups** - リソース制限（CPU、メモリ）
7. **複数コンテナ同時起動** - nsenter を使ったコンテナへのアタッチ

## 必要な環境

- Linux（WSL2でも可）
- sudo権限
- 基本的なLinuxコマンドの知識

## クイックスタート

```bash
cd shell_version
./setup_rootfs.sh    # rootfsを準備
./step1_chroot.sh    # ステップ1から開始
```

詳細は [shell_version/README.md](./shell_version/README.md) を参照

## 参考資料

- [Linux Namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [Docker アーキテクチャ](https://docs.docker.com/get-started/overview/)

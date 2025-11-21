# myOwnContainer

自作コンテナ - Linuxコンテナの仕組みを学ぶための教育プロジェクト

## 概要

このプロジェクトでは、DockerやKubernetesで使われているLinuxコンテナの仕組みを、
段階的に学習できる実装を提供します。

## 実装バージョン

### 🐚 [Shell版（推奨）](./shell_version/)

**おすすめポイント**:
- シンプルで読みやすい
- すぐに実行できる
- コメント付きで理解しやすい

**開始方法**:
```bash
cd shell_version
./setup_rootfs.sh    # rootfsを準備
./step1_chroot.sh    # ステップ1から開始
```

詳細は [shell_version/README.md](./shell_version/README.md) を参照

### 🔧 [C言語版](./step1_chroot/)（上級者向け）

システムコールを直接学びたい方向け

## 学習内容

このプロジェクトで学べること：

1. **chroot** - ファイルシステムの隔離
2. **PID namespace** - プロセスの隔離
3. **Mount namespace** - マウントポイントの隔離
4. **UTS namespace** - ホスト名の隔離
5. **Network namespace** - ネットワークの隔離（今後追加予定）
6. **cgroups** - リソース制限（今後追加予定）

## 必要な環境

- Linux（WSL2でも可）
- sudo権限
- 基本的なLinuxコマンドの知識

## クイックスタート

```bash
# Shell版を使う（初心者におすすめ）
cd shell_version
./setup_rootfs.sh
./step1_chroot.sh
```

## 参考資料

- [Linux Namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [Docker アーキテクチャ](https://docs.docker.com/get-started/overview/)
- [コンテナ学習ガイド](./LEARNING_GUIDE.md)

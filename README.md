# 世界のことば学習館 iOS アプリ

App Store で配信している学習アプリ（単語帳・検定模擬試験）のビルド用リポジトリです。

- `apps/<Target>/` … 各アプリの画面コードとプロジェクト設定
- `apps/<Target>/content.enc` … 教材データ（単語・問題・挿絵）。暗号化してあり、ビルド時にだけ復号します
- `.github/workflows/ios-build.yml` … コンパイル確認と App Store Connect へのアップロード

© 世界のことば学習館. All rights reserved.
ソースコードは参照のために公開しているものです。複製・改変・再配布・他アプリへの流用は許可していません。

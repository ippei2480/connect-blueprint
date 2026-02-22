# connect-blueprint

Amazon Connect コンタクトフローを要件や設計図から自動生成する [OpenClaw](https://openclaw.io) スキル。

## 機能

- **モードA**: 要件ヒアリング → Mermaid設計図 → フローJSON → デプロイ
- **モードB**: draw.io/Mermaid/画像 → フローJSON → デプロイ

## インストール

OpenClaw のスキルディレクトリにクローン：

```bash
cd ~/.openclaw/skills/
git clone https://github.com/ippei2480/connect-blueprint.git
```

## 必要な環境

- AWS CLI（認証済みプロファイル）
- Amazon Connect インスタンス
- IAM権限: `connect:*`
- Python 3.x（layout.py 用）

## 使い方

OpenClaw に以下のように依頼：

> 「Amazon Connect で新しいIVRフローを作りたい」
> 「この設計図からConnectフローを生成して」
> 「既存のフローを更新して」

詳細は [SKILL.md](SKILL.md) を参照。

## ファイル構成

```
connect-blueprint/
├── SKILL.md                          # スキル定義（OpenClawが読む）
├── README.md                         # このファイル
├── scripts/
│   └── layout.py                     # フローJSON座標付与スクリプト
├── references/
│   ├── action_types.md               # ActionType リファレンス
│   ├── flow_json_structure.md        # フローJSON構造仕様
│   ├── mermaid_notation.md           # Mermaid記法ガイド
│   ├── aws_cli_commands.md           # AWS CLIコマンド集
│   └── layout_rules.md              # レイアウトルール
├── templates/                        # テンプレート（今後追加）
└── examples/                         # サンプルフロー（今後追加）
```

## ライセンス

MIT

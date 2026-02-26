> **Note:** 以下の制限値は 2026年2月時点の情報。最新値は AWS 公式ドキュメントまたは `aws___read_documentation` で確認すること。

# Connect Blueprint — Amazon Connect の制限・注意点

## フロー関連の制限

| 項目 | 制限値 | 備考 |
|------|--------|------|
| フローの最大サイズ | 1MB (JSONコンテンツ) | 大規模フローは分割推奨 |
| フロー内の最大Action数 | 制限なし（公式） | 実用上は200以下を推奨 |
| フローモジュール数/インスタンス | 制限なし（公式） | — |
| コンタクトフロー数/インスタンス | デフォルト500 | Service Quotasで引き上げ可 |
| ネストの深さ | 制限なし（公式） | 深すぎると管理困難 |

## Lambda 関連

| 項目 | 制限値 | 備考 |
|------|--------|------|
| Lambda応答タイムアウト | 最大8秒 | `InvocationTimeLimitSeconds` で設定 |
| Lambdaレスポンスサイズ | 32KB | 超過するとエラー |
| Connect連携Lambda数/インスタンス | デフォルト50 | Service Quotasで引き上げ可 |
| Lambda戻り値のキー/値 | 文字列のみ | 数値・配列は不可 |

## DTMF 入力

| 項目 | 制限値 | 備考 |
|------|--------|------|
| 最大入力桁数 | 20桁 | — |
| タイムアウト | 最大10秒 | `InputTimeLimitSeconds` |
| 使用可能キー | 0-9, *, # | — |

## コンタクト属性

| 項目 | 制限値 | 備考 |
|------|--------|------|
| ユーザー定義属性数 | 制限なし（公式） | 実用上はパフォーマンスに注意 |
| 属性キーの最大長 | 128文字 | — |
| 属性値の最大長 | 256文字 | — |
| 全属性の合計サイズ | 32KB | — |

## キュー関連

| 項目 | 制限値 | 備考 |
|------|--------|------|
| キュー数/インスタンス | デフォルト500 | Service Quotasで引き上げ可 |
| 同時通話数/インスタンス | デフォルト10 | リージョンにより異なる、引き上げ可 |

## テキスト読み上げ（TTS）

| 項目 | 制限値 | 備考 |
|------|--------|------|
| テキスト最大長 | 6,000文字 | SSML含む |
| SSMLタグ | Amazon Polly準拠 | `<speak>`, `<break>`, `<prosody>` 等 |

## API スロットリング

| API | スロットリング | 備考 |
|-----|---------------|------|
| CreateContactFlow | 2 TPS | — |
| UpdateContactFlowContent | 2 TPS | — |
| ValidateContactFlowContent | 2 TPS | — |

## 注意点

- **position は Metadata.ActionMetadata 配下に置く** — Action直下のMetadataフィールドはAPIが拒否する
- **Version は "2019-10-30" 固定** — 他の値を指定するとエラー
- **TransferContactToQueue の前に UpdateContactTargetQueue が必要** — キュー未設定で転送するとエラー
- **Lambda関数はConnectインスタンスに事前登録が必要** — 管理画面またはAPIで登録
- **CheckHoursOfOperation はHoursOfOperationリソースの事前設定が必要**

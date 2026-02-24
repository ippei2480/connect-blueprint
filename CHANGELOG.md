# Changelog

## [0.6.0] - 2026-02-24

### Changed
- `references/action_types.md`: パラメータ/Transitions/Errors のJSON例・フィールド説明を削除し、共通ルール + AWS Docs URLパス対応テーブルに簡素化。AWS MCP での参照手順を追加
- `references/flow_json_structure.md`: ActionType別 Transitions 仕様テーブルを削除し「AWS MCP で参照」の注記を追加
- `references/aws_cli_commands.md`: フロー新規作成コマンドを SAVED → ACTIVE の2ステップ方式に更新
- `references/error_handling_patterns.md`: ErrorType一覧に「完全な一覧はAWS MCPで確認」の注記を追加
- `scripts/deploy.sh`: create モードを `--status SAVED` → `update-contact-flow-metadata --contact-flow-state ACTIVE` の2ステップに変更。ACTIVE化失敗時はフローIDを出力して手動対応可能に
- `SKILL.md`: version 0.6.0、Step 3 に AWS MCP Parameter Validation サブステップ追加、Step 4 Deploy を2ステップに変更、Validation セクションを3層構造に更新
- `README.md`: バリデーション方式を3層構造の説明に更新、デプロイコマンドを2ステップ方式に更新、References テーブルの action_types.md 説明を更新
- `CONTRIBUTING.md`: サンプルフロー追加セクションと開発環境の examples 参照を削除

### Added
- `scripts/validate.sh` Check #16: 孤立ブロック検出（StartAction + 全Transitionsで参照されるIDを集計し、未参照アクションを検出）
- `scripts/validate.sh` Check #17: デッドエンド検出（DisconnectParticipant以外で NextAction も Conditions も空のアクションを検出）

### Removed
- `scripts/validate.sh`: `INVALID_DTMF_FIELDS` チェック削除（`InputTimeLimitSeconds` が `DTMFConfiguration` 内にあってもエラーにしない）
- `examples/` ディレクトリ全削除（business-hours-routing, inquiry-routing, nps-survey）
- `README.md`: Examples セクション削除
- `SKILL.md`: Examples セクション削除
- `.gitignore`: `!templates/**/*.json` と `!examples/**/*.json` の2行を削除

## [0.5.0] - 2026-02-24

### Added
- `scripts/validate.sh` に `--api` フラグ追加: `create-contact-flow --status SAVED` でConnect APIをバリデーターとして活用し、ローカルチェックでは検出できないActionType固有のパラメータ制約をデプロイ前に検出可能に
- `scripts/validate.sh` に `--instance-id`/`--profile` オプション追加
- `scripts/validate.sh` に DTMFConfiguration 内の `InputTimeLimitSeconds` 検出チェック追加
- `SKILL.md` Step 4 に APIバリデーションセクション追加

### Fixed
- `references/action_types.md`: `UpdateContactRecordingBehavior` の Errors を「なし」に修正
- `references/action_types.md`: `GetParticipantInput` の `StoreInput=True` 時の正確な仕様・InputValidation例を追加、DTMFConfiguration から `InputTimeLimitSeconds` を削除
- `references/flow_json_structure.md`: Transitions仕様テーブル修正

## [0.4.0] - 2026-02-24

### Changed
- `references/action_types.md` に共通ルールセクション新設（Transitions構造、Conditions必須ActionType一覧、Errors共通ルール、パラメータ値の型ルール）
- `references/flow_json_structure.md` に Conditions必須ルール・Errors必須ルール・バリデーションルール6-10を追加
- `references/error_handling_patterns.md` に StoreInput=True時のErrorType制約・Conditions欠落アンチパターンを追加
- `SKILL.md` にKey Constraints（Conditions必須ActionType、StoreInput使い分け）とTroubleshooting 3項目を追加
- `SKILL.md` のテンプレート参照をサンプル参照に変更、Examples テーブルを3サンプルに更新
- `README.md` の Examples テーブルを3サンプルに更新、`--aws` フラグ参照を削除

### Removed
- `templates/` ディレクトリ削除（action_types.md のスニペットと役割重複のため）
- `examples/callback-reservation/` 削除（Lambda+Compare パターンが inquiry-routing と重複）
- `examples/multilingual/` 削除（IVR+属性パターンが business-hours-routing と重複）
- `examples/vip-escalation/` 削除（Lambda+Compare パターンが callback-reservation と重複）

### Added
- `scripts/validate.sh` に Check #15 追加: ActionType別 Transitions 制約チェック
  - Loop: ContinueLooping + DoneLooping 両方必須
  - CheckHoursOfOperation: True + False 両方必須
  - Compare: 最低1条件必須
  - GetParticipantInput + StoreInput=True: Conditions 不可
  - Conditions 非対応 ActionType: Conditions 設定検出

## [0.3.0] - 2026-02-24

### Fixed
- `SetVoice` → `UpdateContactTextToSpeechVoice` に修正（正しいAWS API ActionType名）
- `SetLoggingBehavior` → `UpdateFlowLoggingBehavior` に修正（正しいAWS API ActionType名）
- `GlobalVoice` → `TextToSpeechVoice` パラメータ名修正
- `LoggingBehavior` → `FlowLoggingBehavior` パラメータ名修正、値を `Enable`/`Disable` → `Enabled`/`Disabled` に修正
- DTMFConfiguration: `FinishOnKey` → `InputTerminationSequence`、`InactivityTimeLimitSeconds` → `InterdigitTimeLimitSeconds` に修正
- 全6サンプルフロー・テンプレートのDTMFConfigurationパラメータ名を修正
- `examples/multilingual/README.md` の `SetVoice` 参照を修正

### Added
- `Loop` ActionType リファレンス追加（自動カウント管理のループ処理）
- `UpdateContactRecordingAndAnalyticsBehavior` ActionType リファレンス追加
- `UpdateContactRecordingBehavior` に AnalyticsBehavior / IVRRecordingBehavior / ScreenRecordedParticipants 設定を追記
- `GetParticipantInput` に `StoreInput` パラメータ・`DisableCancelKey` 設定の説明を追加
- 各ActionTypeに Transitions 仕様（Conditions/Errors の使用可否）を明記
- `references/flow_json_structure.md` に ActionType別 Transitions 仕様表を追加
- `references/mermaid_notation.md` に新しいActionType（Loop, UpdateContactTextToSpeechVoice, UpdateFlowLoggingBehavior, UpdateContactRecordingBehavior, CheckHoursOfOperation, TransferToPhoneNumber）のノード形状を追加
- `references/error_handling_patterns.md` のリトライパターンを `Loop` ActionType 使用に更新（レガシー方式も併記）
- 全6サンプルフローに `UpdateFlowLoggingBehavior` を最初のアクションとして追加
- `scripts/validate.sh` に5項目の新チェックを追加:
  - ActionType ホワイトリストチェック（非推奨名検出）
  - DTMFConfiguration フィールド名検証
  - UpdateFlowLoggingBehavior パラメータ検証
  - UpdateContactTextToSpeechVoice パラメータ検証
  - StartAction が UpdateFlowLoggingBehavior かどうかの警告
- SKILL.md: エラー発生時に aws-mcp で公式ドキュメントを調査する手順を追加
- SKILL.md: 繰り返し処理で Loop ブロックを優先検討するガイドラインを追加
- SKILL.md: Mermaid設計図をファイルとして保存するワークフローを追加
- SKILL.md: フロー最初のアクションに UpdateFlowLoggingBehavior を使用するルールを追加
- SKILL.md: 要件ヒアリング時の録音・分析設定確認項目を追加

## [0.2.0] - 2025-02-22

### Added
- サンプルフロー6種追加
  - 営業時間内外振り分けフロー (`examples/business-hours-routing/`)
  - コールバック予約フロー (`examples/callback-reservation/`)
  - 顧客満足度アンケート（NPS）フロー (`examples/nps-survey/`)
  - エスカレーション（VIP顧客対応）フロー (`examples/vip-escalation/`)
  - 多言語対応フロー（日本語/英語）(`examples/multilingual/`)
  - 問い合わせ種別振り分けフロー (`examples/inquiry-routing/`)
- バリデーションスクリプト (`scripts/validate.sh`) — ローカル＋AWS両対応
- `CHANGELOG.md` 追加
- `CONTRIBUTING.md` 追加
- エラーハンドリングパターン集 (`references/error_handling_patterns.md`)
- SKILL.md にトラブルシューティングセクション追加

## [0.1.0] - 2025-02-20

### Added
- 初回リリース
- SKILL.md（モードA/B対応）
- Mermaid記法ガイド
- ActionTypeリファレンス
- フローJSON構造仕様
- AWS CLIコマンドリファレンス
- レイアウトアルゴリズム（`scripts/layout.py`）

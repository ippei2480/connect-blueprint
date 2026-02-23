# 営業時間内外振り分けフロー

営業時間（平日9:00-18:00）を判定し、時間内はIVRメニューへ、時間外は音声ガイダンスを流して切断するフロー。

## フロー概要

1. 着信→挨拶メッセージ再生
2. 営業時間を判定（CheckHoursOfOperation）
3. **営業時間内**: IVRメニュー → キュー振り分け
4. **営業時間外**: 時間外ガイダンス再生 → 切断

## Mermaid 設計図

```mermaid
graph LR
  greeting("お電話ありがとうございます")
  hours{"営業時間判定"}
  menu{{"メインメニュー\nTimeout:8\nDTMF:1-2"}}
  q_sales["📞 営業キュー"]
  q_support["📞 サポートキュー"]
  transfer[["キューへ転送"]]
  after_hours("営業時間は平日9時から18時です\nおかけ直しください")
  end1(("切断"))

  greeting --> hours
  hours -->|"= True"| menu
  hours -->|"= False"| after_hours
  menu -->|"Pressed 1"| q_sales
  menu -->|"Pressed 2"| q_support
  menu -->|"Timeout"| after_hours
  q_sales --> transfer
  q_support --> transfer
  transfer --> end1
  after_hours --> end1
```

## 使い方

1. Connect管理画面でオペレーション時間（Hours of Operation）を設定
2. `flow.json` 内のキューARNとオペレーション時間ARNを自分の環境に合わせて変更
3. デプロイ前にローカルバリデーション:
   ```bash
   ./scripts/validate.sh flow.json
   ```
   > デプロイ時に Connect API が自動でバリデーションを実行します。失敗時は `InvalidContactFlowException` が返されます。

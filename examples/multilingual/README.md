# 多言語対応フロー（日本語/英語）

着信時に言語を選択させ、選択した言語でIVRメニューを提供するフロー。

## フロー概要

1. 着信→言語選択（日本語は1、英語は2）
2. 言語に応じた音声テキスト設定（UpdateContactAttributes）
3. 各言語のIVRメニュー → キュー振り分け

## Mermaid 設計図

```mermaid
graph LR
  lang_select{{"日本語は1を\nFor English press 2\nTimeout:8\nDTMF:1-2"}}
  set_ja["language=ja"]
  set_en["language=en"]
  menu_ja{{"メインメニュー\n営業は1、サポートは2\nTimeout:8\nDTMF:1-2"}}
  menu_en{{"Main Menu\nSales:1 Support:2\nTimeout:8\nDTMF:1-2"}}
  q_sales["📞 営業キュー"]
  q_support["📞 サポートキュー"]
  transfer[["キューへ転送"]]
  sorry_ja("おかけ直しください")
  sorry_en("Please call back later")
  end1(("切断"))

  lang_select -->|"Pressed 1"| set_ja
  lang_select -->|"Pressed 2"| set_en
  lang_select -->|"Timeout"| set_ja
  set_ja --> menu_ja
  set_en --> menu_en
  menu_ja -->|"Pressed 1"| q_sales
  menu_ja -->|"Pressed 2"| q_support
  menu_ja -->|"Timeout"| sorry_ja
  menu_en -->|"Pressed 1"| q_sales
  menu_en -->|"Pressed 2"| q_support
  menu_en -->|"Timeout"| sorry_en
  q_sales --> transfer
  q_support --> transfer
  transfer --> end1
  sorry_ja --> end1
  sorry_en --> end1
```

## 実装のポイント

- `UpdateContactAttributes` で `language` 属性を設定 → 後続のキュー転送やエージェントルーティングで活用
- Amazon Connect の「音声の設定」ブロックで Polly の言語/音声を切り替えることも可能（`SetVoice` ActionType）
- 言語ごとにキューを分ける場合は `q_sales_ja` / `q_sales_en` のように分離

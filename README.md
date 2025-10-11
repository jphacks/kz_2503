<p align="center">
  <img width="500" alt="image" src="https://github.com/user-attachments/assets/79d5353f-7a39-4156-8b38-0d589f2c5650" />
</p>

## 製品概要
**WinCook** はウィンク操作と AI 会話で料理を革新するクッキングアプリです。

ウィンクするだけでレシピをスクロールし、手が汚れていても操作可能。  
さらに、レシピを理解した AI と「この調味料がないときは？」「もっと濃い味にするには？」といった会話ができ、  
まるで料理上手な友人と一緒に調理しているような体験を提供します。


### 背景(製品開発のきっかけ、課題等）

- 手を洗わないといけない
- レシピを遡らないといけない

### 製品説明（具体的な製品の説明）
### 特長
#### 1. ウィンクによるレシピ遷移
#### 2. AI によるリアルタイムアシスト
#### 3. スケール可能な堅牢なアーキテクチャ

### 解決出来ること
- 料理中の手の汚れた状態でレシピ操作ができない！！
- 料理についてわからないことがあった時に、遡らないといけない！！

### 今後の展望
- アプリ内での食材購入機能
- Android 版
- レシピ API の追加
- Custom Adapter を用いた AI のチューニング

### 注力したこと（こだわり等）
- iOS26 などの最新技術を使用した、革新的なユーザー体験
- スケーラビリティを考慮したアーキテクチャ

## 開発技術
- iOS：Swift 5+ / SwiftUI
- バックエンド：Go

### 活用した技術
- クラウド：Supabase
- Face Tracking：Vision Framework

#### API・データ
- ローカルDB：SwifData
- クラウドDB：Supabase
- API Server：Go

#### フレームワーク・ライブラリ・モジュール
- UIKit
- SwiftUI
- Speech Framework
- 音声：AVFoundation（TTS）
- AI：FandationModels
- Face Tracking：Vision Framework

#### デバイス
* iPhone / iOS 26.0以上

### 独自技術
#### ハッカソンで開発した独自機能・技術
- wink判定
  - Vision Framework の目の高さをトラッキングする API を利用し、目の高さの変化から、ウィンクの動作を検知する。

- AI友達料理サポート
  - 常に音声を文字起こしし、特定の文字列が発生したときに、プロンプトとして AppleInterigence に送ることで、常に友達がいるかのようなサポートを提供する。

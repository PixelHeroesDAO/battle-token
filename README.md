# battle-token
Battle Tokens are ERC20 tokens that are bridged from the Battle Heroes' exp.
To bridge from an off-chain database, they must be minted with a signature by the bridge system's private key.
This token will also be designed to be bridgeable beyond the minted chain by complying with LayerZero's OFT.

## 概要

　コントラクトの拡張性、整備性の観点から、Diamond Pattern([EIP-2535](https://github.com/mudgen/diamond))を採用した。これによりコントラクトの修正、拡張をモジュールごとに柔軟に実行することができる。またマルチチェーンNFTから派生したトークンであることから、LayerZeroのOmniFungibleTokenに準拠した。なお転送に当たってはガス代見積もりの取得が必要なため一般にdAppが必要になる。

## 経験値のトークンへの変換方法

### 処理のイメージ

```mermaid
sequenceDiagram
    actor holder as ホルダー
    participant front as フロントエンド
    participant back as バックエンド
    participant db as データベース
    participant signer as 署名システム
    participant contract as コントラクト
    holder-->>front:経験値のミントを要求
    front-->>back:ミントを要求
    Note left of back:ホルダーアドレス,ミント数
    back-->>db:値を要求
    db-->>back:値を返却
    Note right of back:経験値[ホルダーアドレス]<br/>ミント済み経験値[ホルダーアドレス]<br/>nonce[ホルダーアドレス]
    back-->>contract:getNonce(ホルダアドレス)
    contract-->>back:nonce[ホルダアドレス]
    Note over back:ミント可否を計算:<br/>ミント可能経験値が残っている<br/>nonceが正しい
    back-->>front:[ミント不可の場合]false
    front-->>holder:ミント不可を表示

    back-->>signer:署名を要求
    Note left of signer:ホルダーアドレス,ミント数,nonce
    Note over signer:EIP-712準拠の署名を生成
    signer-->>back:署名を返却
    Note right of back:deadline,署名

    back-->>front:トランザクション用データを返却
    Note right of front:deadline,署名

    front-->>holder:トランザクションの承認要求
    Note left of front:mintWithSign(ミント数,deadline,署名)

    holder-->>contract:mintWithSign
    Note over contract:署名を検証しミント

    contract-->>back:Trasnferイベントをフック(deadlineを有効期限)
    back-->>contract:getNonce(ホルダーアドレス)
    contract-->>back:nonce[ホルダーアドレス]

    back-->>db:ホルダーのnonce,ミント済み経験値を更新
    Note over db:更新処理

```

上記は署名機能を現状のバックエンドと同一ドメイン内に追加した場合の一例。署名機能を例えばAWS KMSなどを使って別立てにする場合、ミント可否は署名者側からコントラクト・DBへの問い合わせを行うことが望ましい。

## Diamond standard

### Facets

- DiamondLoupeFacet.sol
    - Diamond pattern必須のFacet。Diamond関数の状態を確認する。
- OwnershipFacet.sol
    - Diamond pattern必須のFacet。Diamondのオーナーを規定する。
- PermissionControlFacet.sol
    - 権限管理用のFacet。
    - SoladyのOwnableRolesをベースに改修したPermissionControlを継承しFacet化。
- PHBTFacet.sol
    - ERC20/OFT準拠のトークン機能を規定するFacet。本コントラクトの本体。
    - ERC20はSoladyのERC20Permitを継承。
    - OFTはLayerZeroのsolidity-exampleをDiamond用に書き換えたものを継承。
    - 権限管理はPermissionControlの参照機能に限定した親コントラクトPermissionControlBaseを継承。
- Initializer
    - `DiamondInitV1.sol`を使用する。
    
これらの構成は現状は簡単なシナリオテストを記述した`PHBTInit.t.sol`を参照するとわかりやすい。
# First Agents Club (FAC)

First Agents Club is a free badge NFT on BNB Chain that **only Binance Agent ID
holders can claim** — one Pioneer Badge per wallet, claimable directly from a
simple web page.

Built for the **Binance Wallet Agent ID Hackathon** (submissions close
**9 December 2026, 08:00 UTC / 15:00 WIB**).

## What it is

`AgentIDPioneerBadge` is a small, self-contained ERC-721 contract
(Solidity 0.8.20, no external dependencies). Calling `claim()`:

1. checks the caller holds at least one Agent ID
   (`balanceOf` on the SPACE ID Agent ID contract),
2. enforces one badge per wallet (`hasClaimed`),
3. mints the next sequential badge and emits `BadgeClaimed`.

That is the whole product: every claim is a real, distinct Agent ID holder
interacting on-chain with a project that integrates Agent ID as its gate.

Design choices, on purpose:

- **Free.** No mint fee, no sale, nothing to withdraw. The contract holds no
  user funds and asks claimers for no approvals — the claim transaction is
  the only transaction.
- **Non-transferable.** Transfer/approval functions are not implemented, so a
  badge stays with the wallet that earned it (the Agent ID itself is
  soulbound too).
- **Minimal owner power.** The deployer can only update the metadata base URI
  (`setBaseURI`). Nothing else is adjustable after deployment.
- **Honest copy.** The badge is a collectible keepsake. The claim page says
  plainly that it carries no price, no yield, and no promise of any return.

## How it integrates Agent ID

| Piece | Detail |
|---|---|
| Agent ID contract (BSC) | `0x60b9262456de011f7d15a54cdd8c48baaa8b022f` (SPACE ID Agent ID, ERC-721, non-transferable) |
| Integration point | `claim()` reads `balanceOf(msg.sender)` on that contract; > 0 means eligible |
| Claim page | `page/index.html` — standard `window.ethereum` connect, reads Agent ID balance + claim status, sends `claim()` for the user to confirm in their own wallet |
| Red lines respected | No QR-code Agentic Wallet login, no bypassing user confirmation, no collecting seed phrases / private keys / pairing codes, no promises of returns |

## Smart contracts (full source in this repo)

Both production contracts live in [`contracts/`](contracts/) — exactly the
sources that were compiled and tested locally (Solidity 0.8.20, optimizer ON,
200 runs). Remix can import them straight from these URLs:

| Contract | What it is | Source |
|---|---|---|
| `FAC` | First Agents Club Token — fixed-supply ERC-20 (10,000,000 FAC, minted once to the deployer; no mint/burn/tax/owner) | [contracts/FAC.sol](https://github.com/Deffi69/first-agents-club/blob/main/contracts/FAC.sol) |
| `AgentIDPioneerBadge` | The Pioneer Badge (ERC-721) — free claim gated by Agent ID, max 1,000 badges, pays 8,000 FAC per claim from its own funded balance | [contracts/AgentIDPioneerBadge.sol](https://github.com/Deffi69/first-agents-club/blob/main/contracts/AgentIDPioneerBadge.sol) |

Raw files (for import tools):
`https://raw.githubusercontent.com/Deffi69/first-agents-club/main/contracts/FAC.sol`
and
`https://raw.githubusercontent.com/Deffi69/first-agents-club/main/contracts/AgentIDPioneerBadge.sol`.

Deployment order matters: deploy `FAC` first (no constructor arguments), then
deploy `AgentIDPioneerBadge` with
`(agentIDContract_ = 0x60b9262456de011f7d15a54cdd8c48baaa8b022f, baseURI_ = https://deffi69.github.io/first-agents-club/metadata/, facToken_ = <the FAC address>, maxSupply_ = 1000)`,
then fund the badge by transferring exactly 8,000,000 FAC to its address.

## Repository layout

```
contracts/AgentIDPioneerBadge.sol   the badge contract
contracts/MockAgentID.sol           test-only mock (NEVER deploy)
test/badge.test.js                  holder / non-holder / double-claim / owner tests
scripts/estimate.js                 read-only deployment gas estimate vs BSC RPC
page/index.html                     single-file claim page (address placeholder)
metadata/1.json                     sample token metadata served at baseURI + <id>.json
```

## Tests (already run, all passing)

```
npx hardhat test
  ✔ lets an Agent ID holder claim
  ✔ rejects a non-holder
  ✔ rejects a second claim by the same wallet
  ✔ only the owner can set the base URI
```

## Deployment cost estimate (measured 19 Nov 2026, read-only)

| Item | Value |
|---|---|
| Runtime bytecode | 3,143 bytes |
| Estimated deployment gas | 842,577 |
| BSC gas price at measurement | 0.05 gwei |
| Estimated cost | **0.0000421 BNB ≈ Rp453** (BNB/IDR Rp10,762,421, CoinGecko) |

Even at 20× that gas price the deployment stays under ~Rp9,100. Re-run any
time with `node scripts/estimate.js` (read-only; it never sends anything).

## Live hosting (GitHub Pages — done 19 Nov 2026)

The claim page and metadata are hosted on GitHub Pages from the public repo
**https://github.com/Deffi69/first-agents-club** (built from
`site-staging/` in this folder):

| Item | URL |
|---|---|
| Claim page (site root) | https://deffi69.github.io/first-agents-club/ |
| Metadata base URI → pass as `baseURI_` at deploy | `https://deffi69.github.io/first-agents-club/metadata/` |
| Badge image | https://deffi69.github.io/first-agents-club/metadata/badge.png |
| Token metadata | `metadata/1.json` … `metadata/300.json` (pre-generated for token IDs 1–300) |

All URLs verified live (HTTP 200) on 19 Nov 2026. The claim page still
carries the `0x0000…` contract-address placeholder — it gets filled in only
after the contract is deployed. The contract itself is **not** deployed yet.

## Deploy + verify (only when the owner says go)

> ⚠️ Nothing in this repo has been deployed. Deployment is a separate,
> explicitly approved step.

1. **Host the metadata.** ✅ Done — see "Live hosting" above. The metadata
   folder URL (`https://deffi69.github.io/first-agents-club/metadata/`)
   becomes the constructor `baseURI_` (the contract appends `<id>.json`).
2. **Deploy** from the owner's wallet (e.g. Remix or Hardhat) with:
   - `agentIDContract_` = `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`
   - `baseURI_` = the metadata folder URL from step 1
   - Compiler: Solidity 0.8.20, optimizer ON, 200 runs (matches this repo).
3. **Verify on BscScan** (required by the hackathon):
   - Open the new contract on bscscan.com → Contract tab → "Verify and Publish".
   - Compiler type: *Solidity (Single file)*; version `v0.8.20+commit.a1b79de6`;
     license MIT; optimizer enabled, 200 runs.
   - Paste `contracts/AgentIDPioneerBadge.sol`, enter the two constructor
     arguments (address + base URI string), submit.
   - Success = green checkmark and readable source on the contract page.
4. **Wire the claim page.** In `page/index.html`, replace the
   `BADGE_CONTRACT_ADDRESS` placeholder with the deployed address, host the
   page, and test one real claim end-to-end.

## Hackathon submission facts

- Two prize categories, **one award per project**:
  - **Innovation Award** — judged on Agent ID integration depth, practicality,
    completeness, innovation. Requires the product live on BNB Chain with
    **≥ 30 distinct Agent ID holder addresses interacting** during the
    submission period, contract verified + open-source on BscScan.
  - **Ecosystem Pioneer Award** — ranked by on-chain activity of Agent ID
    holders (unique interacting holders, volume).
- A companion **Community Promotion Campaign** (20 × 100 USDC) rewards quality
  original X posts about a participating project with
  `#BinanceWalletHackathon` and `#AgenticWallet`, submitted via the official
  Binance survey. Draft post: see `X_POST.md`.

## License

MIT

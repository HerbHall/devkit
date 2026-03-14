# Changelog

## Unreleased

### Added

- **Release standardization templates** (ADR-0015): release-please config, manifest, workflow, and git-cliff templates in `project-templates/`
- **ADR-0015**: Documents the decision to standardize on release-please + git-cliff + VERSION file across all projects

## [2.4.0](https://github.com/HerbHall/devkit/compare/v2.3.0...v2.4.0) (2026-03-14)


### Features

* add -Samverk flag to Kit 3 new-project scaffolder ([#250](https://github.com/HerbHall/devkit/issues/250)) ([af49a71](https://github.com/HerbHall/devkit/commit/af49a712ce9ff8224d0ffdcba481f62a185b3528))
* add 'use your tools' principle to global CLAUDE.md ([6a52a3f](https://github.com/HerbHall/devkit/commit/6a52a3f86c0674593cea62978ee167408ba66be0))
* add [RUST-CI] and [DOTNET-CI] checklist blocks to subagent-ci-checklist.md ([#266](https://github.com/HerbHall/devkit/issues/266)) ([e95aaeb](https://github.com/HerbHall/devkit/commit/e95aaeb054d25983278d4648121ad1cca7739578))
* add /devkit-sync skill for manual sync operations ([#74](https://github.com/HerbHall/devkit/issues/74)) ([b5b4f2c](https://github.com/HerbHall/devkit/commit/b5b4f2c6d6c1c56b788f857ec63c57b673ea234e))
* add /plan-review and /code-review skill wrappers ([#56](https://github.com/HerbHall/devkit/issues/56)) ([0cad6e5](https://github.com/HerbHall/devkit/commit/0cad6e5ee569c7abe896ce883f9136c1ad7ba554))
* add 6 new skills and document skills ecosystem strategy ([5fcfb9d](https://github.com/HerbHall/devkit/commit/5fcfb9d9ce5063d7e7de711f94b9821d5da492f7))
* add Actions PR Permission check and update conformance audit to 18-point ([#223](https://github.com/HerbHall/devkit/issues/223)) ([82caec2](https://github.com/HerbHall/devkit/commit/82caec27f206a2fd706621607fe02e88f6234ef8))
* add auto-push prompt after /reflect and session review (issue [#89](https://github.com/HerbHall/devkit/issues/89)) ([#100](https://github.com/HerbHall/devkit/issues/100)) ([6930f0c](https://github.com/HerbHall/devkit/commit/6930f0cafefffb7df4e44cf6024ac73a118f9875))
* add CI scaffolding templates for Go projects ([#104](https://github.com/HerbHall/devkit/issues/104)) ([40def87](https://github.com/HerbHall/devkit/commit/40def87e775bbc7890e84c522361a7d92db71a7d))
* add CI template validation for YAML and JSON files ([#182](https://github.com/HerbHall/devkit/issues/182)) ([#203](https://github.com/HerbHall/devkit/issues/203)) ([8c5353d](https://github.com/HerbHall/devkit/commit/8c5353d1ef6a2fb8c51a01c087bafaa600a62ad2))
* add Copilot auto-review setup gotchas ([#199](https://github.com/HerbHall/devkit/issues/199)) ([af71f83](https://github.com/HerbHall/devkit/commit/af71f83c18a35ced530d9f2226b6412fd622d328)), closes [#193](https://github.com/HerbHall/devkit/issues/193)
* add Copilot integration templates, CLI docs, and delegation model ([#177](https://github.com/HerbHall/devkit/issues/177)) ([0898500](https://github.com/HerbHall/devkit/commit/0898500404828b16689061546cf8dae30d6a19da))
* add Docker Desktop extension lessons to rules ([#150](https://github.com/HerbHall/devkit/issues/150)) ([2e2e5b8](https://github.com/HerbHall/devkit/commit/2e2e5b82f10e716fa18a922110faf247bf318fb9))
* add Go CLI and Go Web stack profiles (issue [#15](https://github.com/HerbHall/devkit/issues/15)) ([#42](https://github.com/HerbHall/devkit/issues/42)) ([eb5437b](https://github.com/HerbHall/devkit/commit/eb5437b8b8773be51b4b6b697eaa8243e6a519dd))
* add independent review pipeline ([#55](https://github.com/HerbHall/devkit/issues/55)) ([f809e38](https://github.com/HerbHall/devkit/commit/f809e3838bc134b2be61562423373fc6501845e5))
* add IoT/ESP32 embedded stack profile (issue [#16](https://github.com/HerbHall/devkit/issues/16)) ([#43](https://github.com/HerbHall/devkit/issues/43)) ([a90aa4e](https://github.com/HerbHall/devkit/commit/a90aa4e5a5284655ed1741650ac5ce8e3608eb76))
* add lifecycle metadata to 10 entries and resolve AP[#27](https://github.com/HerbHall/devkit/issues/27)/KG[#17](https://github.com/HerbHall/devkit/issues/17) duplicate ([#127](https://github.com/HerbHall/devkit/issues/127)) ([8020a2e](https://github.com/HerbHall/devkit/commit/8020a2eb426fd656e8e6d48fede1f9f0655c75c9)), closes [#112](https://github.com/HerbHall/devkit/issues/112)
* add machine identity system to sync.ps1 -Link ([#72](https://github.com/HerbHall/devkit/issues/72)) ([cee7ea4](https://github.com/HerbHall/devkit/commit/cee7ea469b3107e3e979864903e08cf0daddfaaa)), closes [#61](https://github.com/HerbHall/devkit/issues/61)
* add new-project scaffolding route to devkit-sync ([#138](https://github.com/HerbHall/devkit/issues/138)) ([6ae7098](https://github.com/HerbHall/devkit/commit/6ae7098f0ca6b3b9a1044d462dd88dffc92daa03)), closes [#132](https://github.com/HerbHall/devkit/issues/132)
* add PowerShell lint (PSScriptAnalyzer) to CI ([#267](https://github.com/HerbHall/devkit/issues/267)) ([dd405ea](https://github.com/HerbHall/devkit/commit/dd405ea05dc5deb6eb6014e7d96ce6312271aa41))
* add project template files for Kit 3 scaffolding (issue [#18](https://github.com/HerbHall/devkit/issues/18)) ([#41](https://github.com/HerbHall/devkit/issues/41)) ([ae9c241](https://github.com/HerbHall/devkit/commit/ae9c2418007a316dd3b01eb17017504124bbf214))
* add project-level settings.json template and document permission strategy ([#135](https://github.com/HerbHall/devkit/issues/135)) ([f585e11](https://github.com/HerbHall/devkit/commit/f585e116511fbc98f730dd8389690122a2a9a411)), closes [#131](https://github.com/HerbHall/devkit/issues/131)
* add quality gates to project templates ([#113](https://github.com/HerbHall/devkit/issues/113)) ([#121](https://github.com/HerbHall/devkit/issues/121)) ([82d38cf](https://github.com/HerbHall/devkit/commit/82d38cfc750ba904f66642424f5a79917a80de87))
* add release gate and nightly build templates ([#178](https://github.com/HerbHall/devkit/issues/178)) ([#179](https://github.com/HerbHall/devkit/issues/179)) ([5a7f43e](https://github.com/HerbHall/devkit/commit/5a7f43e4c1b47523ac554323be082e5f7fe41acd))
* add release standardization templates and ADR-0015 ([#160](https://github.com/HerbHall/devkit/issues/160)) ([b6985cd](https://github.com/HerbHall/devkit/commit/b6985cd027adbe243813eb182a3225fc43b36fba))
* add retrigger-ci template and auto-merge gotcha entries ([#197](https://github.com/HerbHall/devkit/issues/197)) ([0663a03](https://github.com/HerbHall/devkit/commit/0663a032ead1a54485eac58beefb5625b687cc38)), closes [#191](https://github.com/HerbHall/devkit/issues/191)
* add rule lifecycle metadata format and archive structure ([#126](https://github.com/HerbHall/devkit/issues/126)) ([b482a35](https://github.com/HerbHall/devkit/commit/b482a35bc181a63a134261b009090a8d52e82de3)), closes [#112](https://github.com/HerbHall/devkit/issues/112)
* add rules audit workflow and last-relevant tracking in /reflect ([#128](https://github.com/HerbHall/devkit/issues/128)) ([eb3d2e2](https://github.com/HerbHall/devkit/commit/eb3d2e2c3ac08bef4bcc75b36919140049f53ebd)), closes [#112](https://github.com/HerbHall/devkit/issues/112)
* add rules drift detection to SessionStart and devkit-sync status ([#141](https://github.com/HerbHall/devkit/issues/141)) ([71d6568](https://github.com/HerbHall/devkit/commit/71d6568ce743c1d90dd1a12999ac46b82f6b136c))
* add settings audit route to devkit-sync ([#139](https://github.com/HerbHall/devkit/issues/139)) ([3cb1804](https://github.com/HerbHall/devkit/commit/3cb18041c2a7bed490490bfeec922404edff2382)), closes [#134](https://github.com/HerbHall/devkit/issues/134)
* add skill-audit function to DevKit conformance tooling ([#212](https://github.com/HerbHall/devkit/issues/212)) ([#230](https://github.com/HerbHall/devkit/issues/230)) ([30c3834](https://github.com/HerbHall/devkit/commit/30c383484e6c1441617895efaf63fd7cda6ec426))
* add symlink health validation to SessionStart hook ([#111](https://github.com/HerbHall/devkit/issues/111)) ([#118](https://github.com/HerbHall/devkit/issues/118)) ([778b4f8](https://github.com/HerbHall/devkit/commit/778b4f8c570cced2acb99e413a0fe0f41e2dfb3e))
* add sync manifest for multi-machine file scoping ([#68](https://github.com/HerbHall/devkit/issues/68)) ([5b3fd57](https://github.com/HerbHall/devkit/commit/5b3fd5795aae08405666b93ff4da12d7a091f64f)), closes [#58](https://github.com/HerbHall/devkit/issues/58)
* add tiered rule governance and zero-tolerance error policy ([#115](https://github.com/HerbHall/devkit/issues/115), [#106](https://github.com/HerbHall/devkit/issues/106)) ([#117](https://github.com/HerbHall/devkit/issues/117)) ([00ffcfe](https://github.com/HerbHall/devkit/commit/00ffcfea30de8f554bf9cd053ff7f018c3f62daf))
* add two-ruleset Copilot setup and contributor gate templates ([#201](https://github.com/HerbHall/devkit/issues/201)) ([6b810d1](https://github.com/HerbHall/devkit/commit/6b810d1cf2e7b4ce8fdc1704ffd11363497a34ac))
* add workflow conformance checks to audit process ([#198](https://github.com/HerbHall/devkit/issues/198)) ([c23bc8f](https://github.com/HerbHall/devkit/commit/c23bc8f67ce84a9bf4eaab6a9dd2bf8e874eb4a0)), closes [#192](https://github.com/HerbHall/devkit/issues/192)
* align DevKit with Samverk boundary contract ([#249](https://github.com/HerbHall/devkit/issues/249)) ([4273c2d](https://github.com/HerbHall/devkit/commit/4273c2d63292ee581aa895bf92d6f8859f74ed71))
* auto-pull DevKit updates on SessionStart ([#73](https://github.com/HerbHall/devkit/issues/73)) ([0ff23c5](https://github.com/HerbHall/devkit/commit/0ff23c5459c931484df2cd60d226a0fd1299136e)), closes [#62](https://github.com/HerbHall/devkit/issues/62)
* auto-push DevKit changes via /reflect integration ([#75](https://github.com/HerbHall/devkit/issues/75)) ([5941b57](https://github.com/HerbHall/devkit/commit/5941b570f87e70e77136384565a6e24c2b2b75d2)), closes [#63](https://github.com/HerbHall/devkit/issues/63)
* bootstrap.ps1 phases 1-2 — pre-flight checks and tool installs (issue [#10](https://github.com/HerbHall/devkit/issues/10)) ([#36](https://github.com/HerbHall/devkit/issues/36)) ([2e4c63e](https://github.com/HerbHall/devkit/commit/2e4c63ef0423041efb5b18dc9b331e7b548821b3))
* bootstrap.ps1 phases 3-4 — git config, devspace setup, credentials (issue [#11](https://github.com/HerbHall/devkit/issues/11)) ([#37](https://github.com/HerbHall/devkit/issues/37)) ([0b95c90](https://github.com/HerbHall/devkit/commit/0b95c901d85f764e8925b642c92d977eb30e7e3f))
* bootstrap.ps1 phases 5-6 — AI layer deploy and verification (issue [#12](https://github.com/HerbHall/devkit/issues/12)) ([#38](https://github.com/HerbHall/devkit/issues/38)) ([0dd8d62](https://github.com/HerbHall/devkit/commit/0dd8d623e8846046d2f25dd18803b9fb8da4acdd))
* CI accuracy checks for README skill count and verify.sh alignment ([#28](https://github.com/HerbHall/devkit/issues/28)) ([dbdccf8](https://github.com/HerbHall/devkit/commit/dbdccf8bde744bd4767665ef8aee54d89570e251)), closes [#24](https://github.com/HerbHall/devkit/issues/24)
* **conformance-audit:** add check [#19](https://github.com/HerbHall/devkit/issues/19) -- periodic documentation audit ([#246](https://github.com/HerbHall/devkit/issues/246)) ([d9a5ef1](https://github.com/HerbHall/devkit/commit/d9a5ef1641d86d41f712935cae6fe9924ff9f192))
* **credentials:** integrate HomeLabVault credential management ([#280](https://github.com/HerbHall/devkit/issues/280)) ([a335a93](https://github.com/HerbHall/devkit/commit/a335a93ceabbe1e149ee03173cbe5faad3cc3f7e))
* cross-machine conflict resolution strategy ([#78](https://github.com/HerbHall/devkit/issues/78)) ([6c7b2d0](https://github.com/HerbHall/devkit/commit/6c7b2d0915a565e03708c628b03c6c8bd24253fc)), closes [#66](https://github.com/HerbHall/devkit/issues/66)
* devkit promote command for pattern promotion ([#86](https://github.com/HerbHall/devkit/issues/86)) ([#101](https://github.com/HerbHall/devkit/issues/101)) ([b8054fa](https://github.com/HerbHall/devkit/commit/b8054fabe80472f3bdabf62dcf385a1e941241aa))
* enforce .claude/settings.json on all projects ([#145](https://github.com/HerbHall/devkit/issues/145)) ([ec3d9ef](https://github.com/HerbHall/devkit/commit/ec3d9ef0701d84d45c1ddddfd6c0726a2e75ebdc))
* enforce pre-commit verification in methodology and CLAUDE.md ([#107](https://github.com/HerbHall/devkit/issues/107)) ([#119](https://github.com/HerbHall/devkit/issues/119)) ([f400cd7](https://github.com/HerbHall/devkit/commit/f400cd779204966a5a78f3aed6f40d9d8fea0643))
* **forge:** complete Gitea forge migration support ([#276](https://github.com/HerbHall/devkit/issues/276)) ([3f00695](https://github.com/HerbHall/devkit/commit/3f006959d6551dea07ccac2dc3e79a3c4ee9f6db))
* formalize .local.md override pattern with docs and template (issue [#90](https://github.com/HerbHall/devkit/issues/90)) ([#95](https://github.com/HerbHall/devkit/issues/95)) ([6127f43](https://github.com/HerbHall/devkit/commit/6127f43e73a8125a43f3d2b749222324d45365cf))
* harden SessionStart auto-pull with rate limiting and logging (issue [#88](https://github.com/HerbHall/devkit/issues/88)) ([#99](https://github.com/HerbHall/devkit/issues/99)) ([88c339e](https://github.com/HerbHall/devkit/commit/88c339e40d3ea3a758e26a0d042a60ebd1a5c765))
* implement forge abstraction wrappers (scripts/forge-wrappers.sh) ([#224](https://github.com/HerbHall/devkit/issues/224)) ([e34b2c1](https://github.com/HerbHall/devkit/commit/e34b2c1e1aef01c3fc2bf077c57184ef66b39cfb)), closes [#213](https://github.com/HerbHall/devkit/issues/213)
* implement profile format parser (issue [#14](https://github.com/HerbHall/devkit/issues/14)) ([#40](https://github.com/HerbHall/devkit/issues/40)) ([a48e0f0](https://github.com/HerbHall/devkit/commit/a48e0f0a784dd4adf0ae5a35085712d91fefedf1))
* implement setup.ps1 main menu entry point ([#34](https://github.com/HerbHall/devkit/issues/34)) ([4ab24ea](https://github.com/HerbHall/devkit/commit/4ab24ea5158831449850bb7bd9e814f6a58feb3b)), closes [#8](https://github.com/HerbHall/devkit/issues/8)
* implement setup/lib/checks.ps1 prerequisite detection library ([#31](https://github.com/HerbHall/devkit/issues/31)) ([472a072](https://github.com/HerbHall/devkit/commit/472a072b2405e2542fcc4503e548f1d483c76a3e)), closes [#5](https://github.com/HerbHall/devkit/issues/5)
* implement setup/lib/credentials.ps1 credential manager integration ([#33](https://github.com/HerbHall/devkit/issues/33)) ([202da47](https://github.com/HerbHall/devkit/commit/202da477f7065d53ff911066f3350c7874425de5)), closes [#7](https://github.com/HerbHall/devkit/issues/7)
* implement setup/lib/install.ps1 winget and install wrappers ([#32](https://github.com/HerbHall/devkit/issues/32)) ([ec09a47](https://github.com/HerbHall/devkit/commit/ec09a471bcd0b51895180370d8142c5bab676546)), closes [#6](https://github.com/HerbHall/devkit/issues/6)
* implement setup/lib/ui.ps1 console output library ([#30](https://github.com/HerbHall/devkit/issues/30)) ([51d8d06](https://github.com/HerbHall/devkit/commit/51d8d06e9655adc200a13e2fe34c00f1a4559726)), closes [#4](https://github.com/HerbHall/devkit/issues/4)
* implement stack.ps1 Kit 2 profile installer (issue [#17](https://github.com/HerbHall/devkit/issues/17)) ([#44](https://github.com/HerbHall/devkit/issues/44)) ([2e09deb](https://github.com/HerbHall/devkit/commit/2e09deb3e05c7604331ba2b96af15f79687a8f1e))
* implement symlink management script (setup/sync.ps1) ([#70](https://github.com/HerbHall/devkit/issues/70)) ([8a95b7a](https://github.com/HerbHall/devkit/commit/8a95b7a758824d1e99c336162103c85b9bffa3e8)), closes [#60](https://github.com/HerbHall/devkit/issues/60)
* implement verify.ps1 (Kit 4) ([#232](https://github.com/HerbHall/devkit/issues/232)) ([36f7d44](https://github.com/HerbHall/devkit/commit/36f7d44fc9ccd6a399b45af8b27462844237e019)), closes [#204](https://github.com/HerbHall/devkit/issues/204)
* initial devkit — personal development methodology and Claude Code config ([5e1019c](https://github.com/HerbHall/devkit/commit/5e1019c68f41e168d6f8209f9bd00b3cfec30231))
* integrate symlink-based sync into bootstrap Phase 5 ([#76](https://github.com/HerbHall/devkit/issues/76)) ([49504d5](https://github.com/HerbHall/devkit/commit/49504d5ab8dc2cb5d939574e74ecf82e279de566)), closes [#65](https://github.com/HerbHall/devkit/issues/65)
* machine snapshot files and backup script (issue [#9](https://github.com/HerbHall/devkit/issues/9)) ([#35](https://github.com/HerbHall/devkit/issues/35)) ([3819205](https://github.com/HerbHall/devkit/commit/381920535ae7a843db8fdffd6da46cb1887951c5))
* new-project.ps1 steps 1-2 — concept collection and scaffolding (issue [#19](https://github.com/HerbHall/devkit/issues/19)) ([#45](https://github.com/HerbHall/devkit/issues/45)) ([a974652](https://github.com/HerbHall/devkit/commit/a974652bbddadca33098d79a96eb3bff94d11edb))
* new-project.ps1 steps 3-4 — CLAUDE.md generation and workspace open (issue [#20](https://github.com/HerbHall/devkit/issues/20)) ([#46](https://github.com/HerbHall/devkit/issues/46)) ([ac5d3a0](https://github.com/HerbHall/devkit/commit/ac5d3a0988200090664854e26b03ed4d984df3cc))
* project registry schema and manifest update (issue [#85](https://github.com/HerbHall/devkit/issues/85)) ([#96](https://github.com/HerbHall/devkit/issues/96)) ([bb6e37d](https://github.com/HerbHall/devkit/commit/bb6e37d9ee322b0a8fab8557a81389d7b2176f0e))
* propagation verification for DevKit updates ([#124](https://github.com/HerbHall/devkit/issues/124)) ([575749c](https://github.com/HerbHall/devkit/commit/575749cdc59991c50f802445c6fe72156ea6322d)), closes [#114](https://github.com/HerbHall/devkit/issues/114)
* reconcile 44 orphaned entries from local rules to devkit clone ([#140](https://github.com/HerbHall/devkit/issues/140)) ([4cdd17c](https://github.com/HerbHall/devkit/commit/4cdd17cefa7052d5c63e355f3028a404b4f5b93c))
* replace pre-existing classification with fix-forward workflow ([#108](https://github.com/HerbHall/devkit/issues/108)) ([#120](https://github.com/HerbHall/devkit/issues/120)) ([1df4c2f](https://github.com/HerbHall/devkit/commit/1df4c2f26da3cd6bf78bf549e3d6db5bdd173d9e))
* rule validation pipeline for autolearn ([#123](https://github.com/HerbHall/devkit/issues/123)) ([024e8cf](https://github.com/HerbHall/devkit/commit/024e8cf9126835c7f123b16e3e8025191db882b2)), closes [#116](https://github.com/HerbHall/devkit/issues/116)
* **scaffold:** add Gitea forge support to new-project.ps1 ([#285](https://github.com/HerbHall/devkit/issues/285)) ([5a760e0](https://github.com/HerbHall/devkit/commit/5a760e0b4a041216373b075d838aec58676b3269))
* scope-aware autolearn abstraction pipeline ([#122](https://github.com/HerbHall/devkit/issues/122)) ([1bb9508](https://github.com/HerbHall/devkit/commit/1bb9508b15e4eb4dfacc2411abd9c2d1cea3f978)), closes [#109](https://github.com/HerbHall/devkit/issues/109)
* set RELEASE_PLEASE_TOKEN secret during new project initialization ([#234](https://github.com/HerbHall/devkit/issues/234)) ([55eaacc](https://github.com/HerbHall/devkit/commit/55eaacced44c13f54365244db8a0503d9139439d))
* **skills:** add Go goroutine deadlock analysis to systematic-debugging ([#275](https://github.com/HerbHall/devkit/issues/275)) ([33728e6](https://github.com/HerbHall/devkit/commit/33728e64f2d2d8f21c1b4018b42ef5fe9a629c49))
* split append-only rule files into shared + local ([#69](https://github.com/HerbHall/devkit/issues/69)) ([8c283cb](https://github.com/HerbHall/devkit/commit/8c283cb28192199ffcae507a7928b4f65a48ff2c)), closes [#59](https://github.com/HerbHall/devkit/issues/59)
* standardize Copilot auto-review + contributor gating ([#194](https://github.com/HerbHall/devkit/issues/194)) ([#207](https://github.com/HerbHall/devkit/issues/207)) ([fb2d82f](https://github.com/HerbHall/devkit/commit/fb2d82f6dc2d9ffed7957132da1eab1e8bcd3913))
* sync local learnings from SubNetree sprints ([#57](https://github.com/HerbHall/devkit/issues/57)) ([215e932](https://github.com/HerbHall/devkit/commit/215e932c1dc607509c3fd385a8071711248ff544))
* version-tagged releases with update check and workflow (issue [#87](https://github.com/HerbHall/devkit/issues/87)) ([#102](https://github.com/HerbHall/devkit/issues/102)) ([08e80b0](https://github.com/HerbHall/devkit/commit/08e80b0f92d5a4609f9b99905fde06e1d3109b8f))


### Bug Fixes

* add Gitea CI checking graceful fallback to quality-control ([#229](https://github.com/HerbHall/devkit/issues/229)) ([b632fa9](https://github.com/HerbHall/devkit/commit/b632fa900cb6a7640d5d5b8c6374c90a02f4ecaa)), closes [#215](https://github.com/HerbHall/devkit/issues/215)
* add KG[#100](https://github.com/HerbHall/devkit/issues/100) -- large input ignored at task transition (Variant B stall) ([e15281b](https://github.com/HerbHall/devkit/commit/e15281bbb458c21a50f67e375dde2ac22450491e))
* add KG[#101](https://github.com/HerbHall/devkit/issues/101) -- Edit tool CRLF matching failure on Windows ([#231](https://github.com/HerbHall/devkit/issues/231)) ([a856ece](https://github.com/HerbHall/devkit/commit/a856ecef361173eb01df0386e4eecc70d096eeb7)), closes [#211](https://github.com/HerbHall/devkit/issues/211)
* add skip-dismiss and kg-frontmatter autolearn patterns ([a8e04a0](https://github.com/HerbHall/devkit/commit/a8e04a00da8e0cd3e026d0852af649f845421621))
* apply Copilot follow-up fixes from PRs [#235](https://github.com/HerbHall/devkit/issues/235) and [#236](https://github.com/HerbHall/devkit/issues/236) ([#240](https://github.com/HerbHall/devkit/issues/240)) ([f83700c](https://github.com/HerbHall/devkit/commit/f83700c6f5ff813fc58f9697054e5a7a6b0cde91))
* bootstrap runtime bugs and curate winget manifest ([#47](https://github.com/HerbHall/devkit/issues/47)) ([f616b6c](https://github.com/HerbHall/devkit/commit/f616b6c7f0a588d318aa514085ca543204d623d4))
* **ci:** replace invalid -Include param in Invoke-ScriptAnalyzer ([#271](https://github.com/HerbHall/devkit/issues/271)) ([5edd36e](https://github.com/HerbHall/devkit/commit/5edd36ee5d76cb391931730ad851825c8d78efd4))
* cleanup YOUR_PLATFORM, BMAD warning, skill contamination, gotcha renumber ([#25](https://github.com/HerbHall/devkit/issues/25)) ([0b5f7c8](https://github.com/HerbHall/devkit/commit/0b5f7c86ffc9a89c4a4b3dee798d41cd5ee664de))
* copilot review is informational not a merge gate ([a17d898](https://github.com/HerbHall/devkit/commit/a17d898fb189820a7cae89e916ad96f7b51dbb02))
* devkit-sync push auto-creates PR after git push ([#225](https://github.com/HerbHall/devkit/issues/225)) ([ba19012](https://github.com/HerbHall/devkit/commit/ba1901224c392882c7a50a872c97febb54699c58)), closes [#219](https://github.com/HerbHall/devkit/issues/219)
* **docs:** update stale pattern counts in README and CLAUDE.md ([#286](https://github.com/HerbHall/devkit/issues/286)) ([ccf06a4](https://github.com/HerbHall/devkit/commit/ccf06a4ff4169f554a010ce13b993ce94763ba02))
* prevent silent stall when skills trigger on pasted input ([#210](https://github.com/HerbHall/devkit/issues/210)) ([3b47c8a](https://github.com/HerbHall/devkit/commit/3b47c8ae296069ce44b9abebfb85e38bba88111a))
* remove false manual requirement (check [#18](https://github.com/HerbHall/devkit/issues/18)) from automation pipeline ([#248](https://github.com/HerbHall/devkit/issues/248)) ([a68b3cc](https://github.com/HerbHall/devkit/commit/a68b3cc96bb5f09342636b930e457256e4747c5c))
* remove trailing blank line from README (MD012) ([#202](https://github.com/HerbHall/devkit/issues/202)) ([077ec1a](https://github.com/HerbHall/devkit/commit/077ec1a6e258969a368176edd9abe39dc2a27061))
* rename /reflect invocation to /autolearn for consistency ([#228](https://github.com/HerbHall/devkit/issues/228)) ([8141501](https://github.com/HerbHall/devkit/commit/8141501d67165320df062b66b71475c884e88256)), closes [#214](https://github.com/HerbHall/devkit/issues/214)
* replace Python pseudo-code with correct agent format in AGENT-WORKFLOW-GUIDE ([#26](https://github.com/HerbHall/devkit/issues/26)) ([7c7395d](https://github.com/HerbHall/devkit/commit/7c7395dec7cc9c75cef6d18f155df8af6f7530c3)), closes [#22](https://github.com/HerbHall/devkit/issues/22)
* replace static skills array with dynamic discovery in sync.ps1 ([#226](https://github.com/HerbHall/devkit/issues/226)) ([108e22d](https://github.com/HerbHall/devkit/commit/108e22dd7f2c01e331d2ec0d14b1709d3f3351ed)), closes [#221](https://github.com/HerbHall/devkit/issues/221)
* require branch/PR for all autolearn changes, add handoff template ([#255](https://github.com/HerbHall/devkit/issues/255)) ([2b9ccdb](https://github.com/HerbHall/devkit/commit/2b9ccdb84b87e1eb56d2928bfa75f4f7fd9c91ad))
* Set-MachineIdentity crash in non-interactive mode ([#144](https://github.com/HerbHall/devkit/issues/144)) ([ed07e0e](https://github.com/HerbHall/devkit/commit/ed07e0edf58983f7f8cb939aacfd0ce09a1dd656))
* **setup:** remove Set-StrictMode from dot-sourced credentials.ps1 ([#283](https://github.com/HerbHall/devkit/issues/283)) ([241a7fe](https://github.com/HerbHall/devkit/commit/241a7fe1f333b252e44602d398df3e70bc1e6406))
* stack.ps1 runtime bugs and UX improvements ([#48](https://github.com/HerbHall/devkit/issues/48)) ([ad8259b](https://github.com/HerbHall/devkit/commit/ad8259b276c0f0907155dc0b7f093af1763a0b1e))
* sync documentation with actual project state ([#80](https://github.com/HerbHall/devkit/issues/80)) ([c08edd4](https://github.com/HerbHall/devkit/commit/c08edd413a3369fe5a48dec41d16b270fac7160d))
* sync.ps1 StrictMode crash on v2 manifest without shared property ([#142](https://github.com/HerbHall/devkit/issues/142)) ([3cac9ac](https://github.com/HerbHall/devkit/commit/3cac9ac9875580ca9c4614f2e80c62ae45be09eb))
* update golangci-lint-action from [@v6](https://github.com/v6) to [@v7](https://github.com/v7) ([#195](https://github.com/HerbHall/devkit/issues/195)) ([4530da5](https://github.com/HerbHall/devkit/commit/4530da560a989d62ebfc988dac388552d2a19214))
* use 4-backtick outer fence in handoff-template.md to fix markdown lint ([#270](https://github.com/HerbHall/devkit/issues/270)) ([45d1be8](https://github.com/HerbHall/devkit/commit/45d1be87f1f5592e9e83a52df80657d07eac9085))

## v2.3.0 -- 2026-03-01

Rules reconciliation, drift detection, and project settings enforcement.

### Added

- **Rules reconciliation** (PR #140): Imported 44 orphaned entries from local copies back to devkit (22 AP, 17 KG, 5 WP)
- **Rules drift detection** (PR #141): `devkit_drift_check()` in SessionStart.sh warns when local and devkit entry counts diverge; `/devkit-sync status` includes drift report
- **Project settings enforcement** (PR #145): Three-layer mechanism ensures all projects have `.claude/settings.json` -- git template, Kit 3 scaffolder, and SessionStart.sh detection
- **Git template settings.json** (PR #145): `git-templates/.claude/settings.json` auto-deploys on `git init`

### Fixed

- **sync.ps1 StrictMode crash** (PR #142): `PSObject.Properties.Match()` for safe property existence checks under `Set-StrictMode -Version Latest`
- **sync.ps1 Read-Host null** (PR #144): Null guard prevents crash when `Read-Host` returns null in non-interactive mode
- **Known gotcha KG#80** (PR #144): Documented PowerShell StrictMode + PSCustomObject property access gotcha

### Changed

- Rules entry counts: autolearn-patterns 76 -> 98, known-gotchas 62 -> 80, workflow-preferences 11 -> 16
- `/devkit-sync verify` now checks `.claude/settings.json` presence across all projects

## v2.2.0 -- 2026-02-28

Rule lifecycle management for the autolearn system.

### Added

- **Rule lifecycle metadata format** (PR #126): ADR-0014 defines per-entry metadata (`**Added:**`, `**Source:**`, `**Status:**`, `**Last relevant:**`, `**See also:**`), deprecation states, and archive strategy
- **Archive directory** (PR #126): `claude/rules/archive/` for deprecated entries (not loaded into sessions, frees context tokens)
- **Frontmatter extensions** (PR #126): `entry_count` and `last_updated` fields in Tier 2 rules file frontmatter
- **Metadata PoC** (PR #127): 10 proof-of-concept entries annotated with lifecycle metadata (5 AP, 5 KG)
- **Duplicate resolution** (PR #127): AP#27 superseded by KG#17, archived; swagger cluster cross-referenced (5 entries)
- **Rules audit workflow** (PR #128): `/reflect` option 5 for health check -- parses entries, generates report, identifies stale/duplicate entries, proposes actions
- **Last-relevant tracking** (PR #128): `/reflect` quick and session workflows update `**Last relevant:**` timestamps on entries applied during the session

### Changed

- Autolearn-patterns entry count: 76 -> 75 (AP#27 archived)

## v2.1.0 -- 2026-02-28

Governance and quality gates for the autolearn system.

### Added

- **Tiered rule governance** (PR #117): `core-principles.md` (Tier 0, immutable) and `error-policy.md` (Tier 1, governed) rules files with YAML frontmatter tier metadata
- **SessionStart health checks** (PR #118): symlink integrity verification and CLAUDE.md detection at session start
- **Pre-commit verification** (PR #119): build/test/lint gates before commit in workflow preferences
- **Fix-forward workflow** (PR #120): error-policy.md with zero-tolerance fix-forward, replaces "pre-existing" classification
- **Template quality gates** (PR #121): CI scaffolding templates include lint and test verification steps
- **Autolearn scope-aware routing** (PR #122): in DevKit, write Tier 2 rules directly; in projects, write to MCP Memory and create DevKit issues for universal learnings
- **Rule validation pipeline** (PR #123): five-stage gate for proposed rules (dangerous pattern scan, core principles check, conflict check, risk classification, storage decision) in `references/validation-pipeline.md`
- **Propagation verification** (PR #124): `/devkit-sync verify` checks all active projects for DevKit update propagation via symlink health; SessionStart reports rule file changes after pull
- `/devkit-sync promote` subcommand for graduating local patterns to universal rules
- `/devkit-sync update` subcommand for version checking and upgrading

### Changed

- Autolearn workflows (`quick-reflect.md`, `session-review.md`) now include validation and scope assessment steps
- `update-knowledge.md` requires DevKit context (context guard rejects non-DevKit sessions)
- Rules file count increased from 8 to 10

## v2.0.0 -- 2026-02-25

v2.0 represents a major architectural shift from a bash-centric toolkit to a
cross-platform, multi-tier system with formal versioning.

### Added

- Three-tier settings architecture (ADR-0012): User > DevSpace > Project cascade
- Dual-language scripting strategy (ADR-0013): PowerShell primary, bash legacy
- Cross-platform path resolution via `~/.devkit-config.json`
- Forge abstraction layer for GitHub/GitLab operations
- Project registry for multi-project coordination
- Local overrides via `.local.md` pattern (gitignored, machine-specific)
- SessionStart hardening: rate limiting (1/hour), lock-file awareness, pull logging
- Auto-push prompt after `/reflect` sessions
- Version-tagged releases with `VERSION` file as single source of truth
- SessionStart version check: notifies when a newer DevKit release is available
- `devkit update` command via `/devkit-sync` skill (check version, upgrade to tag or latest)
- `devkit promote` command for graduating local patterns to universal rules

### Version Policy

- MAJOR: Breaking changes to rules, skill interfaces, or sync protocol
- MINOR: New skills, agents, or non-breaking rule additions
- PATCH: Bug fixes, documentation, pattern additions

## v1.2.0 -- 2026-02-21

### Fixed

- claude/CLAUDE.md: replaced `YOUR_PLATFORM` placeholder with actual value and substitution note
- METHODOLOGY.md: added Windows warning for BMAD/Spec Kit tools (see known-gotchas #42-44)
- known-gotchas.md: renumbered contiguously 1-46 (was non-contiguous with gaps at 8-9, 13, 40, 42, 44 and #47 out of order)
- Cross-references to gotcha numbers updated in autolearn-patterns.md and workflow-preferences.md
- AGENT-WORKFLOW-GUIDE.md: replaced Python pseudo-code agent examples with correct `.claude/agents/*.md` format

### Added

- CI: README skill count accuracy check (fails if count doesn't match `claude/skills/` directories)
- CI: verify.sh skill list accuracy check (fails on missing directories, warns on unlisted skills)
- `profiles/` directory for Kit 2 stack profiles
- `project-templates/` directory for Kit 3 scaffolding
- `docs/` and `machine/` directories for guides and snapshots
- PowerShell stub files: setup.ps1, bootstrap.ps1, stack.ps1, new-project.ps1, verify.ps1, lib/*.ps1
- `setup/lib/ui.ps1`: console output library (Write-Section/Step/OK/Warn/Fail, Write-VerifyTable, Read-Required/Confirm/Menu, Invoke-ManualChecklist)
- `setup/lib/checks.ps1`: prerequisite and tool detection library (Test-Tool, Test-HyperV, Test-WSL2, Test-Virtualization, Test-DeveloperMode, Test-WindowsVersion, Test-ClaudeAuth/Skill/MCP, Test-DockerRunning/WSLBackend, Test-Credential, Get-PreflightStatus)
- `setup/lib/install.ps1`: winget and manual install wrappers (Install-WingetPackage/Packages, Install-VSCodeExtension/Extensions, Invoke-ManualInstall, Export-WingetManifest, Export-VSCodeExtensions)
- `setup/lib/credentials.ps1`: Windows Credential Manager integration (Set/Get/Test/Remove-DevkitCredential, Invoke-CredentialCollection with validation and secure input)
- `setup/setup.ps1`: main menu entry point with -Kit parameter for direct dispatch, version display, quick status check
- `machine/winget.json`: curated winget export (25 dev packages, personal apps removed)
- `machine/git-config.template`: gitconfig template with YOUR_NAME/YOUR_EMAIL placeholders
- `machine/manual-requirements.md`: reference for non-automatable setup steps (Hyper-V, WSL2, Docker config, Dev Mode)
- `setup/backup.ps1`: refresh machine snapshot files from current state with diff summary
- `setup/bootstrap.ps1` phases 1-2: pre-flight checks (Windows version, Hyper-V, WSL2, virtualization, Developer Mode) and core tool installs from machine/winget.json + vscode-extensions.txt
- `setup/bootstrap.ps1` phases 3-4: git config from template, devspace directory setup with ~/.devkit-config.json, PowerShell profile alias, credentials collection via Windows Credential Manager
- `setup/bootstrap.ps1` phases 5-6: AI layer deploy (Claude Code npm install, skills/rules/agents/hooks with hash-based overwrite, CLAUDE.md placeholder substitution) and full verification table with next steps
- `docs/BOOTSTRAP.md`: step-by-step new machine setup guide with troubleshooting section
- `setup/lib/profiles.ps1`: profile format parser with YAML frontmatter, dependency resolution, and cycle detection
- `project-templates/concept-brief.md`: project vision capture template for Kit 3 scaffolding
- `project-templates/claude-md-template.md`: fallback CLAUDE.md template for new projects
- `project-templates/github-labels.json`: standard label set (13 labels) for new GitHub repos
- `profiles/go-cli.md`: base Go profile (winget, linters, VS Code extensions, cross-compilation)
- `profiles/go-web.md`: extended Go+Web profile (buf, gRPC, REST client, Docker deployment)
- `profiles/iot-embedded.md`: ESP32/ESPHome profile (uv-managed tools, OTA/serial flashing, sensor patterns)
- `setup/stack.ps1`: Kit 2 profile selection and installer (-List, -ShowProfile, -Install, -Force flags)
- `setup/new-project.ps1` steps 1-2: concept collection (interactive + file), project scaffolding (git, GitHub, directories, labels, workspace)
- `setup/new-project.ps1` steps 3-4: Claude-generated CLAUDE.md (with template fallback), Phase 0 issue creation, workspace open

### Changed

- Bash setup scripts moved to `setup/legacy/` with deprecation headers (PowerShell primary)
- SKILLS-ECOSYSTEM.md: expanded Chat skill installation guide with rationale and sync process
- `devspace/CLAUDE.md` moved to `project-templates/workspace-claude-md-template.md`

### Removed

- go-development SKILL.md: removed network_security_patterns section (SubNetree-specific content)

## v1.1.0 -- 2026-02-17

### Removed

- coordination-sync, research-mode, dashboard, pm-view, dev-mode skills
  (moved to SubNetree project -- too project-specific for a general toolkit)

### Fixed

- settings.template.json: JSON syntax errors (missing commas on lines 17, 75)
- settings.template.json: removed hardcoded Windows drive path (`Read(//d/**)`)
- AUTOMATION-SETUP.md: fixed `Claude.md` -> `CLAUDE.md` capitalization (3 instances)
- SessionStart.sh: removed stale `D:/DevSpace/.coordination/` references
- verify.sh: now checks all 9 remaining skills (was only checking 5 of 14)

### Changed

- devspace/CLAUDE.md converted to template with generic placeholders
- memory-seeds.md converted to example with generic entity names
- claude/CLAUDE.md OS line made generic (was hardcoded to Windows MSYS_NT)
- settings.template.json: removed redundant granular permissions, trimmed plugin list to core set
- README.md: added Quick Start, What's Included section, updated skill inventory
- METHODOLOGY.md: updated tool references for removed skills
- SessionStart.sh: simplified to generic CLAUDE.md detection only

### Added

- GitHub Actions CI workflow: markdown lint + skill routing validation
- CHANGELOG.md

## v1.0.0 -- 2026-02-17

Initial release. 101 files: 5 rules (70+ patterns, 47+ gotchas), 14 skills,
6 agent templates, hooks, setup scripts, MCP config, project templates,
and development methodology.

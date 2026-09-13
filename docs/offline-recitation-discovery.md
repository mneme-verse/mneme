# Offline poetry recitation: discovery

Discovery snapshot: 2026-09-13. This document records inspected code and upstream documentation, not implemented features or measured performance. The working tree was read-only during discovery. Planned repository destination: `docs/offline-recitation-discovery.md`.

## Product requirements and confirmed scope

Mneme remains a Flutter Android poetry-memorization app using PoeTree. The requested recognition engine is [handy-computer/transcribe.cpp](https://github.com/handy-computer/transcribe.cpp), not whisper.cpp. Users should be able to start reciting without choosing a poem; the app should identify the poem and location and provide live word feedback. Russian is the priority, including Russian poems containing English, French and Latin passages.

The user chose modern midrange phones, approximately 6–8 GB RAM, and accepted substantial one-time downloads for subsequent offline use. After distinguishing transcription from acoustic pronunciation assessment, the user explicitly chose **word checking first, pronunciation guidance and recording playback**. Automatic stress and phoneme grading are not part of the agreed implementation. Russian literary readings of Latin quotations should be accepted while retaining original Latin spelling.

Anki-like spaced repetition, usable screens, strong tests and CI publishing signed Android builds to GitHub Releases are required. Permission to manage issues/PRs does not override read-only planning restrictions.

## Current application

### Dependencies and platform

Inspected `pubspec.yaml`: package `mneme`, version `0.1.0+1`, Dart `^3.9.0`, Flutter `^3.35.0`. Existing dependencies include Bloc/flutter_bloc, Drift/drift_flutter, HTTP, crypto, es_compression, shared_preferences, path_provider and Flutter localization. There is no speech-recognition, audio-capture or scheduling dependency.

`android/app/src/main/kotlin/com/mnemeverse/mneme/MainActivity.kt` is a plain FlutterActivity. The main Android manifest has no RECORD_AUDIO or INTERNET declarations. There is no native ASR integration in the inspected app. README names Sherpa ONNX as the intended technology, but no Sherpa implementation needs to be migrated or preserved.

`android/app/build.gradle.kts` defines production, staging and development flavors. Production application ID is `com.mnemeverse.mneme`. `android/settings.gradle.kts` specifies AGP 8.12.0 and Kotlin 2.2.10. Compile/target/min SDK and NDK currently derive from Flutter configuration.

### Startup and onboarding

`lib/bootstrap.dart:26–41` constructs `AppDatabase(openConnection(name: 'en'))` unconditionally. Selecting Russian does not change that opening path.

`lib/features/onboarding/cubit/onboarding_cubit.dart` has `completeOnboarding(String languageCode)`. It only writes `selected_language` and `onboarding_completed` and emits the language; its comments explicitly describe the download as a stub. The onboarding page presents English and Russian and navigates immediately after that preference write.

`lib/app/view/app.dart` checks only the completion preference to choose onboarding or home. It does not validate installed corpus/model files. `assets/database/` contains only `.gitkeep` in this checkout.

`lib/db/connection/flutter_connection.dart` attempts to copy an asset to the application documents directory, catches and logs asset-copy failures, then opens a named `driftDatabase`. The copied File is not passed to the database opener. The proposed implementation must use an explicit validated installed File; the current code does not establish that the copied and opened files are identical.

### UI and localization

`lib/features/home/view/home_page.dart` lists authors through HomeCubit with scroll pagination. Search, settings and author-navigation callbacks are TODOs. The inspected feature tree contains onboarding and home, not poem detail, recitation, review or scheduling screens.

`lib/l10n/arb/app_en.arb` is the only locale source found by the app scout. It contains a small English vocabulary for onboarding and authors. Existing patterns to reuse are Material 3, Bloc/Cubit, MaterialPageRoute, ARB-generated localization and repository injection.

## PoeTree data and search

### Corpus pipeline

`tool/builder.dart` supports `cs`, `de`, `en`, `hu`, `no`, `pt`, `ru`, `sl`. Downloads use `https://zenodo.org/records/17414036/files/<language>.zip`. The code describes these as CC BY-SA 4.0 corpora and writes attribution/license metadata. The upstream record itself was not fetched successfully during this investigation; the allowlist and generated attribution were verified in source, not independently audited against every upstream archive.

The builder harvests duplicate records' alternative titles, skips duplicate bodies and processes files in isolates. `extractPoemData` reads title, author(s), each body line's `text`, year_created or source.year_published. It joins surviving nonempty line strings with newlines. Consequences:

- Original source IDs are consulted for duplicate-title lookup but are not retained in stored poem rows.
- Empty line strings are dropped; stanza spacing can be lost.
- Records without a title are discarded even when body text is present.
- Text is otherwise retained as strings; there is no main/embedded-language annotation or phonetic representation.
- Local poem IDs are assigned when concurrent worker results arrive. They are not stable corpus identities for long-lived review history.

The actual Russian archive and a complete Eugene Onegin edition are not present in this checkout. Its exact coverage, line structure and foreign passages must be inspected when the corpus is acquired. The small seed texts are not proof of full corpus coverage.

### Database structure

`lib/db/tables.dart` defines:

| Table | Existing fields |
| --- | --- |
| Poems | id, title, authorNames, body, year nullable, altTitles nullable |
| Authors | id, name, poemCount |
| PoemAuthors | poemId/authorId composite primary key |
| Metadata | key/value |

`lib/db/database.dart` uses schema version 1. Batch inserts encode rows as JSON and insert via SQLite json_each. FTS5 `poems_fts` is external-content over `poems`, with triggers for insertion, deletion and update.

A concrete schema mismatch needs attention: FTS calls its author column `author`, while the content table calls it `author_names`. Triggers explicitly map new.author_names into that slot, but external-content reads/rebuilds expect corresponding content columns. Fixing query code alone would not repair this mismatch. This is a source-level finding; no reproduction or test was executed in plan mode.

### Repository behavior

`lib/repository/poetry_repository.dart` exposes:

- `searchPoems(String query, List<String> activeLanguages, {int limit = 20, int offset = 0})`
- `getRandomPoem(List<String> activeLanguages)`
- `getAuthors({int limit = 20, int offset = 0})`
- `getMetadata(String key)`

Both language-list arguments are unused. The repository operates on a single language-specific database. Search uses parameter binding, but passes the user's text directly as FTS MATCH syntax; binding alone does not make arbitrary FTS expressions safe literal searches. Empty search returns ordinary paged poems. No recitation passage retrieval or sequence alignment exists.

### Data publication

`generateManifest()` writes a flat language-keyed manifest. Entries contain file, name, size, MD5 hash, fixed version `1.0+1` and a license object. Zstandard artifacts are `<language>.db.zst`.

`tool/publish_data.dart` implements `DataPublisher.publish()`: validate artifacts, determine version from a language entry, create/view `data-v<version>`, upload compressed databases plus manifest. It currently uses `--clobber`. This is a **data** release mechanism, not an Android app release workflow.

## transcribe.cpp integration evidence

### Source and ABI

Upstream revision inspected: **585b98f7e66777d16f2da734ceedaa7398060fa7**. Public header version: **0.2.3**. The engine is MIT-licensed and uses C++17, GGUF models and ggml. Sources:

- [README](https://github.com/handy-computer/transcribe.cpp/blob/585b98f7e66777d16f2da734ceedaa7398060fa7/README.md)
- [CMake configuration](https://github.com/handy-computer/transcribe.cpp/blob/585b98f7e66777d16f2da734ceedaa7398060fa7/CMakeLists.txt)
- [Public C API](https://github.com/handy-computer/transcribe.cpp/blob/585b98f7e66777d16f2da734ceedaa7398060fa7/include/transcribe.h)
- [Parakeet streaming extension](https://github.com/handy-computer/transcribe.cpp/blob/585b98f7e66777d16f2da734ceedaa7398060fa7/include/transcribe/parakeet.h)

The README documents Python, TypeScript, Rust and Swift bindings, not a Dart/Android binding. No Android build/runtime validation was found in the inspected documentation. That is **unverified portability**, not evidence that Android cannot work. The intended integration requires a JNI wrapper and an NDK CPU build smoke test.

Load-bearing API rules:

- Audio input is **16 kHz mono float32 PCM**. No built-in caller-format resampler.
- Caller-owned structs must use the matching `transcribe_*_init()` function. Zero-initialized structs are not substitutes.
- Sessions are not thread-safe. At most one inference/active-stream computation may run per loaded model at once.
- Model lifetime must exceed every session lifetime. Stop/join inference before freeing sessions and model.
- Result strings and row text are borrowed session-owned pointers. Copy at the JNI boundary before the next mutation.
- Streaming uses transcribe_stream_begin/feed/get_text/finalize; errors and cancellation can leave partial results, not successful final transcripts.
- `full_text` is authoritative. `committed_text` is an append-only display convenience and may disagree with later authoritative output. Finalization does not necessarily correct an earlier committed prefix.
- `transcribe_token::p` is model-dependent, uncalibrated, and may be NaN. It is not a pronunciation score.
- The public API exposes decoded text/timestamps/token probabilities, **not full CTC frame emissions or phoneme/stress assessment**.

### Relevant models

These are upstream published figures, not Mneme measurements:

| Model | Documented strengths | Important limits |
| --- | --- | --- |
| GigaAM-v3-e2e-rnnt Q8_0 | Russian only, ~261 MB, upstream port reports 5.36% FLEURS Russian WER, token timestamps; MIT | No native streaming, no foreign-language support, recommended utterances ≤25 s; no word-level timestamps |
| Nemotron 3.5 ASR Streaming 0.6B Q8_0 | ~716 MB, cache-aware streaming, Russian/English/French among supported locales, word/token timestamps, automatic language detection; OpenMDW-1.1 | Published port WER gates are English, not Russian poetry; Android latency/memory unmeasured; no claimed native Latin support |
| Multilingual Whisper via transcribe.cpp | Broad multilingual transcription and several size options | Port exposes segment timestamps only and no native streaming; not equivalent to an existing whisper.cpp Android implementation |

Sources: [GigaAM](https://github.com/handy-computer/transcribe.cpp/blob/585b98f7e66777d16f2da734ceedaa7398060fa7/docs/models/gigaam-v3-e2e-rnnt.md), [Nemotron streaming](https://github.com/handy-computer/transcribe.cpp/blob/585b98f7e66777d16f2da734ceedaa7398060fa7/docs/models/nemotron-3.5-asr-streaming-0.6b.md), [Whisper family](https://github.com/handy-computer/transcribe.cpp/blob/585b98f7e66777d16f2da734ceedaa7398060fa7/docs/models/whisper.md).

Decision update (2026-09-13): the user chose to **evaluate GigaAM first**, with Nemotron as the streaming baseline, rather than commit to the originally proposed Nemotron Q8_0 shipping choice. Compare GigaAM-v3-e2e-rnnt Q8_0 segmented inference against Nemotron Q8_0 cache-aware streaming on the same Russian and mixed-language human recordings, including deliberate word errors and confirmed Russian reading variants. Preserve original foreign text; do not automatically accept transliteration as correct. Measure word-error precision/recall, identification, uncertainty, boundary errors, end-to-end latency, inference time excluding feed pacing, peak RSS and sustained phone performance. Existing accuracy and physical-device gates remain unchanged; no shipping model has been selected from measurements.

Comparison prerequisites remain blocked: Hugging Face API access failed for both model repositories through curl, and the GigaAM metadata reader also failed. Immutable revisions, checksums and actual license texts have not been acquired. Java, ADB and sdkmanager were not on PATH; Android SDK environment roots were unset, and no SDK/JDK, model files or recitation fixtures were found in the checked standard/project locations. Neither model was executed. This is prerequisite evidence, not a failed model benchmark. Do not substitute invented hashes, synthetic accuracy evidence or a moving main URL in a release.

## What the immersive-reading article contributes

[Automating immersive reading](https://smoores.dev/post/automating_immersive_reading/) was read from the full text supplied by the user after direct web fetching failed.

The article describes two stages:

1. **Boundary search:** obtain MMS CTC emissions, greedily decode a noisy text stream, condition text while retaining original positions, match character 10-grams and use RANSAC to reject inconsistent matches. This locates corresponding content despite missing/reordered chapters and divergent narration.
2. **Forced alignment:** use globally unique matching anchors to split the problem, then CTC Viterbi between anchors. A valid CTC path can stay, advance, or skip a blank between unequal symbols; repeated equal symbols need intervening blanks. The algorithm uses emission log probabilities and backpointers to recover timing.

Useful adaptations for Mneme:

- Separate “which poem and where?” from “what differed?”
- Preserve source offsets through normalization.
- Retrieve short candidate passages before detailed alignment.
- Permit skips, substitutions and restarts instead of assuming recital begins at the first line.
- Use unique monotonic anchors only when they are actually supported by observations.

Do not transfer long-book thresholds or robustness claims to a few seconds of speech. A 2,000-character anchor interval and stochastic boundary fit are unnecessary for small candidate windows. More importantly, forced alignment can align expected text to imperfect audio; it does **not** establish that every expected word was spoken or correctly pronounced. Expected poem text must not be used to manufacture a matching ASR transcript. Implementing the article's exact acoustic CTC pass would require full emissions that the inspected transcribe.cpp C API does not expose.

## Pronunciation versus word fidelity

ASR can normalize or silently repair mispronunciations. A text match therefore establishes only that the recognizer produced the expected word, not that the learner used the right sounds or stress. Token confidence and forced-alignment success do not solve that distinction.

Canonical Unicode composition/decomposition can reuse [unorm_dart](https://github.com/yshrsmz/unorm-dart): inspected version 0.3.2, Dart >=2.12 <4, documented nfc/nfd functions. Removing all combining acute marks would incorrectly erase French accents. The planned normalizer must remove stress marks only on Cyrillic bases and preserve original source offsets separately from normalized keys.

A read-only scout confirmed no built-in pronunciation/stress API. [Allosaurus](https://github.com/xinjli/allosaurus) was also inspected as an external universal phone recognizer: it documents phone sequences, approximate timestamps and phone inventories, but that is not a validated Android Russian stress-assessment solution. No deployable Russian stress grader was established in this discovery.

The approved scope response is honest word checking, uncertainty states, original text/reading guidance and playback. Embedded Latin script cannot be identified as French, English or Latin from script alone. User-confirmed, poem-version-scoped reading variants can accept Russian literary Latin readings without silently transliterating all foreign words or editing the original poem.

## Spaced repetition reuse

[open-spaced-repetition/dart-fsrs](https://github.com/open-spaced-repetition/dart-fsrs) was inspected, including README, `pubspec.yaml` and `lib/fsrs.dart`. Package version is 2.0.1, MIT license, Dart ^3.3.0.

Verified interface:

```dart
final scheduler = Scheduler();
final previousCard = Card(cardId: databaseAllocatedId);
final (:card, :reviewLog) = scheduler.reviewCard(
  previousCard,
  Rating.good,
  reviewDateTime: utcTime,
  reviewDuration: durationMilliseconds,
);
```

Card, ReviewLog and Scheduler support toMap/fromMap. Ratings are again/hard/good/easy; times must be UTC. New cards are due immediately. The library has learning and relearning steps, retention targeting and optional fuzzing. Use database-allocated IDs instead of Card.create's time-based ID approach. Proposed persistence must be separate from downloadable corpus packs, use stable source identity, and make review submission transactional/idempotent. ASR should inform the learner, not automatically choose a punitive review rating.

## Tests and verification gaps

Existing tests cover database/seed behavior, builder/publisher, home/onboarding Cubits/widgets and app startup. `test/helpers/pump_app.dart` supplies localization in widget tests. There are no existing audio fixtures or native ASR/recitation accuracy tests in the inspected tree.

`test/db/database_test.dart` contains real search cases and tests called language-filter tests that only exercise an already language-specific database. The latter do not verify the advertised filter. Some tests pin fixture counts or plumbing rather than user behavior; do not treat those as evidence of recognition/scheduling quality.

Required new evidence includes:

- Actual Android build and real model inference, not only Dart channel doubles.
- Human Russian recitations with intentional word errors and mixed-language passages, with provenance and held-out speakers.
- Negative cases: silence/noise/unrelated speech, ambiguous quotations, restarts, partial utterances and stale hypotheses.
- Correct source-offset highlighting and uncertainty handling.
- First-run resource installation, corruption/cancellation/restart recovery, and airplane-mode relaunch.
- Review persistence/idempotency and preservation across corpus replacement.
- Actual phone latency/memory over sustained recitation, accessibility and recording lifecycle.

No tests, model benchmarks, Android builds or UI runs were performed during planning. All accuracy/latency/memory thresholds in the execution plan are acceptance targets, not observed results.

## CI and publication

The repository remote is `https://github.com/mneme-verse/mneme.git`. Existing `.github/workflows/main.yaml` runs semantic PR, Flutter package and spell-check workflows on main pushes and PRs. It has no APK publication job.

Existing release signing environment variables in Gradle are:

- ANDROID_KEYSTORE_PATH
- ANDROID_KEYSTORE_ALIAS
- ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD
- ANDROID_KEYSTORE_PASSWORD

The plan can reuse this contract rather than introduce a second signing route. A stable keystore and expected public certificate must be provisioned before production publication; no debug signing or regenerated key may masquerade as a release identity. App release tags and corpus data-v tags must remain separate. Proposed CI publishes a signed arm64 APK only after validation and uploads checksums and verification provenance.

Authenticated issue lookup failed because organization policy rejects the configured fine-grained token's lifetime over 366 days. This is a local GitHub access blocker, not a revocation of user authorization or proof that workflow GITHUB_TOKEN will fail. No issues, PRs or releases were created during discovery. Source code and public GitHub documentation remained readable.

## Remaining factual prerequisites

- Actual Android CPU portability and sustained performance of the pinned transcribe.cpp revision/model.
- ~~Immutable model artifact revision/hash/size and redistributable license text.~~ Acquired on 2026-09-13: revision-pinned Hugging Face URLs, LFS SHA-256 hashes and sizes for both candidates, plus MIT (GigaAM upstream) and OpenMDW-1.1 license texts, are recorded in `docs/model-lock.json` and `docs/licenses/`. Byte-level verification against a full download still runs in the installer and desktop harness.
- Actual Russian PoeTree/Onegin coverage and detailed source text once archives are acquired.
- Consented, redistributable human audio fixtures for meaningful accuracy evidence. Public-domain LibriVox readings may serve as development fixtures; they remain studio-style readings without deliberate word errors or phone-mic noise and do not replace held-out deliberate-error fixtures.
- Stable Android signing secrets and usable GitHub credentials for external publication.

These must not be replaced with mocks, invented success claims or undocumented scope reductions. The execution plan specifies implementation behavior and publication gates separately from this discovery snapshot.

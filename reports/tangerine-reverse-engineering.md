# Tangerine reverse-engineering report

## Executive summary

The submitted artifact is a signed, Mac App Store-style macOS menu-bar
utility named **Tangerine**, bundle identifier `com.th.Tangerine`, version
`2.0.2` (build `9`). It is a native Swift/SwiftUI/AppKit application with a
large local conversion and file-tool suite. Its primary interaction model is
dragging files onto a conversion “fan”/wheel and pressing configured modifier
keys to select a conversion, tool, or file action.

The recovered product is substantially broader than a simple format
converter. It contains:

- local conversion between image, audio, video, document, spreadsheet,
  archive, and subtitle formats;
- image editing, annotation, framing, collage, cropping, QR reading, and
  privacy-oriented redaction/metadata removal;
- video trimming, splitting, joining, snapshots, speed changes, cropping,
  redaction, and audio replacement/muting;
- audio trimming, channel mixing, waveform visualization, normalization, and
  bleep/redaction workflows;
- PDF splitting, merging, reordering, rotation, width equalization, and
  extraction of text/artwork;
- offline document rendering and document conversion for DOCX, Pages, EPUB,
  HTML, RTF/RTFD, text clippings, PowerPoint, and spreadsheets;
- file actions for copying paths, moving files, opening a terminal, floating
  files in a Finder-like window, and AirDropping files;
- a first-run welcome flow, launch-at-login setting, folder permission
  management, progress windows, settings, and a one-time-purchase paywall.

The app is sandboxed and uses security-scoped bookmarks for user-authorized
folders. Results are designed to be saved beside the originals. The embedded
privacy manifest declares no tracking and lists purchase history as collected
for app functionality. RevenueCat/StoreKit is used for purchase and restore
flows; the actual product/entitlement identifiers are primarily remote rather
than plainly embedded in the binary.

This is a **static** reverse engineering result. The Linux worker did not and
cannot launch the macOS application, its Mach-O helpers, its Java runtime, or
its AppKit UI. Therefore the recovered design is evidence-backed, but runtime
claims such as exact conversion matrix cells, current RevenueCat offerings,
and live network destinations still need macOS validation.

## Scope, evidence, and method

### Input

The attached archive was inspected at:

```text
.opencode/omnirush/inbox/chat-attachments/ses_eaac0f52fffeaph44R6KICTKtm/
7d979e5b-152b-4059-95bb-1309d2b4194f-Tangerine.zip
```

It was extracted without launching any member into:

```text
reverse-engineering/Tangerine.app/
```

Archive safety checks found 526 ZIP entries, 0 absolute/path-traversal
members, and only relative JDK-license symlinks pointing to sibling files.
`unzip -t` reported no compressed-data errors.

The runtime does not have the `reverse-engineer-anything` skill installed and
does not have an active REA MCP registration. The official REA CLI fallback
was nevertheless available through `npx -y rea-agents@latest` (CLI `6.7.0`),
so its provider-neutral artifact inventory and dyld-resolution passes are
included below. Native macOS-provider operations remained unavailable in the
Debian worker.

### Static techniques used

- ZIP inventory, path-safety validation, and checksums;
- `Info.plist`, privacy manifest, receipt, license, and helper-script reading;
- Mach-O header/load-command parsing, including linked frameworks, minimum
  OS/build information, code-signature offsets, and architecture;
- extraction of embedded code-signing entitlements and CodeDirectory identity;
- readable-string and Swift reflection-name extraction from the main binary;
- enumeration of bundled Java classes/JAR manifests;
- inspection of Java class-file constant strings for conversion limits and
  rejection conditions;
- offline inspection of the bundled JavaScript and Perl bridges;
- REA artifact inventory and static dyld load-path resolution;
- syntax/integrity checks implemented in `tools/verify.py`.

No disassembler output, UI automation, process tracing, packet capture, or
macOS dynamic execution is represented as completed evidence.

### REA supplemental static pass

The provider-neutral REA artifact inspection completed without executing the
bundle. Evidence `ev_c2cfe9785937194a451b77fa19c8038a875da7685f3e388a724abc882141bf0e`
retains inventory substep Evidence
`ev_1198037dda3db47e272cdf035d828cd1d2934b29e847e6b8daa53067312bb4b4` for
the extracted app. It reports a root SHA-256 of
`889b6780b103e4eeddb31b3ce0d0f5708e94373eae4b66df1319a42ebcdadb35`, graph
SHA-256 `bf48018752108445370fe666d86ad9713607c4744e74b862924dbddb51b38123`,
422 artifact nodes, 525 path occurrences, and 488 graph edges. The inventory
coverage is complete within that inventory substep; it is not a claim about
runtime loading or format semantics.

REA's execution-free dyld resolver also completed for every detected
executable architecture. Evidence
`ev_1c61d2220a8edcc3f91da3b30dd18dd665d4489dc81cd61963a3aff6233f3524`
covered seven process roots, nine parsed images, and 95 load edges with
complete static coverage. It found two derived
`earlier-rpath-candidate-absent` findings for the arm64 and x86_64 Java
launchers: the modeled search checks each launcher directory before its
bundled `lib` fallback for `libjli.dylib`. This is a search-order hypothesis,
not observed hijacking; REA does not evaluate code-signing library validation
or execute dyld.

The REA `inspect_plist` and `inspect_macho` CLI operations were attempted but
returned `capability_unavailable`: their `native-macos` provider requires
macOS. The independent Python plist and Mach-O parsing results in this report
remain the supported observations for those facets in this worker.

REA's JavaScript application pass was also run against the two shipped bridge
files `OfficePreview.js` and `PagesWriter.js`, and against no other resource
files. Evidence
`ev_3d29f71236ce5eb33181b20b576755de1ddf3cf68a16f2e9717038330321176c`
retains the result. Both files were read and parsed as inert text, with no
parse failures, 185,373 visited AST nodes, and 40000 retained semantic nodes.
The selected-file summary found zero browser windows, preload entrypoints,
context-bridge APIs, exposed API members, or IPC operations. That is evidence
about these two selected files only, not proof that the native app has no
JavaScript or IPC integration elsewhere.

The pass emitted two **low-confidence endpoint candidates** from
`PagesWriter.js`: `Metadata/Properties.plist` and
`Metadata/BuildVersionHistory.plist`, both arising from a static `n.get`
candidate. Their values look like local Pages package paths, and REA explicitly
states that the receiver was not established and runtime execution was not
observed. They are therefore not network destinations and do not change the
report's conclusion that live network behavior remains unverified. The
semantic graph also retained many unknowns and partial relation families due
to dynamic JavaScript resolution; these are coverage limits, not findings of
malicious behavior.

## Package identity and build metadata

| Property | Recovered value |
| --- | --- |
| Display/name | Tangerine |
| Bundle identifier | `com.th.Tangerine` |
| Version | `2.0.2` |
| Build | `9` |
| Minimum macOS | `13.0` |
| Category | `public.app-category.utilities` |
| Application type | `APPL` |
| UI mode | `LSUIElement=true` (menu-bar/background app) |
| Main class | `NSApplication` |
| Compiler | Apple Clang (`com.apple.compilers.llvm.clang.1_0`) |
| Xcode/SDK metadata | Xcode `2700`, macOS SDK `27.0` |
| Build machine OS build | `26A428` |
| Encryption declaration | `ITSAppUsesNonExemptEncryption=false` |

The main executable is a **thin arm64 Mach-O**, not a universal binary. The
main app, bundled FFmpeg, and bundled cwebp are arm64. The embedded PowerPoint
runtime contains both arm64 and x86_64 JDK trees, but that does not make the
main application Intel-compatible.

The main Mach-O imports these notable Apple frameworks:

- Foundation, AppKit, SwiftUI, Combine, CoreFoundation, CoreGraphics,
  CoreText, CoreImage, ImageIO;
- AVFoundation, AVKit, CoreMedia, QuickLookThumbnailing, QuickLookUI;
- PDFKit, WebKit, JavaScriptCore, Vision;
- Security, CryptoKit, StoreKit, StoreKit SwiftUI, ServiceManagement, IOKit,
  AdServices.

The mix is consistent with native media/document processing, Quick Look
previews, QR/face analysis, launch-at-login, sandbox/security-scoped access,
and Apple purchase attribution.

## Package inventory

The extracted app contains 467 regular files/symlinks and approximately
180,005,390 bytes of file data. It contains 59 thin Mach-O files: 31 arm64
and 28 x86_64. The dominant payloads are the two bundled JDK module images,
FFmpeg, the Java VM libraries, the SwiftUI asset catalog, and Apache POI/PDFBox
JARs.

Important resources:

| Resource | Role | Observed size |
| --- | --- | ---: |
| `Contents/MacOS/Tangerine` | Main Swift/AppKit/SwiftUI binary | 11,200,496 bytes |
| `Resources/Tools/ffmpeg` | Local media conversion helper | 21,986,240 bytes |
| `Resources/Tools/cwebp` | Local WebP encoder/decoder helper | 505,024 bytes |
| `Resources/ExifTool/` | Vendored ExifTool Perl distribution | 204 `.pm` modules plus bridges |
| `Resources/PowerPoint/` | Bundled Java 21 + POI/PDFBox runtime | roughly 130 MB |
| `Resources/OfficePreview.js` | Offline DOCX/Office preview bridge | 188,843 bytes |
| `Resources/PagesWriter.js` | Pages IWA reader/writer bridge | 694,646 bytes |
| `Resources/PagesTemplate.pages` | Blank Pages template | 82,768 bytes |
| `Resources/Assets.car` | Compiled macOS assets | 3,324,536 bytes |
| `Resources/PrivacyInfo.xcprivacy` | Apple privacy declaration | 1,455 bytes |
| `Resources/RevenueCat_RevenueCat.bundle` | RevenueCat resource bundle | small bundle |

The main binary has no `LC_ENCRYPTION_INFO_64` command, so it is not FairPlay-
encrypted in this snapshot. Its embedded CodeDirectory identifies the binary
as `com.th.Tangerine`; the embedded team identifier is `GTF45UH2VQ`.

## Architecture and components

### Application shell

Recovered native types and source-file names include:

- `AppDelegate`;
- `MenuBarController`;
- `WelcomeModel`, `WelcomeView`, and `WelcomeWindowController`;
- `SettingsWindowController`, `TangerineSettingsModel`, and settings views;
- `OperationProgressController` and
  `OperationProgressWindowController`;
- `ConversionOverlayController`, `ConversionOverlayView`,
  `ConversionOverlayPanel`, `ConversionTaskStore`, and
  `FormatDropTarget`;
- `FanBackdropView`, `NativeGlassFanView`, `FanCenterLabelView`, petal/tint
  views, and highlight-sound support.

The shell is therefore a menu-bar utility with transient panels rather than a
traditional document-window application. The strings explicitly describe a
conversion fan/wheel, drag shortcuts, the icon near the clock, a welcome flow,
and a “Tangerine is working” menu-bar state.

### Drag/drop and output publication

`DragGestureMonitor.swift` and `FormatDropTarget` implement the central drag
workflow. The binary contains diagnostics such as:

- “Monitoring drag-to-convert gestures”;
- “Drop only accessible files”;
- “Drop at least one item”;
- “No shared actions for selected files”;
- “No installed converter for …”;
- “The converter finished without creating an output file.”

`ConversionTaskStore` tracks conversion records and errors. Output publication
is a separate concern: `OutputPublication` verifies that an output exists in
the destination folder before reporting success. The UI has explicit states
for operation progress, finished-with-errors, failed conversion, and output
confirmation failure.

### Conversion categories

The recovered category labels are:

```text
images, documents, spreadsheets, audio, video, archives, subtitles
```

The full extension list observed in the binary is:

```text
jpg png webp heic tiff svg avif bmp pdf
mp3 m4a wav flac ogg opus aiff wma
mp4 mov mkv webm avi wmv gif
docx pages ppt pptx txt rtf rtfd textClipping html epub
xlsx xls ods csv tsv srt vtt zip tar gzip rar
```

The exact source-to-destination compatibility matrix is represented by
`SupportedFormatsMatrix`, `SupportedFormatGroup`, and
`FormatCompatibilityMatrix`; the static binary does not expose every matrix
cell as a readable string. The list above is the strongest recovered format
inventory, not a claim that every pair is convertible.

### File tools and editing workflows

`FileToolOptionsModel`, `FileToolOptionsView`, and
`FileToolOptionsWindowController` expose the following tool identifiers:

```text
compress                 removeMetadata            editImage
annotateImage            frameImage                cropImage
normalizeAudio           muteVideo                 trimVideo
splitPDF                 organizePDF               extractArchive
createPDF                mergePDF                  cropVideo
changeVideoSpeed         joinVideos                videoSnapshots
splitVideo               audioToVideo              trimAudio
audioChannels            createCollage             readQRCode
redactImage              redactVideo               redactAudio
```

Observed option/state fields show that these are interactive editors rather
than one-shot command wrappers. Examples include:

- image adjustment parameters for exposure, highlights/shadows,
  temperature/tint, noise reduction, and sharpening;
- image compression presets, target-size mode, target bytes, and reduction
  percentage;
- frame canvas ratio, background color/image/gradient, padding, corner
  radius, shadow, and fill/fit behavior;
- audio channel count and left/right volume balance;
- audio normalization target loudness, loudness range, and true peak;
- trim start/duration, video crop rectangle, speed from `0.25` to `4` times,
  snapshot times, split points, and removed clips;
- video redaction rectangles and audio bleep ranges;
- PDF page order, per-page rotation, and equalized page widths.

The UI strings confirm concrete workflows such as “Save Organized PDF”,
“Export One Video”, “Save Bleeped Copy”, “Save Redacted Copy”, “Save with
Background”, “Save Annotated Copy”, and “Save Edited Copy”.

### Image annotation and redaction

`AnnotationEditorView` and related types expose arrow, freehand, rectangle,
ellipse, highlighter, numbered callout, magnifier, text, and pasted-image
annotations. The editor supports moving/resizing annotations and keyboard
deletion.

Photo redaction has two modes, `Solid` and `Blur`, with a `detectPhotoFaces`
path visible in the binary. The UI states that a redaction preview draws
rectangles over a sensitive area and that the original file remains separate
from the saved redacted copy. Video redaction is timeline-based: rectangles
have a start/end time and can cover the entire video. Audio redaction is a
timeline of bleep ranges with playhead controls and “Bleep Entire Audio”.

### Media backend

The app ships a custom arm64 FFmpeg `8.0.3` build. Its embedded build
configuration claims:

- static build with network autodetection disabled;
- no `ffplay`/`ffprobe`;
- AudioToolbox and VideoToolbox enabled;
- zlib, libmp3lame, and libwebp enabled;
- WebP animation encoder disabled;
- macOS 13 minimum and arm64 target.

The main binary invokes local helper processes with flags including
`-progress`, `-nostats`, `-nostdin`, `-loglevel`, `-map`, `-movflags`,
`-map_metadata`, `-map_metadata:s`, `-c:a`, `-b:a`, `-af`, `-ac`, and
`-pix_fmt`. Filter strings show implementations for:

- aspect-ratio-preserving scaling and padding;
- palette generation and palette use for GIF-like output;
- `silencedetect` for automatic silent-end trimming;
- gain/normalization and audio channel mapping;
- `gblur` for video redaction;
- visualizer generation with an optional static image.

The app also looks for system `cwebp` and `ffmpeg` at `/opt/homebrew/bin` and
`/usr/local/bin` before using bundled tools. Those fallback paths were
recovered from strings; their actual selection order requires a macOS run.

### Documents, EPUB, and Office

The document subsystem is large and mostly self-contained:

- `PDFOfficeConverter`, `OfficePDFRenderer`, and `EPUBPDFRenderer` convert
  documents to PDF or reflow them into editable structures;
- the Office JavaScript bridge embeds JSZip and a DOCX preview implementation;
- the Pages bridge reads/writes Apple IWA packages and exposes
  `readPages`, `writePages`, and `inspectPages` globals;
- the PowerPoint/spreadsheet runtime is a bundled Java 21.0.12.1 image with
  Apache POI 5.5.1, PDFBox 3.0.6, PDFBox-Graphics2D 3.0.5, Commons libraries,
  XMLBeans 5.3.0, and a small app-specific JAR;
- the app uses WebKit/JavaScriptCore for offline vector/Office/EPUB rendering
  rather than depending on an online document service.

The PowerPoint helper class `TangerinePowerPoint` uses Apache POI and PDFBox
to render PPT/PPTX slides to PDF and rebuild PowerPoint from PDF page images.
Static constants and error strings establish these protections:

- source must be a regular file and be at most 128 MB;
- the presentation must contain 1–1,000 slides/pages;
- page dimensions must be finite and within a supported bound;
- external linked resources are rejected;
- charts, SmartArt, embedded objects, and unsupported graphic frames are
  rejected instead of silently approximated;
- missing or unverifiable pictures/pages fail the conversion;
- the generated PDF page count is verified.

The spreadsheet helper `TangerineSpreadsheet` handles XLS/XLSX, ODS, CSV/TSV,
and PDF-to-XLSX workflows. Its recovered limits and checks include:

- 128 MB document limit;
- 1–256 worksheets;
- XLS limits of 65,536 rows and 256 columns;
- a two-million-cell limit;
- a five-thousand-PDF-page output limit;
- a one-million-character delimited field limit;
- rejection of unterminated quoted fields;
- rejection of hidden-only/no-visible-sheet workbooks;
- removal/rejection of drawings, charts, and embedded spreadsheet objects;
- protected XML parser settings that disallow DTDs, external general
  entities, external parameter entities, external DTD access, and external
  schema access;
- explicit ODS path/package and repeated-row/column validation.

`PagesWriter.js` similarly validates package contents, keeps output editable
where possible, and rejects unsupported drawings rather than flattening them
without notice. The bundled blank Pages template contains ordinary IWA package
paths and the marker `Template: Blank (13.2)`.

### Archives and subtitles

`ArchiveConverter`, `RAREntry`, and archive-related strings show ZIP, TAR,
GZIP, and RAR workflows. The app reports when the source archive is empty and
when an output format cannot store a given entry type. The exact 7z support is
not in the recovered extension enum even though vendored ExifTool can read
7z metadata; do not assume archive extraction supports 7z without a runtime
test.

`SubtitleConverter` handles SRT/VTT-style text and rejects invalid UTF-8 or
files without valid subtitle cues.

### File actions and floating files

The app includes these non-conversion actions:

- copy file/folder paths to the clipboard;
- copy files/folders to a chosen destination;
- move files/folders to a chosen destination;
- open a terminal in a local folder;
- AirDrop files;
- float files in a persistent Finder-like thumbnail window.

`FloatingFileWindowController` owns a floating window with grouping, drag
selection, rubber-band selection, Quick Look, thumbnails, detachable tabs,
and a paper-clip visual. The app explicitly prevents copying/moving remote or
non-local URLs and prevents moves into invalid/same destinations.

The terminal action recognizes Apple Terminal and iTerm2 by bundle identifier,
reports when iTerm2 is not installed, and lets the user choose the terminal
application in settings.

## Metadata and privacy implementation

### User-facing metadata editor

`MetadataEditorView` and the two vendored Perl bridges implement metadata
inspection, field-level editing/removal, and a separate “Remove All” path.
The bridge is intentionally offline and fail-closed:

- it disables arbitrary ExifTool configuration loading;
- it parses unknown XMP with XML parser callbacks that reject DTDs and
  external entities;
- it treats nested/unknown XMP properties as grouped removable units;
- it keeps rendering-critical information protected, including orientation,
  color profiles, dimensions, codec-related properties, HDR/gain-map data,
  and auxiliary image packets;
- it checks that selected changes match the original metadata snapshot before
  writing, preventing stale-editor overwrites;
- it refuses to overwrite an existing destination;
- it verifies image data hashes before and after a rewrite;
- it verifies that unselected rendering information is unchanged;
- it rejects output if private EXIF/XMP/IPTC/Photoshop/JUMBF/MakerNotes data
  remains where the selected operation promised removal.

The `Remove All` privacy path explicitly handles TIFF directories and has a
custom HEIC/HEIF box parser. It removes metadata item records and zeroes their
payloads while preserving image-data offsets, retaining only a minimal
orientation case where required for display. It rejects unsupported or
externally referenced HEIC layouts instead of guessing.

The code also has a GIF-specific rendering-stream hash because ExifTool's
ordinary image-data hash does not cover all GIF timing/disposal/loop details.

### Privacy manifest

`Resources/PrivacyInfo.xcprivacy` declares:

- `NSPrivacyTracking=false`;
- no tracking domains;
- purchase history collected, not linked and not used for tracking, for app
  functionality;
- UserDefaults access reason `CA92.1`;
- system boot time access reason `35F9.1`;
- file timestamp access reasons `3B52.1` and `C617.1`.

This is an Apple declaration, not an independent proof that no other data is
processed. It is consistent with RevenueCat purchase state and local file
metadata/processing behavior.

## Persistence, permissions, and user flow

### First run

The welcome flow stores `hasCompletedWelcome` and includes pages for:

1. learning the drag-and-modifier-key wheel;
2. choosing launch at login;
3. allowing home-folder access or deferring to per-folder prompts;
4. confirming the menu-bar icon and finishing onboarding.

The user can skip home-folder access. In that case macOS asks for each output
folder when needed. The app explains that allowing a parent folder covers
folders below it.

### Folder access

`FolderAccessStore` and the `folderAccessBookmarks` key indicate that the app
stores security-scoped bookmark data. It calls URL bookmark creation and
resolution APIs, starts/stops security-scoped resource access, and refuses to
save when the source/output folder is outside the granted scope.

The app's intended output rule is “results are saved beside the originals”.
The user can grant the home folder once or authorize individual parent
folders.

### Settings and defaults

Recovered keys and state names include:

```text
hasCompletedWelcome
didMigrateToolsWheelToCommand
folderAccessBookmarks
conversionWheelDragModifierMask
conversionFanTheme
soundsAndHapticsEnabled
floatWheelBehavior
settingsFreeUses
settingsFullVersion
freeUsesConsumed
com.th.Tangerine.usage
```

The app ships several usage-store implementations:

- `DefaultsUsageCountStore`;
- `KeychainUsageCountStore`;
- `MirroredUsageCountStore`;
- `InMemoryUsageCountStore`;
- `UnlockStore`.

This indicates a deliberate fallback/migration strategy for free-use counts
and purchase state. The static binary does not prove which store is selected
on every OS/install state.

### Launch at login

`LoginItemController` and `ServiceManagement` implement the launch-at-login
setting. The UI reports that the user may need to allow Tangerine in macOS
Login Items and offers an “Open Login Items” action.

## Monetization and network/data flow

### Purchase flow

The paywall and purchase types are visible in both source-file names and
strings:

- `PaywallModel`, `PaywallWindowController`, `PaywallView`, and
  `RevenueCatPurchaseService`;
- `UnavailablePurchaseService` for missing/unavailable purchases;
- “Unlock Tangerine”, “Restore Purchase”, “Unlimited conversions and tools”,
  “Batch drops of any size”, and “One-time purchase, no subscription”;
- “free uses left” and “Full version unlocked” states;
- restore-purchase handling for an Apple Account with no prior purchase;
- RevenueCat packages named `monthly` and `lifetime` in the linked SDK, while
  the app-facing copy emphasizes a one-time purchase.

The app reads a RevenueCat client API key from `Info.plist`. The key is
redacted in this report; it is not a server secret and must be treated as
public client configuration. Actual product identifiers and entitlement names
are not clearly present in the app-specific string block, so the live
RevenueCat dashboard/StoreKit configuration determines the current offering.

The binary links StoreKit 1/2 and RevenueCat purchase/receipt/restore code. It
also contains RevenueCat paywall, remote-config, offline-entitlement, and
purchase-history code. The presence of generic RevenueCat capabilities such as
web purchases, virtual currencies, and ad event tracking is an SDK fact; it
does not prove that Tangerine exposes every one of those features.

### Network destinations

App-specific readable URLs are limited to:

- `https://tangerineformac.com/privacy`;
- Apple's standard EULA URL;
- RevenueCat service URLs and RevenueCat diagnostic/fallback URLs from the
  linked SDK.

No Tangerine-specific content API, sync service, upload endpoint, or custom
database host was recovered. The app's core conversion paths are local and
use local file URLs. RevenueCat can communicate with its own backend for
offerings, customer info, receipts, entitlements, diagnostics, and purchase
restore.

The document renderer embeds offline content rules. The recovered WebKit rule
lists block `http://`, `https://`, and in one renderer `file://` navigation.
The Office/EPUB output uses local HTML/data images and strict content security
policy strings. This is strong evidence that local document conversion was
designed not to fetch arbitrary document resources.

The main binary imports `AdServices`, and RevenueCat contains attribution
code. The privacy manifest nevertheless declares no tracking. A dynamic test
would be needed to determine whether any attribution token is actually sent
in this build and under which user action.

### Sandbox and embedded entitlements

The main binary's embedded entitlements are:

```text
com.apple.application-identifier = GTF45UH2VQ.com.th.Tangerine
com.apple.developer.team-identifier = GTF45UH2VQ
com.apple.security.app-sandbox = true
com.apple.security.files.bookmarks.app-scope = true
com.apple.security.files.user-selected.read-write = true
com.apple.security.network.client = true
```

### User-run macOS signature validation

The corrected default, non-launching collector was rerun on an Apple Silicon
Mac against the bundle at `reverse-engineering/Tangerine.app`. The
user-provided output reported:

- `Info.plist` syntax valid and bundle identifier `com.th.Tangerine`;
- a thin arm64 main executable;
- `codesign --verify --deep --strict` valid on disk and satisfying its
  designated requirement;
- Gatekeeper accepted the bundle with `source=Mac App Store`;
- Apple Mac OS Application Signing authority, team identifier `GTF45UH2VQ`,
  CodeDirectory `v=20500` with the runtime flag, and 462 sealed resources;
- embedded entitlements matching the static extraction above: App Sandbox,
  app-scoped bookmarks, user-selected read/write access, and network client;
- the entitlement XML parsed successfully after the collector separated
  `codesign` diagnostics on stderr from entitlement XML on stdout.

The reported CDHash was
`a649af2fa1d7bdc1c5cfef3e42ee455b97c03d62`; the full SHA-256 CodeDirectory
hash was
`a649af2fa1d7bdc1c5cfef3e42ee455b97c03d62f237a4286c93f1335808d61c`.
This confirms package integrity and admission/signing observations for that
copy, but it is not a runtime test: the collector was run without `--launch`.
Conversion behavior, cleanup, process arguments, network traffic, and
purchase flows remain unvalidated.

### User-run bounded launch observation

The same Apple Silicon Mac then ran the collector with
`--launch --seconds 20`. The repeated static and signing checks passed, the
macOS `open` launch request returned success, and the collector waited the
full 20-second observation window without terminating any process. At the end
of that window, `pgrep -x Tangerine` reported two matching process IDs.

This establishes that one or more processes named `Tangerine` were visible
after the launch request. The collector does not compare before/after process
lists, inspect windows, or prove that either process was newly created by this
invocation, so this is process-visibility evidence rather than proof of UI
readiness, conversion behavior, cleanup, network behavior, or purchase flows.

## Clean-room reconstruction status

The repository now includes a native macOS SwiftUI reconstruction under
`reconstruction/TangerineReplica/`. It is based on the observed menu-bar shell,
welcome flow, conversion fan, recovered categories/actions, settings keys, and
drag/drop state. It is not an exact binary clone and does not copy the shipped
executable, signing identity, RevenueCat client configuration, or bundled
converter helpers. The reconstruction deliberately reports unsupported
conversion backends instead of claiming behavior that the available REA and
macOS evidence did not establish.

The Linux worker has no Swift/Xcode toolchain, so the reconstruction has not
been compiled here. A macOS build and visual comparison remain required.

FFmpeg and cwebp carry sandbox-inherit entitlements. The embedded Java
launcher carries sandbox inheritance plus `com.apple.security.cs.allow-jit`.
That JIT entitlement is expected for a bundled Java VM, but it increases the
amount of third-party code that should be kept behind strict input limits.

## Security assessment

### Positive controls recovered

1. **Sandbox boundary.** The application and helper binaries are signed with
   sandbox entitlements; file access is explicitly user-selected/bookmark
   based.
2. **Local-first processing.** The main conversion architecture uses local
   files and bundled helpers rather than uploading user documents to a custom
   service.
3. **Offline renderers.** WebKit renderer rules block external navigation and
   the Office/EPUB code rejects unsafe paths, escaped package paths, DTDs,
   entities, duplicate ZIP paths, symbolic links, oversized XML, and
   excessive nesting.
4. **Fail-closed metadata removal.** The ExifTool bridge checks source
   snapshots, preserves image hashes/appearance data, refuses unsupported
   layouts, and rejects output if private metadata remains.
5. **Output verification.** Conversion tasks verify that outputs exist and
   that output pages/worksheets/image data can be read back.
6. **Resource limits.** The Office, spreadsheet, PDF, EPUB, and media paths
   contain explicit size, page, row, column, cell, duration, spacing, or
   nesting checks.

### Risks and unknowns

1. **No runtime validation here.** The Linux worker cannot validate actual
   process arguments, sandbox behavior, dynamic URL requests, file cleanup,
   or whether every advertised rejection is reachable.
2. **Large helper attack surface.** Apache POI, PDFBox, XMLBeans, FFmpeg,
   ExifTool, WebKit, and a JDK create a substantial parser surface. The
   explicit limits are helpful, but dependency patch level and fuzz behavior
   need a macOS test harness.
3. **JDK JIT entitlement.** The inherited JIT entitlement is necessary for
   Java but makes the bundled office path more privileged than a pure native
   parser.
4. **Client purchase key.** The RevenueCat key is embedded in the app and
   therefore recoverable by any user. It should never be treated as a secret;
   entitlement enforcement must remain server-side.
5. **Fallback tools.** The binary searches common Homebrew/system paths for
   FFmpeg/cwebp. A dynamic audit should confirm that it does not accidentally
   run an unexpected user-controlled executable or accept unsafe PATH-based
   substitutions.
6. **Build-path leakage.** Debug-readable strings contain an absolute source
   path from the original build workstation. It is redacted here, but this is
   unnecessary information disclosure in a release binary.
7. **Architecture packaging.** The main app is arm64-only while Java helpers
   include x86_64. Intel support is not established by the presence of the
   x86_64 JDK.

## Reconstructed end-to-end flows

### Drag conversion

```text
User drags local files
  -> DragGestureMonitor observes modifier combination
  -> FormatDropTarget validates accessibility and selected category
  -> ConversionOverlay presents compatible formats/actions
  -> ConversionTaskStore creates one or more operation records
  -> native converter or helper process runs with progress callbacks
  -> output is written beside source after security-scope authorization
  -> OutputPublication confirms the file in the destination folder
  -> progress window/menu-bar state reports success or per-item failures
```

### Image privacy cleanup

```text
User selects Remove Metadata / Remove All
  -> ImageIO/ExifTool bridge reads metadata and image-data hash
  -> UI exposes safe editable/removable fields
  -> user selects fields or all-private-data mode
  -> bridge writes a new destination, never overwriting the source
  -> image hash and rendering invariants are re-read
  -> private metadata is scanned for leftovers
  -> only verified output is published beside the original
```

### Purchase/unlock

```text
App starts
  -> Purchases service reads RevenueCat client configuration
  -> offerings/customer info are fetched or served from RevenueCat cache
  -> local free-use/unlock store determines feature gate
  -> paywall offers purchase or restore
  -> StoreKit transaction/receipt is handled by RevenueCat
  -> customer info/entitlement state updates UnlockStore
  -> UI changes from free-use state to Full version unlocked
```

### Offline document conversion

```text
User drops Office/EPUB/Pages input
  -> package/path/XML limits are checked
  -> local JS/PDF/Java bridge parses the document
  -> external URLs/entities/linked resources are rejected or blocked
  -> pages/text/tables/artwork are rendered or reflowed
  -> output is written and reopened for verification
```

## Evidence hashes and reproducibility

These hashes identify the analyzed snapshot:

| Artifact | SHA-256 |
| --- | --- |
| Attached ZIP | `5e9e0000a91bdab98a81dda603974dadf9a105ad2527e8113a5aad6f0cbbff8b` |
| Main `Tangerine` binary | `7691b34cc2c728aaf280041c0a13adef3e5192c43cb3e886a19ae4c69ea92928` |
| Bundled `ffmpeg` | `a2aaac6ef1c8cf57462abf3ded3d22f42fbeed71e1280fab01884522eb36145e` |
| Bundled `cwebp` | `5623c96d4096f54a997b3bb526324d50cd37ced8648282bc903835f8a96a61ea` |
| `tangerine_metadata.pl` | `86384fc48028591063a7a52bfefcd40f20cc96bcaa0baf0db15bbdb5ba6480aa` |
| `tangerine_privacy.pl` | `43a8304615b2c241bf197d233cc32a3b1812beb62f6bb923b49b095046349b50` |
| `tangerine-powerpoint.jar` | `0c5576c93a1f1156d7048acac0cd8f4dfd7834bbf04191a2abd073dd40a7a622` |
| `_CodeSignature/CodeResources` | `1df9b576fae938a437e1f1b979825d8bab44e901595eaadd53ede586e62db0a3` |

Run the reproducible offline checks from the project root:

```sh
make test
```

The checks validate the attached ZIP when it is present, reject archive path
traversal, verify the extracted bundle identity/Mach-O magic, and ensure this
report contains no raw RevenueCat key. They do not execute the application.

### Checks actually run

| Check | Result |
| --- | --- |
| `make test` | Passed; archive/package/report checks completed |
| `python3 -m py_compile tools/verify.py` | Passed |
| `node --check` on `OfficePreview.js` and `PagesWriter.js` | Passed |
| macOS `tools/macos_validate.sh` corrected default rerun (user-supplied output) | Passed; signing, Gatekeeper, and entitlement checks succeeded; no launch was requested |
| macOS `tools/macos_validate.sh --launch --seconds 20` (user-supplied output) | Passed; launch request succeeded and two exact-name `Tangerine` processes were visible after the wait |
| `unzip -tq` on the attached archive | Passed |
| Python ZIP integrity check for all PowerPoint JARs | Passed |
| Python plist parsing for app/privacy/RevenueCat plists | Passed |
| `perl -c tangerine_privacy.pl` | Passed |
| `perl -c tangerine_metadata.pl` | Not runnable in this worker: `XML::Parser` is not installed and is not vendored in the app resources |

The failed Perl metadata check is intentionally recorded rather than hidden.
It does not prove the macOS install is broken: the app labels the path as a
macOS Perl runtime, and the worker does not contain the macOS system modules.
It does establish a deployment dependency that should be verified on the
target OS, because the metadata bridge imports `XML::Parser` at startup.

## Limitations and next steps

The static reconstruction is complete enough to describe the shipped product
and its local architecture, but the following work is still required for a
runtime-complete assessment:

1. The reported Apple Silicon launch-mode run established process visibility
   after a 20-second launch request. UI readiness, sandbox behavior during
   real operations, and actual user-facing runtime behavior still need direct
   observation.
2. Exercise one sample for each extension and record the actual compatibility
   matrix, output filename rules, progress behavior, and cleanup behavior.
3. Test malformed ZIP/EPUB/DOCX/ODS/PDF/HEIC/EXIF inputs against the stated
   limits and confirm failures do not leave partial outputs.
4. Capture process launches and network traffic during onboarding, purchase
   restore, paywall loading, document conversion, and metadata cleanup. Verify
   that document bytes never leave the machine.
5. Inspect the live RevenueCat offerings and product/entitlement mapping in a
   StoreKit sandbox; do not infer product IDs from the generic SDK package
   names.
6. Test Intel behavior separately; the current main binary is arm64-only.
7. Fuzz the native and Java helper parsers within the app's sandbox and
   confirm that temporary files under the `.tangerine-*` prefixes are removed
   after success, failure, and cancellation.

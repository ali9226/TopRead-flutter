# TopRead local compatibility change

Base: flutter_patcher 1.1.0 from pub.dev; the upstream LICENSE is preserved.

Dart 3.13.7's dynamic-interface member index lets a named constructor hide an
identically named field. A `dynamically-callable` row naming `text` therefore
fails for the two Flutter Cupertino text-selection toolbar button classes.
`get:text` is not a valid field name in this interface format.

Before `merge-interface`, the build and interface pipelines promote only these
two exact library/class/member declarations to class-level dynamic declarations.
The compiler then visits instance fields directly, retaining dynamic access to
`text`. Constructor entries in `callable` remain unchanged. Other classes and
members are untouched.

Both referenced and trim inputs are normalized. The official merge adds defaults
which can reintroduce the ambiguous member. After checking the complete original
interface/detail pair with the upstream validator, only those redundant member
rows are removed from the interface, trim interface and detail entries when a
class-wide row already covers them. The tools' real class locations and sources
are retained verbatim; callable constructor rows are untouched. The interface
hash is computed from the actual resulting bytes and the complete transformed
pair must pass the same upstream validator. Original and normalized artifacts
are retained as build-work evidence, outside the published baseline.
No Flutter SDK, native runtime, signing or global package cache is changed.

Asset-only packages, including `cupertino_icons`, may legitimately have no
`lib/` directory. Whole-tier patch source enumeration and source remapping skip
that absent directory while retaining the package configuration and asset
identity. Native package pin validation remains enabled. Regression fixtures
cover absent Dart sources and unchanged native pin checks.

Regression evidence: `verification/flutter_patcher_collision_repro` in the parent
workspace contains a standalone Dart reproducer and compiler-interface dumps.

Asset-only dependencies such as `cupertino_icons` may have a package URI pointing
at a nonexistent `lib/` directory. Patch input scanning now skips that missing
Dart source root. Module remapping preserves the original package identity and
URI without creating an empty fake source directory or a renamed Dart namespace.
The package's real assets remain available to the existing resource bundle
pipeline, and native-plugin pin checks are unchanged. The regression fixture
contains a real pubspec and asset file with no `lib/`, plus a native plugin whose
source changes must still be detected as pinned changes.

Android releases can explicitly request `--android-format both`. The default
remains `apk` for upstream compatibility. A `both` build first produces and
verifies the canonical APK and completes its original kernel/compiler receipt.
It then runs `flutter build appbundle` inside that same controlled build copy,
with the generated bootstrap target, host-trust asset, managed patched engine,
ABI and compiler options unchanged. The published baseline remains the original
APK baseline; the bundle cannot replace its kernel, engine or libapp identity.

Before publication, the AAB base module's engine must match the engine manifest,
its libapp must be byte-identical to the canonical APK's libapp, and its host
trust and complete Flutter resource receipt must match the APK. Existing local
bundletool jars validate the protobuf manifest and actual application ID/build
number. The output contains both `app-release.apk` and `app-release.aab` and a
separate bundle receipt including its hash and engine build ID. A bundle failure
retains build evidence and does not publish a partial output or bypass checks.
The AAB must also have matching JAR signature entries and pass the existing
JDK's `jarsigner -verify` with an explicit verified result. An unsigned JAR's
successful exit code alone is insufficient; the bundle receipt records the
verified signed status. Certificate trust warnings remain distinct from payload
signature verification, as Android upload certificates are commonly self signed.

Bundletool is never downloaded or installed by this change. The tool accepts an
existing `BUNDLETOOL_JAR` (an all.jar) or `BUNDLETOOL_CLASSPATH`, or resolves the
already cached bundletool runtime from Gradle's Maven cache. Missing jars fail
with a setup error. Regression fixtures reject stock/different engines, different
libapp, altered host trust/resources, additional ABI payloads and missing tools.
Actual split APK installation and OTA acceptance remain separate device checks;
a successful structural bundle verification does not claim device verification.

Flutter 3.47.9's final AAB check (`android/gradle.dart:659-668,769-776`) requires
a `libflutter.so.sym`/`.dbg` metadata file, even when the trusted replacement
engine was already stripped. There is no command flag for this heuristic.
Only for that exact Flutter version and exact terminal error, after a newly
produced AAB, the build verifies both ARM64 ELF section tables contain no debug
or full symbol sections, then performs every normal AAB/APK/signature check.
The pinned Flutter code reaches this error only after Gradle returned zero.
All other errors, stale/missing bundles, malformed or unstripped ELF payloads
fail normally. The receipt names this compatibility branch; no SDK modification
or fabricated debug-symbol file is used.

Release APK and AAB verification also rejects native payloads for every ABI
except `arm64-v8a`, including third party plugin libraries without `libapp.so`.
Flutter's target platform flag alone can retain those plugin ABIs and make Play
advertise unsupported devices. The app's release build type therefore filters
NDK ABIs to arm64; debug ABI configuration remains unchanged. Regression fixtures
cover extra APK plugin ABIs and extra AAB base/feature ABIs.
Flutter's default ABI set merges with build-type NDK filters in AGP 8.11.1, so
the release variant also excludes unsupported plugin ABI directories from JNI
packaging. This leaves debug packaging unchanged; actual output verification,
rather than the Gradle declaration, is the final release gate.

The native bootstrap bridge uses NDK r27, so its CMake target explicitly links
with both `max-page-size=16384` and `common-page-size=16384`. The bridge contains
no mmap/mprotect/custom page allocator or hard-coded 4 KB runtime page assumption;
its 64 KB request limit is a transport bound. APK and AAB validation checks every
native ARM64 PT_LOAD alignment and 16 KB file/virtual congruence. APK validation
also runs the existing build-tools `zipalign -c -P 16 4`; AAB validation requires
bundletool config `PAGE_ALIGNMENT_16K` for uncompressed native splits. Fixtures
reject 4 KB, malformed/incongruent ELF and 4 KB/disabled bundle packaging.

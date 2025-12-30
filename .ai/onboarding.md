# Project Onboarding: DFHack

## Welcome

Welcome to the DFHack project! DFHack is a Dwarf Fortress memory access library, distributed with scripts and plugins implementing a wide variety of useful functions and tools including bugfixes, interface enhancements, automation tools, and modding capabilities.

## Project Overview & Structure

The core functionality revolves around providing a unified, cross-platform environment where tools can be developed to extend Dwarf Fortress. The project is organized as a monolithic repository with multiple components, combining a C++ core library with a rich ecosystem of plugins and Lua scripts.

## Core Modules

### `plugins/`

- **Role:** C++ plugins providing complex functionality and performance-critical features that integrate directly with Dwarf Fortress. Plugins must maintain strict binary compatibility with specific DF versions and are the primary performance-critical extension mechanism.
- **Key Files/Areas:**
  - Automation Tools: `autofarm.cpp`, `autobutcher.cpp`, `autochop.cpp`, `autoclothing.cpp`, `autolabor/`, `autonestbox.cpp`, `autogems.cpp`, `autoslab.cpp`
  - Building & Construction: `buildingplan/`, `building-hacks.cpp`, `blueprint.cpp`, `cleanconst.cpp`
  - Gameplay Modification: `createitem.cpp`, `changeitem.cpp`, `changelayer.cpp`, `changevein.cpp`, `channel-safely/`
  - Utility: `cleaners.cpp`, `cleanowned.cpp`, `cursecheck.cpp`, `debug.cpp`
- **Top Contributed Files:** `plugins/CMakeLists.txt` (425 changes - plugin ecosystem management), numerous individual plugin .cpp files
- **Recent Focus:** DF version compatibility updates (53.06, 53.05, 53.04), bug fixes in `buildingplan` (bolt throwers, reinforced walls), `sort` (crash fixes preventing exit crashes), `suspendmanager` (construction blocking), and adding support for new DF features like siege engines and reinforced walls. Recent activity shows plugin lifecycle management with `infinite-sky` temporarily disabled due to DF siege update incompatibility, demonstrating reactive maintenance patterns.
- **Module Dependencies:** Plugins depend on `library/` for core functionality, `library/modules/` for high-level APIs, `library/include/` for type definitions, and generated headers from `library/xml/` for DF structure access. Changes to library APIs can cascade to multiple plugins.

### `library/`

- **Role:** The foundational DFHack core library implementing the dfhooks API that DF calls during initialization and main loop. Orchestrates plugin loading, Lua environment initialization, command dispatch, performance monitoring, and background threads. This is the heart of DFHack that coordinates all other components.
- **Key Files/Areas:**
  - Core Systems: `Core.cpp` (461 changes - initialization, plugin coordination, threading), `PluginManager.cpp`, `Process.cpp` (recently merged into single file), `Error.cpp`, `Debug.cpp`
  - Lua Integration: `LuaApi.cpp` (406 changes - C++ to Lua bridge), `LuaTools.cpp`, `LuaTypes.cpp`, `LuaWrapper.cpp`
  - Data Handling: `DataDefs.cpp`, `DataIdentity.cpp`, `DataStatics.cpp`
  - Platform Support: `Console-posix.cpp`, `Console-windows.cpp`, `Hooks.cpp`, `Crashlog.cpp` (Linux, recently added)
  - Testing: `*.test.cpp` files for unit tests (BitArray.test.cpp, MiscUtils.test.cpp, main.test.cpp)
- **Top Contributed Files:** `Core.cpp` (461 changes), `LuaApi.cpp` (406 changes), `library/CMakeLists.txt` (296 changes - build configuration and code generation)
- **Recent Focus:** Active C++ modernization wave with constexpr usage expansion in Core.cpp (some later rolled back, indicating practical constraints), BitArray complete rewrite for code quality, std::string_view adoption, elimination of C-varargs, improved file system handling with noexcept overloads, unordered map/set implementation, and ABI compatibility maintenance. Recent Linux crashlog implementation shows ongoing platform parity work.
- **Module Dependencies:** Core.cpp depends on all modules (World, Maps, Gui, etc.) and initializes them. Provides services to plugins via PluginManager. LuaApi.cpp bridges to all module functionality for Lua scripts. Nearly every other component depends on library/ either directly or indirectly.

### `library/modules/`

- **Role:** Modular components providing high-level, domain-specific APIs for interacting with Dwarf Fortress gameplay and state. Each module encapsulates knowledge for specific DF subsystems, abstracting raw memory structures into usable C++ and Lua interfaces. These are the primary APIs that plugins and scripts use.
- **Key Files/Areas:**
  - Game State: `World.cpp`, `Maps.cpp`, `MapCache.cpp`, `Gui.cpp`, `Screen.cpp`
  - Entity Management: `Units.cpp`, `Items.cpp` (v53 updates), `Buildings.cpp` (v53 updates, bolt throwers), `Constructions.cpp`
  - Systems: `Job.cpp`, `Materials.cpp`, `Military.cpp` (recent API expansion), `Kitchen.cpp`
  - Events & Persistence: `EventManager.cpp`, `Persistence.cpp`, `Random.cpp`
  - Platform: `DFSDL.cpp`, `DFSteam.cpp`, `Filesystem.cpp` (noexcept overloads), `Renderer.cpp`, `Textures.cpp`
- **Top Contributed Files:** 2065 total changes across this directory, indicating high activity and importance
- **Recent Focus:** Balance between supporting new DF features and improving code quality. Military module API expansion (`addToSquad`, `removeFromSquad`), Units module improvements (cached unit lookups via get_cached_unit_by_global_id, teleportation fixes), Buildings module updates for DF 51.11+ compatibility and v53 items/buildings, Filesystem API enhancements, extensive const correctness improvements throughout, and cleanup of unused includes to reduce compilation dependencies.
- **Module Dependencies:** Modules depend on `library/include/df/` for generated DF structures and `library/include/modules/` for their own headers. Called by `library/LuaApi.cpp` to expose functionality to Lua, and used directly by plugins.

### `library/include/`

- **Role:** C++ header files defining the complete public API and internal structures for DFHack. This is the contract between DFHack components and external plugins. Headers evolve in lockstep with implementation changes to maintain API consistency.
- **Key Files/Areas:**
  - Core Headers: `Core.h`, `DataDefs.h`, `DataIdentity.h`, `Error.h`, `Debug.h`
  - Lua Integration: `LuaTools.h`, `LuaWrapper.h`, `PluginLua.h` (recently split out)
  - Utilities: `Console.h`, `BitArray.h` (complete rewrite), `ColorText.h`, `Export.h`
  - Module Headers: `modules/` subdirectory mirroring library/modules/ structure
  - Generated DF Structures: `df/` subdirectory containing Perl-generated C++ headers from XML definitions
- **Top Contributed Files:** 903 total changes reflecting API evolution and modernization
- **Recent Focus:** Header updates closely track implementation: BitArray header rewrite, unordered map/set type definitions, explicit conversion additions, missing header inclusions, unit_list structure updates, and cleanup work removing unused includes to reduce compilation dependencies. All changes synchronized with C++20 modernization efforts in library/ implementations.
- **Module Dependencies:** Headers in `df/` generated by Perl scripts from `library/xml/` during CMake. Module headers included by plugins and Core.cpp. Changes here affect all consumers of the DFHack API.

### `library/xml/`

- **Role:** Git submodule containing the df-structures repository - the authoritative source of truth for Dwarf Fortress's complete memory layout. XML files define every struct, enum, class, and bitfield that DFHack accesses. During CMake configuration, Perl scripts (codegen.pl using XML::LibXML/LibXSLT) transform these into C++ headers in library/include/df/. This is the critical dependency on the project's critical path for every DF version update.
- **Key Files/Areas:**
  - Structure Definitions: XML files organized by DF subsystem, describing internal data structures
  - Code Generation Source: Consumed by `library/xml/codegen.pl` and supporting Perl scripts
- **Top Contributed Files:** 1352 total changes, making this one of the most frequently updated components
- **Recent Focus:** Extremely high update frequency with multiple automated and manual structure updates per DF version. DF 53.06 alone received three separate structure ref updates on the same day, indicating iterative discovery process. DFHack-Urist bot handles routine submodule tracking while ab9rf manually updates structures for new DF features. Recent work includes siege engine enum definitions, unordered map/set structures, and continuous refinement as DF's memory layout is reverse-engineered.
- **Module Dependencies:** **Critical upstream dependency** - changes here propagate to generated headers in library/include/df/, affecting library/modules/, library/Core.cpp, plugins/, and scripts that access DF structures. Every DF version update starts here. The code generation process in library/CMakeLists.txt defines this as GENERATE_INPUT_XMLS dependency.

### `docs/`

- **Role:** Comprehensive documentation system using reStructuredText and Sphinx, serving as the primary knowledge base for both end users and developers. Acts as the single source of truth for changes via changelog.txt. Built into HTML hosted on ReadTheDocs and bundled with distributions.
- **Key Files/Areas:**
  - User Documentation: `Introduction.rst`, `Installing.rst`, `Quickstart.rst`, `Core.rst`, `Tools.rst`
  - Developer Documentation: `dev/Contributing.rst`, `dev/compile/Compile.rst`, `dev/compile/Dependencies.rst`, `dev/Dev-intro.rst`, `dev/Lua API.rst` (339 changes)
  - Change Documentation: `changelog.txt` (1536 changes - **highest change count in entire project**), `NEWS.rst` (wrapper for processed changelog), `NEWS-dev.rst`
  - Guides: `guides/modding-guide.rst`, `guides/quickfort-user-guide.rst`
  - Plugin Documentation: `plugins/` subdirectory
  - Build Infrastructure: `sphinx_extensions/dfhack/changelog.py` (processes changelog.txt), `build.py`, `gen_changelog.py`
- **Top Contributed Files:** `changelog.txt` with 1536 changes (updated with every feature, fix, and release), `dev/Lua API.rst` (339 changes, tracking API evolution)
- **Recent Focus:** Strong documentation-as-code discipline - changelog.txt updated in same commits as features, synchronized with each release (53.06-r1, 53.05-r1, 53.04-r1). Lua API documentation updates accompany LuaApi.cpp changes (job helpers, slider widget, external DF API links). Demonstrates excellent documentation maintenance practices with docs updated before/during implementation, not after.
- **Module Dependencies:** Processed by Sphinx via conf.py configuration. Changelog content feeds into NEWS.rst. API documentation in dev/Lua API.rst documents interfaces from LuaApi.cpp. Generated docs deployed to ReadTheDocs and hack/docs/ in distributions.

### `scripts/`

- **Role:** Git submodule pointing to DFHack/scripts repository containing Lua scripts - the primary community contribution channel and lower-barrier extension mechanism. Scripts provide user-facing tools, automation, and gameplay enhancements with full access to the Lua API. Can be distributed independently via Steam Workshop or forums.
- **Key Files/Areas:**
  - User Scripts: Various .lua files for gameplay automation and utilities
  - Third-party Integration: Steam Workshop support, mod-specific folders (scripts_modactive, scripts_modinstalled)
  - Runtime Loading: Loaded by Core.cpp via LuaTools, appearing in DFHack's script search paths
- **Top Contributed Files:** 1300 total changes tracked as submodule pointer updates
- **Recent Focus:** Regular automated submodule updates (DFHack-Urist bot) synchronized with DFHack releases showing tight coupling. Pattern shows coordinated version management - submodule pointers updated during release preparation (53.06-r1, 53.04-r1). Multiple automated updates per week suggest active development in scripts repository itself. Script manager improvements for mod integration, Windows script reloading fixes.
- **Module Dependencies:** Consumes Lua API from LuaApi.cpp and LuaTools.cpp. Loaded at runtime by Core.cpp. Scripts can access all module functionality exposed to Lua. Changes to Lua API can affect scripts.

### `.` (Root Directory)

- **Role:** Master build configuration, version management, CI/CD orchestration, and top-level project organization. The CMakeLists.txt here is the entry point for the entire build system, coordinating all submodules and defining global compile flags.
- **Key Files/Areas:**
  - Build System: `CMakeLists.txt` (622 changes - **critical file**), `CMakeSettings.json`, `CMake/` directory, `build/` with platform-specific scripts
  - Documentation Config: `conf.py`, `index.rst`, `.readthedocs.yml`
  - Project Metadata: `README.md`, `LICENSE.rst`, `docs/NEWS.rst` (changelog wrapper)
  - Development Tools: `.pre-commit-config.yaml`, `.ycm_extra_conf.py`
  - CI/CD: `.github/workflows/` (build, test, release automation)
  - Dependencies: `depends/` directory
- **Top Contributed Files:** `CMakeLists.txt` (622 changes - version management, compiler requirements), `conf.py` (documentation build)
- **Recent Focus:** Release coordination with version updates for every DF release (53.06, 53.05, 53.04), compiler toolchain management including MSVC warning level increases (enabling C4062 for exhaustive switch), GCC 10 requirement enforcement, build system improvements (ccache integration, LTS compatibility adjustments), and C++20 standard adoption enforcement. Demonstrates active maintenance of build infrastructure and compiler compatibility.
- **Module Dependencies:** Entry point including library/CMakeLists.txt (core), plugins/CMakeLists.txt (plugins), docs build. Coordinates library/xml and scripts submodules. Global compile flags affect all targets. Version numbers here (DF_VERSION, DFHACK_RELEASE) propagate throughout project.

## Key Contributors

**Analysis Note:** Git history reveals concentrated maintenance responsibility with Kelly Kinkade appearing across nearly all modules, indicating single maintainer dominance for core infrastructure.

- **Myk Taylor (Myk/myk002/myk):** Primary maintainer with extensive contributions (740+ commits: 465 as "Myk Taylor" + 242 as "Myk" + 36 as "myk002"). **Focus areas:** Lua scripts repository (submodule management), API development and Lua bridge enhancements, documentation improvements, and feature development. **Recent work:** Blueprint and stockpiles functionality, nestboxes burrow support, tailor dye automation, UI widget library (Slider widget), and script manager mod integration. **Expertise:** High-level feature development, Lua scripting ecosystem, user-facing tools.

- **Kelly Kinkade (ab9rf):** Core library and structures expert (313 commits). **Critical role** - appears in git history across all modules including library/Core.cpp, library/xml, plugins/, docs/changelog.txt, and CMakeLists.txt. Functions as the de facto release manager coordinating version updates. **Focus areas:** DF memory structure definitions (library/xml updates), core library internals, compiler compatibility enforcement, low-level system work, and release coordination. **Recent work:** BitArray complete rewrite, constexpr improvements in Core.cpp (with pragmatic rollbacks), unordered map/set implementation, structure updates for every DF version (53.06 with 3 updates, 53.05, 53.04), MSVC warning management, and GCC version requirements. **Expertise:** Memory structures reverse engineering, build system, ABI compatibility, C++ modernization, cross-platform compilation.

- **DFHack-Urist via GitHub Actions:** Automated bot (167 commits as "DFHack-Urist via GitHub Actions" + "github-actions[bot]"). Handles routine submodule updates for library/xml (structure auto-updates) and scripts (submodule pointer tracking). Demonstrates high degree of automation in maintenance workflows.

- **Squid Coder:** Plugin and UI development (71 commits). **Focus areas:** Plugin enhancements and new UI widgets. **Recent work:** Slider widget implementation merged into Lua API. **Expertise:** User interface components, widget library.

- **dhthwy:** Code quality and stability improvements (57 commits). **Focus areas:** Bug fixes, code modernization, and cleanup. **Recent work:** Debug filter initialization fixes, unused includes removal from headers, Core.cpp modernization (string_view, constexpr), filesystem noexcept overloads. **Expertise:** C++ modernization, code hygiene, stability improvements.

- **Nicholas McDaniel (nickmcdaniel00):** Platform features and DF version updates (37 commits). **Focus areas:** Platform-specific features and v53 compatibility updates. **Recent work:** Linux crashlog implementation, v53 items/buildings updates, bolt thrower building size fixes. **Expertise:** Platform-specific code, DF structure updates.

- **Christian Doczkal (chdoc):** API documentation and feature exports. **Recent work:** Job helpers export with documentation, Lua API documentation fixes. **Expertise:** API design and documentation.

## Overall Takeaways & Recent Focus

**Synthesis from Git History Analysis:** The project exhibits well-defined patterns in how changes flow through the system, with strong coordination between code and documentation, and clear division between automated and manual maintenance work.

1. **Release Coordination Pattern (Primary Activity):** Changes flow in coordinated waves driven by DF version updates. Each Dwarf Fortress release triggers a cascade: `library/xml/` structure updates (often multiple iterations - DF 53.06 had 3 separate updates) → `CMakeLists.txt` version numbers → `library/Core.cpp` and `library/modules/` API adjustments → `plugins/` compatibility fixes → `scripts/` submodule update → `docs/changelog.txt` and release notes. Kelly Kinkade manages this entire cascade as de facto release coordinator, appearing in commits across all affected modules. Recent versions: 53.06-r1, 53.05-r1, 53.04-r1.1, 53.04-r1, demonstrating rapid response to DF updates.

2. **Code Modernization Wave (Secondary Activity):** Sustained C++ modernization effort spanning multiple contributors and months. Includes C++20 standard adoption project-wide, constexpr usage expansion in Core.cpp (with pragmatic rollbacks when constraints discovered), BitArray complete rewrite, std::string_view adoption, elimination of C-varargs, unordered map/set support matching new DF structures, extensive const correctness improvements across library/modules/, cleanup of unused includes to reduce compilation dependencies, and filesystem API enhancements with noexcept overloads. Shows tension between modernization goals and practical constraints (some constexpr rolled back in Core.cpp).

3. **Documentation-as-Code Discipline:** Exemplary synchronization between code and documentation. `docs/changelog.txt` (1536 changes - highest in project) updated in same commits as features. `docs/dev/Lua API.rst` documentation accompanies `library/LuaApi.cpp` changes. Link additions to external DF API documentation for disambiguation. Plugin disabling documented immediately (infinite-sky). Pattern shows docs updated before/during implementation, not after, preventing documentation drift.

4. **Automated vs Manual Maintenance:** Clear division of labor between automated bot (DFHack-Urist, 167 commits) handling routine submodule updates for library/xml and scripts, and manual maintenance for structure discovery, API changes, and feature work. Bot provides daily/weekly submodule tracking while humans focus on DF version adaptation and feature development.

5. **Feature Development (Tertiary Activity):** New features balanced with maintenance work. Recent additions: automation enhancements (autoclothing dye automation, nestboxes burrow support, animaltrap-reuse tweak), DF v53 feature support (bolt throwers, reinforced walls, siege engine rotation), blueprint/zone recording capabilities, Military module API expansion (addToSquad, removeFromSquad), UI widget library (Slider widget), and platform parity work (Linux crashlog implementation).

6. **Stability & Bug Fixes:** Reactive maintenance addressing crashes and compatibility issues. Recent fixes: sort plugin crash on exit (DF unit_list changes), buildingplan with bolt throwers and bins, suspendmanager construction blocking logic, preserve-rooms/preserve-tombs crashes with missing units, debug filter initialization, script-manager reloading on Windows. Shows responsiveness to user-reported issues.

7. **Plugin Ecosystem Churn:** Plugins regularly added, disabled, moved, or removed based on DF compatibility and maintenance burden. Recent: infinite-sky disabled (DF siege update broke it), army-controller-sanity added, spectate moved to main plugins, many commented-out entries in plugins/CMakeLists.txt indicating deprecated/unmaintained plugins. Demonstrates active curation of plugin ecosystem.

## Potential Complexity/Areas to Note

**High-Change Rate Files (Complexity Indicators):**
- `docs/changelog.txt`: 1536 changes - requires understanding custom syntax and Sphinx processing
- `library/xml/`: 1352 changes - most complex area, requires DF reverse engineering skills, iterative structure discovery (3 updates for single DF version indicates trial-and-error process)
- `scripts/`: 1300 changes - submodule management complexity, requires coordination with separate repository
- `CMakeLists.txt`: 622 changes - central build orchestration point, changes affect entire project
- `library/Core.cpp`: 461 changes - core initialization logic, modernization tensions visible (constexpr rollbacks)
- `plugins/CMakeLists.txt`: 425 changes - plugin ecosystem management, many commented-out plugins indicate maintenance debt
- `library/LuaApi.cpp`: 406 changes - complex C++/Lua boundary, type marshalling complexity

**Critical Complexity Areas:**

- **DF Memory Structure Synchronization (library/xml/ - Highest Risk):** Git history shows multiple structure updates per DF version (3 for 53.06), indicating iterative reverse engineering process. XML definitions must be discovered through memory analysis, trial and error. Code generation process (Perl + XML → C++ headers via library/CMakeLists.txt) is build-time critical path - failures here break entire build. Changes propagate to all DF-accessing code. Only ab9rf appears to have deep expertise here. **Risk:** Single point of knowledge, complex reverse engineering, no clear documentation on structure discovery methodology.

- **Core.cpp Modernization Tensions (461 changes, Multiple Contributors):** Recent git history shows constexpr additions followed by rollbacks ("fix row format, roll back one constexpr"), indicating practical constraints not initially apparent. Multiple contributors (Kelly Kinkade, dhthwy) working on modernization creates potential for conflicts. **Risk:** Modernization changes may introduce subtle bugs, rollbacks suggest incomplete understanding of constraints, threading and initialization code is inherently complex.

- **Multi-Language Integration (C++/Lua - LuaApi.cpp 406 changes):** The bridge between C++ plugins and Lua scripts involves complex type marshalling, memory management, and maintaining API consistency. `LuaApi.cpp` includes 60+ headers from both DFHack modules and DF structures, creating wide dependency surface. Documentation updates in `docs/dev/Lua API.rst` lag slightly behind implementation. **Risk:** Memory safety issues, type marshalling bugs, API versioning challenges, documentation drift.

- **Build System Complexity (CMakeLists.txt 622 changes, Multi-Platform):** Three-level CMake hierarchy (root → library → plugins), code generation from XML (Perl dependency), submodule management (2 submodules with separate repos), platform-specific settings (MSVC vs GCC with different warning levels and versions), optional components (docs, stonesense), and batch file generation for Windows. Git history shows frequent compiler version adjustments. **Risk:** Build breaks affect productivity, cross-platform differences, Perl dependency for code generation, submodule sync issues.

- **Plugin Lifecycle & Compatibility (plugins/CMakeLists.txt 425 changes):** Many commented-out plugins in CMakeLists.txt indicate maintenance challenges. Recent disable of infinite-sky shows reactive compatibility management. Binary compatibility requirements (specific MSVC/GCC versions) strict. **Risk:** Plugin rot, compatibility breaks with DF updates, unclear deprecation process, knowledge of which plugins are maintained.

- **Platform-Specific Divergence:** Separate implementations for Console, Hooks, and Crashlog (recently added for Linux). MSVC vs GCC different warning levels and suppressions managed separately. Debug builds forbidden on Windows (ABI incompatibility). **Risk:** Testing burden, platform-specific bugs, different contributor expertise per platform.

- **Release Process Knowledge Concentration:** Kelly Kinkade appears in git history for nearly every release-critical file (CMakeLists.txt version updates, library/xml, plugins/, docs/changelog.txt, structure updates). **Risk:** Bus factor of 1 for releases, concentrated knowledge of release process, unclear handoff procedures.

## Questions for the Team

**Based on Git History Analysis - Clarifying Observed Patterns:**

1. **Structure Discovery Process:** Why does DF 53.06 require three separate structure updates on the same day in library/xml/? What is the methodology for discovering DF memory structures - is it manual memory inspection, automated tools, or hybrid? How are structure definitions validated before committing? What documentation exists for contributors wanting to help with structure updates?

2. **Core.cpp Modernization Constraints:** What specific constraints led to rolling back constexpr usage in Core.cpp after initial implementation? The git history shows "fix row format, roll back one `constexpr`" - what practical issues were encountered? Are there guidelines for when constexpr is appropriate vs problematic in DFHack's initialization code?

3. **Release Coordination Process:** Kelly Kinkade appears in commits across all release-critical files. Is there documented release checklist/runbook? What is the bus factor mitigation plan for releases? How are release decisions coordinated between main repo, library/xml submodule, and scripts submodule?

4. **Plugin Deprecation Policy:** plugins/CMakeLists.txt contains many commented-out plugins (building-hacks, channel-safely, dwarfmonitor, infinite-sky, etc.). What criteria determine when a plugin is commented vs removed entirely? Is there a formal deprecation process, or is it reactive to DF breakage? Who makes these decisions?

5. **Automated Bot Workflows:** The DFHack-Urist bot handles submodule updates - what triggers these updates? How does the bot know when library/xml or scripts have new commits to pull? What happens when bot updates cause build breaks? Is there human review before automated commits?

6. **LuaApi.cpp Change Patterns:** This file has 406 changes - is there a pattern to when APIs are added vs modified? How is backward compatibility maintained for existing Lua scripts when the C++ API changes? Are there versioning concerns?

7. **Build System Stability:** CMakeLists.txt has 622 changes with frequent compiler version adjustments. How do you test build changes across all supported platforms (Windows MSVC 2022, Linux GCC 10+) before committing? What CI/CD validation exists for build configuration changes?

8. **Cross-Platform Testing:** With separate Console, Hooks, and Crashlog implementations per platform, how do you ensure feature parity? What percentage of development/testing happens on Windows vs Linux? How are platform-specific bugs caught?

## Next Steps

**Prioritized Learning Path Based on Analysis:**

1. **Understand the Build System First (Critical Path):** Before writing any code, understand the build-time code generation process that is unique to DFHack:
   - Read `library/CMakeLists.txt` (296 changes) focusing on the `add_custom_command` for codegen.out.xml generation
   - Examine how `library/xml/codegen.pl` transforms XML to C++ headers in `library/include/df/`
   - Build the project with verbose output to see code generation in action: `cmake .. -G Ninja && ninja -v`
   - Understand that changes to library/xml/ trigger full header regeneration affecting all downstream code
   - **Why this matters:** This is the most complex and critical part of the build, and build failures here are cryptic

2. **Trace a DF Version Update (Real-World Change Pattern):** To understand how the project actually evolves, examine a complete DF version update cycle:
   - Look at git history for 53.06-r1 release: `git log --all --oneline --grep="53.06"`
   - Follow the cascade: structure updates in library/xml (3 commits for 53.06), CMakeLists.txt version change, Core.cpp updates, plugin fixes, changelog.txt entries
   - This reveals the actual workflow and dependencies between modules better than architecture diagrams
   - **Why this matters:** DF updates are the primary activity, understanding this workflow is essential

3. **Study High-Change Files (Where Work Happens):** Focus on the files with most activity:
   - `docs/changelog.txt` (1536 changes): Learn the syntax and see what changes are important enough to document
   - `library/Core.cpp` (461 changes): Read initialization code, understand threading model, note recent modernization attempts and rollbacks
   - `library/LuaApi.cpp` (406 changes): Understand the C++/Lua bridge, examine how new APIs are added
   - `plugins/CMakeLists.txt` (425 changes): See plugin ecosystem - note commented plugins (deprecated), understand plugin registration
   - **Why this matters:** These are the files you'll most likely need to modify, and they show project evolution

4. **Set Up Development Environment with Submodules:** Submodules are critical and frequently cause issues:
   - Clone with `--recursive`: `git clone --recursive https://github.com/DFHack/dfhack`
   - Understand that library/xml and scripts are separate repositories with their own histories
   - Practice `git submodule update --init` and understand when it's needed (after branch switches)
   - Examine .gitmodules to see submodule tracking
   - **Why this matters:** Submodule sync issues are the #1 cause of "Not a known DF version" and missing script errors

5. **Understand Platform Differences Early:** Platform-specific code is pervasive:
   - Identify platform-specific files: Console-windows.cpp vs Console-posix.cpp, Crashlog.cpp (Linux only)
   - Examine CMakeLists.txt compiler checks and warning suppressions for MSVC vs GCC
   - Note that Debug builds don't work on Windows (ABI incompatibility with DF)
   - **Why this matters:** Avoids wasted time trying to debug platform-specific issues on wrong platform

6. **Read Recent PRs for Code Review Standards:** GitHub PR history shows expectations:
   - Look for PRs from recent contributors (dhthwy, Nicholas McDaniel) to see review feedback
   - Note that Kelly Kinkade reviews most PRs, establishes standards
   - Observe that pre-commit hooks enforce formatting (setup with `pre-commit install`)
   - See that documentation updates are expected in same PR as code changes
   - **Why this matters:** Faster PR acceptance, matches team expectations

7. **Explore Plugin Ecosystem (Optional, If Contributing Plugins):**
   - Start with simple, maintained plugins: `3dveins.cpp`, `debug.cpp`
   - Note plugin categories in plugins/CMakeLists.txt: supported vs dev vs commented (deprecated)
   - Understand that plugins link to library/ and depend on generated headers from library/xml/
   - Examine plugin examples in `plugins/examples/skeleton.cpp`
   - **Why this matters:** Plugins are the primary extension mechanism for performance-critical features

8. **If Contributing to Lua Scripts:** Understand the scripts submodule is separate:
   - The scripts/ directory is a submodule pointing to DFHack/scripts repository
   - Changes to scripts require commits in the scripts repo, then submodule pointer update in main repo
   - Script changes have lower barrier but still require Lua API understanding from docs/dev/Lua API.rst
   - **Why this matters:** Contributing to scripts has different workflow than contributing to core/plugins

## Development Environment Setup

1. **Prerequisites:**
   - **Build Tools:** CMake 3.21 or newer, Ninja or Make build system
   - **Compilers:**
     - Linux: GCC 10 or newer (GCC 10 recommended for distribution compatibility)
     - Windows: Microsoft Visual C++ 2022 (MSVC v143, versions 1930-1944)
   - **Languages:** C++20 standard required
   - **Required Tools:** Perl 5 with XML::LibXML and XML::LibXSLT modules (for code generation)
   - **Optional Tools:** Python 3 with Sphinx (for documentation builds), ccache (strongly recommended for build performance), OpenGL headers (for stonesense plugin)
   - **Version Control:** Git (with submodule support)
   - **Other:** zlib compression library, SDL2 development libraries, pthread
2. **Dependency Installation:**
   - **Linux (Ubuntu/Debian):** `apt-get install gcc cmake ccache ninja-build git zlib1g-dev libsdl2-dev libxml-libxml-perl libxml-libxslt-perl`
   - **Linux (Fedora):** `yum install gcc-c++ cmake ccache ninja-build git zlib-devel SDL2-devel perl-core perl-XML-LibXML perl-XML-LibXSLT ruby`
   - **Linux (Arch):** `pacman -Sy gcc cmake ccache ninja git dwarffortress zlib perl-xml-libxml perl-xml-libxslt`
   - **Windows (Chocolatey):** `choco install cmake ccache strawberryperl python sphinx visualstudio2022community --params "--add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"`
3. **Getting the Code:**
   - `git clone --recursive https://github.com/DFHack/dfhack`
   - `cd dfhack`
   - Note: The `--recursive` flag is critical for downloading submodules (scripts and df-structures)
4. **Building the Project:**
   - **Linux:**
     - `cd build`
     - `cmake .. -G Ninja -DCMAKE_BUILD_TYPE:string=Release -DCMAKE_INSTALL_PREFIX=<path to DF>`
     - `ninja install` (or `ninja -jX install` to use X CPU cores)
   - **Windows:**
     - `cd build\win64` (or `build\win32` for 32-bit)
     - Run `set_df_path.vbs` and point to your Dwarf Fortress installation
     - Run `generate-gui.bat` (opens CMake GUI) or `generate-msvc-all.bat` (generates everything)
     - Open `VC2022\dfhack.sln` in Visual Studio 2022 and build the INSTALL target (use Release or RelWithDebInfo, NOT Debug)
     - OR run `install.bat` from command line for quick builds
5. **Running the Application/Service:** Install DFHack into your Dwarf Fortress directory (done by build install step), then launch Dwarf Fortress normally. DFHack will hook in automatically via the dfhooks library interface.
6. **Running Tests:** Run the test suite after building (specific test command not found in checked documentation files, but test infrastructure exists in `test/` directory with Lua and C++ tests)
7. **Common Issues:**
   - **Submodule Issues:** Failing to update submodules (`git submodule update --init`) causes build errors, "Not a known DF version" errors, or missing scripts. Always update submodules when switching branches.
   - **Compiler Version Mismatch:** Using GCC < 10 on Linux or non-MSVC 2022 on Windows causes build failures or ABI incompatibility.
   - **Debug Build on Windows:** Debug builds are NOT binary-compatible with Dwarf Fortress and will crash. Always use Release or RelWithDebInfo.
   - **Perl Module Missing:** Build will fail during CMake configuration if XML::LibXML or XML::LibXSLT Perl modules are not installed (needed for structure code generation).
   - **Python/Sphinx Missing:** Documentation builds will fail without Python 3 and Sphinx installed (can be skipped with BUILD_DOCS option).

## Helpful Resources

- **Documentation:** https://dfhack.readthedocs.org (official documentation, also available offline in `hack/docs` after installation)
- **Issue Tracker:** https://github.com/DFHack/dfhack/issues (for bug reports and feature requests)
- **Contribution Guide:** https://docs.dfhack.org/en/latest/docs/Contributing.html (detailed contributing guidelines, code format, PR guidelines)
- **Communication Channels:**
  - Discord: https://dfhack.org/discord
  - Bay 12 Forums: https://dfhack.org/bay12
  - Reddit: https://www.reddit.com/r/dwarffortress/ (DF subreddit with DFHack discussions)
  - GitHub Discussions: https://github.com/DFHack/dfhack/discussions (for open-ended questions)
- **Learning Resources:**
  - Architecture Diagrams: Available in `docs/dev/Dev-intro.rst` showing DFHack's integration with DF and internal component structure
  - Developer Introduction: `docs/dev/Dev-intro.rst` for development overview
  - Compilation Guide: `docs/dev/compile/Compile.rst` for detailed build instructions
  - Lua API Documentation: `docs/dev/Lua API.rst` for scripting reference
  - Plugin Examples: `plugins/examples/` directory contains template plugins (e.g., `skeleton.cpp`)

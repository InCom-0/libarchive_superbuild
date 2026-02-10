
[libarchive_superbuild](https://github.com/InCom-0/libarchive_superbuild) is a pure CMake wrapper repository that is meant to act as a superbuild of [libarchive](https://github.com/libarchive/libarchive). It is not really useful on its own, it is meant to be used as a dependency in other projects (through CMake ie. by add_subdirectory, FetchContent or [CPM.CMake](https://github.com/cpm-cmake/CPM.cmake)) <br><br>

What it does:
1) Enables users to perform self-contained CMake builds where libarchive is a first class target in CMake (to be linked against) without installing it,
2) Enables users to easily customize libarchive to includes/link just the components/dependencies they need,
3) Enables fully static build of libarchive to keep the binary size down,
4) Enables easy use of libarchive in cross-platform projects (eg. very useful in CI where one would normally link to system installed libarchive on Linux, but need to build libarchive from scratch on Windows or elsewhere where its not available through a standardized package manager),
5) Defaults to attempting to use system installed libarchive first as one normally would on systems where libarchive exists and one doesn't need anything else or special (ie. performs find_package(LibArchive)). Only if it doesn't succeed (or if overriden to not use system installed) does it try to build libarchive from scratch.
<br><br>

Notes:
1) As of Feb 2026 [libarchive_superbuild](https://github.com/InCom-0/libarchive_superbuild) does not support 100% of the dependencies of libarchive to be built as part of the superbuild. However, almost all of the compression libraries are supported (see the option() lines in CMakeLists.txt to learn more),
2) [libarchive](https://github.com/libarchive/libarchive) does include CMake, but it is ancient 'legacy style' CMake that is (arguably) not very ergonomic for it's users and it assumes specific setup and workflow,
3) The author is aware that all of what this does can be achieved in other ways ... but not in ways that are all that straightforward without a lot of digging or know-how (as far as the author knows)
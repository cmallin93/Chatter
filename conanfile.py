from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps

class ChatterConan(ConanFile):
    # -------------------------------------------------------------------------
    # Settings & Options
    # -------------------------------------------------------------------------
    # Settings that affect compatibility. Conan uses these to generate unique
    # package IDs so specific configurations get their own cached binary.
    settings = "os", "compiler", "build_type", "arch"

    # -------------------------------------------------------------------------
    # Layout
    # -------------------------------------------------------------------------
    # cmake_layout tells conan where the build artifacts will land so it can
    # find them after the build step matches standard CMake conventions
    def layout(self):
        cmake_layout(self)

    # -------------------------------------------------------------------------
    # Dependencies
    # -------------------------------------------------------------------------
    # Any Conan packages that Chatter needs go here, separated by build and runtime requirements
    def requirements(self):
        self.requires("boost/1.86.0")

    def build_requirements(self):
        # Build specific tools not linked into the final library
        self.test_requires("gtest/1.14.0")

    # -------------------------------------------------------------------------
    # Toolchain generation
    # -------------------------------------------------------------------------
    # This is where Conan options get passed into CMake as cache variables so CMakeLists.txt can act on them
    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()

        # CMakeDeps generates find_package() config files for any dependencies
        # declared in requirements() above
        deps = CMakeDeps(self)
        deps.generate()

    # -------------------------------------------------------------------------
    # Build
    # -------------------------------------------------------------------------
    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
        # Uncomment to run tests as part of conan build:
        # cmake.test()
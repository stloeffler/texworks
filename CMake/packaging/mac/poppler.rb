# This file contains a formula for installing Poppler on Mac OS X using the
# Homebrew package manager:
#
#     http://brew.sh/
#
# To install Poppler using this formula:
#
#     brew install path/to/this/poppler.rb
#
# Changes compared to Homebrew's standard Poppler formula:
#
#   - TeXworks-specific patches are applied to
#        - help Qt apps find the poppler-data directory.
#        - use native Mac OS X font handling (instead of fontconfig)
#
# Upstream source: https://github.com/Homebrew/homebrew-core/blob/master/Formula/poppler.rb
class Poppler < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base)"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-0.79.0.tar.xz"
  sha256 "f985a4608fe592d2546d9d37d4182e502ff6b4c42f8db4be0a021a1c369528c8"
  head "https://anongit.freedesktop.org/git/poppler/poppler.git"

# BEGIN TEXWORKS MODIFICATION
#  bottle do
#    sha256 "f1c8ead874f888f7324a5ca6c95efd5e04519038393a89a6f7c030b8807bddc1" => :mojave
#    sha256 "5d050e5f3355e4a72c9bfe4128108a4f64228c0e10fe6bb51aac32a07c10e707" => :high_sierra
#    sha256 "438fc1e448307d1bf17bdc37eb74bbc645ff526b26dd0423915b5f68af12a49d" => :sierra
#  end

  version '0.79.0-texworks'

  TEXWORKS_SOURCE_DIR = Pathname.new(__FILE__).realpath.dirname.join('../../..')
  TEXWORKS_PATCH_DIR = TEXWORKS_SOURCE_DIR + 'lib-patches/'
  patch do
    url "file://" + TEXWORKS_PATCH_DIR + 'poppler-0001-Fix-bogus-memory-allocation-in-SplashFTFont-makeGlyp.patch'
    sha256 "c4006033402c05290efec016a02d395aee9b92cdc9ea4eebe94e01a44b449db7"
  end
  patch do
    url "file://" + TEXWORKS_PATCH_DIR + 'poppler-0002-Native-Mac-font-handling.patch'
    sha256 "ac20ddc6c49f01173b7225e3452aca23ea99bdb7bd41b7880ecdb0cabe994bd7"
  end
  patch do
    url "file://" + TEXWORKS_PATCH_DIR + 'poppler-0003-Add-support-for-persistent-GlobalParams.patch'
    sha256 "ba4d43493afeaea13496c5786163cc0b790accaffc991477abc66645e114e11b"
  end
# END TEXWORKS MODIFICATION

  depends_on "cmake" => :build
  depends_on "gobject-introspection" => :build
  depends_on "pkg-config" => :build
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "little-cms2"
  depends_on "nss"
  depends_on "openjpeg"
  depends_on "qt"

  conflicts_with "pdftohtml", "pdf2image", "xpdf",
    :because => "poppler, pdftohtml, pdf2image, and xpdf install conflicting executables"

  resource "font-data" do
    url "https://poppler.freedesktop.org/poppler-data-0.4.9.tar.gz"
    sha256 "1f9c7e7de9ecd0db6ab287349e31bf815ca108a5a175cf906a90163bdbe32012"
  end

  def install
    ENV.cxx11

    args = std_cmake_args + %w[
      -DBUILD_GTK_TESTS=OFF
      -DENABLE_CMS=lcms2
      -DENABLE_GLIB=ON
      -DENABLE_QT5=ON
      -DENABLE_UNSTABLE_API_ABI_HEADERS=ON
      -DWITH_GObjectIntrospection=ON
    ]

    system "cmake", ".", *args
    system "make", "install"
    system "make", "clean"
    system "cmake", ".", "-DBUILD_SHARED_LIBS=OFF", *args
    system "make"
    lib.install "libpoppler.a"
    lib.install "cpp/libpoppler-cpp.a"
    lib.install "glib/libpoppler-glib.a"
    resource("font-data").stage do
      system "make", "install", "prefix=#{prefix}"
    end

    libpoppler = (lib/"libpoppler.dylib").readlink
    [
      "#{lib}/libpoppler-cpp.dylib",
      "#{lib}/libpoppler-glib.dylib",
      "#{lib}/libpoppler-qt5.dylib",
      *Dir["#{bin}/*"],
    ].each do |f|
      macho = MachO.open(f)
      macho.change_dylib("@rpath/#{libpoppler}", "#{lib}/#{libpoppler}")
      macho.write!
    end
  end

  test do
    system "#{bin}/pdfinfo", test_fixtures("test.pdf")
  end
end

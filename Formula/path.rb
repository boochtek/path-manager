class Path < Formula
  desc "Easily manipulate your shell PATH"
  homepage "https://github.com/boochtek/path-manager"
  url "https://github.com/boochtek/path-manager/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256_AFTER_RELEASE"
  license "MIT"
  head "https://github.com/boochtek/path-manager.git", branch: "main"

  def install
    prefix.install "path.sh"
  end

  def caveats
    <<~EOS
      Add the following to your shell profile (e.g., ~/.bashrc or ~/.zshrc):

        source "#{opt_prefix}/path.sh"

      Then restart your shell or run:

        source ~/.bashrc  # or source ~/.zshrc
    EOS
  end

  test do
    # Test that the file exists and is sourceable
    assert_predicate prefix/"path.sh", :exist?
    # Basic syntax check
    system "bash", "-n", prefix/"path.sh"
  end
end

class Path < Formula
  desc "Easily manipulate your shell PATH"
  homepage "https://github.com/boochtek/path-manager"
  url "https://github.com/boochtek/path-manager/archive/refs/tags/v0.9.tar.gz"
  sha256 "ae1c8950908dadb72bfb840dba452bd2a7014dd93a24fb022b2b465ea87f69d4"
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

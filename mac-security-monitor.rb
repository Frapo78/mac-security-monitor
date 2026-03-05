class MacSecurityMonitor < Formula
  desc "Lightweight integrity monitor for macOS using baseline comparison"
  homepage "https://github.com/Frapo78/mac-security-monitor"
  url "https://github.com/Frapo78/mac-security-monitor/archive/refs/tags/v1.0.3.tar.gz"
  sha256 "REPLACE_WITH_RELEASE_ARCHIVE_SHA256"
  license "MIT"

  depends_on :macos

  def install
    libexec.install Dir["*"]

    bin.install_symlink libexec/"src/security-monitor" => "security-monitor"
    bin.install_symlink libexec/"src/security-monitor-update" => "security-monitor-update"
  end

  def post_install
    ENV["BASE_DIR"] = "#{Dir.home}/.mac-security-monitor"
    ENV["CLI_DIR"] = "#{HOMEBREW_PREFIX}/bin"
    ENV["MSM_INSTALL_NONINTERACTIVE"] = "1"
    ENV["MSM_PRESERVE_BASELINE"] = "1"
    ENV["MSM_AUTO_UPDATE_CHECK"] = "false"

    system "#{libexec}/installer/install.sh"
  end

  def caveats
    <<~EOS
      Mac Security Monitor was installed.

      Main commands:
        security-monitor
        security-monitor update-baseline
        security-monitor check-update
        security-monitor upgrade
        security-monitor reinstall
    EOS
  end
end

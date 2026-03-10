class MacSecurityMonitor < Formula
  desc "Lightweight integrity monitor for macOS using baseline comparison"
  homepage "https://github.com/Frapo78/mac-security-monitor"
  url "https://github.com/Frapo78/mac-security-monitor/archive/850e496.tar.gz"
  sha256 "870219a15fc0d7126a8ebe99bf1e71ff19e1868da5bb3434021f5d302172fd49"
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
    ENV["MSM_SKIP_LAUNCHD"] = "1"

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
        security-monitor self-test

      Note:
        LaunchAgent activation is skipped during Homebrew post_install.
        Open a user login session and run:
          security-monitor self-test
    EOS
  end
end

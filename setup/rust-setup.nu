def is_cargo_installed [] {
    (which cargo | length) > 0
}

def --env install_rust [] {
    if $nu.os-info.name == 'windows' {
        let arch = match $nu.os-info.arch {
            "arm64" => "aarch64"
            other => other
        }

        let triple = $"($arch)-pc-windows-msvc"
        let url = $"https://static.rust-lang.org/rustup/dist/($triple)/rustup-init.exe"
        let exe = ([$nu.temp-path 'rustup-init.exe'] | path join)

        http get --raw $url | save --raw --force $exe
        try {
            ^$exe -y
        } catch { |err|
            echo $"Failed to install Rustup: ($err.msg)"
            rm $exe
            return false
        }
        rm $exe
    } else {
        let script = ([$nu.temp-path 'rustup-init.sh'] | path join)
        http get --raw https://sh.rustup.rs | save --raw --force $script
        try {
            ^sh $script -s -- -y
        } catch { |err|
            echo $"Failed to install Rustup: ($err.msg)"
            rm $script
            return false
        }
        rm $script
    }

    # Add cargo bin to this session
    let cargo_dir = ([$nu.home-path '.cargo' 'bin'] | path join)
    if (not ($env.PATH | any {|p| $p == $cargo_dir})) {
        $env.PATH = $env.PATH | append $cargo_dir
    }

  # Return the final status with versions
  is_rust_installed
}
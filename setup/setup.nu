def has-cmd [name: string] { which $name | is-not-empty }
def get-config-dir [] { ($nu.config-path | path dirname) }


def confirm [prompt: string] {
    let ans = (input $prompt | str trim | str downcase)
    $ans in ["y" "yes"]
}

def get-git-url [slug: string, owner_names: list<string>, current_user: string] {
    if $current_user in $owner_names {
        $"git@github.com:($slug).git"
    } else {
        $"https://github.com/($slug).git"
    }
}

def clone-config [git_url: string, config_dir: string, slug: string] {
    ^git clone $git_url $config_dir
    if $env.LAST_EXIT_CODE == 0 {
        print $"✓ Cloned ($slug) into ($config_dir)"
    } else {
        error make { msg: "git clone failed", git_url: $git_url, config_dir: $config_dir }
    }
}

def ensure-nu-in-etc-shells [nu_path: string] {
    if not ("/etc/shells" | path exists ) {
        return
    }
  
    let listed = (open /etc/shells | lines | any {|it| $it == $nu_path })
    if $listed {
        return
    }
    if (has-cmd sudo) {
        print $"Adding ($nu_path) to /etc/shells (sudo may prompt you)..."
        ($nu_path + (char nl)) | ^sudo nu -c 'save --append /etc/shells'
    } else {
        print "sudo not found; skipping /etc/shells update. You may need to add it manually."
    }
}

def change-default-shell-to-nu [] {
    let osname = $nu.os-info.name
    let nu_path = (which nu | get -i path | get -i 0 | default "")
    if ($nu_path | str length) == 0 {
    print "Couldn't find 'nu' in PATH"
    return
    }

    # Ensure it's an allowed shell on macOS/Linux
    ensure-nu-in-etc-shells $nu_path

    if (has-cmd chsh) {
    let res = ^chsh -s $nu_path | complete
    if $res.exit_code == 0 {
        print $"Default shell changed to Nushell at ($nu_path)"
        return
    }
    }
    if $nu.os-info.name != "linux" {
    print $"chsh not available (OS: ($nu.os-info.name)). Try changing your shell manually."
    return
    }
    if not (has-cmd sudo) {
        print $"No chsh and no sudo. Try as root:\n  usermod -s '($nu_path)' '(whoami)'"
        return
    }
    let res = ^sudo usermod -s $nu_path (whoami) | complete
    if $res.exit_code == 0 {
        print "Default shell changed via usermod. Log out and back in."
    } else {
        print $"Couldn't change shell. Try manually:\n  sudo chsh -s '($nu_path)' '(whoami)'"
    }
}

def main [] {
    if not (cmd-exists "git") {
    print "git isn't available on this system"
    return
    }

    # settings
    let slug = "lov3b/nushell-config"
    let owner_names = ["lovbi127" "love"]
    let current_user = (whoami)
    let config_dir = get-config-dir
    let git_url    = get-git-url $slug $owner_names $current_user

    print $"This will REPLACE your Nushell config at: ($config_dir)"
    if (confirm "Continue? [y/N] ") == false {
    print "Aborted."
    return
    }

    clone-config $git_url $config_dir $slug

    if $nu.os-info.name != "windows" and (confirm "Also set Nushell as your default login shell? [y/N] ") {
        change-default-shell-to-nu
    }
}

# run it
main

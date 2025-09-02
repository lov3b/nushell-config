def is_in_git_repo [] {
  let res = (^git rev-parse --is-inside-work-tree | complete)
  $res.exit_code == 0 and ($res.stdout | str trim) == "true"
}

def get_current_git_ref [] {
  try {
    let branch = (^git symbolic-ref --short -q HEAD | str trim)
    if $branch == "" {
      ^git rev-parse --short HEAD | str trim
    } else {
      $branch
    }
  } catch {
    ""
  }
}

$env.PROMPT_COMMAND = {||
  let path = (pwd | str replace --all $nu.home-path "~")
  let user = (whoami)
  let host = (sys host).hostname

  let git_part = if (is_in_git_repo) {
    let ref = (get_current_git_ref)
    if $ref == "" { "" } else { $" \((ansi yellow)($ref)(ansi reset)\)" }
  } else {
    ""
  }

  $"(ansi cyan)($user)(ansi blue)@(ansi magenta)($host)(ansi reset) (ansi blue)::(ansi reset) (ansi green)($path)(ansi reset)($git_part)"
}

def json_f [file?: path] {
    if $file == null {
        print "Please provide a file name"
        return
    }
    let tmp = (mktemp)
    jq . $file | save -f $tmp
    mv $tmp $file
    print $"Formatted ($file)!"
}

def yda [url?: string] {
    if $url == null {
        print "Usage: yda <URL>"
        return 1
    }

    ^yt-dlp ...[
       "-f bestaudio"
       "--extract-audio"
       "--audio-quality 0"
       "--external-downloader aria2c"
       "--external-downloader-args '-x 16 -k 1M'"
       "$url"
    ]
}

def yd [url?: string] {
    if $url == null {
        print "Usage: yd <URL> [sub-langs]"
        return 1
    }

    ^yt-dlp ...[
        "--embed-subs"
        "--merge-output-format mkv"
        "--external-downloader aria2c"
        "--external-downloader-args 'aria2c:-x 16 -k 8M'"
        "$url"
    ]
}

def fix-lw [] {
    xattr -r -d com.apple.quarantine /Applications/LibreWolf.app
}

if (sys host | get name) == "Darwin" {
    let brew_bin = if (uname | get machine) == "arm64" {
        "/opt/homebrew/bin"
    } else {
        "/usr/local/bin"
    }

    if not ($env.PATH | any {|p| $p == $brew_bin }) {
        $env.PATH = [$brew_bin, ...$env.PATH]
    }
}

let cargo_dir = ($nu.home-path | path join .cargo bin)
if ($cargo_dir | path exists) and (not ($env.PATH | any {|p| $p == $cargo_dir})) {
      $env.PATH = $env.PATH | append $cargo_dir
}
